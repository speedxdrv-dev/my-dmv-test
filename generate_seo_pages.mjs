/**
 * generate_seo_pages.mjs
 *
 * 从 Supabase 读取全部 DMV 题目，在 web/questions/ 目录生成：
 *   - index.html       题目列表（Google 可以爬到所有链接）
 *   - {id}.html        每道题单独一页（Google 可以读到题目文字）
 *
 * 运行方法：
 *   node generate_seo_pages.mjs
 */

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

// ── Supabase 连接配置 ──────────────────────────────────────────────────────
const SUPABASE_URL  = 'https://rjxjofocedvazhcmkrgj.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqeGpvZm9jZWR2YXpoY21rcmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1MTE5OTUsImV4cCI6MjA4NjA4Nzk5NX0.Fl5PXHKs-j5139cvpkSg0YstBGg_HlHsqZSa7FoybEA';
const SITE_URL      = 'https://zylandedu.com';

// Supabase Storage 图片前缀
const STORAGE_BASE  = `https://rjxjofocedvazhcmkrgj.supabase.co/storage/v1/object/public/quiz_images/`;

// 输出目录（相对于项目根）
const OUT_DIR = path.resolve('web', 'questions');

// ── 工具函数 ───────────────────────────────────────────────────────────────
function escape(str = '') {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function fullImageUrl(imageUrl) {
  if (!imageUrl || !imageUrl.trim()) return null;
  if (imageUrl.toLowerCase().includes('http')) return imageUrl.trim();
  return STORAGE_BASE + imageUrl.trim();
}

// ── 单题 HTML 模板 ─────────────────────────────────────────────────────────
function questionPage(q, index, total) {
  const imgUrl = fullImageUrl(q.image_url);
  const imgTag = imgUrl
    ? `<img src="${escape(imgUrl)}" alt="题目配图" class="q-img" loading="lazy">`
    : '';

  const options = [
    { letter: 'A', text: q.option_a },
    { letter: 'B', text: q.option_b },
    { letter: 'C', text: q.option_c },
  ]
    .filter(o => o.text && o.text.trim())
    .map(o => {
      const correct = o.letter === (q.correct_answer || '').toUpperCase().charAt(0);
      return `<li class="opt${correct ? ' correct' : ''}">${escape(o.letter)}. ${escape(o.text)}</li>`;
    })
    .join('\n');

  const correct = (q.correct_answer || '').toUpperCase().charAt(0);
  const correctText = { A: q.option_a, B: q.option_b, C: q.option_c }[correct] || '';

  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DMV 题目 #${index + 1}：${escape(q.question_text?.substring(0, 40) || '')} - 加州驾照中文刷题</title>
  <meta name="description" content="加州 DMV 笔试题：${escape(q.question_text?.substring(0, 100) || '')}。正确答案：${escape(correctText?.substring(0, 60) || '')}。中文解析，助你一次通过加州驾照笔试。">
  <link rel="canonical" href="${SITE_URL}/questions/${q.id}.html">
  <style>
    body{font-family:system-ui,Arial,sans-serif;max-width:720px;margin:0 auto;padding:20px 16px;color:#1a1a1a;background:#f5f7fa}
    h1{font-size:1.15rem;color:#0d47a1;line-height:1.5;margin:0 0 16px}
    .q-img{width:100%;max-width:480px;border-radius:8px;margin:12px 0;display:block}
    ul{list-style:none;padding:0;margin:0 0 20px}
    li.opt{padding:10px 14px;border:1px solid #ddd;border-radius:6px;margin-bottom:8px;background:#fff}
    li.opt.correct{background:#e8f5e9;border-color:#43a047;font-weight:600;color:#1b5e20}
    .answer-box{background:#fff3e0;border-left:4px solid #ff8f00;padding:12px 16px;border-radius:4px;margin-bottom:20px}
    .exp-box{background:#e3f2fd;border-left:4px solid #1976d2;padding:12px 16px;border-radius:4px;margin-bottom:24px}
    .cta{display:block;text-align:center;background:#0d47a1;color:#fff;text-decoration:none;padding:14px 24px;border-radius:8px;font-size:1.05rem;font-weight:600;margin-bottom:16px}
    .nav{display:flex;justify-content:space-between;font-size:.9rem}
    .nav a{color:#0d47a1;text-decoration:none}
    .breadcrumb{font-size:.85rem;color:#666;margin-bottom:16px}
    .breadcrumb a{color:#0d47a1;text-decoration:none}
  </style>
</head>
<body>
  <p class="breadcrumb">
    <a href="${SITE_URL}">首页</a> &rsaquo;
    <a href="${SITE_URL}/questions/">题库列表</a> &rsaquo;
    题目 #${index + 1}
  </p>

  <h1>题目 #${index + 1}（共 ${total} 题）<br>${escape(q.question_text || '')}</h1>

  ${imgTag}

  <ul>
    ${options}
  </ul>

  <div class="answer-box">
    <strong>✅ 正确答案：${escape(correct)}. ${escape(correctText)}</strong>
  </div>

  ${q.explanation ? `<div class="exp-box"><strong>解析：</strong> ${escape(q.explanation)}</div>` : ''}

  <a href="${SITE_URL}" class="cta">开始在线刷题 →</a>

  <div class="nav">
    ${index > 0 ? `<a href="./${q._prevId}.html">← 上一题</a>` : '<span></span>'}
    <a href="./index.html">题库目录</a>
    ${q._nextId ? `<a href="./${q._nextId}.html">下一题 →</a>` : '<span></span>'}
  </div>
</body>
</html>`;
}

// ── 题目列表 HTML 模板 ─────────────────────────────────────────────────────
function indexPage(questions) {
  const rows = questions.map((q, i) =>
    `<li><a href="./${q.id}.html">#${i + 1} ${escape((q.question_text || '').substring(0, 60))}${q.question_text?.length > 60 ? '…' : ''}</a></li>`
  ).join('\n');

  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>加州 DMV 中文题库（${questions.length} 题）- ZyLand 驾考通</title>
  <meta name="description" content="加州 DMV 笔试中文题库全集，共 ${questions.length} 道真题，含正确答案和中文解析。免费在线刷题，助你一次通过加州驾照笔试。">
  <link rel="canonical" href="${SITE_URL}/questions/">
  <style>
    body{font-family:system-ui,Arial,sans-serif;max-width:800px;margin:0 auto;padding:20px 16px;color:#1a1a1a;background:#f5f7fa}
    h1{color:#0d47a1;font-size:1.4rem;margin-bottom:8px}
    p.sub{color:#555;margin-bottom:20px}
    ul{list-style:none;padding:0;margin:0 0 24px}
    li{border-bottom:1px solid #e0e0e0}
    li a{display:block;padding:10px 4px;color:#0d47a1;text-decoration:none;font-size:.95rem}
    li a:hover{background:#e3f2fd;border-radius:4px}
    .cta{display:block;text-align:center;background:#0d47a1;color:#fff;text-decoration:none;padding:14px 24px;border-radius:8px;font-size:1.05rem;font-weight:600;margin-bottom:24px}
  </style>
</head>
<body>
  <h1>加州 DMV 中文题库</h1>
  <p class="sub">共 <strong>${questions.length}</strong> 道真题，含正确答案和中文解析。点击题目查看详情，或直接进入 App 在线刷题。</p>

  <a href="${SITE_URL}" class="cta">进入刷题 App →</a>

  <ul>
    ${rows}
  </ul>

  <a href="${SITE_URL}" class="cta">进入刷题 App →</a>
</body>
</html>`;
}

// ── 主流程 ─────────────────────────────────────────────────────────────────
async function main() {
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON);

  console.log('📥 正在从 Supabase 拉取题目...');

  // 分批拉取（Supabase 单次最多 1000 条）
  let all = [];
  let from = 0;
  const pageSize = 1000;

  while (true) {
    const { data, error } = await supabase
      .from('questions')          // ← 表名，如果不对请修改
      .select('id, question_text, option_a, option_b, option_c, correct_answer, explanation, image_url')
      .order('id', { ascending: true })
      .range(from, from + pageSize - 1);

    if (error) {
      console.error('❌ 拉取失败：', error.message);
      console.error('提示：请检查 Supabase 表名是否正确（可能是 "dmv_questions" 或其他名称）');
      process.exit(1);
    }

    if (!data || data.length === 0) break;
    all = all.concat(data);
    console.log(`  已拉取 ${all.length} 条...`);
    if (data.length < pageSize) break;
    from += pageSize;
  }

  if (all.length === 0) {
    console.error('❌ 未拉取到任何题目。请确认 Supabase 表名正确，且表中有数据。');
    process.exit(1);
  }

  console.log(`✅ 共拉取 ${all.length} 道题目`);

  // 建立 prev/next 关联
  for (let i = 0; i < all.length; i++) {
    all[i]._prevId = i > 0 ? all[i - 1].id : null;
    all[i]._nextId = i < all.length - 1 ? all[i + 1].id : null;
  }

  // 创建输出目录
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  // 生成每道题的 HTML
  console.log('📝 正在生成单题页面...');
  for (let i = 0; i < all.length; i++) {
    const q = all[i];
    const html = questionPage(q, i, all.length);
    fs.writeFileSync(path.join(OUT_DIR, `${q.id}.html`), html, 'utf8');
    if ((i + 1) % 100 === 0) console.log(`  已生成 ${i + 1} / ${all.length}`);
  }

  // 生成列表页
  console.log('📋 正在生成题库列表页...');
  fs.writeFileSync(path.join(OUT_DIR, 'index.html'), indexPage(all), 'utf8');

  console.log(`\n🎉 完成！共生成 ${all.length + 1} 个 HTML 文件`);
  console.log(`   输出目录: web/questions/`);
  console.log(`   列表页:   web/questions/index.html`);
  console.log(`\n下一步：`);
  console.log(`  1. 运行 flutter build web --release`);
  console.log(`  2. 把 build/web 整个目录推送到你的 Vercel/GitHub 仓库`);
  console.log(`  3. 在 web/sitemap.xml 里把这些页面加进去（下面会生成 sitemap）`);

  // 顺手生成 sitemap 补丁（追加到现有 sitemap）
  const urls = all.map(q =>
    `  <url><loc>${SITE_URL}/questions/${q.id}.html</loc><changefreq>monthly</changefreq><priority>0.7</priority></url>`
  ).join('\n');

  const sitemapPatch = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>${SITE_URL}/</loc><changefreq>weekly</changefreq><priority>1.0</priority></url>
  <url><loc>${SITE_URL}/questions/</loc><changefreq>weekly</changefreq><priority>0.9</priority></url>
${urls}
</urlset>`;

  fs.writeFileSync(path.join('web', 'sitemap.xml'), sitemapPatch, 'utf8');
  console.log(`\n📍 已更新 web/sitemap.xml（包含所有题目页面的链接）`);
}

main().catch(e => { console.error(e); process.exit(1); });
