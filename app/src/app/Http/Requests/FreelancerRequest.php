<?php

namespace App\Http\Requests;

use App\Models\Freelancer;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * フリーランスの登録・更新に共通のバリデーション。
 * 社内向け(admin)とパートナー向けの双方から使う。
 *
 * partner_company_id はここでは扱わない。所属はリクエスト値ではなく
 * ログイン主体から決まるため、コントローラ側で明示的に入れる。
 * フォームから送られてきた所属を信じると、他社の人材を作られる
 */
class FreelancerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $freelancer = $this->route('freelancer');

        return [
            'name' => ['required', 'string', 'max:255'],
            'name_kana' => ['nullable', 'string', 'max:255'],
            'email' => [
                'nullable', 'string', 'email', 'max:255',
                Rule::unique('freelancers', 'email')->ignore($freelancer),
            ],
            'phone' => ['nullable', 'string', 'max:50'],
            'skills' => ['nullable', 'string', 'max:2000'],
            'experience_years' => ['nullable', 'integer', 'min:0', 'max:60'],
            'desired_rate' => ['nullable', 'integer', 'min:0', 'max:9999'],
            'status' => ['required', Rule::in(array_keys(Freelancer::STATUSES))],
            'available_from' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
