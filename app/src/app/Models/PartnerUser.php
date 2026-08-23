<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Authenticatable;

/**
 * パートナー企業の担当者。partner ガードの認証主体。
 *
 * 社内の User とは別クラス・別テーブルであることが、そのまま
 * 「社内アカウントではパートナー画面にログインできない」保証になる。
 */
#[Fillable(['partner_company_id', 'name', 'email', 'password', 'is_active'])]
#[Hidden(['password', 'remember_token'])]
class PartnerUser extends Authenticatable
{
    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function partnerCompany(): BelongsTo
    {
        return $this->belongsTo(PartnerCompany::class);
    }
}
