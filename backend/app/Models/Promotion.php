<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Promotion extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'title', 'description', 'discount_type', 'discount_value', 'product_id',
        'category', 'starts_at', 'ends_at', 'active', 'notified_at', 'created_at',
    ];

    protected function casts(): array
    {
        return ['active' => 'boolean'];
    }

    public function badge(): string
    {
        return match ($this->discount_type) {
            'percent' => '-' . (int) $this->discount_value . '%',
            'fixed' => '-' . number_format((int) $this->discount_value, 0, ',', ' ') . ' F',
            default => 'PROMO',
        };
    }

    public function toApi(): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description ?? '',
            'badge' => $this->badge(),
            'discountType' => $this->discount_type,
            'discountValue' => (int) $this->discount_value,
            'productId' => $this->product_id,
            'category' => $this->category,
            'startsAt' => $this->starts_at !== null ? (int) $this->starts_at : null,
            'endsAt' => $this->ends_at !== null ? (int) $this->ends_at : null,
            'active' => (bool) $this->active,
            'createdAt' => (int) $this->created_at,
        ];
    }
}
