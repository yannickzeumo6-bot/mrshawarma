<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Promotions programmées : nécessite le cron Laravel (voir README_BACKEND.md)
Schedule::command('promotions:notify')->everyMinute();
