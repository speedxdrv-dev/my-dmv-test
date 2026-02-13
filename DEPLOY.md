# Web 部署说明

## Vercel 部署（推荐）

1. **base-href 必须为 `/`**（根路径）
2. **Vercel 项目设置**：
   - Framework: Other
   - Build Command: `flutter build web --release --base-href=/ --pwa-strategy none --no-source-maps`
   - Output Directory: `build/web`
   - Install Command: `git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter && ./_flutter/bin/flutter config --enable-web && ./_flutter/bin/flutter pub get`

3. **vercel.json** 已配置 buildCommand 和 outputDirectory

## GitHub Pages 部署

1. **访问地址**：`https://<用户名>.github.io/<仓库名>/`
2. **构建命令**：`flutter build web --release --base-href=/<仓库名>/ --pwa-strategy none --no-source-maps`

## 404 排查

- **Supabase 404**：已移除启动时的 Supabase 检测，不再阻塞应用
- **资源 404**：Vercel 用 `/`，GitHub Pages 用 `/仓库名/`
- **清除缓存**：用无痕模式或强制刷新 (Ctrl+Shift+R) 测试
