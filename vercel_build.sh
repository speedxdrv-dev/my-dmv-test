#!/bin/bash
set -e # 遇到错误立刻停止
set -x # 打印每一行执行的命令，方便看日志

# 1. 检查并清理旧目录
rm -rf f

# 2. 克隆 Flutter (使用最快的镜像和深度)
git clone https://github.com/flutter/flutter.git -b stable --depth 1 f

# 3. 环境变量注入
printf "SUPABASE_URL=$SUPABASE_URL\nSUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" > .env

# 4. 显式指定路径运行构建
./f/bin/flutter build web --release --web-renderer html
