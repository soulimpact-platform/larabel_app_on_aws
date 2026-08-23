<?php

use App\Http\Controllers\Auth\PartnerAuthenticatedSessionController;
use App\Http\Controllers\FreelancerController;
use App\Http\Controllers\Partner\FreelancerController as PartnerFreelancerController;
use App\Http\Controllers\Partner\ProfileController as PartnerProfileController;
use App\Http\Controllers\PartnerCompanyController;
use App\Http\Controllers\PartnerUserController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

/*
 * デプロイ確認用ページ。
 *
 * CIでのデプロイが本番へ届いたかを画面から判別するために、
 * RELEASE の文字列を変更してコミットする運用を想定している。
 */
Route::get('/status', function () {
    try {
        DB::connection()->getPdo();
        $database = 'ok';
    } catch (\Throwable $e) {
        $database = 'error';
    }

    return view('status', [
        'release' => 'v1 (sample page)',
        'now' => now()->toDateTimeString(),
        'database' => $database,
    ]);
})->name('status');

///////////////////////////////////////////////////////////////////////////////
// パートナー領域（社外）
//
// partner ガード（partner_users テーブル）で認証する。社内の users とは
// テーブルが別なので、社内アカウントでここへログインすることはできない。
//
// パスを /partner/* に揃えているのは、WAFのIP制限を配下ごと免除するため。
// 社外の担当者は任意のIPから接続するのでIPでは絞れず、代わりに
// 認証とデータスコープ（自社ぶんのみ）で守る。
///////////////////////////////////////////////////////////////////////////////
Route::prefix('partner')->name('partner.')->group(function () {
    Route::middleware('guest:partner')->group(function () {
        Route::get('login', [PartnerAuthenticatedSessionController::class, 'create'])->name('login');
        Route::post('login', [PartnerAuthenticatedSessionController::class, 'store']);
    });

    Route::middleware('auth:partner')->group(function () {
        Route::post('logout', [PartnerAuthenticatedSessionController::class, 'destroy'])->name('logout');

        Route::get('profile', [PartnerProfileController::class, 'edit'])->name('profile.edit');
        Route::patch('profile', [PartnerProfileController::class, 'update'])->name('profile.update');
        Route::put('password', [PartnerProfileController::class, 'updatePassword'])->name('password.update');

        // 自社が登録した人材のみ。スコープはコントローラ側で強制する
        Route::resource('freelancers', PartnerFreelancerController::class)->except(['show']);
    });
});

///////////////////////////////////////////////////////////////////////////////
// 社内領域
//
// URLだけを /admin/ 配下へ寄せ、ルート名は変更していない。
// login / password.reset / verification.verify などの名前は
// Laravel本体とパスワード再設定メールが参照しており、改名すると
// メールのリンクが存在しないルートを指すなど静かに壊れるため。
//
// URLの第1セグメントで対象者が確定する:
//   /admin/*   社内
//   /partner/* 社外パートナー
//   それ以外    公開（/ と /status のみ）
///////////////////////////////////////////////////////////////////////////////
Route::prefix('admin')->group(function () {
    Route::get('/dashboard', function () {
        return view('dashboard');
    })->middleware(['auth', 'verified'])->name('dashboard');

    Route::middleware('auth')->group(function () {
        Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
        Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');

        Route::resource('users', UserController::class)->except(['show']);

        // 全パートナー企業ぶん + 社内直登録を横断して扱う
        Route::resource('freelancers', FreelancerController::class)->except(['show']);

        Route::resource('partner-companies', PartnerCompanyController::class)->except(['show']);

        // 担当者アカウントの発行は企業に紐づくため、企業配下のパスにする
        Route::get('partner-companies/{partnerCompany}/users/create', [PartnerUserController::class, 'create'])
            ->name('partner-users.create');
        Route::post('partner-companies/{partnerCompany}/users', [PartnerUserController::class, 'store'])
            ->name('partner-users.store');

        Route::get('partner-users/{partnerUser}/edit', [PartnerUserController::class, 'edit'])
            ->name('partner-users.edit');
        Route::put('partner-users/{partnerUser}', [PartnerUserController::class, 'update'])
            ->name('partner-users.update');
        Route::delete('partner-users/{partnerUser}', [PartnerUserController::class, 'destroy'])
            ->name('partner-users.destroy');
    });

    // Breezeが生成した認証系。ファイルを書き換えず、まとめて /admin/ 配下へ置く
    Route::group([], __DIR__.'/auth.php');
});
