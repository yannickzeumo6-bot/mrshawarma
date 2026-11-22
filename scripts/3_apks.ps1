# =====================================================================
#  ETAPE 3 : construire les 3 APK et obtenir les liens de telechargement
#  Lancer : powershell -ExecutionPolicy Bypass -File .\scripts\3_apks.ps1 -ApiUrl https://ton-serveur.onrender.com
# =====================================================================
param(
    [Parameter(Mandatory = $true)][string]$ApiUrl,
    [string]$NomDepot = 'mrshawarma'
)
$ErrorActionPreference = 'Continue'
$racine = Split-Path -Parent $PSScriptRoot
Set-Location $racine
function Etape($t) { Write-Host "`n=== $t ===" -ForegroundColor Yellow }
function Echec($t) { Write-Host "`n  ERREUR : $t" -ForegroundColor Red; exit 1 }

$ApiUrl = $ApiUrl.Trim().TrimEnd('/')
if ($ApiUrl -notmatch '^https://') { Echec "L'adresse doit commencer par https:// (exemple : https://mrshawarma.onrender.com)" }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Echec 'gh introuvable : rouvre PowerShell apres l''etape 1.' }
$login = (gh api user --jq .login).Trim()
$depot = "$login/$NomDepot"

Etape '1/3  Adresse du serveur'
gh variable set API_BASE --repo $depot --body $ApiUrl
if ($LASTEXITCODE -ne 0) { Echec 'Impossible d''enregistrer API_BASE.' }
Write-Host "  OK  Les applications parleront a : $ApiUrl" -ForegroundColor Green

Etape '2/3  Construction des APK dans le cloud GitHub (10 a 20 minutes, gratuit)'
gh workflow run build-apks.yml --repo $depot
if ($LASTEXITCODE -ne 0) { Echec 'Impossible de lancer la construction.' }
Start-Sleep -Seconds 10
$id = (gh run list --repo $depot --workflow build-apks.yml --limit 1 --json databaseId --jq '.[0].databaseId').Trim()
Write-Host "  Suivi en direct (Ctrl+C pour quitter le suivi sans arreter la construction) : run $id"
gh run watch $id --repo $depot --exit-status
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n  La construction a echoue. Affiche le detail avec :" -ForegroundColor Red
    Write-Host "     gh run view $id --repo $depot --log-failed"
    exit 1
}

Etape '3/3  Liens de telechargement'
$base = "https://github.com/$depot/releases/latest/download"
Write-Host ''
Write-Host '================ TERMINE ================' -ForegroundColor Green
Write-Host " Page a partager aux CLIENTS : $ApiUrl/"
Write-Host " Page a donner a l'EQUIPE    : $ApiUrl/equipe"
Write-Host ''
Write-Host ' Liens directs :'
Write-Host "   Client  : $base/mr-shawarma-client.apk"
Write-Host "   Livreur : $base/mr-shawarma-livreur.apk"
Write-Host "   Admin   : $base/mr-shawarma-admin.apk"
Write-Host '=========================================' -ForegroundColor Green
Write-Host ''
Write-Host "N'oublie pas : dans Render, la variable APK_BASE_URL doit valoir  $base" -ForegroundColor Cyan
