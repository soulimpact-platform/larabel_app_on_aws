# syntax=docker/dockerfile:1
#
# Laravelアプリ用のPHPイメージ（開発用・本番用を1ファイルに統合）
#
# ビルドコンテキストは app/ ディレクトリ。
#   ローカル: docker compose build                                     → target: dev
#   デプロイ: docker build -f docker/php/Dockerfile --target runtime .  → CIが使用
#             docker build -f docker/php/Dockerfile --target nginx .    → CIが使用
#
# ■ ステージ構成と依存関係
#
#     [1] base ──┬── [2] dev                    ← target: dev
#                │
#                └── [5] runtime ←┐             ← target: runtime（php-fpm）
#                                 │
#                     [6] nginx ←─┤             ← target: nginx（リバースプロキシ）
#                                 │
#                     [3] vendor ─┤  composer install の成果物
#                     [4] assets ─┘  npm run build の成果物
#
# [5] runtime と [6] nginx はECS上で同一タスクの2コンテナとして動く。
# どちらも [3][4] の成果物を取り込むが、互いには依存しない。
#
# ■ なぜ "prod" ではなく "runtime" か
# このイメージは環境non依存。同じイメージをstagingにもproductionにも配り、
# 差分は環境変数とSSMパラメータで与える（build once, deploy many）。
# ステージ名に環境名を入れると「stg用イメージを別ビルドする」設計に
# 引きずられ、検証したものと違う成果物を本番へ出すことになる。
#
# BuildKitは依存グラフを解析するため、指定したターゲットに必要な
# ステージだけがビルドされる。dev を指定しても [3][4] は走らない。
# また [3] と [4] は互いに独立なので並列にビルドされる。
#
# ■ なぜ base を共有するか
# PHP拡張機能の定義を1箇所に集約するため。開発用と本番用で別々に書くと、
# 片方だけ拡張を足したときに「ローカルでは動くのに本番で落ちる」が起きる。


###############################################################################
# [1/6] base ここから
#   役割: 開発用・本番用が共有するPHP実行環境
###############################################################################
FROM php:8.4-fpm AS base

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install \
    pdo_mysql \
    zip \
    bcmath \
    mbstring \
    exif \
    pcntl \
    gd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

###############################################################################
# [1/6] base ここまで
#   成果物: PHP 8.4-fpm + 拡張機能7種。アプリコードはまだ無い
###############################################################################


###############################################################################
# [2/6] dev ここから
#   役割: ローカル開発用（docker compose が使う）
#   基点: base
#
#   ソースは docker-compose がボリュームマウントするためCOPYしない。
#   opcacheも入れない（有効にするとコードの変更が反映されなくなるため）。
###############################################################################
FROM base AS dev

# Node.js(LTS)。フロントエンド資産をコンテナ内でビルドするため
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ボリュームマウントするホスト側ファイルの所有者(UID/GID)にwww-dataを合わせる
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# entrypoint.sh は前処理（資産ビルド）のあと docker-php-entrypoint へ委譲する。
# そのためCMDが素通りし、runtimeと同じく引数の上書きが効く
ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]

###############################################################################
# [2/6] dev ここまで
#   成果物: base + Node.js + composer + 起動時に資産をビルドするentrypoint
#   ※ 以降のステージはこれを参照しない（devは終着点）
###############################################################################


###############################################################################
# [3/6] vendor ここから
#   役割: デプロイ用のPHP依存関係を解決する
#   基点: composer公式イメージ（php-fpmではない）
#
#   ここで作った vendor/ を [5] runtime が受け取る。
#   composer自体は最終イメージに入らない。
###############################################################################
FROM composer:2 AS vendor

WORKDIR /app

# 依存定義だけを先にコピーしてレイヤキャッシュを効かせる。
# この時点ではartisanが無いためスクリプトとオートローダ生成は行わない
COPY src/composer.json src/composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --no-interaction

# アプリ本体をコピーしてから最適化オートローダを生成する
# （post-autoload-dumpでpackage:discoverが実行される）
COPY src/ ./
RUN composer dump-autoload --no-dev --optimize --classmap-authoritative

