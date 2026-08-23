<?php

namespace App\Http\Controllers\Partner;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;

/**
 * パートナー担当者の自己管理。
 *
 * 社内の ProfileController は web ガードの User を対象にしているため
 * 流用できない。扱う対象が別テーブルなので別実装になる。
 */
class ProfileController extends Controller
{
    public function edit(): View
    {
        return view('partner.profile.edit', [
            'partnerUser' => Auth::guard('partner')->user(),
        ]);
    }

    /**
     * 氏名の変更。メールはアカウントIDのため変更させない
     * （社内の ProfileController と同じ方針）
     */
    public function update(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
        ]);

        $user = Auth::guard('partner')->user();
        $user->name = $validated['name'];
        $user->save();

        return redirect()->route('partner.profile.edit')
            ->with('status', 'profile-updated');
    }

    /**
     * パスワード変更
     */
    public function updatePassword(Request $request): RedirectResponse
    {
        $validated = $request->validateWithBag('updatePassword', [
            'current_password' => ['required', 'current_password:partner'],
            'password' => ['required', Password::defaults(), 'confirmed'],
        ]);

        $user = Auth::guard('partner')->user();
        $user->password = $validated['password'];
        $user->save();

        return back()->with('status', 'password-updated');
    }
}
