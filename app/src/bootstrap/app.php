<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // 未ログインで保護ページを開いたときの誘導先。
        // 既定の /login はWAFのIP制限下にあるため、/partner 配下への
        // アクセスはパートナー用ログインへ誘導する。
        // これが無いとセッション切れの瞬間にパートナーが締め出される
        $middleware->redirectGuestsTo(function (Request $request) {
            return $request->is('partner/*') ? route('partner.login') : route('login');
        });

        // ログイン済みでログイン画面を開いたときの遷移先。
        // ガードが分かれているため、どちらでログイン中かで振り分ける
        $middleware->redirectUsersTo(function (Request $request) {
            return $request->is('partner/*') || Auth::guard('partner')->check()
                ? route('partner.freelancers.index')
                : route('dashboard');
        });

        // ALBがTLSを終端するため、アプリにはHTTPで到達する。
        // X-Forwarded-Proto を信頼しないとLaravelがhttpのURLを生成してしまい、
        // 混在コンテンツやリダイレクトループの原因になる。
        // 送信元はALBのみ（タスクへ直接到達できないSG構成）のため at: '*' で問題ない。
        $middleware->trustProxies(at: '*');
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );
    })->create();
