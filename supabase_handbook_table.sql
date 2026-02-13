-- 在 Supabase SQL Editor 中执行此脚本，创建 handbook 表
-- 用于驾照官方手册 (Handbook) 模块

CREATE TABLE IF NOT EXISTS public.handbook (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 0
);

-- 开启 RLS，允许匿名读取
ALTER TABLE public.handbook ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access" ON public.handbook
  FOR SELECT USING (true);

-- 插入示例章节（可按需修改）
INSERT INTO public.handbook (title, content, display_order)
VALUES
  (
    '第一章 驾照概述',
    '# 第一章 驾照概述\n\n## 1.1 驾照类型\n\n加州驾照分为多种类型，包括：\n\n- **C 类驾照**：普通小客车\n- **M 类驾照**：摩托车\n- **A/B 类驾照**：商用车辆\n\n## 1.2 申请资格\n\n申请人需年满 16 周岁，通过笔试和路考。',
    1
  ),
  (
    '第二章 交通标志',
    '# 第二章 交通标志\n\n## 2.1 禁止标志\n\n红色圆形表示禁止。\n\n## 2.2 警告标志\n\n黄色菱形表示警告，提醒驾驶人注意前方路况。',
    2
  );
