# Publier Mr. Shawarma gratuitement (serveur + 3 applications téléchargeables)

Ce que tu vas obtenir :
- un **serveur en ligne** (gratuit) : https://ton-serveur.onrender.com
- une **page de téléchargement** pour les clients (`/`) et une pour l'équipe (`/equipe`)
- **3 fichiers APK** : client, livreur, administrateur (icône = ton logo, écran de démarrage animé)

Services gratuits utilisés (vérifiés en novembre 2026) :
| Rôle | Service | Gratuit comment |
|---|---|---|
| Serveur | **Render** | sans carte bancaire ; 750 h/mois ; s'endort après 15 min sans visite |
| Base de données | **Neon** (PostgreSQL) | sans carte bancaire ; 1 Go ; pas d'expiration |
| Construction des APK + liens | **GitHub** (Actions + Releases) | gratuit pour un dépôt public |
| Garder le serveur éveillé | **UptimeRobot** | gratuit (visite toutes les 5 min) |

> Pourquoi pas la base de données de Render ? Sa base gratuite est supprimée au bout de 30 jours. Neon n'expire pas.

---

## Partie 1 — Sur ton PC (PowerShell)
Ouvre PowerShell dans le dossier du dépôt (celui qui contient ce guide) :

```powershell
cd $HOME\Downloads\mrshawarma-deploy\mrshawarma      # adapte le chemin
powershell -ExecutionPolicy Bypass -File .\scripts\1_prerequis.ps1
```
Puis **ferme et rouvre PowerShell** (pour que les nouveaux outils soient reconnus) et lance :
```powershell
cd $HOME\Downloads\mrshawarma-deploy\mrshawarma
powershell -ExecutionPolicy Bypass -File .\scripts\2_depot_github.ps1
```
Le script : te connecte à GitHub (page web), crée la clé de signature des applications, publie le code, et **affiche les valeurs à copier dans Render** (APP_KEY, mots de passe admin/livreur, APK_BASE_URL).
**Sauvegarde le dossier `C:\Users\<toi>\mrshawarma-secrets`** (clé USB, mail à toi-même) : sans la clé, plus de mises à jour possibles.

## Partie 2 — La base de données (Neon), dans le navigateur
1. Va sur **neon.com**, crée un compte (sans carte), crée un projet (région la plus proche, ex. Europe).
2. Sur le tableau de bord du projet, clique **Connect**. **Décoche « Connection pooling »** (on veut la connexion directe).
3. Copie la chaîne qui commence par `postgresql://...`. Si elle se termine par `&channel_binding=require`, **supprime cette partie** (garde `?sslmode=require`).
   → c'est ta valeur **DB_URL**.

## Partie 3 — Le serveur (Render), dans le navigateur
1. Va sur **render.com**, connecte-toi avec ton compte GitHub (sans carte).
2. **New + → Blueprint**, choisis ton dépôt `mrshawarma`, puis **Apply**.
3. Render te demande les valeurs secrètes. Colle :
   | Variable | Valeur |
   |---|---|
   | APP_KEY | celle affichée par le script 2 |
   | SEED_ADMIN_PASSWORD | idem |
   | SEED_LIVREUR_PASSWORD | idem |
   | APK_BASE_URL | idem |
   | DB_URL | la chaîne Neon (partie 2) |
   | APP_URL | mets `https://mrshawarma.onrender.com` pour l'instant (tu corrigeras juste après) |
4. Attends la fin du déploiement (5 à 10 min la première fois). Render affiche l'adresse de ton service, par exemple `https://mrshawarma-x1y2.onrender.com`.
5. **Si cette adresse n'est pas celle que tu as mise dans APP_URL** : Render → ton service → *Environment* → corrige **APP_URL** avec l'adresse exacte (sans `/` final) → *Save* (le serveur redémarre).
6. Teste dans le navigateur : `https://ton-adresse/up` doit répondre OK, et `https://ton-adresse/api/products` doit afficher le menu.

## Partie 4 — Construire les 3 APK (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\3_apks.ps1 -ApiUrl https://ton-adresse.onrender.com
```
Compte 10 à 20 minutes (la construction se fait chez GitHub, pas sur ton PC). À la fin, le script affiche :
- la page à partager aux **clients** : `https://ton-adresse/`
- la page pour l'**équipe** : `https://ton-adresse/equipe` (livreur + admin)
- les liens directs des 3 APK.

## Partie 5 — Garder le serveur éveillé (recommandé)
Sans cela, la première personne qui ouvre l'app après 15 minutes d'inactivité attend environ 1 minute.
1. Compte gratuit sur **uptimerobot.com** → *Add New Monitor* → type HTTP(s).
2. URL : `https://ton-adresse/up` — intervalle : 5 minutes.

---

## Mettre à jour plus tard
- **Changer l'application** : modifie les fichiers, puis `git add -A; git commit -m "maj"; git push`, puis relance le script 3. Les utilisateurs réinstallent le nouvel APK par-dessus l'ancien (même clé de signature = mise à jour sans perdre le compte).
- **Changer le serveur** : `git push` suffit, Render redéploie tout seul.

## Mot de passe oublié (admin ou livreur)
Dans Render → ton service → *Environment* : mets `RESET_STAFF_PASSWORDS` = `true` et le nouveau mot de passe dans `SEED_ADMIN_PASSWORD` (ou `SEED_LIVREUR_PASSWORD`), enregistre : au redémarrage le mot de passe est remplacé. **Remets ensuite `RESET_STAFF_PASSWORDS` à `false`.**

## Bon à savoir
- **Mots de passe** : `admin@mrshawarma.cm` et `livreur@mrshawarma.cm` avec les mots de passe du script 2. Change-les si tu les as montrés à quelqu'un.
- **Lien `/equipe`** : ne le diffuse pas aux clients. Les applications livreur/admin demandent de toute façon un compte du personnel.
- **Avertissement Android** : l'application n'est pas sur le Play Store, donc Android affiche « installer quand même » : c'est normal (la page de téléchargement l'explique).
- **Le code est public** sur GitHub (il ne contient aucun secret : les clés et mots de passe sont dans Render et dans les secrets GitHub).
- **Notifications quand l'application est fermée** : à activer plus tard avec Firebase (ajoute un secret GitHub `GOOGLE_SERVICES_JSON` et, dans Render, `PUSH_ENABLED=true` + les identifiants Firebase : voir `backend/README`/ton ancien guide). Sans Firebase, les notifications fonctionnent quand l'application est ouverte.
- **Limites du gratuit** : serveur qui s'endort sans UptimeRobot, 1 Go de base de données (les photos y sont stockées, redimensionnées automatiquement par l'application), pas de sauvegarde automatique de la base. Pour un vrai lancement commercial, prévoir un petit abonnement (Render ~7 $/mois) pour un serveur toujours éveillé.
- **iPhone** : non pris en charge par ces APK (Android uniquement).
