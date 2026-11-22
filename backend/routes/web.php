<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

// Pages de téléchargement des applications
Route::get('/', fn () => view('telecharger', ['mode' => 'client']));
Route::get('/equipe', fn () => view('telecharger', ['mode' => 'equipe']));

// Photos des produits (stockées en base : le disque des hébergeurs gratuits est effacé à chaque redémarrage)
Route::get('/media/{id}', function (string $id) {
    $row = DB::table('media')->where('id', $id)->first();
    abort_unless($row, 404);

    return response(base64_decode($row->data), 200, [
        'Content-Type' => $row->mime,
        'Cache-Control' => 'public, max-age=31536000, immutable',
    ]);
})->where('id', '[0-9a-fA-F-]{36}');

// Anciennes photos sur disque (développement local, sans « storage:link » sous Windows)
Route::get('/storage/{path}', function (string $path) {
    abort_if(str_contains($path, '..'), 404);
    $disk = Storage::disk('public');
    abort_unless($disk->exists($path), 404);

    return response()->file($disk->path($path));
})->where('path', '.*');
