<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('フリーランス編集') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-6">
                <form method="POST" action="{{ route('freelancers.update', $freelancer) }}">
                    @csrf
                    @method('PUT')

                    @include('freelancers.partials.form')

                    <div class="flex items-center justify-end mt-6 space-x-4">
                        <a href="{{ route('freelancers.index') }}" class="text-sm text-gray-600 hover:text-gray-900">{{ __('キャンセル') }}</a>
                        <x-primary-button>{{ __('更新') }}</x-primary-button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</x-app-layout>
