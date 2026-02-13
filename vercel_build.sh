#!/bin/bash
# Vercel 构建脚本 - 解决指令过长问题

# 1. 克隆轻量版 Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1 f

# 2. 设置环境变量
printf "SUPABASE_URL=$SUPABASE_URL\nSUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" > .env

# 3. 运行构建（包含自动下载依赖、生成代码和 HTML 模式编译）
./f/bin/flutter config --enable-web
./f/bin/flutter pub get
./f/bin/flutter build web --release --web-renderer html --base-href=/
