<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Promotion;
use App\Services\PromotionService;
use App\Services\PushService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPromotionController extends Controller
{
    public function __construct(private PushService $push)
    {
    }

    public function index(): JsonResponse
    {
        return response()->json([
            'promotions' => Promotion::orderByDesc('created_at')->get()->map(fn ($p) => $p->toApi())->all(),
        ]);
    }

    private function rules(): array
    {
        return [
            'title' => 'required|string|max:120',
            'description' => 'nullable|string|max:500',
            'discountType' => 'required|in:percent,fixed,info',
            'discountValue' => 'nullable|integer|min:0|max:1000000',
            'productId' => 'nullable|string|exists:products,id',
            'category' => 'nullable|string|max:40',
            'startsAt' => 'nullable|integer',
            'endsAt' => 'nullable|integer',
        ];
    }

    private function check(array $d): ?JsonResponse
    {
        $type = $d['discountType'];
        $val = (int) ($d['discountValue'] ?? 0);
        if ($type === 'percent' && ($val < 1 || $val > 100)) {
            return response()->json(['error' => 'Le pourcentage doit être entre 1 et 100.'], 422);
        }
        if ($type === 'fixed' && $val < 1) {
            return response()->json(['error' => 'Indique le montant de la réduction.'], 422);
        }
        if (! empty($d['startsAt']) && ! empty($d['endsAt']) && $d['endsAt'] <= $d['startsAt']) {
            return response()->json(['error' => 'La date de fin doit être après la date de début.'], 422);
        }

        return null;
    }

    private function fields(array $d): array
    {
        return [
            'title' => trim($d['title']),
            'description' => $d['description'] ?? null,
            'discount_type' => $d['discountType'],
            'discount_value' => $d['discountType'] === 'info' ? 0 : (int) ($d['discountValue'] ?? 0),
            'product_id' => $d['productId'] ?? null,
            'category' => empty($d['productId']) ? (($d['category'] ?? '') !== '' ? strtolower($d['category']) : null) : null,
            'starts_at' => $d['startsAt'] ?? null,
            'ends_at' => $d['endsAt'] ?? null,
        ];
    }

    public function store(Request $request): JsonResponse
    {
        $d = $request->validate($this->rules());
        if ($err = $this->check($d)) return $err;

        $now = PromotionService::nowMs();
        $promo = Promotion::create($this->fields($d) + ['active' => true, 'created_at' => $now]);

        // Démarre déjà ? -> notification immédiate. Sinon la commande planifiée s'en charge.
        if ($promo->starts_at === null || $promo->starts_at <= $now) {
            $this->push->promo($promo);
            $promo->update(['notified_at' => $now]);
        }

        return response()->json(['promotion' => $promo->toApi()], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $promo = Promotion::findOrFail($id);
        $d = $request->validate($this->rules());
        if ($err = $this->check($d)) return $err;
        $promo->update($this->fields($d));

        return response()->json(['promotion' => $promo->toApi()]);
    }

    public function toggle(int $id): JsonResponse
    {
        $promo = Promotion::findOrFail($id);
        $promo->update(['active' => ! $promo->active]);

        return response()->json(['promotion' => $promo->toApi()]);
    }

    public function destroy(int $id): JsonResponse
    {
        Promotion::findOrFail($id)->delete();

        return response()->json(['deleted' => true]);
    }
}
