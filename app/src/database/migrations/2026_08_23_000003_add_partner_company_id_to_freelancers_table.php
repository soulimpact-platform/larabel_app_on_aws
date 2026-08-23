<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * フリーランスの所属パートナー企業。
     *
     * NULL は「社内が直接登録した人材」を意味する。
     * どのパートナーからも見えず、adminの全体管理画面にのみ現れる。
     */
    public function up(): void
    {
        Schema::table('freelancers', function (Blueprint $table) {
            $table->foreignId('partner_company_id')
                ->nullable()
                ->after('id')
                // 企業を消しても人材は残す。社内の管理対象として引き継ぐ
                ->constrained()
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('freelancers', function (Blueprint $table) {
            $table->dropForeign(['partner_company_id']);
            $table->dropColumn('partner_company_id');
        });
    }
};
