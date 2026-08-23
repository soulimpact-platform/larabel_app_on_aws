<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'partner_company_id',
    'name',
    'name_kana',
    'email',
    'phone',
    'skills',
    'experience_years',
    'desired_rate',
    'status',
    'available_from',
    'notes',
])]
class Freelancer extends Model
{
    /**
     * 稼働状況の選択肢。バリデーション・画面表示の両方で参照する
     */
    public const STATUSES = [
        'available' => '稼働可能',
        'working' => '稼働中',
        'inactive' => '対象外',
    ];

    protected function casts(): array
    {
        return [
            'available_from' => 'date',
        ];
    }

    /**
     * 画面表示用の稼働状況ラベル
     */
    public function statusLabel(): string
    {
        return self::STATUSES[$this->status] ?? $this->status;
    }

    /**
     * 氏名・フリガナ・スキルを横断してキーワード検索する。
     * 件数が増えたら全文検索へ移行する前提の簡易実装
     */
    public function scopeKeyword(Builder $query, ?string $keyword): Builder
    {
        if (blank($keyword)) {
            return $query;
        }

        return $query->where(function (Builder $q) use ($keyword) {
            foreach (['name', 'name_kana', 'skills'] as $column) {
                $q->orWhere($column, 'like', '%'.$keyword.'%');
            }
        });
    }

    /**
     * 所属パートナー企業。NULL は社内が直接登録した人材
     */
    public function partnerCompany(): BelongsTo
    {
        return $this->belongsTo(PartnerCompany::class);
    }

    /**
     * 特定のパートナー企業のものだけに絞る。
     * パートナー側の一覧は必ずこれを通し、他社の人材が漏れないようにする
     */
    public function scopeOfPartnerCompany(Builder $query, int $partnerCompanyId): Builder
    {
        return $query->where('partner_company_id', $partnerCompanyId);
    }

    /**
     * 稼働状況で絞り込む
     */
    public function scopeStatus(Builder $query, ?string $status): Builder
    {
        if (blank($status)) {
            return $query;
        }

        return $query->where('status', $status);
    }
}
