-- Dulac Auto : base des inscriptions
-- À coller dans Supabase > SQL Editor > New query, puis cliquer sur Run.

-- 1. Table des inscriptions envoyées depuis le site
create table if not exists public.inscriptions (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  prenom      text not null check (char_length(prenom) between 1 and 80),
  nom         text not null check (char_length(nom) between 1 and 80),
  naissance   date not null,
  tel         text not null check (char_length(tel) between 6 and 30),
  email       text not null check (char_length(email) between 5 and 160),
  formule_id  text check (char_length(formule_id) <= 60),
  formule     text not null check (char_length(formule) <= 120),
  prix        text check (char_length(prix) <= 40),
  code        text check (char_length(code) <= 20),
  financement text[] not null default '{}',
  message     text check (char_length(message) <= 2000),
  statut      text not null default 'nouvelle'
              check (statut in ('nouvelle', 'rappelée', 'inscrite', 'annulée'))
);

-- 2. Liste des comptes administrateurs
create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.inscriptions enable row level security;
alter table public.admins       enable row level security;

-- 3. Règles d'accès
-- Les visiteurs peuvent seulement ENVOYER une inscription (jamais la lire).
drop policy if exists "envoi public" on public.inscriptions;
create policy "envoi public" on public.inscriptions
  for insert to anon, authenticated
  with check (statut = 'nouvelle');

-- Contrôle admin rangé dans un schéma privé (non exposé par l'API).
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.admins a where a.user_id = (select auth.uid())); $$;
revoke all on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated;

-- Seuls les administrateurs lisent, modifient et suppriment.
drop policy if exists "admin lecture" on public.inscriptions;
create policy "admin lecture" on public.inscriptions
  for select to authenticated
  using ((select private.is_admin()));

drop policy if exists "admin modification" on public.inscriptions;
create policy "admin modification" on public.inscriptions
  for update to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

drop policy if exists "admin suppression" on public.inscriptions;
create policy "admin suppression" on public.inscriptions
  for delete to authenticated
  using ((select private.is_admin()));

-- Droits : les visiteurs peuvent seulement envoyer.
grant insert on public.inscriptions to anon;
revoke select, update, delete on public.inscriptions from anon;
revoke all on public.admins from anon;

-- Un admin peut vérifier qu'il est bien admin.
drop policy if exists "admin se voit" on public.admins;
create policy "admin se voit" on public.admins
  for select to authenticated
  using (user_id = auth.uid());

-- 4. Te déclarer administrateur
-- D'abord : Authentication > Users > Add user > Create new user
-- (ton e-mail + un mot de passe solide, cocher "Auto Confirm User").
-- Ensuite remplace l'adresse ci-dessous par la tienne et exécute ces lignes :
--
-- insert into public.admins (user_id)
-- select id from auth.users where email = 'ton.email@exemple.fr';

-- 5. Contenu du site modifiable depuis l'espace gestion
alter table public.inscriptions add column if not exists extra jsonb not null default '{}'::jsonb;
alter table public.inscriptions drop constraint if exists inscriptions_extra_taille;
alter table public.inscriptions add constraint inscriptions_extra_taille check (pg_column_size(extra) <= 8000);
alter table public.inscriptions drop constraint if exists inscriptions_code_check;
alter table public.inscriptions add constraint inscriptions_code_check check (char_length(code) <= 80);

create table if not exists public.site_config (
  id         smallint primary key default 1 check (id = 1),
  data       jsonb not null check (pg_column_size(data) < 3000000),
  updated_at timestamptz not null default now(),
  updated_by uuid
);
alter table public.site_config enable row level security;
create or replace function private.touch_site_config()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at := now(); new.updated_by := auth.uid(); return new; end $$;
revoke all on function private.touch_site_config() from public, anon;
drop trigger if exists site_config_touch on public.site_config;
create trigger site_config_touch before insert or update on public.site_config
  for each row execute function private.touch_site_config();
drop policy if exists "lecture publique" on public.site_config;
create policy "lecture publique" on public.site_config for select to anon, authenticated using (true);
drop policy if exists "admin publie" on public.site_config;
create policy "admin publie" on public.site_config for insert to authenticated with check ((select private.is_admin()));
drop policy if exists "admin met a jour" on public.site_config;
create policy "admin met a jour" on public.site_config for update to authenticated
  using ((select private.is_admin())) with check ((select private.is_admin()));
grant select on public.site_config to anon, authenticated;
grant insert, update on public.site_config to authenticated;
revoke insert, update, delete on public.site_config from anon;
