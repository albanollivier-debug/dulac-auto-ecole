# Dulac Auto — site de l'auto-école

Site vitrine avec inscriptions en ligne et espace de gestion.

- `index.html` : le site public (formations, tarifs, parcours, financement, inscription, contact).
- `admin.html` : l'espace de gestion des inscriptions, protégé par e-mail et mot de passe.
- `supabase.sql` : la base de données et ses règles d'accès.
- `CNAME` : le nom de domaine `dulac-auto-ecole.fr`.

## 1. Supabase (base des inscriptions)

1. Créer un compte sur supabase.com, puis un projet. Région conseillée : **West EU (Paris)**.
2. **SQL Editor > New query** : coller tout `supabase.sql`, cliquer sur **Run**.
3. **Authentication > Users > Add user > Create new user** : votre e-mail et un mot de passe solide, cocher *Auto Confirm User*.
4. Dans **SQL Editor**, vous déclarer administrateur (remplacer l'e-mail) :
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'votre.email@exemple.fr';
   ```
5. **Authentication > Sign In / Providers > Email** : désactiver *Allow new users to sign up*, pour que personne d'autre ne puisse créer de compte.
6. **Project Settings > API** : copier l'**URL du projet** et la clé publique **anon** (ou *publishable*). Ne jamais utiliser la clé *service_role* dans le site.

Reporter ces deux valeurs :
- dans `index.html` : ouvrir le site avec `#edition` à la fin de l'adresse, onglet **Inscription > Réception des inscriptions**, puis **Télécharger le site** et remplacer `index.html` dans le dépôt ;
- dans `admin.html` : en haut du script, lignes `SB_URL` et `SB_KEY`.

## 2. Mettre en ligne (GitHub Pages)

**Settings > Pages > Build and deployment** : *Deploy from a branch*, branche `main`, dossier `/ (root)`.

## 3. Nom de domaine dulac-auto-ecole.fr

Chez le registraire (OVH, Gandi, IONOS…), zone DNS :

| Type  | Nom | Valeur                     |
|-------|-----|----------------------------|
| A     | @   | 185.199.108.153            |
| A     | @   | 185.199.109.153            |
| A     | @   | 185.199.110.153            |
| A     | @   | 185.199.111.153            |
| CNAME | www | `<compte-github>.github.io.` |

Puis dans **Settings > Pages** : vérifier que *Custom domain* affiche `dulac-auto-ecole.fr` et cocher **Enforce HTTPS** dès que c'est possible (quelques minutes à quelques heures).

## Modifier le site

Ouvrir `https://dulac-auto-ecole.fr/#edition`. Les changements sont gardés dans votre navigateur ; cliquer sur **Télécharger le site** puis remplacer `index.html` dans le dépôt pour les rendre visibles par tous.

## Gérer les inscriptions

Ouvrir `https://dulac-auto-ecole.fr/admin.html` (lien « Espace gestion » en bas du site), se connecter, puis changer le statut, supprimer ou exporter en CSV.
