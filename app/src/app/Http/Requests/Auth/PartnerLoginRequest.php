<?php

namespace App\Http\Requests\Auth;

use Illuminate\Auth\Events\Lockout;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * パートナー担当者のログイン。
 *
 * 社内向けの LoginRequest との違いは partner ガードを使う点だけ。
 * 認証先が partner_users テーブルなので、社内アカウントを入力しても
 * 「該当なし」として素直に失敗する。ロールを見て取り消す処理は不要。
 */
class PartnerLoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ];
    }

    public function authenticate(): void
    {
        $this->ensureIsNotRateLimited();

        // 退職者などを止められるよう is_active も条件に含める。
        // レコードを消さずにログインだけ無効化できる
        $credentials = $this->only('email', 'password') + ['is_active' => true];

        if (! Auth::guard('partner')->attempt($credentials, $this->boolean('remember'))) {
            RateLimiter::hit($this->throttleKey());

            throw ValidationException::withMessages([
                'email' => trans('auth.failed'),
            ]);
        }

        RateLimiter::clear($this->throttleKey());
    }

    public function ensureIsNotRateLimited(): void
    {
        if (! RateLimiter::tooManyAttempts($this->throttleKey(), 5)) {
            return;
        }

        event(new Lockout($this));

        $seconds = RateLimiter::availableIn($this->throttleKey());

        throw ValidationException::withMessages([
            'email' => trans('auth.throttle', [
                'seconds' => $seconds,
                'minutes' => ceil($seconds / 60),
            ]),
        ]);
    }

    /**
     * 社内向けログインとレート制限の枠を分ける。
     * 同じメールアドレスでも入口ごとに独立して数える
     */
    public function throttleKey(): string
    {
        return 'partner|'.Str::transliterate(Str::lower($this->string('email')).'|'.$this->ip());
    }
}
