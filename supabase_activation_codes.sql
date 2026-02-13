-- 激活码表与兑换函数
-- 在 Supabase SQL Editor 中执行此脚本

-- 1. 创建 activation_codes 表（如不存在）
CREATE TABLE IF NOT EXISTS public.activation_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  is_used BOOLEAN NOT NULL DEFAULT false,
  used_at TIMESTAMPTZ,
  used_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 创建索引便于按 code 查询
CREATE INDEX IF NOT EXISTS idx_activation_codes_code ON public.activation_codes(code);

-- 开启 RLS
ALTER TABLE public.activation_codes ENABLE ROW LEVEL SECURITY;

-- 普通用户无法直接读取/修改 activation_codes，仅通过 RPC 兑换
CREATE POLICY "No direct access to activation_codes"
  ON public.activation_codes FOR ALL
  USING (false)
  WITH CHECK (false);

-- 2. 确认 profiles 表有 is_vip 列（如无则添加）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_vip'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN is_vip BOOLEAN NOT NULL DEFAULT false;
  END IF;
END $$;

-- 3. 创建兑换函数（需以 service_role 或具有足够权限执行）
CREATE OR REPLACE FUNCTION public.redeem_activation_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID;
  v_row RECORD;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', '请先登录');
  END IF;

  -- 标准化 code：去除首尾空格、转大写
  p_code := UPPER(TRIM(p_code));

  IF LENGTH(p_code) <> 8 THEN
    RETURN jsonb_build_object('ok', false, 'error', '激活码须为 8 位');
  END IF;

  SELECT id, is_used INTO v_row
  FROM public.activation_codes
  WHERE code = p_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', '激活码无效');
  END IF;

  IF v_row.is_used THEN
    RETURN jsonb_build_object('ok', false, 'error', '该激活码已被使用');
  END IF;

  -- 标记为已使用
  UPDATE public.activation_codes
  SET is_used = true, used_at = NOW(), used_by = v_uid
  WHERE id = v_row.id;

  -- 更新 profiles.is_vip
  UPDATE public.profiles SET is_vip = true WHERE id = v_uid;
  IF NOT FOUND THEN
    INSERT INTO public.profiles (id, is_vip) VALUES (v_uid, true);
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- 4. 授予认证用户执行权限
GRANT EXECUTE ON FUNCTION public.redeem_activation_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_activation_code(TEXT) TO service_role;
