#!/bin/sh
set -e

if [ ! -d /var/www/html/public/build ]; then
    echo "public/build が見つからないため、フロントエンド資産をビルドします..."
    su www-data -s /bin/sh -c "cd /var/www/html && npm install && npm run build"
fi

exec php-fpm
