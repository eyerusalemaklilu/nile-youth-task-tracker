-- =====================================================================
-- Nile Youth Network Task Tracker: complete database setup for Supabase
-- Run this whole file ONCE: Supabase dashboard -> SQL Editor -> New query -> paste -> Run
-- =====================================================================

-- ---------- Tables ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text,
  full_name   text not null default '',
  phone       text not null default '',
  avatar_path text not null default '',
  role        text not null default 'member' check (role in ('admin','member')),
  active      boolean not null default false,
  committee_position    text not null default '' check (committee_position in ('','chair','vice_chair','secretary','advocacy','communication','treasurer','coordinator')),
  is_training boolean not null default false,
  is_comms    boolean not null default false,
  created_at  timestamptz not null default now()
);

create table public.tasks (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text not null default '',
  owner_id     uuid references public.profiles(id) on delete set null,
  due          date,
  priority     text not null default 'med' check (priority in ('low','med','high')),
  team         text not null default '',
  status       text not null default 'todo' check (status in ('todo','progress','done')),
  progress     int  not null default 0 check (progress between 0 and 100),
  mentions     uuid[] not null default '{}',
  checklist    jsonb not null default '[]'::jsonb,
  created_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  completed_at timestamptz
);

create table public.task_updates (
  id         uuid primary key default gen_random_uuid(),
  task_id    uuid not null references public.tasks(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete set null,
  text       text not null,
  kind       text not null default 'note',
  created_at timestamptz not null default now()
);

-- meetings, events and trainings share one table (kind)
create table public.meetings (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  kind       text not null default 'meeting' check (kind in ('meeting','event','training')),
  date       date not null,
  time       text not null default '',
  place      text not null default '',
  meet_link  text not null default '',
  rsvp_by    date,
  host_id    uuid references public.profiles(id) on delete set null,
  agenda     text not null default '',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.minutes (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  date       date not null,
  attendees  text not null default '',
  summary    text not null default '',
  decisions  text not null default '',
  actions    text not null default '',
  meeting_id uuid references public.meetings(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.meeting_rsvps (
  id         uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references public.meetings(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  response   text not null check (response in ('going','maybe','no')),
  comment    text not null default '',
  updated_at timestamptz not null default now(),
  unique (meeting_id, user_id)
);

create table public.media_posts (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  platform   text not null default 'Facebook',
  caption    text not null default '',
  link       text not null default '',
  post_date  date not null,
  confirm_by date,
  status     text not null default 'awaiting' check (status in ('awaiting','published')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.media_confirmations (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.media_posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  response   text not null check (response in ('approved','changes')),
  comment    text not null default '',
  updated_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create table public.weekly_goals (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  week_start date not null,
  text       text not null,
  done       boolean not null default false,
  created_at timestamptz not null default now()
);

-- files, photos, videos and links attached to anything (owner_kind + owner_id)
create table public.attachments (
  id          uuid primary key default gen_random_uuid(),
  owner_kind  text not null,
  owner_id    text not null,
  name        text not null default '',
  path        text not null default '',
  url         text not null default '',
  mime        text not null default '',
  size        bigint not null default 0,
  uploaded_by uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);

-- posts inside the work areas (plans, reports, drafts, notes)
create table public.area_posts (
  id         uuid primary key default gen_random_uuid(),
  area       text not null check (area in ('leadership','secretariat','advocacy','projects')),
  kind       text not null default 'Note',
  title      text not null,
  body       text not null default '',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.training_docs (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  category    text not null default 'Other',
  doc_date    date,
  description text not null default '',
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);

-- finance (treasurer)
create table public.finance_entries (
  id          uuid primary key default gen_random_uuid(),
  entry_date  date not null,
  kind        text not null check (kind in ('income','expense')),
  category    text not null default '',
  description text not null default '',
  party       text not null default '',
  amount      numeric(14,2) not null check (amount >= 0),
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);

create table public.finance_budgets (
  id       uuid primary key default gen_random_uuid(),
  category text not null unique,
  amount   numeric(14,2) not null check (amount >= 0)
);

create table public.app_settings (
  key   text primary key,
  value text not null default ''
);

create index on public.tasks (owner_id);
create index on public.tasks (due);
create index on public.task_updates (task_id);
create index on public.attachments (owner_kind, owner_id);
create index on public.weekly_goals (user_id, week_start);
create index on public.finance_entries (entry_date);

-- ---------- Helper functions (who is who) ----------
create or replace function public.is_active() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select active from public.profiles where id = auth.uid()), false)
$$;
create or replace function public.is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select active and role = 'admin' from public.profiles where id = auth.uid()), false)
$$;
-- chair person, vice chair person, secretary general (or admin): schedule meetings, post minutes
create or replace function public.is_leader() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select active and (role = 'admin' or committee_position in ('chair','vice_chair','secretary')) from public.profiles where id = auth.uid()), false)
$$;
create or replace function public.can_manage_finance() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select active and (role = 'admin' or committee_position = 'treasurer') from public.profiles where id = auth.uid()), false)
$$;
create or replace function public.can_train() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select active and (role = 'admin' or is_training) from public.profiles where id = auth.uid()), false)
$$;
create or replace function public.can_post_media() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select active and (role = 'admin' or is_comms or committee_position = 'communication') from public.profiles where id = auth.uid()), false)
$$;

