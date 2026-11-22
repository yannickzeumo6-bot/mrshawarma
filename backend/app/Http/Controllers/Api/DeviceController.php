<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    /** Enregistre le jeton FCM de l'appareil pour l'utilisateur connecté. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate(['token' => 'required|string|max:512', 'platform' => 'nullable|string|max:20']);

        DeviceToken::updateOrCreate(
            ['token' => $data['token']],
            ['user_id' => $request->user()->id, 'platform' => $data['platform'] ?? null, 'created_at' => (int) round(microtime(true) * 1000)]
        );

        return response()->json(['ok' => true]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $token = (string) $request->input('token', '');
        DeviceToken::where('token', $token)->where('user_id', $request->user()->id)->delete();

        return response()->json(['ok' => true]);
    }
}
