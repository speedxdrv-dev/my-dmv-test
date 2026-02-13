-- 若 questions 表有数据但 APP 显示「题库为空」，多半是 RLS 阻止了读取
-- 在 Supabase SQL Editor 中执行以下 SQL：

-- 1. 删除可能冲突的旧策略（若存在）
DROP POLICY IF EXISTS "Allow public read access" ON public.questions;

-- 2. 创建允许所有人读取的策略
CREATE POLICY "Allow public read access" ON public.questions
  FOR SELECT USING (true);

-- 3. 插入示例题目（若表已有数据则会新增 3 道题，可跳过此步）
INSERT INTO public.questions (question_text, option_a, option_b, option_c, correct_answer, explanation)
VALUES
  ('Flutter 是由哪家公司开发的？', 'Google', 'Facebook', 'Microsoft', 'A', 'Flutter 由 Google 开发。'),
  ('Dart 语言的主要特点是什么？', '编译型语言', '解释型语言', '标记语言', 'A', 'Dart 是 AOT 编译型语言。'),
  ('Supabase 的主要功能是？', '前端框架', '后端即服务 (BaaS)', '数据库设计工具', 'B', 'Supabase 提供数据库、认证等后端服务。');
