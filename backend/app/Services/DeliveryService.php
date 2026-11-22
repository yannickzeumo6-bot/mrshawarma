<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

/** Calcule distance et frais de livraison : le serveur est la seule autorité. */
class DeliveryService
{
    public function feeFor(float $km): int
    {
        $free = (float) config('shawarma.delivery.free_below_km');
        if ($km < $free) return 0;

        return (int) config('shawarma.delivery.base')
            + (int) ceil($km - $free) * (int) config('shawarma.delivery.per_extra_km');
    }

    /** @return array{km:float,fee:int,method:string} @throws \DomainException */
    public function quote(float $lat, float $lng): array
    {
        $cfg = config('shawarma.delivery');
        $km = null;
        $method = 'estimate';

        try {
            $url = sprintf(
                'https://router.project-osrm.org/route/v1/driving/%F,%F;%F,%F',
                $cfg['start_lng'], $cfg['start_lat'], $lng, $lat
            );
            $meters = Http::timeout(4)->get($url, ['overview' => 'false'])->json('routes.0.distance');
            if (is_numeric($meters)) {
                $km = $meters / 1000;
                $method = 'route';
            }
        } catch (\Throwable $e) {
            // repli sur l'estimation
        }

        if ($km === null) {
            $km = $this->haversine($cfg['start_lat'], $cfg['start_lng'], $lat, $lng) * $cfg['detour_factor'];
        }

        $km = round($km, 1);
        if ($km > $cfg['max_km']) {
            throw new \DomainException("Adresse hors de notre zone de livraison (maximum {$cfg['max_km']} km).");
        }

        return ['km' => $km, 'fee' => $this->feeFor($km), 'method' => $method];
    }

    /** @return array{lat:float,lng:float,label:string}|null */
    public function geocode(string $address): ?array
    {
        try {
            $res = Http::withHeaders(['User-Agent' => config('app.name', 'MrShawarma') . '-delivery/1.0'])
                ->timeout(5)
                ->get('https://nominatim.openstreetmap.org/search', [
                    'format' => 'json',
                    'limit' => 1,
                    'countrycodes' => 'cm',
                    'viewbox' => '9.55,4.20,9.85,3.90',
                    'bounded' => 1,
                    'q' => $address . ', Douala',
                ])->json();
            if (is_array($res) && isset($res[0]['lat'], $res[0]['lon'])) {
                return [
                    'lat' => (float) $res[0]['lat'],
                    'lng' => (float) $res[0]['lon'],
                    'label' => (string) ($res[0]['display_name'] ?? $address),
                ];
            }
        } catch (\Throwable $e) {
        }

        return null;
    }

    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $r = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $r * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
