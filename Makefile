COMPOSE_FILE := app/docker-compose.yml
DC := docker compose -f $(COMPOSE_FILE)
ARTISAN := $(DC) exec -u www-data php php artisan

.DEFAULT_GOAL := help

.PHONY: help app-up dev-up migrate-seed wait-db infra-down build-assets

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

app-up: ## バックグラウンドで起動し、マイグレーション・初期データ投入まで行う
	$(DC) up -d --build
	$(MAKE) migrate-seed

dev-up: ## フォアグラウンドでログを表示しながら起動する（マイグレーション・初期データ投入も実行）
	$(DC) up -d --build
	$(MAKE) migrate-seed
	$(DC) up

migrate-seed: wait-db
	$(ARTISAN) migrate --seed

wait-db:
	@echo "Waiting for MySQL..."
	@until $(DC) exec -T mysql mysqladmin ping -h 127.0.0.1 -uroot -psecret --silent >/dev/null 2>&1; do sleep 1; done
	@echo "MySQL is ready"

infra-down: ## コンテナとDBデータのボリュームを含めて削除する
	$(DC) down -v

build-assets: ## CSS/JS（Tailwind/Vite）を再ビルドする
	$(DC) exec -u www-data php npm install
	$(DC) exec -u www-data php npm run build
