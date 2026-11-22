<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\Promotion;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

/**
 * Notifications push via Firebase Cloud Messaging.
 * Si PUSH_ENABLED=false (ou Firebase mal configuré), ne fait rien et ne casse rien.
 */
class PushService
{
    private function enabled(): bool
    {
        return (bool) config('shawarma.push.enabled');
    }

    private function build(string $title, string $body, string $channel, array $data): CloudMessage
    {
        return CloudMessage::new()
            ->withNotification(Notification::create($title, $body))
            ->withData(array_map('strval', $data))
            ->withAndroidConfig(AndroidConfig::fromArray([
                'priority' => 'high',
                'notification' => ['channel_id' => $channel],
            ]));
    }

    public function promo(Promotion $p): void
    {
        if (! $this->enabled()) return;
        try {
            $msg = $this->build(
                '🔥 ' . $p->badge() . ' · ' . $p->title,
                $p->description ?: "Une nouvelle promotion vient d'arriver chez Mr. Shawarma !",
                'promotions',
                ['type' => 'promo', 'id' => $p->id]
            )->withChangedTarget('topic', config('shawarma.push.promo_topic'));
            app(Messaging::class)->send($msg);
        } catch (\Throwable $e) {
            Log::warning('Push promo échoué : ' . $e->getMessage());
        }
    }

    public function toUser(int $userId, string $title, string $body, array $data = []): void
    {
        $this->toTokens(DeviceToken::where('user_id', $userId)->pluck('token')->all(), $title, $body, $data);
    }

    public function toRole(string $role, string $title, string $body, array $data = []): void
    {
        $tokens = DeviceToken::join('users', 'users.id', '=', 'device_tokens.user_id')
            ->where('users.role', $role)->pluck('device_tokens.token')->all();
        $this->toTokens($tokens, $title, $body, $data);
    }

    private function toTokens(array $tokens, string $title, string $body, array $data): void
    {
        if (! $this->enabled() || empty($tokens)) return;
        $messaging = app(Messaging::class);
        foreach ($tokens as $token) {
            try {
                $messaging->send($this->build($title, $body, 'orders', $data)->withChangedTarget('token', $token));
            } catch (\Kreait\Firebase\Exception\Messaging\NotFound $e) {
                DeviceToken::where('token', $token)->delete(); // appareil désinstallé
            } catch (\Throwable $e) {
                Log::warning('Push échoué : ' . $e->getMessage());
            }
        }
    }
}
