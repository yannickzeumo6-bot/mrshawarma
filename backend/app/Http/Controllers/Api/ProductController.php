<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;

class ProductController extends Controller
{
    private const CATEGORY_ORDER = ['shawarma' => 1, 'boissons' => 2];

    /** PUBLIC : tout le menu visible. Les produits épuisés sont renvoyés avec available=false. */
    public function index(): JsonResponse
    {
        $rows = Product::where('active', true)->orderBy('sort_order')->orderBy('name')->get();

        $byCategory = [];
        foreach ($rows as $p) {
            $byCategory[$p->category][] = $p->toApi();
        }

        uksort($byCategory, function ($a, $b) {
            $ra = self::CATEGORY_ORDER[$a] ?? 99;
            $rb = self::CATEGORY_ORDER[$b] ?? 99;

            return $ra === $rb ? strcmp($a, $b) : $ra <=> $rb;
        });

        return response()->json([
            'categories' => array_keys($byCategory),
            'products' => (object) $byCategory,
        ]);
    }
}
