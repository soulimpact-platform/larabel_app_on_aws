<x-partner-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('プロフィール') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8 space-y-6">

            {{-- 氏名の変更。メールはアカウントIDのため変更させない --}}
            <div class="p-4 sm:p-8 bg-white shadow sm:rounded-lg">
                <section class="max-w-xl">
                    <header>
                        <h3 class="text-lg font-medium text-gray-900">{{ __('アカウント情報') }}</h3>
                        <p class="mt-1 text-sm text-gray-600">
                            {{ __('所属企業とメールアドレスの変更は、発行元の管理者にご依頼ください。') }}
                        </p>
                    </header>

                    <form method="post" action="{{ route('partner.profile.update') }}" class="mt-6 space-y-6">
                        @csrf
                        @method('patch')

                        <div>
                            <x-input-label for="company" :value="__('所属企業')" />
                            <x-text-input id="company" type="text" class="mt-1 block w-full bg-gray-100"
                                :value="$partnerUser->partnerCompany->name" disabled />
                        </div>

                        <div>
                            <x-input-label for="email" :value="__('メールアドレス')" />
                            <x-text-input id="email" type="email" class="mt-1 block w-full bg-gray-100"
                                :value="$partnerUser->email" disabled />
                        </div>

                        <div>
                            <x-input-label for="name" :value="__('氏名')" />
                            <x-text-input id="name" name="name" type="text" class="mt-1 block w-full"
                                :value="old('name', $partnerUser->name)" required autofocus />
                            <x-input-error class="mt-2" :messages="$errors->get('name')" />
                        </div>

                        <div class="flex items-center gap-4">
                            <x-primary-button>{{ __('保存') }}</x-primary-button>
                            @if (session('status') === 'profile-updated')
                                <p class="text-sm text-gray-600">{{ __('保存しました') }}</p>
                            @endif
                        </div>
                    </form>
                </section>
            </div>

            {{-- パスワード変更 --}}
            <div class="p-4 sm:p-8 bg-white shadow sm:rounded-lg">
                <section class="max-w-xl">
                    <header>
                        <h3 class="text-lg font-medium text-gray-900">{{ __('パスワード変更') }}</h3>
                        <p class="mt-1 text-sm text-gray-600">
                            {{ __('推測されにくい長いパスワードを設定してください。') }}
                        </p>
                    </header>

                    <form method="post" action="{{ route('partner.password.update') }}" class="mt-6 space-y-6">
                        @csrf
                        @method('put')

                        <div>
                            <x-input-label for="current_password" :value="__('現在のパスワード')" />
                            <x-text-input id="current_password" name="current_password" type="password"
                                class="mt-1 block w-full" autocomplete="current-password" />
                            <x-input-error :messages="$errors->updatePassword->get('current_password')" class="mt-2" />
                        </div>

                        <div>
                            <x-input-label for="password" :value="__('新しいパスワード')" />
                            <x-text-input id="password" name="password" type="password"
                                class="mt-1 block w-full" autocomplete="new-password" />
                            <x-input-error :messages="$errors->updatePassword->get('password')" class="mt-2" />
                        </div>

                        <div>
                            <x-input-label for="password_confirmation" :value="__('新しいパスワード（確認）')" />
                            <x-text-input id="password_confirmation" name="password_confirmation" type="password"
                                class="mt-1 block w-full" autocomplete="new-password" />
                            <x-input-error :messages="$errors->updatePassword->get('password_confirmation')" class="mt-2" />
                        </div>

                        <div class="flex items-center gap-4">
                            <x-primary-button>{{ __('変更') }}</x-primary-button>
                            @if (session('status') === 'password-updated')
                                <p class="text-sm text-gray-600">{{ __('変更しました') }}</p>
                            @endif
                        </div>
                    </form>
                </section>
            </div>
        </div>
    </div>
</x-partner-app-layout>
