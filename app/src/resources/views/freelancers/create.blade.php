<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('フリーランス登録（社内）') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                <form method="POST" action="{{ route('freelancers.store') }}">
                    @csrf

                    @include('freelancers.partials.form')

                    <div class="flex items-center justify-end mt-6 space-x-4">
                        <a href="{{ route('freelancers.index') }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('キャンセル') }}</a>
                        <x-primary-button>{{ __('登録') }}</x-primary-button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
