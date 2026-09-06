<?php

namespace App\Http\Controllers;

use App\Models\PartnerCompany;
use App\Models\PartnerUser;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;

/**
 * パートナー担当者アカウントの発行・管理（社内adminのみ）。
 *
 * 社内adminがここでアカウントを作り、認証情報を相手に渡す運用。
 * 社外からの自己登録経路は用意しない。
 */
class PartnerUserController extends Controller
{
    public function create(PartnerCompany $partnerCompany): View
    {
        return view('partner_users.create', compact('partnerCompany'));
    }

    public function store(Request $request, PartnerCompany $partnerCompany): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('partner_users', 'email')],
            'password' => ['required', Password::defaults()],
        ]);

        $partnerCompany->partnerUsers()->create($validated + ['is_active' => true]);

        return redirect()->route('partner-companies.edit', $partnerCompany)
            ->with('status', '担当者アカウントを発行しました');
    }

    public function edit(PartnerUser $partnerUser): View
    {
        $partnerUser->load('partnerCompany');

        return view('partner_users.edit', compact('partnerUser'));
    }

    /**
     * 更新。パスワードは空欄なら据え置き
     */
    public function update(Request $request, PartnerUser $partnerUser): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255',
                Rule::unique('partner_users', 'email')->ignore($partnerUser)],
            'password' => ['nullable', Password::defaults()],
            'is_active' => ['required', 'boolean'],
        ]);

        $partnerUser->name = $validated['name'];
        $partnerUser->email = $validated['email'];
        $partnerUser->is_active = $validated['is_active'];

        if (filled($validated['password'] ?? null)) {
            $partnerUser->password = $validated['password'];
        }

        $partnerUser->save();

        return redirect()->route('partner-companies.edit', $partnerUser->partner_company_id)
            ->with('status', '担当者アカウントを更新しました');
    }

    public function destroy(PartnerUser $partnerUser): RedirectResponse
    {
        $companyId = $partnerUser->partner_company_id;
        $partnerUser->delete();

        return redirect()->route('partner-companies.edit', $companyId)
            ->with('status', '担当者アカウントを削除しました');
    }
}
