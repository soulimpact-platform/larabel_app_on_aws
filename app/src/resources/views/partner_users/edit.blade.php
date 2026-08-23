<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('担当者アカウントの編集') }} — {{ $partnerUser->partnerCompany->name }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                <form method="POST" action="{{ route('partner-users.update', $partnerUser) }}">
                    @csrf
                    @method('PUT')
                    <div>
                        <x-input-label for="name" :value="__('氏名')" />
                        <x-text-input id="name" name="name" type="text" class="mt-1 block w-full"
                            :value="old('name', $partnerUser->name)" required autofocus />
                        <x-input-error :messages="$errors->get('name')" class="mt-2" />
                    </div>
                    <div class="mt-4">
                        <x-input-label for="email" :value="__('メールアドレス')" />
                        <x-text-input id="email" name="email" type="email" class="mt-1 block w-full"
                            :value="old('email', $partnerUser->email)" required />
                        <x-input-error :messages="$errors->get('email')" class="mt-2" />
                    </div>
                    <div class="mt-4">
                        <x-input-label for="password" :value="__('パスワード（変更する場合のみ）')" />
                        <x-text-input id="password" name="password" type="text" class="mt-1 block w-full" autocomplete="off" />
                        <x-input-error :messages="$errors->get('password')" class="mt-2" />
                    </div>
                    <div class="mt-4">
                        <x-input-label for="is_active" :value="__('状態')" />
                        <select id="is_active" name="is_active"
                            class="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm">
                            <option value="1" @selected((bool) old('is_active', $partnerUser->is_active))>{{ __('有効') }}</option>
                            <option value="0" @selected(! (bool) old('is_active', $partnerUser->is_active))>{{ __('停止（ログイン不可）') }}</option>
                        </select>
                        <p class="mt-1 text-xs text-gray-500">{{ __('停止にしても登録済みの人材データは残ります。') }}</p>
                    </div>
                    <div class="flex items-center justify-end mt-6 space-x-4">
                        <a href="{{ route('partner-companies.edit', $partnerUser->partner_company_id) }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('キャンセル') }}</a>
                        <x-primary-button>{{ __('更新') }}</x-primary-button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
