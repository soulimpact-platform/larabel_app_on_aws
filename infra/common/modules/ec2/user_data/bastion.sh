#!/bin/bash
#
# 踏み台サーバーの初期セットアップ
# aws_instance.bastion の user_data として初回起動時に一度だけ実行される
#
set -eux

export DEBIAN_FRONTEND=noninteractive

# cloud-init起動直後はunattended-upgradesがaptロックを掴んでいることがあるため待つ
apt-get -o DPkg::Lock::Timeout=300 update

# RDS(MySQL)へ接続するためのクライアント
apt-get -o DPkg::Lock::Timeout=300 install -y mysql-client
