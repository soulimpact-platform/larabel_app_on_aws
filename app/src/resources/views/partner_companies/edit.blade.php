<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ $partnerCompany->name }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8 space-y-6">
            @if (session('status'))
                <div class="text-sm text-green-600">{{ session('status') }}</div>
            @endif

            {{-- 企業情報 --}}
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <h3 class="text-lg font-medium text-gray-900 mb-4">{{ __('企業情報') }}</h3>
                <form method="POST" action="{{ route('partner-companies.update', $partnerCompany) }}">
                    @csrf
                    @method('PUT')
                    <div>
                        <x-input-label for="name" :value="__('企業名')" />
                        <x-text-input id="name" name="name" type="text" class="mt-1 block w-full"
                            :value="old('name', $partnerCompany->name)" required />
                        <x-input-error :messages="$errors->get('name')" class="mt-2" />
                    </div>
                    <div class="mt-4">
                        <x-input-label for="notes" :value="__('備考')" />
                        <textarea id="notes" name="notes" rows="3"
                            class="mt-1 block w-full border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm">{{ old('notes', $partnerCompany->notes) }}</textarea>
                    </div>
                    <div class="flex items-center justify-end mt-6 space-x-4">
                        <a href="{{ route('partner-companies.index') }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('戻る') }}</a>
                        <x-primary-button>{{ __('更新') }}</x-primary-button>
                    </div>
                </form>
            </div>

            {{-- 担当者アカウント --}}
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <div class="flex items-center justify-between mb-4">
                    <div>
                        <h3 class="text-lg font-medium text-gray-900">{{ __('担当者アカウント') }}</h3>
                        <p class="mt-1 text-sm text-gray-600">
                            {{ __('ここで発行した認証情報を先方にお渡しください。ログインは /partner/login です。') }}
                        </p>
                    </div>
                    <a href="{{ route('partner-users.create', $partnerCompany) }}"
                       class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700 whitespace-nowrap">
                        {{ __('発行') }}
                    </a>
                </div>

                <table class="min-w-full divide-y divide-gray-200">
                    <thead>
                        <tr>
                            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('氏名') }}</th>
                            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('メールアドレス') }}</th>
                            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('状態') }}</th>
                            <th class="px-4 py-2"></th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200">
                        @forelse ($partnerCompany->partnerUsers as $partnerUser)
                            <tr>
                                <td class="px-4 py-2">{{ $partnerUser->name }}</td>
                                <td class="px-4 py-2 text-sm text-gray-700">{{ $partnerUser->email }}</td>
                                <td class="px-4 py-2">
                                    @if ($partnerUser->is_active)
                                        <span class="inline-flex px-2 py-0.5 rounded text-xs bg-green-100 text-green-800">{{ __('有効') }}</span>
                                    @else
                                        <span class="inline-flex px-2 py-0.5 rounded text-xs bg-gray-100 text-gray-600">{{ __('停止中') }}</span>
                                    @endif
                                </td>
                                <td class="px-4 py-2 text-right space-x-2 whitespace-nowrap">
                                    <a href="{{ route('partner-users.edit', $partnerUser) }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('編集') }}</a>
                                    <form action="{{ route('partner-users.destroy', $partnerUser) }}" method="POST" class="inline"
                                          onsubmit="return confirm('{{ __('削除しますか？') }}');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="text-sm text-red-600 hover:text-red-900">{{ __('削除') }}</button>
                                    </form>
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="4" class="px-4 py-6 text-center text-sm text-gray-500">{{ __('担当者アカウントがまだありません') }}</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</x-app-layout>