###############################################################################
# [3/6] vendor ここまで
#   成果物: /app 配下にアプリコード + vendor/ + bootstrap/cache/packages.php
#   受け渡し先: [5] runtime の COPY --from=vendor
###############################################################################


###############################################################################
# [4/6] assets ここから
#   役割: デプロイ用のフロントエンド資産をビルドする（Vite / Tailwind）
#   基点: Node公式イメージ（php-fpmではない）
#
#   ここで作った public/build を [5] runtime が受け取る。
#   Node.jsとnode_modulesは最終イメージに入らない。
###############################################################################
FROM node:22-slim AS assets

WORKDIR /app

COPY src/package.json src/package-lock.json ./
RUN npm ci

COPY src/ ./
RUN npm run build

###############################################################################
# [4/6] assets ここまで
#   成果物: /app/public/build（コンパイル済みCSS/JS + manifest.json）
#   受け渡し先: [5] runtime の COPY --from=assets
###############################################################################


###############################################################################
# [5/6] runtime ここから
#   役割: デプロイされる実行イメージ（ECRへpushしてECSで動かす）
#   基点: base ＋ [3] vendor と [4] assets の成果物
#
#   アプリコード・vendor・ビルド済み資産をすべてイメージ内に焼き込む。
#   ビルドツール（Node.js / composer）は含まれない。
#
#   環境固有の値（DB接続先・APP_KEY等）はここに一切埋め込まない。
#   実行時にECSタスク定義のenvironment / secretsから注入する。
#   これにより同一イメージをstaging・productionの双方へ配れる。
#
#   ECSでは nginx コンテナと同一タスクに同居し、localhost:9000 で待ち受ける。
###############################################################################
FROM base AS runtime

RUN docker-php-ext-install opcache

# 本番向けのopcache設定（ソースは不変なのでタイムスタンプ検証を切る）
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.memory_consumption=192'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# php.iniは公式が同梱する本番向け推奨設定を使う
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# 他ステージの成果物を取り込む。ここでのみ vendor / assets を参照する
COPY --from=vendor --chown=www-data:www-data /app /var/www/html
COPY --from=assets --chown=www-data:www-data /app/public/build /var/www/html/public/build

# Laravelが書き込むディレクトリを用意する
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

USER www-data

# ENTRYPOINTはベースイメージの docker-php-entrypoint のまま。
# これにより ECS のタスク定義で command を上書きすると
# そのコマンドがそのまま実行される（migrateタスクがこれを利用している）
CMD ["php-fpm"]

###############################################################################
# [5/6] runtime ここまで
#   成果物: 実行可能なアプリイメージ（約580MB / 環境non依存）
#   起動: docker-php-entrypoint php-fpm
#   上書き例: command = ["php","artisan","migrate","--force"]
###############################################################################


###############################################################################
# [6/6] nginx ここから
#   役割: Webリクエストを受けてphp-fpmへ転送するリバースプロキシ
#   基点: nginx公式イメージ ＋ [3] vendor と [4] assets の成果物
#
#   ECSでは runtime コンテナと同一タスクに配置される（awsvpcのため
#   localhostを共有し、127.0.0.1:9000 でphp-fpmに到達する）。
#
#   public/ を焼き込んでいるのは、try_files がファイルの実在を
#   nginx自身のファイルシステムで判定するため。これが無いと
#   静的ファイルへのリクエストがすべてindex.phpへ流れてしまう。
###############################################################################
FROM nginx:1.27-alpine AS nginx

# ローカルと同じテンプレートを使う。差分は環境変数のみ
COPY docker/nginx/templates/ /etc/nginx/templates/

ENV FASTCGI_PASS=127.0.0.1:9000

COPY --from=vendor /app/public /var/www/html/public
COPY --from=assets /app/public/build /var/www/html/public/build

###############################################################################
# [6/6] nginx ここまで
#   成果物: 設定と静的ファイルを内包したnginxイメージ
#   起動: nginx公式のentrypointがtemplateを展開してから起動する
###############################################################################
