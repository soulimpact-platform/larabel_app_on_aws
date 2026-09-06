<x-partner-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('フリーランス管理') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">

                @if (session('status'))
                    <div class="mb-4 text-sm text-green-600">{{ session('status') }}</div>
                @endif

                {{-- 絞り込み。GETなのでURLを共有すれば同じ条件を再現できる --}}
                <form method="GET" action="{{ route('partner.freelancers.index') }}"
                      class="mb-4 flex flex-wrap items-end gap-3">
                    <div>
                        <x-input-label for="keyword" :value="__('キーワード')" />
                        <x-text-input id="keyword" name="keyword" type="text" class="mt-1 block w-64"
                            :value="$keyword" placeholder="氏名・フリガナ・スキル" />
                    </div>
                    <div>
                        <x-input-label for="status" :value="__('稼働状況')" />
                        <select id="status" name="status"
                            class="mt-1 block w-40 border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 rounded-md shadow-sm">
                            <option value="">{{ __('すべて') }}</option>
                            @foreach (\App\Models\Freelancer::STATUSES as $value => $label)
                                <option value="{{ $value }}" @selected($status === $value)>{{ $label }}</option>
                            @endforeach
                        </select>
                    </div>
                    <x-primary-button>{{ __('検索') }}</x-primary-button>
                    @if (filled($keyword) || filled($status))
                        <a href="{{ route('partner.freelancers.index') }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('条件をクリア') }}</a>
                    @endif
                </form>

                <div class="mb-4 flex items-center justify-between">
                    <p class="text-sm text-gray-600">{{ __('全') }} {{ $freelancers->total() }} {{ __('件') }}</p>
                    <a href="{{ route('partner.freelancers.create') }}"
                       class="inline-flex items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-gray-700">
                        {{ __('新規登録') }}
                    </a>
                </div>

                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead>
                            <tr>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('氏名') }}</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('スキル') }}</th>
                                <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase">{{ __('経験') }}</th>
                                <th class="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase">{{ __('希望単価') }}</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('稼働状況') }}</th>
                                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">{{ __('稼働可能') }}</th>
                                <th class="px-4 py-2"></th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-200">
                            @forelse ($freelancers as $freelancer)
                                <tr>
                                    <td class="px-4 py-2">
                                        <div class="text-gray-900">{{ $freelancer->name }}</div>
                                        @if ($freelancer->name_kana)
                                            <div class="text-xs text-gray-500">{{ $freelancer->name_kana }}</div>
                                        @endif
                                    </td>
                                    <td class="px-4 py-2 text-sm text-gray-700 max-w-xs truncate" title="{{ $freelancer->skills }}">
                                        {{ $freelancer->skills }}
                                    </td>
                                    <td class="px-4 py-2 text-right text-sm">
                                        {{ $freelancer->experience_years !== null ? $freelancer->experience_years.'年' : '-' }}
                                    </td>
                                    <td class="px-4 py-2 text-right text-sm">
                                        {{ $freelancer->desired_rate !== null ? $freelancer->desired_rate.'万' : '-' }}
                                    </td>
                                    <td class="px-4 py-2">
                                        @php($badge = match ($freelancer->status) {
                                            'available' => 'bg-green-100 text-green-800',
                                            'working' => 'bg-blue-100 text-blue-800',
                                            default => 'bg-gray-100 text-gray-600',
                                        })
                                        <span class="inline-flex px-2 py-0.5 rounded text-xs {{ $badge }}">
                                            {{ $freelancer->statusLabel() }}
                                        </span>
                                    </td>
                                    <td class="px-4 py-2 text-sm text-gray-700">
                                        {{ $freelancer->available_from?->format('Y-m-d') ?? '-' }}
                                    </td>
                                    <td class="px-4 py-2 text-right space-x-2 whitespace-nowrap">
                                        <a href="{{ route('partner.freelancers.edit', $freelancer) }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('編集') }}</a>
                                        <form action="{{ route('partner.freelancers.destroy', $freelancer) }}" method="POST" class="inline"
                                              onsubmit="return confirm('{{ __('削除しますか？') }}');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="text-sm text-red-600 hover:text-red-900">{{ __('削除') }}</button>
                                        </form>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="px-4 py-8 text-center text-sm text-gray-500">
                                        {{ __('該当するフリーランスがいません') }}
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                <div class="mt-4">
                    {{ $freelancers->links() }}
                </div>
            </div>
        </div>
    </div>
</x-partner-app-layout>
