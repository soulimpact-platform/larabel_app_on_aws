#!/bin/sh
set -e

if [ ! -d /var/www/html/public/build ]; then
    echo "public/build が見つからないため、フロントエンド資産をビルドします..."
    su www-data -s /bin/sh -c "cd /var/www/html && npm install && npm run build"
fi

# 前処理が終わったら公式のentrypointへ委譲する。
# php-fpm を直接execすると渡された引数が捨てられ、
# `docker compose run php php artisan ...` のようなコマンド指定が効かなくなる
exec docker-php-entrypoint "$@"
