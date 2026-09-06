<?php

namespace App\Http\Controllers\Partner;

use App\Http\Controllers\Controller;
use App\Http\Requests\FreelancerRequest;
use App\Models\Freelancer;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

/**
 * パートナー担当者から見たフリーランス管理。
 *
 * 自社が登録した人材だけを扱う。所属の絞り込みは必ず
 * ログイン中の担当者の partner_company_id から導出し、
 * リクエストパラメータは一切信用しない。
 */
class FreelancerController extends Controller
{
    public function index(Request $request): View
    {
        $freelancers = $this->scoped()
            ->keyword($request->query('keyword'))
            ->status($request->query('status'))
            ->orderByDesc('id')
            ->paginate(15)
            ->withQueryString();

        return view('partner.freelancers.index', [
            'freelancers' => $freelancers,
            'keyword' => $request->query('keyword'),
            'status' => $request->query('status'),
        ]);
    }

    public function create(): View
    {
        return view('partner.freelancers.create');
    }

    public function store(FreelancerRequest $request): RedirectResponse
    {
        Freelancer::create($request->validated() + [
            'partner_company_id' => $this->companyId(),
        ]);

        return redirect()->route('partner.freelancers.index')
            ->with('status', 'フリーランスを登録しました');
    }

    public function edit(Freelancer $freelancer): View
    {
        $this->authorizeCompany($freelancer);

        return view('partner.freelancers.edit', compact('freelancer'));
    }

    public function update(FreelancerRequest $request, Freelancer $freelancer): RedirectResponse
    {
        $this->authorizeCompany($freelancer);

        $freelancer->update($request->validated());

        return redirect()->route('partner.freelancers.index')
            ->with('status', 'フリーランス情報を更新しました');
    }

    public function destroy(Freelancer $freelancer): RedirectResponse
    {
        $this->authorizeCompany($freelancer);

        $freelancer->delete();

        return redirect()->route('partner.freelancers.index')
            ->with('status', 'フリーランスを削除しました');
    }

    /**
     * ログイン中の担当者が所属する企業ID
     */
    private function companyId(): int
    {
        return Auth::guard('partner')->user()->partner_company_id;
    }

    /**
     * 自社のものだけに絞ったクエリ
     */
    private function scoped()
    {
        return Freelancer::query()->ofPartnerCompany($this->companyId());
    }

    /**
     * 他社の人材をID直打ちで操作されるのを防ぐ。
     * 一覧に出ないだけでは不十分で、個別操作にも必要
     */
    private function authorizeCompany(Freelancer $freelancer): void
    {
        abort_unless($freelancer->partner_company_id === $this->companyId(), 404);
    }
}
