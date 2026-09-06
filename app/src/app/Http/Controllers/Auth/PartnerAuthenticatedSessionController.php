<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\PartnerLoginRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

/**
 * 社外パートナー担当者のログイン入口。
 *
 * partner ガード（partner_users テーブル）を使う。社内の User とは
 * テーブルが違うため、社内アカウントを弾くための特別な処理は要らない。
 */
class PartnerAuthenticatedSessionController extends Controller
{
    public function create(): View
    {
        return view('partner.auth.login');
    }

    public function store(PartnerLoginRequest $request): RedirectResponse
    {
        $request->authenticate();

        $request->session()->regenerate();

        return redirect()->intended(route('partner.freelancers.index', absolute: false));
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::guard('partner')->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('partner.login');
    }
}
