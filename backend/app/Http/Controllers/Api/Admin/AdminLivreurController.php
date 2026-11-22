<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\Phone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** ADMIN : gérer les comptes livreurs (connexion par téléphone, email facultatif). */
class AdminLivreurController extends Controller
{
    private function serialize(User $u): array
    {
        return ['id' => $u->id, 'name' => $u->name, 'phone' => $u->phone, 'email' => $u->email];
    }

    private function fail(string $msg, int $code = 422): JsonResponse
    {
        return response()->json(['error' => $msg], $code);
    }

    public function index(): JsonResponse
    {
        $list = User::where('role', 'livreur')->orderBy('name')->get();

        return response()->json(['livreurs' => $list->map(fn ($u) => $this->serialize($u))->all()]);
    }

    public function store(Request $request): JsonResponse
    {
        $name = trim((string) $request->input('name', ''));
        $phone = Phone::normalize((string) $request->input('phone', ''));
        $email = strtolower(trim((string) $request->input('email', '')));
        $password = (string) $request->input('password', '');

        if ($name === '') return $this->fail('Le nom est requis.');
        if ($phone === null) return $this->fail('Numéro de téléphone invalide (exemple : 6 90 00 00 00).');
        if ($email !== '' && ! filter_var($email, FILTER_VALIDATE_EMAIL)) return $this->fail('Email invalide.');
        if (strlen($password) < 8) return $this->fail('Mot de passe : 8 caractères minimum.');
        if (User::where('phone', $phone)->exists()) return $this->fail('Ce numéro est déjà utilisé.', 409);
        if ($email !== '' && User::where('email', $email)->exists()) return $this->fail('Cet email est déjà utilisé.', 409);

        $user = User::create([
            'name' => $name, 'phone' => $phone, 'email' => $email !== '' ? $email : null,
            'password' => $password, 'role' => 'livreur',
        ]);

        return response()->json(['livreur' => $this->serialize($user)], 201);
    }

    /** Modifier le nom / numéro / email, ou réinitialiser le mot de passe (champ "password" rempli). */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = User::where('role', 'livreur')->find($id);
        if (! $user) return $this->fail('Livreur introuvable.', 404);

        $data = [];
        if ($request->filled('name')) $data['name'] = trim((string) $request->input('name'));
        if ($request->filled('phone')) {
            $phone = Phone::normalize((string) $request->input('phone'));
            if ($phone === null) return $this->fail('Numéro de téléphone invalide (exemple : 6 90 00 00 00).');
            if (User::where('phone', $phone)->where('id', '!=', $user->id)->exists()) return $this->fail('Ce numéro est déjà utilisé.', 409);
            $data['phone'] = $phone;
        }
        if ($request->has('email')) {
            $email = strtolower(trim((string) $request->input('email', '')));
            if ($email !== '' && ! filter_var($email, FILTER_VALIDATE_EMAIL)) return $this->fail('Email invalide.');
            if ($email !== '' && User::where('email', $email)->where('id', '!=', $user->id)->exists()) return $this->fail('Cet email est déjà utilisé.', 409);
            $data['email'] = $email !== '' ? $email : null;
        }
        if ($request->filled('password')) {
            $password = (string) $request->input('password');
            if (strlen($password) < 8) return $this->fail('Mot de passe : 8 caractères minimum.');
            $data['password'] = $password;
        }

        $user->update($data);
        if (isset($data['password'])) $user->tokens()->delete(); // déconnecte ses appareils

        return response()->json(['livreur' => $this->serialize($user->fresh())]);
    }

    public function destroy(int $id): JsonResponse
    {
        $user = User::where('role', 'livreur')->find($id);
        if (! $user) return $this->fail('Livreur introuvable.', 404);
        $user->tokens()->delete();
        $user->delete();

        return response()->json(['ok' => true]);
    }
}
