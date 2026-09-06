<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * users.role を廃止する。
     *
     * 「社内 / 社外」の境界は partner_users テーブルの分離が引き取ったため、
     * role列に残っていたのは社内の中の権限差だけだった。
     * その差が実体を持たず（member はログインできるだけで全機能403）、
     * 選択肢として残すと発行時に誤って無権限アカウントを作る事故になるため削除する。
     *
     * 社内ユーザーは全員が同じ権限を持つ前提になる。
     * 権限差が必要になった時点で、その時の要件に合わせて作り直す。
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('role');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('member')->after('password');
        });
    }
};
