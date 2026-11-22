# =====================================================================
#  ETAPE 2 : creer le depot GitHub, la cle de signature et les secrets
#  Lancer : powershell -ExecutionPolicy Bypass -File .\scripts\2_depot_github.ps1
# =====================================================================
param([string]$NomDepot = 'mrshawarma')
$ErrorActionPreference = 'Continue'
$racine = Split-Path -Parent $PSScriptRoot
Set-Location $racine

function Etape($t) { Write-Host "`n=== $t ===" -ForegroundColor Yellow }
function Ok($t)    { Write-Host "  OK  $t" -ForegroundColor Green }
function Echec($t) { Write-Host "`n  ERREUR : $t" -ForegroundColor Red; exit 1 }
function MdpSur($n) {
    $b = New-Object byte[] $n
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
    $chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    -join ($b | ForEach-Object { $chars[$_ % $chars.Length] })
}
function TrouverKeytool {
    $c = Get-Command keytool -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($d in @('C:\Program Files\Eclipse Adoptium','C:\Program Files\Java','C:\Program Files\Android\Android Studio\jbr')) {
        if (Test-Path $d) {
            $p = Get-ChildItem $d -Recurse -Filter keytool.exe -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($p) { return $p.FullName }
        }
    }
    return $null
}

# ---------------------------------------------------------------- 1. Verifications
Etape '1/6  Verification des outils'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Echec "git introuvable : lance d'abord l'etape 1, puis rouvre PowerShell." }
if (-not (Get-Command gh -ErrorAction SilentlyContinue))  { Echec "gh (GitHub CLI) introuvable : lance d'abord l'etape 1, puis rouvre PowerShell." }
$keytool = TrouverKeytool
if (-not $keytool) { Echec "keytool (Java) introuvable : lance d'abord l'etape 1, puis rouvre PowerShell." }
Ok 'git, gh et keytool presents'

# ---------------------------------------------------------------- 2. Connexion GitHub
Etape '2/6  Connexion a GitHub'
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Une page web va s'ouvrir : connecte-toi (ou cree un compte GitHub gratuit) et valide le code affiche."
    gh auth login --web --git-protocol https
    if ($LASTEXITCODE -ne 0) { Echec 'Connexion GitHub impossible.' }
}
$login = (gh api user --jq .login).Trim()
if (-not $login) { Echec 'Impossible de lire ton nom GitHub.' }
Ok "Connecte en tant que $login"

# ---------------------------------------------------------------- 3. Version de Flutter
Etape '3/6  Version de Flutter'
$versionFlutter = ''
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    try {
        $json = (flutter --version --machine) -join "`n"
        $versionFlutter = ($json | ConvertFrom-Json).frameworkVersion
    } catch { }
}
if ($versionFlutter) {
    [IO.File]::WriteAllText((Join-Path $racine 'app\.flutter-version'), $versionFlutter)
    Ok "Flutter $versionFlutter (les APK seront construits avec la meme version)"
} else {
    Write-Host '  Flutter introuvable ici : les APK utiliseront la derniere version stable.' -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------- 4. Cle de signature
Etape '4/6  Cle de signature Android'
$secrets = Join-Path $HOME 'mrshawarma-secrets'
New-Item -ItemType Directory -Force -Path $secrets | Out-Null
$jks = Join-Path $secrets 'mrshawarma-release.jks'
$infos = Join-Path $secrets 'signature.txt'
$alias = 'mrshawarma'
if (-not (Test-Path $jks)) {
    $mdpCle = MdpSur 24
    & $keytool -genkeypair -v -keystore $jks -storepass $mdpCle -keypass $mdpCle -alias $alias `
        -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Mr Shawarma, O=Mr Shawarma, L=Douala, C=CM' 2>&1 | Out-Null
    if (-not (Test-Path $jks)) { Echec 'La creation de la cle de signature a echoue.' }
    "Fichier : $jks`r`nAlias : $alias`r`nMot de passe : $mdpCle`r`n" | Out-File -Encoding ascii $infos
    Ok "Cle creee : $jks"
    Write-Host "  IMPORTANT : sauvegarde le dossier $secrets (cle USB / mail a toi-meme)." -ForegroundColor Red
    Write-Host '  Sans ce fichier, tu ne pourras plus publier de mises a jour de l''application.' -ForegroundColor Red
} else {
    Ok "Cle deja presente : $jks"
    $mdpCle = ((Get-Content $infos | Where-Object { $_ -like 'Mot de passe :*' }) -replace 'Mot de passe :\s*','').Trim()
    if (-not $mdpCle) { Echec "Mot de passe introuvable dans $infos" }
}

# ---------------------------------------------------------------- 5. Depot GitHub
Etape '5/6  Depot GitHub'
if (-not (Test-Path (Join-Path $racine '.git'))) { git init -b main | Out-Null }
git config user.name  $login
git config user.email "$login@users.noreply.github.com"
git add -A
git commit -m 'Mr. Shawarma' 2>&1 | Out-Null
gh repo view "$login/$NomDepot" *> $null
if ($LASTEXITCODE -ne 0) {
    gh repo create $NomDepot --public --source . --remote origin --push
    if ($LASTEXITCODE -ne 0) { Echec 'Creation du depot GitHub impossible.' }
} else {
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$login/$NomDepot.git"
    git push -u origin main
}
Ok "Depot : https://github.com/$login/$NomDepot"

# Secrets GitHub (utilises par la construction des APK)
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($jks))
gh secret set KEYSTORE_B64      --repo "$login/$NomDepot" --body $b64
gh secret set KEYSTORE_PASSWORD --repo "$login/$NomDepot" --body $mdpCle
gh secret set KEY_ALIAS         --repo "$login/$NomDepot" --body $alias
Ok 'Secrets de signature enregistres dans GitHub'

# ---------------------------------------------------------------- 6. Valeurs pour Render
Etape '6/6  Valeurs pour le serveur (Render)'
$kb = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($kb)
$appKey   = 'base64:' + [Convert]::ToBase64String($kb)
$mdpAdmin = MdpSur 14
$mdpLiv   = MdpSur 14
$apkBase  = "https://github.com/$login/$NomDepot/releases/latest/download"
$fichier  = Join-Path $secrets 'valeurs-render.txt'
@"
APP_KEY=$appKey
SEED_ADMIN_PASSWORD=$mdpAdmin
SEED_LIVREUR_PASSWORD=$mdpLiv
APK_BASE_URL=$apkBase
DB_URL=(la chaine de connexion Neon : voir le guide)
APP_URL=(l'adresse https que Render te donnera)
"@ | Out-File -Encoding ascii $fichier

Write-Host ''
Write-Host '================ A COPIER DANS RENDER (etape suivante du guide) ================' -ForegroundColor Green
Write-Host " APP_KEY               = $appKey"
Write-Host " SEED_ADMIN_PASSWORD   = $mdpAdmin     (mot de passe de admin@mrshawarma.cm)"
Write-Host " SEED_LIVREUR_PASSWORD = $mdpLiv     (mot de passe de livreur@mrshawarma.cm)"
Write-Host " APK_BASE_URL          = $apkBase"
Write-Host '================================================================================' -ForegroundColor Green
Write-Host " Tout est aussi enregistre dans : $fichier"
Write-Host ''
Write-Host 'Suite : cree la base Neon puis le serveur Render (voir GUIDE_PUBLICATION.md, parties 3 et 4).' -ForegroundColor Cyan
