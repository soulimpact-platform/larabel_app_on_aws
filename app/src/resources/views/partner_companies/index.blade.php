<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ __('パートナー企業管理') }}</h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                @if (session('status'))
                    <div class="mb-4 text-sm text-green-600">{{ session('status') }}</div>
                @endif

                <div class="mb-4 flex items-center justify-between">
                    <p class="text-sm text-gray-600">{{ __('全') }} {{ $companies->total() }} {{ __('社') }}</p>
                    <a href="{{ route('partner-companies.create') }}"
                       class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">
                        {{ __('企業を追加') }}
                    </a>
                </div>

                <table class="min-w-full divide-y divide-gray-200">
                    <thead>
                        <tr>
                            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('企業名') }}</th>
                            <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase">{{ __('担当者') }}</th>
                            <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase">{{ __('登録人材') }}</th>
                            <th class="px-4 py-2"></th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200">
                        @forelse ($companies as $company)
                            <tr>
                                <td class="px-4 py-2 text-gray-900">{{ $company->name }}</td>
                                <td class="px-4 py-2 text-right text-sm">{{ $company->partner_users_count }}</td>
                                <td class="px-4 py-2 text-right text-sm">{{ $company->freelancers_count }}</td>
                                <td class="px-4 py-2 text-right space-x-2 whitespace-nowrap">
                                    <a href="{{ route('partner-companies.edit', $company) }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('編集・担当者') }}</a>
                                    <form action="{{ route('partner-companies.destroy', $company) }}" method="POST" class="inline"
                                          onsubmit="return confirm('{{ __('削除すると担当者アカウントも消えます。よろしいですか？') }}');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="text-sm text-red-600 hover:text-red-900">{{ __('削除') }}</button>
                                    </form>
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="4" class="px-4 py-8 text-center text-sm text-gray-500">{{ __('パートナー企業がまだありません') }}</td></tr>
                        @endforelse
                    </tbody>
                </table>

                <div class="mt-4">{{ $companies->links() }}</div>
            </div>
        </div>
    </div>
</x-app-layout>
