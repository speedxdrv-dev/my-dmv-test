#!/bin/bash
# Vercel Install: 克隆 Flutter 并准备环境
set -e
if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi
./_flutter/bin/flutter config --enable-web
./_flutter/bin/flutter pub get
