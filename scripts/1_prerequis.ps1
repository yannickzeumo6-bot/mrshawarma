# =====================================================================
#  ETAPE 1 : installer les outils (Git, GitHub CLI, Java pour la signature)
#  Lancer : powershell -ExecutionPolicy Bypass -File .\scripts\1_prerequis.ps1
# =====================================================================
$ErrorActionPreference = 'Continue'
function Etape($t) { Write-Host "`n=== $t ===" -ForegroundColor Yellow }
function Ok($t)    { Write-Host "  OK  $t" -ForegroundColor Green }
function RafraichirPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}
function TrouverKeytool {
    $c = Get-Command keytool -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $dossiers = @('C:\Program Files\Eclipse Adoptium','C:\Program Files\Java','C:\Program Files\Android\Android Studio\jbr')
    foreach ($d in $dossiers) {
        if (Test-Path $d) {
            $p = Get-ChildItem $d -Recurse -Filter keytool.exe -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($p) { return $p.FullName }
        }
    }
    return $null
}

Etape 'Verification de winget'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  winget est introuvable. Mets Windows a jour ou installe 'Programme d'installation d'application' depuis le Microsoft Store." -ForegroundColor Red
    exit 1
}
Ok 'winget disponible'

function Installer($commande, $id, $nom) {
    if (Get-Command $commande -ErrorAction SilentlyContinue) { Ok "$nom est deja installe"; return }
    Write-Host "  Installation de $nom (accepte la fenetre Windows si elle apparait)..."
    winget install -e --id $id --accept-package-agreements --accept-source-agreements
    RafraichirPath
}

Etape 'Installation des outils'
Installer 'git' 'Git.Git' 'Git'
Installer 'gh'  'GitHub.cli' 'GitHub CLI'
if (TrouverKeytool) {
    Ok 'Java (keytool) est deja installe'
} else {
    Write-Host '  Installation de Java 17 (pour creer la cle de signature)...'
    winget install -e --id EclipseAdoptium.Temurin.17.JDK --accept-package-agreements --accept-source-agreements
    RafraichirPath
}

Etape 'Verification'
$manque = @()
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $manque += 'git' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue))  { $manque += 'gh' }
if (-not (TrouverKeytool)) { $manque += 'java/keytool' }
if ($manque.Count -gt 0) {
    Write-Host ("  Pas encore visible : " + ($manque -join ', ') + ". Ferme PowerShell, rouvre-le, et relance ce script.") -ForegroundColor DarkYellow
} else {
    Ok 'Tout est pret.'
}
Write-Host "`nFerme cette fenetre PowerShell, ouvre-en une nouvelle, puis lance l'ETAPE 2 :" -ForegroundColor Cyan
Write-Host '   powershell -ExecutionPolicy Bypass -File .\scripts\2_depot_github.ps1'
