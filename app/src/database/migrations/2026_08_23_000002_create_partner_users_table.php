<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * パートナー企業の担当者。社外からログインする主体。
     *
     * 社内の users とは別テーブルにすることで、
     *   - 社内アカウントがパートナー用ログインに存在しない（相互拒否の実装が不要）
     *   - role列の設定ミスで社外の人が管理者になる事故が構造的に起きない
     * という性質を得る。
     */
    public function up(): void
    {
        Schema::create('partner_users', function (Blueprint $table) {
            $table->id();

            // 所属企業。企業が消えたら担当者アカウントも消す
            $table->foreignId('partner_company_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');

            // 退職時などにログインだけ止める。削除すると監査で追えなくなるため
            $table->boolean('is_active')->default(true);

            $table->rememberToken();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('partner_users');
    }
};
