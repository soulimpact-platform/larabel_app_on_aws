{{--
    デプロイ確認用のページ。
    認証不要で開けるため、CIでのデプロイが反映されたかを素早く確認できる。

    RELEASE_NOTE を書き換えてコミットすれば、
    「その変更が本番に届いたか」を画面から判別できる。
--}}
<x-guest-layout>
    <div class="space-y-4">
        <h1 class="text-lg font-semibold text-gray-900">
            デプロイ状況
        </h1>

        <dl class="divide-y divide-gray-200 text-sm">
            <div class="flex justify-between py-2">
                <dt class="text-gray-500">リリース</dt>
                <dd class="font-mono text-gray-900">{{ $release }}</dd>
            </div>
            <div class="flex justify-between py-2">
                <dt class="text-gray-500">アプリ名</dt>
                <dd class="text-gray-900">{{ config('app.name') }}</dd>
            </div>
            <div class="flex justify-between py-2">
                <dt class="text-gray-500">環境</dt>
                <dd class="text-gray-900">{{ config('app.env') }}</dd>
            </div>
            <div class="flex justify-between py-2">
                <dt class="text-gray-500">サーバー時刻</dt>
                <dd class="font-mono text-gray-900">{{ $now }}</dd>
            </div>
            <div class="flex justify-between py-2">
                <dt class="text-gray-500">DB接続</dt>
                <dd class="{{ $database === 'ok' ? 'text-green-700' : 'text-red-700' }}">
                    {{ $database }}
                </dd>
            </div>
        </dl>

        <p class="text-xs text-gray-500">
            このページは動作確認用です。
        </p>
    </div>
</x-guest-layout>
