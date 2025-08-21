-- Create exhibition_favorites table
create table public.exhibition_favorites (
  id uuid not null default extensions.uuid_generate_v4 (),
  user_id uuid not null,
  exhibition_id uuid not null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint exhibition_favorites_pkey primary key (id),
  constraint unique_user_exhibition_favorite unique (user_id, exhibition_id),
  constraint exhibition_favorites_exhibition_id_fkey foreign KEY (exhibition_id) references exhibitions (id) on delete CASCADE,
  constraint exhibition_favorites_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

-- Create indexes for better performance
create index IF not exists idx_exhibition_favorites_user_id on public.exhibition_favorites using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_exhibition_favorites_exhibition_id on public.exhibition_favorites using btree (exhibition_id) TABLESPACE pg_default;

-- Enable RLS (Row Level Security)
alter table public.exhibition_favorites enable row level security;

-- Create RLS policies
create policy "Users can view their own exhibition favorites"
  on public.exhibition_favorites
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own exhibition favorites"
  on public.exhibition_favorites
  for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own exhibition favorites"
  on public.exhibition_favorites
  for delete
  using (auth.uid() = user_id);
