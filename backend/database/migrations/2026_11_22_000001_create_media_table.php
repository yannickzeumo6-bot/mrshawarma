<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('media')) return;
        Schema::create('media', function (Blueprint $t) {
            $t->string('id', 36)->primary();
            $t->string('mime', 60);
            $t->longText('data'); // image encodée en base64
            $t->unsignedBigInteger('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media');
    }
};
