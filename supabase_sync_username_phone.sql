-- 1. 确保 public.users 和 public.profiles 的数据一致性
-- 当 public.users 更新 username 时，同步到 public.profiles.phone_number
CREATE OR REPLACE FUNCTION public.sync_users_username_to_profiles()
RETURNS TRIGGER AS $$
BEGIN
  -- 防止无限递归：仅当值确实改变时执行
  UPDATE public.profiles
  SET phone_number = NEW.username
  WHERE id = NEW.user_id
  AND (phone_number IS DISTINCT FROM NEW.username);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_users_username_change ON public.users;
CREATE TRIGGER on_users_username_change
AFTER INSERT OR UPDATE OF username ON public.users
FOR EACH ROW EXECUTE FUNCTION public.sync_users_username_to_profiles();

-- 2. 当 public.profiles 更新 phone_number 时，同步到 public.users.username
CREATE OR REPLACE FUNCTION public.sync_profiles_phone_to_users()
RETURNS TRIGGER AS $$
BEGIN
  -- 尝试更新 public.users，如果不存在则可能需要插入（视业务逻辑而定，这里仅更新）
  UPDATE public.users
  SET username = NEW.phone_number
  WHERE user_id = NEW.id
  AND (username IS DISTINCT FROM NEW.phone_number);
  
  -- 如果 users 表中不存在该用户，是否自动创建？
  -- 通常 profiles 由 auth 触发创建，users 也应存在。
  -- 为防止死锁或复杂逻辑，这里仅做更新同步。
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profiles_phone_change ON public.profiles;
CREATE TRIGGER on_profiles_phone_change
AFTER INSERT OR UPDATE OF phone_number ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profiles_phone_to_users();

-- 3. 手动修复现有不一致的数据 (以 profiles 为准)
UPDATE public.users u
SET username = p.phone_number
FROM public.profiles p
WHERE u.user_id = p.id
AND p.phone_number IS NOT NULL
AND u.username IS DISTINCT FROM p.phone_number;
