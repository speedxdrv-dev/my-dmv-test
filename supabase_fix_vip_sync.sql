-- 1. 确保 RLS 已启用
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. 策略：用户可以查看自己的 profile
-- 先删除旧策略以防冲突
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;

CREATE POLICY "Users can read own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- 允许 Service Role (Edge Functions) 完全访问
-- (虽然 service_role key 默认绕过 RLS，但明确策略是个好习惯，或者不需要，但为了保险)
-- CREATE POLICY "Service role full access" ON public.profiles FOR ALL USING (auth.role() = 'service_role');

-- 3. 触发器：当 profiles.is_vip 变更时，自动同步到 auth.users.raw_user_meta_data
-- 这样即使直接查询 profiles 失败，也可以尝试从 session metadata 获取（作为备选）
CREATE OR REPLACE FUNCTION public.handle_vip_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- 仅当 is_vip 发生变化时更新
  IF NEW.is_vip IS DISTINCT FROM OLD.is_vip THEN
    UPDATE auth.users
    SET raw_user_meta_data = 
      COALESCE(raw_user_meta_data, '{}'::jsonb) || 
      jsonb_build_object('is_vip', NEW.is_vip)
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_vip_change ON public.profiles;
CREATE TRIGGER on_vip_change
AFTER UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_vip_status_change();

-- 4. 补充数据：将现有的 is_vip = true 同步到 metadata
UPDATE auth.users u
SET raw_user_meta_data = 
  COALESCE(raw_user_meta_data, '{}'::jsonb) || 
  jsonb_build_object('is_vip', p.is_vip)
FROM public.profiles p
WHERE u.id = p.id AND p.is_vip = true;
