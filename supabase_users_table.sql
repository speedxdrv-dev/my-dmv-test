-- 在 Supabase SQL Editor 中执行此脚本，创建 users 表（注册/登录必需）

CREATE TABLE IF NOT EXISTS public.users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  points INTEGER NOT NULL DEFAULT 0,
  quizzes JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 开启 RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 所有人可读（用于排行榜）
CREATE POLICY "Users are viewable by everyone"
  ON public.users FOR SELECT
  USING (true);

-- 用户只能插入自己的记录（注册时）
CREATE POLICY "Users can insert own row"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 用户只能更新自己的记录（修改用户名、上传测验等）
CREATE POLICY "Users can update own row"
  ON public.users FOR UPDATE
  USING (auth.uid() = user_id);
