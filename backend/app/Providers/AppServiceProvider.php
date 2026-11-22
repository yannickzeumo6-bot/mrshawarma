<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // En production (derrière le proxy HTTPS de l'hébergeur), tous les liens générés
        // (photos des produits...) doivent être en https avec l'adresse publique.
        $url = (string) config('app.url');
        if (app()->environment('production') && str_starts_with($url, 'https://')) {
            URL::forceRootUrl($url);
            URL::forceScheme('https');
        }
    }
}
