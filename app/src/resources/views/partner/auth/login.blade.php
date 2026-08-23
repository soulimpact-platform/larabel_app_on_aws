<x-guest-layout>
    <div class="mb-6">
        <h1 class="text-lg font-semibold text-gray-800">{{ __('パートナーログイン') }}</h1>
        <p class="mt-1 text-sm text-gray-600">
            {{ __('発行されたアカウントでログインしてください。') }}
        </p>
    </div>

    <x-auth-session-status class="mb-4" :status="session('status')" />

    <form method="POST" action="{{ route('partner.login') }}">
        @csrf

        <div>
            <x-input-label for="email" :value="__('メールアドレス')" />
            <x-text-input id="email" class="block mt-1 w-full" type="email" name="email"
                :value="old('email')" required autofocus autocomplete="username" />
            <x-input-error :messages="$errors->get('email')" class="mt-2" />
        </div>

        <div class="mt-4">
            <x-input-label for="password" :value="__('パスワード')" />
            <x-text-input id="password" class="block mt-1 w-full" type="password" name="password"
                required autocomplete="current-password" />
            <x-input-error :messages="$errors->get('password')" class="mt-2" />
        </div>

        <div class="block mt-4">
            <label for="remember_me" class="inline-flex items-center">
                <input id="remember_me" type="checkbox"
                    class="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500" name="remember">
                <span class="ms-2 text-sm text-gray-600">{{ __('ログイン状態を保持する') }}</span>
            </label>
        </div>

        {{-- パスワード再発行は社内管理者が行う運用のため、リンクは置かない --}}
        <div class="flex items-center justify-end mt-6">
            <x-primary-button>{{ __('ログイン') }}</x-primary-button>
        </div>
    </form>
</x-guest-layout>
