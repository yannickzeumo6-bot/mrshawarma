<?php

use App\Http\Controllers\Api\Admin\AdminProductController;
use App\Http\Controllers\Api\Admin\AdminPromotionController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentMethodController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\PromotionController;
use Illuminate\Support\Facades\Route;

// --- Auth (limitée : 10 essais / minute / IP contre le brute force) ---
Route::middleware('throttle:10,1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
});

// --- Public ---
Route::get('/products', [ProductController::class, 'index']);
Route::get('/promotions', [PromotionController::class, 'index']);
Route::get('/payment-methods', [PaymentMethodController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/devices', [DeviceController::class, 'store']);
    Route::delete('/devices', [DeviceController::class, 'destroy']);

    // --- Client ---
    Route::middleware('role:client')->group(function () {
        Route::post('/delivery/quote', [DeliveryController::class, 'quote'])->middleware('throttle:30,1');
        Route::post('/orders', [OrderController::class, 'store'])->middleware('throttle:10,1');
        Route::get('/orders/mine', [OrderController::class, 'mine']);
        Route::patch('/orders/{ref}/confirm-receipt', [OrderController::class, 'confirmReceipt']);
    });

    // --- Livreur + admin ---
    Route::middleware('role:livreur,admin')->group(function () {
        Route::get('/orders/active', [OrderController::class, 'active']);
        Route::patch('/orders/{ref}/status', [OrderController::class, 'updateStatus']);
    });

    // --- Admin ---
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/orders', [OrderController::class, 'index']);
        Route::get('/stats', [OrderController::class, 'statsSummary']);
        Route::patch('/orders/{ref}/set-status', [OrderController::class, 'adminSetStatus']);

        Route::get('/products', [AdminProductController::class, 'index']);
        Route::post('/products', [AdminProductController::class, 'store']);
        Route::post('/products/{id}', [AdminProductController::class, 'update']); // multipart
        Route::patch('/products/{id}/availability', [AdminProductController::class, 'availability']);
        Route::delete('/products/{id}', [AdminProductController::class, 'destroy']);

        Route::get('/promotions', [AdminPromotionController::class, 'index']);
        Route::post('/promotions', [AdminPromotionController::class, 'store']);
        Route::put('/promotions/{id}', [AdminPromotionController::class, 'update']);
        Route::patch('/promotions/{id}/toggle', [AdminPromotionController::class, 'toggle']);
        Route::delete('/promotions/{id}', [AdminPromotionController::class, 'destroy']);
    });
});
