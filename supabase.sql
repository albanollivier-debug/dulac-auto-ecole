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

-- Seuls les administrateurs lisent, modifient et suppriment.
drop policy if exists "admin lecture" on public.inscriptions;
create policy "admin lecture" on public.inscriptions
  for select to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

drop policy if exists "admin modification" on public.inscriptions;
create policy "admin modification" on public.inscriptions
  for update to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

drop policy if exists "admin suppression" on public.inscriptions;
create policy "admin suppression" on public.inscriptions
  for delete to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

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
