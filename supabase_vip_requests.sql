-- VIP 开通申请表
-- 在 Supabase SQL Editor 中执行

CREATE TABLE IF NOT EXISTS public.vip_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vip_requests_user_id ON public.vip_requests(user_id);

ALTER TABLE public.vip_requests ENABLE ROW LEVEL SECURITY;

-- 用户只能插入自己的申请
CREATE POLICY "Users can insert own vip_request"
  ON public.vip_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 用户只能读取自己的申请
CREATE POLICY "Users can select own vip_request"
  ON public.vip_requests FOR SELECT
  USING (auth.uid() = user_id);
