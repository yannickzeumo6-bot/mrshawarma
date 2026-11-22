<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\Phone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    private const TOKEN_DAYS = 30;

    /** Inscription : toujours "client". Livreur/admin sont créés par l'admin (ou le seeder). */
    public function register(Request $request): JsonResponse
    {
        $name = trim((string) $request->input('name', ''));
        $email = strtolower(trim((string) $request->input('email', '')));
        $password = (string) $request->input('password', '');
        $phone = Phone::normalize((string) $request->input('phone', ''));

        if ($name === '') return response()->json(['error' => 'Le nom est requis.'], 400);
        if (! filter_var($email, FILTER_VALIDATE_EMAIL)) return response()->json(['error' => 'Email invalide.'], 400);
        if ($phone === null) return response()->json(['error' => 'Numéro de téléphone invalide (exemple : 6 90 00 00 00).'], 400);
        if (strlen($password) < 8) return response()->json(['error' => 'Mot de passe : 8 caractères minimum.'], 400);
        if (User::where('email', $email)->exists()) {
            return response()->json(['error' => 'Un compte existe déjà avec cet email. Connecte-toi plutôt.'], 409);
        }
        if (User::where('phone', $phone)->exists()) {
            return response()->json(['error' => 'Un compte existe déjà avec ce numéro. Connecte-toi plutôt.'], 409);
        }

        $user = User::create(['name' => $name, 'email' => $email, 'phone' => $phone, 'password' => $password, 'role' => 'client']);

        return response()->json(['token' => $this->token($user), 'user' => $this->publicUser($user)], 201);
    }

    /** Connexion par email OU par numéro de téléphone (champ "login"; "email" reste accepté). */
    public function login(Request $request): JsonResponse
    {
        $login = trim((string) $request->input('login', $request->input('email', '')));
        $password = (string) $request->input('password', '');

        if ($login === '' || $password === '') {
            return response()->json(['error' => 'Identifiant et mot de passe requis.'], 400);
        }

        if (str_contains($login, '@')) {
            $user = User::where('email', strtolower($login))->first();
        } else {
            $phone = Phone::normalize($login);
            $user = $phone ? User::where('phone', $phone)->first() : null;
        }

        if (! $user || ! Hash::check($password, $user->password)) {
            return response()->json(['error' => 'Identifiant ou mot de passe incorrect.'], 401);
        }

        return response()->json(['token' => $this->token($user), 'user' => $this->publicUser($user)]);
    }

    /** Met à jour son propre numéro de téléphone (comptes créés avant l'ajout du téléphone). */
    public function updateMe(Request $request): JsonResponse
    {
        $user = $request->user();
        $phone = Phone::normalize((string) $request->input('phone', ''));
        if ($phone === null) return response()->json(['error' => 'Numéro de téléphone invalide (exemple : 6 90 00 00 00).'], 422);
        if (User::where('phone', $phone)->where('id', '!=', $user->id)->exists()) {
            return response()->json(['error' => 'Ce numéro est déjà utilisé par un autre compte.'], 409);
        }

        $user->update(['phone' => $phone]);

        return response()->json(['user' => $this->publicUser($user)]);
    }

    /** Révoque le jeton courant (déconnexion réelle côté serveur). */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['ok' => true]);
    }

    private function token(User $user): string
    {
        // Jeton qui expire (30 jours) au lieu d'un jeton éternel.
        return $user->createToken('api', ['*'], now()->addDays(self::TOKEN_DAYS))->plainTextToken;
    }

    private function publicUser(User $user): array
    {
        return ['id' => $user->id, 'name' => $user->name, 'email' => $user->email, 'phone' => $user->phone, 'role' => $user->role];
    }
}
