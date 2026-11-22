<?php

namespace App\Console\Commands;

use App\Models\Promotion;
use App\Services\PromotionService;
use App\Services\PushService;
use Illuminate\Console\Command;

/** Envoie la notification des promotions programmées dont la date de début est arrivée. */
class NotifyDuePromotions extends Command
{
    protected $signature = 'promotions:notify';
    protected $description = 'Notifie les clients des promotions programmées qui viennent de démarrer';

    public function handle(PushService $push): int
    {
        $now = PromotionService::nowMs();
        $due = Promotion::where('active', true)
            ->whereNull('notified_at')
            ->whereNotNull('starts_at')
            ->where('starts_at', '<=', $now)
            ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>=', $now))
            ->get();

        foreach ($due as $promo) {
            $push->promo($promo);
            $promo->update(['notified_at' => $now]);
        }
        $this->info($due->count() . ' promotion(s) notifiée(s).');

        return self::SUCCESS;
    }
}
