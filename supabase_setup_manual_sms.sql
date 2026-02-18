-- Enable the pg_net extension to make HTTP requests (if needed for older setups, but Edge Functions handle email)
-- create extension if not exists pg_net;

-- Create the verification codes table
create table if not exists public.verification_codes (
  id uuid default gen_random_uuid() primary key,
  phone_number text not null,
  code text not null,
  ip_address text,
  is_used boolean default false,
  expires_at timestamptz not null,
  created_at timestamptz default now()
);

-- Enable Row Level Security (RLS)
alter table public.verification_codes enable row level security;

-- Policies
-- Allow anyone to insert (controlled by Edge Function typically, but if client inserts, we need this)
-- However, since we use Service Role in Edge Function, we don't strictly need public insert if only the function writes.
-- Let's keep it locked down. Only Service Role can access this table by default.

-- Index for faster lookups
create index if not exists idx_verification_codes_phone on public.verification_codes(phone_number);
create index if not exists idx_verification_codes_ip on public.verification_codes(ip_address);
