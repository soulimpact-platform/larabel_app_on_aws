<?php

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

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
});

Route::middleware(['auth', 'admin'])->group(function () {
    Route::resource('users', UserController::class)->except(['show']);
});

require __DIR__.'/auth.php';
