-- 在 Supabase SQL Editor 中执行此脚本，创建 user_mistakes 表
-- 用于存储用户答错的题目 ID，实现个人错题本功能

CREATE TABLE IF NOT EXISTS public.user_mistakes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, question_id)
);

-- 创建索引以便快速查询
CREATE INDEX IF NOT EXISTS idx_user_mistakes_user_id ON public.user_mistakes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_mistakes_question_id ON public.user_mistakes(question_id);

-- 开启 RLS
ALTER TABLE public.user_mistakes ENABLE ROW LEVEL SECURITY;

-- 用户只能读取和操作自己的错题
CREATE POLICY "Users can read own mistakes" ON public.user_mistakes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own mistakes" ON public.user_mistakes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own mistakes" ON public.user_mistakes
  FOR DELETE USING (auth.uid() = user_id);
