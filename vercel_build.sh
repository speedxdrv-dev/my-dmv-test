#!/bin/bash
# 1. 打印当前目录，确认文件位置
pwd
ls -l vercel_build.sh

# 2. 开始安装 Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1 f

# 3. 环境变量注入
printf "SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s" "$SUPABASE_URL" "$SUPABASE_ANON_KEY" > .env

# 4. 执行构建（必须用 html 渲染器，否则微信内会尝试加载 WASM 导致蓝屏）
./f/bin/flutter build web --release --web-renderer html
