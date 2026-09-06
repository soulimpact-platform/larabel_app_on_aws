<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('担当者アカウントの発行') }} — {{ $partnerCompany->name }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                <p class="mb-6 text-sm text-gray-600">
                    {{ __('発行後、メールアドレスとパスワードを先方へお渡しください。ログイン先は /partner/login です。') }}
                </p>

                <form method="POST" action="{{ route('partner-users.store', $partnerCompany) }}">
                    @csrf
                    <div>
                        <x-input-label for="name" :value="__('氏名')" />
                        <x-text-input id="name" name="name" type="text" class="mt-1 block w-full" :value="old('name')" required autofocus />
                        <x-input-error :messages="$errors->get('name')" class="mt-2" />
                    </div>
                    <div class="mt-4">
                        <x-input-label for="email" :value="__('メールアドレス')" />
                        <x-text-input id="email" name="email" type="email" class="mt-1 block w-full" :value="old('email')" required />
                        <x-input-error :messages="$errors->get('email')" class="mt-2" />
                    </div>
                    <div class="mt-4">
                        <x-input-label for="password" :value="__('初期パスワード')" />
                        <x-text-input id="password" name="password" type="text" class="mt-1 block w-full" required autocomplete="off" />
                        <p class="mt-1 text-xs text-gray-500">{{ __('先方へ伝えるため、入力内容が見える形にしています。') }}</p>
                        <x-input-error :messages="$errors->get('password')" class="mt-2" />
                    </div>
                    <div class="flex items-center justify-end mt-6 space-x-4">
                        <a href="{{ route('partner-companies.edit', $partnerCompany) }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('キャンセル') }}</a>
                        <x-primary-button>{{ __('発行') }}</x-primary-button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
