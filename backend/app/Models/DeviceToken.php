<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeviceToken extends Model
{
    public $timestamps = false;
    protected $fillable = ['user_id', 'token', 'platform', 'created_at'];
}
