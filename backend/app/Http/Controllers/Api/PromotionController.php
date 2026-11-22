<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PromotionService;
use Illuminate\Http\JsonResponse;

class PromotionController extends Controller
{
    /** PUBLIC : promotions en cours (lues par l'app client). */
    public function index(PromotionService $promos): JsonResponse
    {
        return response()->json([
            'promotions' => $promos->current()->get()->map(fn ($p) => $p->toApi())->all(),
        ]);
    }
}
