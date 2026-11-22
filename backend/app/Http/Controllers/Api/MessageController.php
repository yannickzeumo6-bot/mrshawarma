<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\Order;
use App\Services\PushService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Discussion client ⇄ livreur, rattachée à une commande. */
class MessageController extends Controller
{
    private const MAX_LENGTH = 1000;

    public function __construct(private PushService $push)
    {
    }

    private function nowMs(): int
    {
        return (int) round(microtime(true) * 1000);
    }

    /** Un client ne voit que ses commandes ; livreur et admin voient toutes les commandes. */
    private function orderFor(Request $request, string $ref): ?Order
    {
        $order = Order::where('ref', $ref)->first();
        if (! $order) return null;
        $user = $request->user();
        if ($user->role === 'client' && (int) $order->client_id !== (int) $user->id) return null;

        return $order;
    }

    private function serialize(Message $m): array
    {
        return [
            'id' => $m->id,
            'senderId' => $m->sender_id,
            'senderRole' => $m->sender_role,
            'senderName' => $m->sender?->name,
            'body' => $m->body,
            'createdAt' => (int) $m->created_at,
        ];
    }

    /** ?after=<id> : ne renvoie que les nouveaux messages (le téléphone interroge toutes les ~5 s). */
    public function index(Request $request, string $ref): JsonResponse
    {
        $order = $this->orderFor($request, $ref);
        if (! $order) return response()->json(['error' => 'Commande introuvable.'], 404);

        $after = (int) $request->query('after', 0);
        $q = Message::with('sender')->where('order_id', $order->id);
        if ($after > 0) {
            $messages = $q->where('id', '>', $after)->orderBy('id')->limit(200)->get();
        } else {
            $messages = $q->orderByDesc('id')->limit(100)->get()->reverse()->values();
        }

        return response()->json([
            'messages' => $messages->map(fn ($m) => $this->serialize($m))->all(),
            'closed' => $order->status === 'delivered',
        ]);
    }

    public function store(Request $request, string $ref): JsonResponse
    {
        $order = $this->orderFor($request, $ref);
        if (! $order) return response()->json(['error' => 'Commande introuvable.'], 404);
        if ($order->status === 'delivered') {
            return response()->json(['error' => 'Cette commande est terminée : la discussion est fermée.'], 409);
        }

        $body = trim((string) $request->input('body', ''));
        if ($body === '') return response()->json(['error' => 'Le message est vide.'], 422);
        if (mb_strlen($body) > self::MAX_LENGTH) return response()->json(['error' => 'Message trop long (1000 caractères maximum).'], 422);

        $user = $request->user();
        $message = Message::create([
            'order_id' => $order->id,
            'sender_id' => $user->id,
            'sender_role' => $user->role,
            'body' => $body,
            'created_at' => $this->nowMs(),
        ]);

        $preview = mb_strimwidth($body, 0, 90, '…');
        $data = ['type' => 'chat', 'ref' => $order->ref];
        if ($user->role === 'client') {
            $this->push->toRole('livreur', 'Message · ' . $order->ref, ($user->name ?: 'Client') . ' : ' . $preview, $data);
            $this->push->toRole('admin', 'Message · ' . $order->ref, ($user->name ?: 'Client') . ' : ' . $preview, $data);
        } else {
            $this->push->toUser((int) $order->client_id, 'Ton livreur · ' . $order->ref, $preview, $data);
        }

        return response()->json(['message' => $this->serialize($message->load('sender'))], 201);
    }
}
