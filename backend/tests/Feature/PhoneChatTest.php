<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PhoneChatTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role, ?string $phone, ?string $email = null, string $name = 'Test'): User
    {
        return User::create(['name' => $name, 'email' => $email, 'phone' => $phone, 'password' => 'motdepasse1', 'role' => $role]);
    }

    private function order(User $client, string $status = 'received'): Order
    {
        return Order::create([
            'ref' => '#12345', 'client_id' => $client->id, 'items_json' => [], 'subtotal' => 1000, 'delivery_fee' => 0,
            'address' => 'Akwa', 'total' => 1000, 'status' => $status, 'placed_at' => 1, 'status_at' => 1,
        ]);
    }

    public function test_livreur_without_email_logs_in_with_any_phone_format(): void
    {
        $this->user('livreur', '690000000', null, 'Paul');

        foreach (['690000000', '6 90 00 00 00', '+237 690 00 00 00', '00237690000000'] as $login) {
            $this->postJson('/api/auth/login', ['login' => $login, 'password' => 'motdepasse1'])
                ->assertOk()->assertJsonPath('user.role', 'livreur')->assertJsonPath('user.phone', '690000000')->assertJsonPath('user.email', null);
        }
        $this->postJson('/api/auth/login', ['login' => '690000000', 'password' => 'faux'])->assertStatus(401);
        $this->postJson('/api/auth/login', ['login' => '699999999', 'password' => 'motdepasse1'])->assertStatus(401);
    }

    public function test_email_login_still_works_with_the_old_field(): void
    {
        $this->user('admin', null, 'admin@mrshawarma.cm');
        $this->postJson('/api/auth/login', ['email' => 'ADMIN@mrshawarma.cm', 'password' => 'motdepasse1'])->assertOk();
        $this->postJson('/api/auth/login', ['login' => 'admin@mrshawarma.cm', 'password' => 'motdepasse1'])->assertOk();
    }

    public function test_client_registration_requires_a_valid_unique_phone(): void
    {
        $base = ['name' => 'Awa', 'email' => 'awa@test.cm', 'password' => 'motdepasse1'];
        $this->postJson('/api/auth/register', $base)->assertStatus(400);
        $this->postJson('/api/auth/register', $base + ['phone' => '12345'])->assertStatus(400);
        $this->postJson('/api/auth/register', $base + ['phone' => '6 71 11 11 11'])->assertCreated()->assertJsonPath('user.phone', '671111111');
        $this->postJson('/api/auth/register', ['email' => 'b@test.cm'] + $base + ['phone' => '+237671111111'])->assertStatus(409);
    }

    public function test_existing_client_can_add_a_phone(): void
    {
        $c = $this->user('client', null, 'old@test.cm');
        $this->actingAs($c, 'sanctum')->patchJson('/api/auth/me', ['phone' => 'abc'])->assertStatus(422);
        $this->actingAs($c, 'sanctum')->patchJson('/api/auth/me', ['phone' => '655 00 00 01'])->assertOk()->assertJsonPath('user.phone', '655000001');
    }

    public function test_admin_manages_livreurs_without_email(): void
    {
        $admin = $this->user('admin', null, 'admin@mrshawarma.cm');
        $this->actingAs($admin, 'sanctum')->postJson('/api/admin/livreurs', ['name' => 'Jean', 'phone' => '677000000', 'password' => 'secret123'])
            ->assertCreated()->assertJsonPath('livreur.email', null);
        $this->actingAs($admin, 'sanctum')->postJson('/api/admin/livreurs', ['name' => 'Bis', 'phone' => '677000000', 'password' => 'secret123'])->assertStatus(409);
        $this->actingAs($admin, 'sanctum')->postJson('/api/admin/livreurs', ['name' => 'Court', 'phone' => '677000001', 'password' => 'abc'])->assertStatus(422);
        $this->actingAs($admin, 'sanctum')->getJson('/api/admin/livreurs')->assertOk()->assertJsonCount(1, 'livreurs');

        $this->postJson('/api/auth/login', ['login' => '677000000', 'password' => 'secret123'])->assertOk();

        $id = User::where('phone', '677000000')->value('id');
        $this->actingAs($admin, 'sanctum')->deleteJson("/api/admin/livreurs/{$id}")->assertOk();
        $this->assertDatabaseMissing('users', ['id' => $id]);
    }

    public function test_only_admin_can_manage_livreurs(): void
    {
        $l = $this->user('livreur', '690000000');
        $this->actingAs($l, 'sanctum')->getJson('/api/admin/livreurs')->assertStatus(403);
    }

    public function test_livreur_sees_the_client_phone_on_active_orders(): void
    {
        $client = $this->user('client', '655123456', 'c@test.cm', 'Awa');
        $this->order($client);
        $l = $this->user('livreur', '690000000');
        $this->actingAs($l, 'sanctum')->getJson('/api/orders/active')->assertOk()
            ->assertJsonPath('orders.0.client.phone', '655123456');
    }

    public function test_chat_between_client_and_livreur(): void
    {
        $client = $this->user('client', '655123456', 'c@test.cm', 'Awa');
        $other = $this->user('client', '655123457', 'o@test.cm', 'Autre');
        $livreur = $this->user('livreur', '690000000', null, 'Paul');
        $order = $this->order($client);
        $url = '/api/orders/' . rawurlencode($order->ref) . '/messages';

        $this->actingAs($client, 'sanctum')->postJson($url, ['body' => 'Je suis devant le portail bleu'])->assertCreated()
            ->assertJsonPath('message.senderRole', 'client');
        $this->actingAs($livreur, 'sanctum')->postJson($url, ['body' => 'J\'arrive dans 5 minutes'])->assertCreated()
            ->assertJsonPath('message.senderName', 'Paul');

        $res = $this->actingAs($livreur, 'sanctum')->getJson($url)->assertOk()->assertJsonCount(2, 'messages')->assertJsonPath('closed', false);
        $firstId = $res->json('messages.0.id');
        $this->actingAs($client, 'sanctum')->getJson($url . '?after=' . $firstId)->assertOk()->assertJsonCount(1, 'messages');

        // Un autre client n'a aucun accès à cette discussion.
        $this->actingAs($other, 'sanctum')->getJson($url)->assertStatus(404);
        $this->actingAs($other, 'sanctum')->postJson($url, ['body' => 'coucou'])->assertStatus(404);

        // Validation
        $this->actingAs($client, 'sanctum')->postJson($url, ['body' => '   '])->assertStatus(422);
        $this->actingAs($client, 'sanctum')->postJson($url, ['body' => str_repeat('a', 1001)])->assertStatus(422);

        // Discussion fermée quand la commande est terminée (lecture toujours possible).
        $order->update(['status' => 'delivered']);
        $this->actingAs($client, 'sanctum')->postJson($url, ['body' => 'merci'])->assertStatus(409);
        $this->actingAs($client, 'sanctum')->getJson($url)->assertOk()->assertJsonPath('closed', true);
    }

    public function test_chat_requires_login(): void
    {
        $this->getJson('/api/orders/' . rawurlencode('#12345') . '/messages')->assertStatus(401);
    }
}
