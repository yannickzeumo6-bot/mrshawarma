<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'id', 'category', 'name', 'description', 'base_price', 'active',
        'has_flavors', 'image_path', 'flavors_json', 'available', 'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'active' => 'boolean',
            'has_flavors' => 'boolean',
            'available' => 'boolean',
            'base_price' => 'integer',
            'flavors_json' => 'array',
        ];
    }

    private function imageUrl(): ?string
    {
        $p = $this->image_path;
        if (! $p) return null;
        if (str_starts_with($p, 'media:')) return url('/media/' . substr($p, 6));

        return asset('storage/' . $p);
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'category' => $this->category,
            'name' => $this->name,
            'description' => $this->description ?? '',
            'basePrice' => (int) $this->base_price,
            'hasFlavors' => (bool) $this->has_flavors,
            'flavors' => array_values($this->flavors_json ?? []),
            'available' => (bool) $this->available,
            'imageUrl' => $this->imageUrl(),
            'sortOrder' => (int) $this->sort_order,
        ];
    }
}
