<?php

namespace App\Http\Controllers;

use App\Http\Requests\FreelancerRequest;
use App\Models\Freelancer;
use App\Models\PartnerCompany;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * 社内(admin)から見たフリーランス管理。
 *
 * 全パートナー企業ぶんに加えて、社内が直接登録した人材
 * （partner_company_id が NULL）も扱う。
 */
class FreelancerController extends Controller
{
    public function index(Request $request): View
    {
        $company = $request->query('partner_company_id');

        $freelancers = Freelancer::query()
            ->with('partnerCompany')
            ->keyword($request->query('keyword'))
            ->status($request->query('status'))
            // 'internal' は社内直登録（所属なし）を指す擬似的な値
            ->when($company === 'internal', fn ($q) => $q->whereNull('partner_company_id'))
            ->when($company !== null && $company !== '' && $company !== 'internal',
                fn ($q) => $q->where('partner_company_id', $company))
            ->orderByDesc('id')
            ->paginate(15)
            ->withQueryString();

        return view('freelancers.index', [
            'freelancers' => $freelancers,
            'companies' => PartnerCompany::orderBy('name')->get(),
            'keyword' => $request->query('keyword'),
            'status' => $request->query('status'),
            'partnerCompanyId' => $company,
        ]);
    }

    public function create(): View
    {
        return view('freelancers.create', [
            'companies' => PartnerCompany::orderBy('name')->get(),
        ]);
    }

    public function store(FreelancerRequest $request): RedirectResponse
    {
        Freelancer::create($request->validated() + [
            'partner_company_id' => $this->companyIdFrom($request),
        ]);

        return redirect()->route('freelancers.index')
            ->with('status', 'フリーランスを登録しました');
    }

    public function edit(Freelancer $freelancer): View
    {
        return view('freelancers.edit', [
            'freelancer' => $freelancer,
            'companies' => PartnerCompany::orderBy('name')->get(),
        ]);
    }

    public function update(FreelancerRequest $request, Freelancer $freelancer): RedirectResponse
    {
        $freelancer->update($request->validated() + [
            'partner_company_id' => $this->companyIdFrom($request),
        ]);

        return redirect()->route('freelancers.index')
            ->with('status', 'フリーランス情報を更新しました');
    }

    public function destroy(Freelancer $freelancer): RedirectResponse
    {
        $freelancer->delete();

        return redirect()->route('freelancers.index')
            ->with('status', 'フリーランスを削除しました');
    }

    /**
     * 社内向け画面だけは所属をフォームから指定できる。
     * 空文字は「社内直登録」としてNULLに落とす
     */
    private function companyIdFrom(Request $request): ?int
    {
        $id = $request->input('partner_company_id');

        if (blank($id)) {
            return null;
        }

        // 存在しないIDを渡されても落ちないよう検証する
        return PartnerCompany::whereKey($id)->value('id');
    }
}
