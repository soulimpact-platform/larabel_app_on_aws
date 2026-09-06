<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // ローカル検証用のアカウント。
        //
        // 本番のmigrateタスクは `php artisan migrate --force` のみを実行し
        // --seed を付けないため、この認証情報が本番に作られることはない。
        // 本番の初期アカウント作成は別手段が必要（README参照）。
        User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Admin User',
                'password' => 'password',
            ]
        );
    }
}
