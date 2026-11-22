<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // --- Produits : photo, saveurs, disponibilité, ordre ---
        Schema::table('products', function (Blueprint $t) {
            if (! Schema::hasColumn('products', 'image_path')) $t->string('image_path')->nullable();
            if (! Schema::hasColumn('products', 'flavors_json')) $t->json('flavors_json')->nullable();
            if (! Schema::hasColumn('products', 'available')) $t->boolean('available')->default(true);
            if (! Schema::hasColumn('products', 'sort_order')) $t->unsignedInteger('sort_order')->default(0);
        });

        // --- Commandes : promo appliquée ---
        Schema::table('orders', function (Blueprint $t) {
            if (! Schema::hasColumn('orders', 'promo_id')) $t->unsignedBigInteger('promo_id')->nullable();
            if (! Schema::hasColumn('orders', 'promo_title')) $t->string('promo_title')->nullable();
            if (! Schema::hasColumn('orders', 'promo_amount')) $t->unsignedInteger('promo_amount')->default(0);
        });

        // --- Promotions (créée, ou complétée si la 1re version existe déjà) ---
        if (! Schema::hasTable('promotions')) {
            Schema::create('promotions', function (Blueprint $t) {
                $t->id();
                $t->string('title');
                $t->text('description')->nullable();
                $t->string('discount_type')->default('info'); // percent | fixed | info
                $t->unsignedInteger('discount_value')->default(0);
                $t->string('product_id')->nullable();
                $t->string('category')->nullable();
                $t->unsignedBigInteger('starts_at')->nullable();
                $t->unsignedBigInteger('ends_at')->nullable();
                $t->boolean('active')->default(true);
                $t->unsignedBigInteger('notified_at')->nullable();
                $t->unsignedBigInteger('created_at');
            });
        } else {
            Schema::table('promotions', function (Blueprint $t) {
                if (! Schema::hasColumn('promotions', 'category')) $t->string('category')->nullable();
                if (! Schema::hasColumn('promotions', 'notified_at')) $t->unsignedBigInteger('notified_at')->nullable();
            });
        }

        // --- Appareils (notifications push ciblées) ---
        if (! Schema::hasTable('device_tokens')) {
            Schema::create('device_tokens', function (Blueprint $t) {
                $t->id();
                $t->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $t->string('token')->unique();
                $t->string('platform')->nullable();
                $t->unsignedBigInteger('created_at');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
    }
};
