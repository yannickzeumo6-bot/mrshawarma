<?php

namespace App\Services;

use App\Models\Promotion;

class PromotionService
{
    public static function nowMs(): int
    {
        return (int) round(microtime(true) * 1000);
    }

    /** Promotions actives EN CE MOMENT (dans leur fenêtre de dates). */
    public function current()
    {
        $now = self::nowMs();

        return Promotion::where('active', true)
            ->where(fn ($q) => $q->whereNull('starts_at')->orWhere('starts_at', '<=', $now))
            ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>=', $now))
            ->orderByDesc('created_at');
    }

    /**
     * Meilleure promotion applicable (une seule, pas de cumul entre promos).
     * @param array<int,array{productId:string,category:string,unitPrice:int,qty:int}> $lines
     * @return array{0:?Promotion,1:int}
     */
    public function best(array $lines): array
    {
        $best = null;
        $bestAmount = 0;
        foreach ($this->current()->get() as $p) {
            $amount = $this->amountFor($p, $lines);
            if ($amount > $bestAmount) {
                $best = $p;
                $bestAmount = $amount;
            }
        }

        return [$best, $bestAmount];
    }

    public function amountFor(Promotion $p, array $lines): int
    {
        $eligible = 0;
        foreach ($lines as $l) {
            if ($p->product_id) {
                if ($l['productId'] !== $p->product_id) continue;
            } elseif ($p->category) {
                if ($l['category'] !== $p->category) continue;
            }
            $eligible += $l['unitPrice'] * $l['qty'];
        }
        if ($eligible <= 0) return 0;

        return match ($p->discount_type) {
            'percent' => (int) floor($eligible * min(100, (int) $p->discount_value) / 100),
            'fixed' => min((int) $p->discount_value, $eligible),
            default => 0,
        };
    }
}
