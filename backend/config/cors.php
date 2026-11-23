<?php

// Autorise les versions web (GitHub Pages) à appeler l'API et charger les photos.
return [
    'paths' => ['api/*', 'media/*', 'storage/*'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 86400,
    'supports_credentials' => false,
];