-- ---------- New user -> profile (the very first user becomes the admin) ----------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare first_user boolean;
begin
  select not exists (select 1 from public.profiles) into first_user;
  insert into public.profiles (id, email, full_name, role, active)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''),
          case when first_user then 'admin' else 'member' end, first_user);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Admin: approve people, set roles, positions and trainer ----------
create or replace function public.admin_set_profile(target uuid, new_role text, new_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Only an admin can do this'; end if;
  if target = auth.uid() then raise exception 'You cannot change your own access'; end if;
  if new_role not in ('admin','member') then raise exception 'Invalid role'; end if;
  update public.profiles set role = new_role, active = new_active where id = target;
end $$;

create or replace function public.admin_set_position(target uuid, new_position text, new_training boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Only an admin can do this'; end if;
  if new_position not in ('','chair','vice_chair','secretary','advocacy','communication','treasurer','coordinator') then raise exception 'Invalid committee_position'; end if;
  -- the Chair person and the Secretary general are admins as well
  update public.profiles set committee_position = new_position, is_training = new_training,
    role = case when new_position in ('chair','secretary') then 'admin' else role end
  where id = target;
end $$;

revoke all on function public.admin_set_profile(uuid, text, boolean) from public, anon;
revoke all on function public.admin_set_position(uuid, text, boolean) from public, anon;
grant execute on function public.admin_set_profile(uuid, text, boolean) to authenticated;
grant execute on function public.admin_set_position(uuid, text, boolean) to authenticated;
revoke all on function public.is_active(), public.is_admin(), public.is_leader(), public.can_manage_finance(), public.can_train(), public.can_post_media() from public, anon;
grant execute on function public.is_active(), public.is_admin(), public.is_leader(), public.can_manage_finance(), public.can_train(), public.can_post_media() to authenticated;

-- ---------- Row Level Security: who can see and change what ----------
alter table public.profiles            enable row level security;
alter table public.tasks               enable row level security;
alter table public.task_updates        enable row level security;
alter table public.meetings            enable row level security;
alter table public.minutes             enable row level security;
alter table public.meeting_rsvps       enable row level security;
alter table public.media_posts         enable row level security;
alter table public.media_confirmations enable row level security;
alter table public.weekly_goals        enable row level security;
alter table public.attachments         enable row level security;
alter table public.area_posts          enable row level security;
alter table public.training_docs       enable row level security;
alter table public.finance_entries     enable row level security;
alter table public.finance_budgets     enable row level security;
alter table public.app_settings        enable row level security;

revoke all on public.profiles, public.tasks, public.task_updates, public.meetings, public.minutes, public.meeting_rsvps,
  public.media_posts, public.media_confirmations, public.weekly_goals, public.attachments, public.area_posts,
  public.training_docs, public.finance_entries, public.finance_budgets, public.app_settings from anon;

-- profiles: approved people see everyone; everyone sees themselves.
-- People can edit only their own name, WhatsApp number and profile photo (not role, committee_position or approval).
create policy "profiles read" on public.profiles for select to authenticated using (id = auth.uid() or public.is_active());
create policy "profiles edit own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
revoke insert, update, delete on public.profiles from authenticated;
grant update (full_name, phone, avatar_path) on public.profiles to authenticated;

-- tasks: any approved member reads, creates and updates; delete by admin or creator
create policy "tasks read"   on public.tasks for select to authenticated using (public.is_active());
create policy "tasks insert" on public.tasks for insert to authenticated with check (public.is_active() and created_by = auth.uid());
create policy "tasks update" on public.tasks for update to authenticated using (public.is_active()) with check (public.is_active());
create policy "tasks delete" on public.tasks for delete to authenticated using (public.is_active() and (public.is_admin() or created_by = auth.uid()));

create policy "updates read"   on public.task_updates for select to authenticated using (public.is_active());
create policy "updates insert" on public.task_updates for insert to authenticated with check (public.is_active() and user_id = auth.uid());
create policy "updates delete" on public.task_updates for delete to authenticated using (public.is_admin());

-- meetings: leaders (chair, vice chair, secretary, admin) manage all; the trainer manages trainings
create policy "meetings read"  on public.meetings for select to authenticated using (public.is_active());
create policy "meetings write" on public.meetings for all to authenticated
  using (public.is_leader() or (kind = 'training' and public.can_train()))
  with check (public.is_leader() or (kind = 'training' and public.can_train()));

-- minutes: leaders write; everyone reads (members add attachments through the attachments table)
create policy "minutes read"  on public.minutes for select to authenticated using (public.is_active());
create policy "minutes write" on public.minutes for all to authenticated using (public.is_leader()) with check (public.is_leader());

-- replies to meetings, media confirmations, weekly goals: each person manages their own
create policy "rsvps read"   on public.meeting_rsvps for select to authenticated using (public.is_active());
create policy "rsvps insert" on public.meeting_rsvps for insert to authenticated with check (public.is_active() and user_id = auth.uid());
create policy "rsvps update" on public.meeting_rsvps for update to authenticated using (public.is_active() and user_id = auth.uid()) with check (user_id = auth.uid());
create policy "rsvps delete" on public.meeting_rsvps for delete to authenticated using (user_id = auth.uid() or public.is_admin());

create policy "confirms read"   on public.media_confirmations for select to authenticated using (public.is_active());
create policy "confirms insert" on public.media_confirmations for insert to authenticated with check (public.is_active() and user_id = auth.uid());
create policy "confirms update" on public.media_confirmations for update to authenticated using (public.is_active() and user_id = auth.uid()) with check (user_id = auth.uid());
create policy "confirms delete" on public.media_confirmations for delete to authenticated using (user_id = auth.uid() or public.is_admin());

create policy "goals read"   on public.weekly_goals for select to authenticated using (public.is_active());
create policy "goals insert" on public.weekly_goals for insert to authenticated with check (public.is_active() and user_id = auth.uid());
create policy "goals update" on public.weekly_goals for update to authenticated using (public.is_active() and user_id = auth.uid()) with check (user_id = auth.uid());
create policy "goals delete" on public.weekly_goals for delete to authenticated using (user_id = auth.uid() or public.is_admin());

-- media posts: the communication lead and admins plan posts
create policy "posts read"   on public.media_posts for select to authenticated using (public.is_active());
create policy "posts insert" on public.media_posts for insert to authenticated with check (public.can_post_media() and created_by = auth.uid());
create policy "posts update" on public.media_posts for update to authenticated using (public.can_post_media()) with check (public.can_post_media());
create policy "posts delete" on public.media_posts for delete to authenticated using (public.can_post_media());

-- attachments: every approved member can add; the uploader or an admin can remove
create policy "attach read"   on public.attachments for select to authenticated using (public.is_active());
create policy "attach insert" on public.attachments for insert to authenticated with check (public.is_active() and uploaded_by = auth.uid());
create policy "attach delete" on public.attachments for delete to authenticated using (uploaded_by = auth.uid() or public.is_admin());

-- work-area posts and training documents: every approved member can add and edit
create policy "area read"   on public.area_posts for select to authenticated using (public.is_active());
create policy "area insert" on public.area_posts for insert to authenticated with check (public.is_active() and created_by = auth.uid());
create policy "area update" on public.area_posts for update to authenticated using (public.is_active()) with check (public.is_active());
create policy "area delete" on public.area_posts for delete to authenticated using (created_by = auth.uid() or public.is_admin());

create policy "tdocs read"   on public.training_docs for select to authenticated using (public.is_active());
create policy "tdocs insert" on public.training_docs for insert to authenticated with check (public.is_active() and created_by = auth.uid());
create policy "tdocs update" on public.training_docs for update to authenticated using (public.is_active()) with check (public.is_active());
create policy "tdocs delete" on public.training_docs for delete to authenticated using (created_by = auth.uid() or public.can_train());

-- finance: every approved member can view; the treasurer and admins record
create policy "fin read"   on public.finance_entries for select to authenticated using (public.is_active());
create policy "fin write"  on public.finance_entries for all to authenticated using (public.can_manage_finance()) with check (public.can_manage_finance());
create policy "bud read"   on public.finance_budgets for select to authenticated using (public.is_active());
create policy "bud write"  on public.finance_budgets for all to authenticated using (public.can_manage_finance()) with check (public.can_manage_finance());
create policy "set read"   on public.app_settings for select to authenticated using (public.is_active());
create policy "set write"  on public.app_settings for all to authenticated using (public.can_manage_finance()) with check (public.can_manage_finance());

-- ---------- File storage (private bucket for photos, documents and videos) ----------
insert into storage.buckets (id, name, public, file_size_limit)
values ('attachments', 'attachments', false, 52428800)
on conflict (id) do nothing;

create policy "files read" on storage.objects for select to authenticated
  using (bucket_id = 'attachments' and public.is_active());
create policy "files upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'attachments' and public.is_active() and (storage.foldername(name))[1] = auth.uid()::text);
create policy "files delete" on storage.objects for delete to authenticated
  using (bucket_id = 'attachments' and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text));

-- ---------- Profile photos (public bucket 'avatars': one small square picture per person) ----------
-- Pictures are public by URL so they load instantly everywhere; each person can only add or delete inside their own folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 1048576, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 1048576, allowed_mime_types = array['image/jpeg','image/png','image/webp'];

create policy "avatars read" on storage.objects for select to authenticated
  using (bucket_id = 'avatars');
create policy "avatars upload own" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and public.is_active() and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- Live updates (everyone sees changes without refreshing) ----------
alter publication supabase_realtime add table
  public.profiles, public.tasks, public.task_updates, public.meetings, public.minutes, public.meeting_rsvps,
  public.media_posts, public.media_confirmations, public.weekly_goals, public.attachments, public.area_posts,
  public.training_docs, public.finance_entries, public.finance_budgets, public.app_settings;
