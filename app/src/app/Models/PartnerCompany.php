<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'notes'])]
class PartnerCompany extends Model
{
    /**
     * この企業の担当者アカウント
     */
    public function partnerUsers(): HasMany
    {
        return $this->hasMany(PartnerUser::class);
    }

    /**
     * この企業が登録したフリーランス
     */
    public function freelancers(): HasMany
    {
        return $this->hasMany(Freelancer::class);
    }
}
