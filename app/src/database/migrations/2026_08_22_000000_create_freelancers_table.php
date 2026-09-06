<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('freelancers', function (Blueprint $table) {
            $table->id();

            $table->string('name');
            $table->string('name_kana')->nullable();

            // 連絡先。同一人物の重複登録を防ぐためメールは一意にする。
            // ただし未取得の段階でも登録できるよう nullable にしている
            $table->string('email')->nullable()->unique();
            $table->string('phone')->nullable();

            // 保有スキル。タグ管理にすると別テーブルが必要になるため、
            // まずは自由記述で運用し、検索は LIKE で賄う
            $table->text('skills')->nullable();

            $table->unsignedTinyInteger('experience_years')->nullable();

            // 希望単価（万円/月）。SESの商習慣に合わせて月額で保持する
            $table->unsignedInteger('desired_rate')->nullable();

            // available: 稼働可能 / working: 稼働中 / inactive: 対象外
            $table->string('status')->default('available');

            $table->date('available_from')->nullable();

            $table->text('notes')->nullable();

            $table->timestamps();

            // 一覧の既定の絞り込み条件になるためインデックスを張る
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('freelancers');
    }
};
