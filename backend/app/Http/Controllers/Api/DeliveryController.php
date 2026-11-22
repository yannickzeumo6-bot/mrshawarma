<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DeliveryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeliveryController extends Controller
{
    /**
     * Devis de livraison calculé par le serveur.
     * Entrée : {lat,lng} (GPS)  OU  {address} (géocodée par le serveur).
     */
    public function quote(Request $request, DeliveryService $delivery): JsonResponse
    {
        $lat = $request->input('lat');
        $lng = $request->input('lng');
        $label = null;

        if (! is_numeric($lat) || ! is_numeric($lng)) {
            $address = trim((string) $request->input('address', ''));
            if (strlen($address) < 3) {
                return response()->json(['error' => 'Indique une adresse ou active ta position.'], 422);
            }
            $geo = $delivery->geocode($address);
            if (! $geo) {
                return response()->json(['error' => "Adresse introuvable. Essaie un quartier ou un point de repère connu, ou utilise ta position."], 422);
            }
            [$lat, $lng, $label] = [$geo['lat'], $geo['lng'], $geo['label']];
        }

        $lat = (float) $lat;
        $lng = (float) $lng;
        if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
            return response()->json(['error' => 'Coordonnées invalides.'], 422);
        }

        try {
            $q = $delivery->quote($lat, $lng);
        } catch (\DomainException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }

        return response()->json($q + ['lat' => $lat, 'lng' => $lng, 'label' => $label]);
    }
}
