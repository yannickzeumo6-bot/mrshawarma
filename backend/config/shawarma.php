<?php

return [
    // Le dépôt se fait HORS de l'application — ces informations sont
    // uniquement affichées au client pour qu'il envoie l'argent lui-même.
    'payment' => [
        'orange_money' => [
            'label' => 'Orange Money',
            'name' => env('ORANGE_MONEY_NAME', 'Mr. Shawarma'),
            'number' => env('ORANGE_MONEY_NUMBER', '+237 6 90 00 00 00'),
        ],
        'mtn_momo' => [
            'label' => 'MTN Mobile Money',
            'name' => env('MTN_MOMO_NAME', 'Mr. Shawarma'),
            'number' => env('MTN_MOMO_NUMBER', '+237 6 70 00 00 00'),
        ],
    ],

    // Livraison : TOUT est calculé côté serveur à partir des coordonnées GPS.
    'delivery' => [
        'start_name' => env('DELIVERY_START_NAME', 'Hôpital Général de Douala'),
        'start_lat' => (float) env('DELIVERY_START_LAT', 4.0653),
        'start_lng' => (float) env('DELIVERY_START_LNG', 9.7586),
        'free_below_km' => 1,
        'base' => 300,
        'per_extra_km' => 50,
        'max_km' => (float) env('DELIVERY_MAX_KM', 20),
        'detour_factor' => 1.3, // estimation route = ligne droite x 1.3 si OSRM indisponible
    ],

    'loyalty' => ['qty_per_free' => 10], // 1 shawarma offert tous les 10

    'orders' => ['max_qty_per_line' => 50, 'max_lines' => 30],

    // Dossier public où sont publiés les APK (GitHub Releases) : sert à la page de téléchargement
    'apk_base' => env('APK_BASE_URL', ''),

    // Notifications push (Firebase Cloud Messaging)
    'push' => [
        'enabled' => (bool) env('PUSH_ENABLED', false),
        'promo_topic' => 'promotions',
    ],
];
