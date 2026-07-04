FROM php:8.4-fpm

# Laravelに必要な拡張機能とビルドツールをインストール
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

# Node.js(LTS)をインストール（フロントエンド資産のビルド用）
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Composerを公式イメージからコピー
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ボリュームマウントするホスト側ファイルの所有者(UID/GID)にwww-dataを合わせる
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["entrypoint.sh"]
