-- 在 Supabase SQL Editor 中执行此脚本，创建 questions 表并插入示例数据

CREATE TABLE IF NOT EXISTS public.questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_text TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  option_c TEXT NOT NULL,
  correct_answer TEXT NOT NULL CHECK (correct_answer IN ('A', 'B', 'C')),
  explanation TEXT DEFAULT ''
);

-- 开启 RLS，允许匿名读取（如需登录后使用，可调整策略）
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access" ON public.questions
  FOR SELECT USING (true);

-- 插入示例题目
INSERT INTO public.questions (question_text, option_a, option_b, option_c, correct_answer, explanation)
VALUES
  ('Flutter 是由哪家公司开发的？', 'Google', 'Facebook', 'Microsoft', 'A', 'Flutter 由 Google 开发，用于构建跨平台应用。'),
  ('Dart 语言的主要特点是什么？', '编译型语言', '解释型语言', '标记语言', 'A', 'Dart 是 AOT 编译型语言，可编译为原生代码。'),
  ('Supabase 的主要功能是？', '前端框架', '后端即服务 (BaaS)', '数据库设计工具', 'B', 'Supabase 提供数据库、认证、存储等后端服务。');
