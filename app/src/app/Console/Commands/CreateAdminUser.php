<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Validator;

/**
 * 社内管理者アカウントを1件作成する。
 *
 * 本番のmigrateタスクは `migrate --force` のみを実行し --seed を付けない。
 * DatabaseSeeder が作る admin@example.com / password を本番へ流すと、
 * 公開環境に既知の認証情報が置かれてしまうため。
 *
 * 代わりに、認証情報を環境変数で受け取るこのコマンドをCIから一度だけ実行する。
 * 値はGitHub Secretsに置き、run-task の overrides で注入される。
 * 以降のアカウント（社内ユーザー・パートナー企業・担当者）は、
 * ここで作った管理者が画面から発行する運用。
 *
 * 冪等。同じメールアドレスで再実行しても新規作成はしない。
 */
class CreateAdminUser extends Command
{
    protected $signature = 'app:create-admin-user
                            {--force-password : 既存アカウントのパスワードも上書きする}';

    protected $description = '初期の社内管理者アカウントを作成する（認証情報は環境変数から受け取る）';

    public function handle(): int
    {
        $attributes = [
            'email' => config('app.initial_admin.email'),
            'name' => config('app.initial_admin.name'),
            'password' => config('app.initial_admin.password'),
        ];

        // 値が入っていないまま作成すると、意図しないアカウントができるか
        // 例外で落ちる。どちらも原因が分かりにくいので先に弾く
        $validator = Validator::make($attributes, [
            'email' => ['required', 'email', 'max:255'],
            'name' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string', 'min:12'],
        ]);

        if ($validator->fails()) {
            $this->error('初期管理者の設定が不正です。INITIAL_ADMIN_* の環境変数を確認してください:');

            foreach ($validator->errors()->all() as $message) {
                $this->line('  - '.$message);
            }

            return self::FAILURE;
        }

        $user = User::where('email', $attributes['email'])->first();

        if ($user !== null) {
            // パスワードをログに出さないよう、メールアドレスのみ表示する
            $this->info("既に存在します: {$user->email}");

            if ($this->option('force-password')) {
                $user->password = $attributes['password'];
                $user->save();
                $this->info('パスワードを更新しました。');
            }

            return self::SUCCESS;
        }

        $user = User::create($attributes);

        $this->info("作成しました: {$user->email}");

        return self::SUCCESS;
    }
}
