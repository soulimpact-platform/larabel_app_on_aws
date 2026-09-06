<?php

namespace App\Http\Controllers;

use App\Models\PartnerCompany;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * パートナー企業の管理（社内adminのみ）。
 * 担当者アカウントの発行は PartnerUserController が担う。
 */
class PartnerCompanyController extends Controller
{
    public function index(): View
    {
        $companies = PartnerCompany::query()
            ->withCount(['partnerUsers', 'freelancers'])
            ->orderBy('name')
            ->paginate(15);

        return view('partner_companies.index', compact('companies'));
    }

    public function create(): View
    {
        return view('partner_companies.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $company = PartnerCompany::create($this->validated($request));

        return redirect()->route('partner-companies.edit', $company)
            ->with('status', 'パートナー企業を登録しました。担当者アカウントを発行してください');
    }

    /**
     * 企業の編集。同じ画面で担当者アカウントの一覧も出す
     */
    public function edit(PartnerCompany $partnerCompany): View
    {
        $partnerCompany->load('partnerUsers');

        return view('partner_companies.edit', compact('partnerCompany'));
    }

    public function update(Request $request, PartnerCompany $partnerCompany): RedirectResponse
    {
        $partnerCompany->update($this->validated($request));

        return redirect()->route('partner-companies.index')
            ->with('status', 'パートナー企業を更新しました');
    }

    /**
     * 企業の削除。担当者アカウントも連鎖削除される（cascadeOnDelete）。
     * 登録済みのフリーランスは所属だけ外れて残る（nullOnDelete）
     */
    public function destroy(PartnerCompany $partnerCompany): RedirectResponse
    {
        $partnerCompany->delete();

        return redirect()->route('partner-companies.index')
            ->with('status', 'パートナー企業を削除しました。登録されていた人材は社内直登録として残ります');
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);
    }
}
