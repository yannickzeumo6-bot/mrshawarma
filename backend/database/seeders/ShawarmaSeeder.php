<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\User;
use App\Support\Phone;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * php artisan db:seed --class=ShawarmaSeeder
 *
 * - Crée l'admin et le livreur s'ils n'existent pas (mot de passe pris dans .env
 *   SEED_ADMIN_PASSWORD / SEED_LIVREUR_PASSWORD, sinon généré aléatoirement
 *   et affiché UNE SEULE FOIS ici).
 * - Ne change JAMAIS le mot de passe d'un compte existant.
 * - Crée/met à jour le menu officiel (sans toucher à la disponibilité ni à la photo).
 */
class ShawarmaSeeder extends Seeder
{
    public function run(): void
    {
        $this->staff('Admin Mr. Shawarma', env('SEED_ADMIN_EMAIL', 'admin@mrshawarma.cm'), env('SEED_ADMIN_PASSWORD'), 'admin');
        $this->staff('Livreur Principal', env('SEED_LIVREUR_EMAIL', 'livreur@mrshawarma.cm'), env('SEED_LIVREUR_PASSWORD'), 'livreur', env('SEED_LIVREUR_PHONE'));

        $menu = [
            ['sw1', 'shawarma', 'Shawarma Pain Libanais', 'Pain libanais, viande, salade, sauce maison', 1000, [], 1],
            ['sw2', 'shawarma', 'Shawarma Pain Libanais + Viande', 'Double viande · pain libanais, salade, sauce maison', 1500, [], 2],
            ['sw3', 'shawarma', 'Shawarma au Plat', 'Viande, salade, sauce maison', 2000, [], 3],
            ['sw4', 'shawarma', 'Shawarma Pain Ordinaire', 'Viande, salade, sauce maison', 1000, [], 4],
            ['sw5', 'shawarma', 'Shawarma Pain Ordinaire + Viande', 'Double viande · viande, salade, sauce maison', 1500, [], 5],
            ['dr1', 'boissons', 'Bissap Naturel', '', 300, [], 1],
            ['dr2', 'boissons', 'Jus de Fruits', 'Selon la saison', 500, ['Orange', 'Ananas', 'Mangue', 'Cocktail', 'Gingembre'], 2],
            ['dr3', 'boissons', 'Eau Minérale', '', 400, [], 3],
            ['dr4', 'boissons', 'Kossam', '', 400, [], 4],
        ];

        foreach ($menu as [$id, $cat, $name, $desc, $price, $flavors, $sort]) {
            $p = Product::find($id) ?? new Product(['id' => $id, 'available' => true]);
            $p->fill([
                'category' => $cat, 'name' => $name, 'description' => $desc, 'base_price' => $price,
                'has_flavors' => count($flavors) > 0, 'flavors_json' => $flavors, 'sort_order' => $sort, 'active' => true,
            ])->save();
        }
        $this->command->info(count($menu) . ' produits du menu enregistrés.');
    }

    private function staff(string $name, string $email, ?string $password, string $role, ?string $phone = null): void
    {
        $user = User::where('email', $email)->first();
        if ($user) {
            $data = ['name' => $name, 'role' => $role];
            $p = Phone::normalize($phone);
            if ($p && ! User::where('phone', $p)->where('id', '!=', $user->id)->exists()) $data['phone'] = $p;
            // Réinitialisation volontaire : RESET_STAFF_PASSWORDS=true + SEED_*_PASSWORD définis (à retirer ensuite)
            $reset = $password && filter_var(env('RESET_STAFF_PASSWORDS'), FILTER_VALIDATE_BOOLEAN);
            if ($reset) $data['password'] = $password;
            $user->update($data);
            $this->command->info("Compte {$role} existant : {$email} (" . ($reset ? 'mot de passe réinitialisé' : 'mot de passe inchangé') . ')');

            return;
        }
        $generated = $password === null || $password === '';
        $password = $generated ? Str::password(14, symbols: false) : $password;
        User::create(['name' => $name, 'email' => $email, 'phone' => Phone::normalize($phone), 'password' => $password, 'role' => $role]);
        $this->command->warn("Compte {$role} créé : {$email}" . ($generated ? " / mot de passe : {$password}  (note-le, il ne sera plus affiché)" : ' (mot de passe défini dans .env)'));
    }
}
