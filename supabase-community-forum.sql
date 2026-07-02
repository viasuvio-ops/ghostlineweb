-- GhostNumber Community Forum
-- Run this in Supabase SQL Editor for the same project used by GhostNumber.

create extension if not exists pgcrypto;

create table if not exists public.community_topics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in (
    'us-number',
    'international',
    'esim',
    'sms-calling',
    'privacy',
    'wallet',
    'features'
  )),
  title text not null check (char_length(title) between 5 and 160),
  body text not null check (char_length(body) between 10 and 8000),
  tags text[] not null default '{}',
  author_name text not null check (char_length(author_name) between 1 and 80),
  country text,
  status text not null default 'published' check (status in ('published', 'hidden', 'deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.community_replies (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.community_topics(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 2 and 8000),
  author_name text not null check (char_length(author_name) between 1 and 80),
  country text,
  status text not null default 'published' check (status in ('published', 'hidden', 'deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists community_topics_category_idx on public.community_topics(category);
create index if not exists community_topics_created_at_idx on public.community_topics(created_at desc);
create index if not exists community_replies_topic_id_idx on public.community_replies(topic_id);
create index if not exists community_replies_created_at_idx on public.community_replies(created_at asc);

alter table public.community_topics enable row level security;
alter table public.community_replies enable row level security;

drop policy if exists "Public can read published community topics" on public.community_topics;
create policy "Public can read published community topics"
on public.community_topics
for select
using (status = 'published');

drop policy if exists "Logged in users can create community topics" on public.community_topics;
create policy "Logged in users can create community topics"
on public.community_topics
for insert
to authenticated
with check (auth.uid() = user_id and status = 'published');

drop policy if exists "Users can update own community topics" on public.community_topics;
create policy "Users can update own community topics"
on public.community_topics
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Public can read published community replies" on public.community_replies;
create policy "Public can read published community replies"
on public.community_replies
for select
using (
  status = 'published'
  and exists (
    select 1
    from public.community_topics t
    where t.id = community_replies.topic_id
      and t.status = 'published'
  )
);

drop policy if exists "Logged in users can create community replies" on public.community_replies;
create policy "Logged in users can create community replies"
on public.community_replies
for insert
to authenticated
with check (
  auth.uid() = user_id
  and status = 'published'
  and exists (
    select 1
    from public.community_topics t
    where t.id = community_replies.topic_id
      and t.status = 'published'
  )
);

drop policy if exists "Users can update own community replies" on public.community_replies;
create policy "Users can update own community replies"
on public.community_replies
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
