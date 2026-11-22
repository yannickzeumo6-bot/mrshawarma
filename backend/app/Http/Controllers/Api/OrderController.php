<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Services\DeliveryService;
use App\Services\PromotionService;
use App\Services\PushService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    private const PAYMENT_METHODS = ['cash', 'orange_money', 'mtn_momo'];
    private const ALL_STATUSES = ['received', 'preparing', 'delivering', 'client_confirmed', 'delivered'];

    /** Étapes que le LIVREUR peut faire avancer ("delivering" exige la confirmation du client). */
    private const LIVREUR_NEXT = [
        'received' => 'preparing',
        'preparing' => 'delivering',
        'client_confirmed' => 'delivered',
    ];

    private const LABELS = [
        'received' => 'Commande reçue',
        'preparing' => 'En préparation 👨‍🍳',
        'delivering' => 'En route vers toi 🛵',
        'client_confirmed' => 'Réception confirmée',
        'delivered' => 'Commande terminée ✅',
    ];

    public function __construct(
        private DeliveryService $delivery,
        private PromotionService $promos,
        private PushService $push,
    ) {
    }

    private function nowMs(): int
    {
        return (int) round(microtime(true) * 1000);
    }

    private function newRef(): string
    {
        for ($i = 0; $i < 20; $i++) {
            $ref = '#' . random_int(10000, 99999);
            if (! Order::where('ref', $ref)->exists()) return $ref;
        }

        return '#' . random_int(1000000, 9999999);
    }

    private function fail(string $msg, int $code = 422): JsonResponse
    {
        return response()->json(['error' => $msg], $code);
    }

    /** CLIENT : créer une commande. Prix, promo, distance et frais sont TOUS recalculés ici. */
    public function store(Request $request): JsonResponse
    {
        $items = $request->input('items');
        $address = trim((string) $request->input('address', ''));
        $coords = $request->input('addressCoords');
        $payment = (string) $request->input('paymentMethod', 'cash');
        if (! in_array($payment, self::PAYMENT_METHODS, true)) $payment = 'cash';

        if (! is_array($items) || count($items) === 0) return $this->fail('Le panier est vide.', 400);
        if (count($items) > config('shawarma.orders.max_lines')) return $this->fail('Panier trop volumineux.');
        if ($address === '') return $this->fail('Adresse de livraison requise.', 400);
        if (! is_array($coords) || ! is_numeric($coords['lat'] ?? null) || ! is_numeric($coords['lng'] ?? null)) {
            return $this->fail('Localisation de livraison requise : utilise ta position ou valide ton adresse.');
        }

        try {
            $quote = $this->delivery->quote((float) $coords['lat'], (float) $coords['lng']);
        } catch (\DomainException $e) {
            return $this->fail($e->getMessage());
        }

        $maxQty = (int) config('shawarma.orders.max_qty_per_line');
        $subtotal = 0;
        $resolved = [];
        $lines = [];

        foreach ($items as $raw) {
            $productId = is_array($raw) ? ($raw['productId'] ?? null) : null;
            $product = $productId ? Product::where('id', $productId)->where('active', true)->first() : null;
            if (! $product) return $this->fail('Produit inconnu.');
            if (! $product->available) return $this->fail("« {$product->name} » est indisponible pour le moment.", 409);

            $qty = (int) ($raw['qty'] ?? 1);
            if ($qty < 1 || $qty > $maxQty) return $this->fail("Quantité invalide pour « {$product->name} » (1 à {$maxQty}).");

            $flavor = '';
            if ($product->has_flavors) {
                $flavor = trim((string) ($raw['customization']['saveur'] ?? ''));
                $allowed = $product->flavors_json ?? [];
                if (count($allowed) > 0 && ! in_array($flavor, $allowed, true)) {
                    return $this->fail("Saveur invalide pour « {$product->name} ».");
                }
            }

            $unit = (int) $product->base_price;
            $subtotal += $unit * $qty;
            $lines[] = ['productId' => $product->id, 'category' => $product->category, 'unitPrice' => $unit, 'qty' => $qty];
            $resolved[] = [
                'productId' => $product->id,
                'category' => $product->category,
                'name' => $product->name,
                'qty' => $qty,
                'unitPrice' => $unit,
                'summary' => $flavor !== '' ? "Saveur : {$flavor}" : ($product->description ?? ''),
            ];
        }

        // Fidélité : 1 shawarma offert tous les 10 (le moins cher).
        $shaw = array_values(array_filter($lines, fn ($l) => $l['category'] === 'shawarma'));
        $free = intdiv(array_sum(array_column($shaw, 'qty')), (int) config('shawarma.loyalty.qty_per_free'));
        $loyalty = ($free > 0 && count($shaw) > 0) ? $free * min(array_column($shaw, 'unitPrice')) : 0;
        $loyalty = min($loyalty, $subtotal);

        // Promotion admin : la meilleure uniquement.
        [$promo, $promoAmount] = $this->promos->best($lines);
        $promoAmount = min($promoAmount, $subtotal - $loyalty);

        $total = $subtotal - $loyalty - $promoAmount + $quote['fee'];
        $now = $this->nowMs();

        $order = Order::create([
            'ref' => $this->newRef(),
            'client_id' => $request->user()->id,
            'items_json' => $resolved,
            'subtotal' => $subtotal,
            'promo_discount' => $loyalty,
            'promo_free' => $free,
            'promo_id' => $promoAmount > 0 ? $promo?->id : null,
            'promo_title' => $promoAmount > 0 ? $promo?->title : null,
            'promo_amount' => $promoAmount,
            'delivery_fee' => $quote['fee'],
            'distance_km' => $quote['km'],
            'address' => $address,
            'address_lat' => (float) $coords['lat'],
            'address_lng' => (float) $coords['lng'],
            'total' => $total,
            'payment_method' => $payment,
            'status' => 'received',
            'placed_at' => $now,
            'status_at' => $now,
        ]);

        $this->push->toRole('admin', 'Nouvelle commande ' . $order->ref, number_format($total, 0, ',', ' ') . ' FCFA · ' . $address, ['type' => 'new_order', 'ref' => $order->ref]);
        $this->push->toRole('livreur', 'Nouvelle commande ' . $order->ref, $address, ['type' => 'new_order', 'ref' => $order->ref]);

        return response()->json(['order' => $this->serialize($order)], 201);
    }

    private function serialize(Order $order): array
    {
        return [
            'id' => $order->id,
            'ref' => $order->ref,
            'items' => $order->items_json,
            'subtotal' => (int) $order->subtotal,
            'promoDiscount' => (int) $order->promo_discount,
            'promoFree' => (int) $order->promo_free,
            'promoTitle' => $order->promo_title,
            'promoAmount' => (int) $order->promo_amount,
            'deliveryFee' => (int) $order->delivery_fee,
            'distanceKm' => $order->distance_km !== null ? (float) $order->distance_km : null,
            'address' => $order->address,
            'addressCoords' => ($order->address_lat !== null && $order->address_lng !== null)
                ? ['lat' => (float) $order->address_lat, 'lng' => (float) $order->address_lng] : null,
            'total' => (int) $order->total,
            'paymentMethod' => $order->payment_method,
            'status' => $order->status,
            'placedAt' => (int) $order->placed_at,
            'statusAt' => (int) $order->status_at,
        ];
    }

    private function serializeWithClient(Order $order): array
    {
        $data = $this->serialize($order);
        $c = $order->client;
        $data['client'] = $c ? ['name' => $c->name, 'email' => $c->email] : null;

        return $data;
    }

    private function notifyClient(Order $order): void
    {
        $this->push->toUser($order->client_id, 'Commande ' . $order->ref, self::LABELS[$order->status] ?? $order->status, ['type' => 'order', 'ref' => $order->ref]);
    }

    public function mine(Request $request): JsonResponse
    {
        $orders = Order::where('client_id', $request->user()->id)->orderByDesc('placed_at')->limit(100)->get();

        return response()->json(['orders' => $orders->map(fn ($o) => $this->serialize($o))->all()]);
    }

    /** LIVREUR (+ admin) : commandes en cours. */
    public function active(): JsonResponse
    {
        $orders = Order::with('client')->where('status', '!=', 'delivered')->orderBy('placed_at')->get();

        return response()->json(['orders' => $orders->map(fn ($o) => $this->serializeWithClient($o))->all()]);
    }

    /** ADMIN : toutes les commandes (200 dernières), filtre ?status= possible. */
    public function index(Request $request): JsonResponse
    {
        $q = Order::with('client')->orderByDesc('placed_at');
        $status = $request->query('status');
        if (is_string($status) && in_array($status, self::ALL_STATUSES, true)) $q->where('status', $status);

        return response()->json(['orders' => $q->limit(200)->get()->map(fn ($o) => $this->serializeWithClient($o))->all()]);
    }

    public function confirmReceipt(Request $request, string $ref): JsonResponse
    {
        $order = Order::where('ref', $ref)->where('client_id', $request->user()->id)->first();
        if (! $order) return $this->fail('Commande introuvable.', 404);
        if ($order->status !== 'delivering') return $this->fail("Cette commande n'est pas en attente de confirmation.", 400);

        $order->update(['status' => 'client_confirmed', 'status_at' => $this->nowMs()]);
        $this->push->toRole('admin', 'Réception confirmée', $order->ref . ' : le client a reçu sa commande.', ['type' => 'order', 'ref' => $order->ref]);
        $this->push->toRole('livreur', 'Réception confirmée', $order->ref . ' peut être clôturée.', ['type' => 'order', 'ref' => $order->ref]);

        return response()->json(['order' => $this->serialize($order)]);
    }

    /** LIVREUR (+ admin) : fait avancer d'une étape. */
    public function updateStatus(string $ref): JsonResponse
    {
        $order = Order::where('ref', $ref)->first();
        if (! $order) return $this->fail('Commande introuvable.', 404);
        if ($order->status === 'delivering') return $this->fail('En attente de la confirmation de réception du client.', 400);
        if (! isset(self::LIVREUR_NEXT[$order->status])) return $this->fail('Cette commande est déjà à son statut final.', 400);

        $order->update(['status' => self::LIVREUR_NEXT[$order->status], 'status_at' => $this->nowMs()]);
        $this->notifyClient($order);

        return response()->json(['order' => $this->serializeWithClient($order->fresh('client'))]);
    }

    /** ADMIN : force un statut (débloque une commande dont le client n'a pas confirmé). */
    public function adminSetStatus(Request $request, string $ref): JsonResponse
    {
        $status = (string) $request->input('status', '');
        if (! in_array($status, self::ALL_STATUSES, true)) return $this->fail('Statut invalide.');
        $order = Order::where('ref', $ref)->first();
        if (! $order) return $this->fail('Commande introuvable.', 404);

        $order->update(['status' => $status, 'status_at' => $this->nowMs()]);
        $this->notifyClient($order);

        return response()->json(['order' => $this->serializeWithClient($order->fresh('client'))]);
    }

    /** ADMIN : statistiques. Le chiffre d'affaires ne compte que les commandes terminées. */
    public function statsSummary(): JsonResponse
    {
        $startOfDay = (int) (now('Africa/Douala')->startOfDay()->getTimestamp() * 1000);
        $done = ['delivered', 'client_confirmed'];

        return response()->json([
            'totalOrders' => Order::count(),
            'totalRevenue' => (int) Order::whereIn('status', $done)->sum('total'),
            'delivered' => Order::where('status', 'delivered')->count(),
            'inProgress' => Order::whereNotIn('status', ['delivered'])->count(),
            'todayOrders' => Order::where('placed_at', '>=', $startOfDay)->count(),
            'todayRevenue' => (int) Order::where('placed_at', '>=', $startOfDay)->whereIn('status', $done)->sum('total'),
        ]);
    }
}
