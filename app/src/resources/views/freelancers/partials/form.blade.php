{{-- 登録・編集で共通のフォーム項目。$freelancer は編集時のみ渡される --}}
@php($f = $freelancer ?? null)

{{-- 社内向け画面だけ所属を選べる。パートナー側はログイン主体から自動決定される --}}
<div class="mb-4">
    <x-input-label for="partner_company_id" :value="__('所属パートナー企業')" />
    <select id="partner_company_id" name="partner_company_id"
        class="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm">
        <option value="">{{ __('（社内直登録）') }}</option>
        @foreach ($companies as $company)
            <option value="{{ $company->id }}"
                @selected((string) old('partner_company_id', $f?->partner_company_id) === (string) $company->id)>
                {{ $company->name }}
            </option>
        @endforeach
    </select>
    <x-input-error :messages="$errors->get('partner_company_id')" class="mt-2" />
</div>

<div>
    <x-input-label for="name" :value="__('氏名')" />
    <x-text-input id="name" name="name" type="text" class="mt-1 block w-full"
        :value="old('name', $f?->name)" required autofocus />
    <x-input-error :messages="$errors->get('name')" class="mt-2" />
</div>

<div class="mt-4">
    <x-input-label for="name_kana" :value="__('フリガナ')" />
    <x-text-input id="name_kana" name="name_kana" type="text" class="mt-1 block w-full"
        :value="old('name_kana', $f?->name_kana)" />
    <x-input-error :messages="$errors->get('name_kana')" class="mt-2" />
</div>

<div class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
    <div>
        <x-input-label for="email" :value="__('メールアドレス')" />
        <x-text-input id="email" name="email" type="email" class="mt-1 block w-full"
            :value="old('email', $f?->email)" />
        <x-input-error :messages="$errors->get('email')" class="mt-2" />
    </div>
    <div>
        <x-input-label for="phone" :value="__('電話番号')" />
        <x-text-input id="phone" name="phone" type="text" class="mt-1 block w-full"
            :value="old('phone', $f?->phone)" />
        <x-input-error :messages="$errors->get('phone')" class="mt-2" />
    </div>
</div>

<div class="mt-4">
    <x-input-label for="skills" :value="__('保有スキル')" />
    <textarea id="skills" name="skills" rows="3"
        class="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm"
        placeholder="PHP / Laravel / AWS / Terraform">{{ old('skills', $f?->skills) }}</textarea>
    <x-input-error :messages="$errors->get('skills')" class="mt-2" />
</div>

<div class="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-4">
    <div>
        <x-input-label for="experience_years" :value="__('経験年数')" />
        <x-text-input id="experience_years" name="experience_years" type="number" min="0" max="60"
            class="mt-1 block w-full" :value="old('experience_years', $f?->experience_years)" />
        <x-input-error :messages="$errors->get('experience_years')" class="mt-2" />
    </div>
    <div>
        <x-input-label for="desired_rate" :value="__('希望単価（万円/月）')" />
        <x-text-input id="desired_rate" name="desired_rate" type="number" min="0" max="9999"
            class="mt-1 block w-full" :value="old('desired_rate', $f?->desired_rate)" />
        <x-input-error :messages="$errors->get('desired_rate')" class="mt-2" />
    </div>
    <div>
        <x-input-label for="available_from" :value="__('稼働可能時期')" />
        <x-text-input id="available_from" name="available_from" type="date" class="mt-1 block w-full"
            :value="old('available_from', $f?->available_from?->format('Y-m-d'))" />
        <x-input-error :messages="$errors->get('available_from')" class="mt-2" />
    </div>
</div>

<div class="mt-4">
    <x-input-label for="status" :value="__('稼働状況')" />
    <select id="status" name="status"
        class="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm">
        @foreach (\App\Models\Freelancer::STATUSES as $value => $label)
            <option value="{{ $value }}" @selected(old('status', $f?->status ?? 'available') === $value)>{{ $label }}</option>
        @endforeach
    </select>
    <x-input-error :messages="$errors->get('status')" class="mt-2" />
</div>

<div class="mt-4">
    <x-input-label for="notes" :value="__('備考')" />
    <textarea id="notes" name="notes" rows="3"
        class="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm">{{ old('notes', $f?->notes) }}</textarea>
    <x-input-error :messages="$errors->get('notes')" class="mt-2" />
</div>
