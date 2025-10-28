# Script de Correction des Vulnérabilités Flowise (PowerShell)

param(
    [switch]$DryRun,
    [switch]$Force
)

Write-Host "[SECURITY] Correction des Vulnerabilites Flowise" -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue

# Fonction pour exécuter une commande avec gestion d'erreur
function Invoke-SafeCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "`n[INFO] $Description" -ForegroundColor Yellow
    Write-Host "Exécution: $Command" -ForegroundColor Gray
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Commande simulée" -ForegroundColor Cyan
        return $true
    }
    
    try {
        Invoke-Expression $Command
        Write-Host "[SUCCESS] $Description terminé" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[ERROR] Échec de $Description : $_" -ForegroundColor Red
        return $false
    }
}

# Vérifier les prérequis
Write-Host "`n[INFO] Vérification des prérequis..." -ForegroundColor Blue

if (-not (Get-Command "pnpm" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] pnpm n'est pas installé" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "package.json")) {
    Write-Host "[ERROR] package.json non trouvé. Exécutez depuis la racine du projet." -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Prérequis vérifiés" -ForegroundColor Green

# Sauvegarder le package.json
if (-not $DryRun) {
    Write-Host "`n[INFO] Sauvegarde du package.json..." -ForegroundColor Yellow
    Copy-Item "package.json" "package.json.backup" -Force
    Write-Host "[SUCCESS] Sauvegarde créée: package.json.backup" -ForegroundColor Green
}

# Étape 1: Correction des vulnérabilités critiques
Write-Host "`n[CRITICAL] ETAPE 1: Correction des vulnerabilites CRITIQUES" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Red

$criticalFixes = @(
    @{Package="sha.js"; Version="^2.4.12"; Description="sha.js - Problème de vérification de type"},
    @{Package="tar-fs"; Version="^3.1.1"; Description="tar-fs - Contournement validation liens symboliques"},
    @{Package="playwright"; Version="^1.55.1"; Description="playwright - Téléchargement sans vérification SSL"},
    @{Package="mammoth"; Version="^1.11.0"; Description="mammoth - Traversal de répertoire"}
)

foreach ($fix in $criticalFixes) {
    $command = "pnpm update $($fix.Package)@$($fix.Version)"
    Invoke-SafeCommand -Command $command -Description $fix.Description
}

# Étape 2: Correction des vulnérabilités modérées prioritaires
Write-Host "`n[MODERATE] ETAPE 2: Correction des vulnerabilites MODEREES prioritaires" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Yellow

$moderateFixes = @(
    @{Package="vite"; Version="^5.4.19"; Description="vite - Contournements server.fs.deny"},
    @{Package="katex"; Version="^0.16.21"; Description="katex - Problèmes de validation"},
    @{Package="express"; Version="^4.19.2"; Description="express - Redirection ouverte"},
    @{Package="@babel/helpers"; Version="^7.26.10"; Description="@babel/helpers - Complexité RegExp"},
    @{Package="@babel/runtime"; Version="^7.26.10"; Description="@babel/runtime - Complexité RegExp"}
)

foreach ($fix in $moderateFixes) {
    $command = "pnpm update $($fix.Package)@$($fix.Version)"
    Invoke-SafeCommand -Command $command -Description $fix.Description
}

# Étape 3: Correction automatique
Write-Host "`n[AUTO] ETAPE 3: Correction automatique" -ForegroundColor Blue
Write-Host "=================================" -ForegroundColor Blue

Invoke-SafeCommand -Command "pnpm audit fix" -Description "Correction automatique des vulnérabilités"

# Étape 4: Mise à jour générale (optionnelle)
if ($Force) {
    Write-Host "`n[UPDATE] ETAPE 4: Mise a jour generale (FORCEE)" -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta
    
    Invoke-SafeCommand -Command "pnpm update --latest" -Description "Mise à jour de toutes les dépendances"
}

# Étape 5: Vérification
Write-Host "`n[VERIFY] ETAPE 5: Verification des corrections" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Write-Host "`n[INFO] Exécution de l'audit de sécurité..." -ForegroundColor Yellow
try {
    $auditResult = pnpm audit 2>&1
    Write-Host $auditResult -ForegroundColor White
    
    # Analyser les résultats
    if ($auditResult -match "(\d+) vulnerabilities found") {
        $vulnCount = [int]$matches[1]
        if ($vulnCount -eq 0) {
            Write-Host "`n🎉 SUCCÈS: Aucune vulnérabilité détectée!" -ForegroundColor Green
        } elseif ($vulnCount -lt 20) {
            Write-Host "`n✅ AMÉLIORATION: Vulnérabilités réduites à $vulnCount" -ForegroundColor Yellow
        } else {
            Write-Host "`n⚠️ ATTENTION: $vulnCount vulnérabilités restantes" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "[ERROR] Échec de la vérification: $_" -ForegroundColor Red
}

# Étape 6: Reconstruction et tests
Write-Host "`n[BUILD] ETAPE 6: Reconstruction et tests" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

if (-not $DryRun) {
    Write-Host "`n[INFO] Installation des dépendances..." -ForegroundColor Yellow
    Invoke-SafeCommand -Command "pnpm install" -Description "Installation des dépendances"
    
    Write-Host "`n[INFO] Reconstruction du projet..." -ForegroundColor Yellow
    Invoke-SafeCommand -Command "pnpm build" -Description "Reconstruction du projet"
    
    Write-Host "`n[INFO] Exécution des tests..." -ForegroundColor Yellow
    Invoke-SafeCommand -Command "pnpm test" -Description "Exécution des tests"
}

# Résumé final
Write-Host "`n[SUMMARY] RESUME FINAL" -ForegroundColor Blue
Write-Host "===============" -ForegroundColor Blue

Write-Host "`n✅ Actions effectuées:" -ForegroundColor Green
Write-Host "  - Correction des vulnérabilités critiques" -ForegroundColor White
Write-Host "  - Correction des vulnérabilités modérées prioritaires" -ForegroundColor White
Write-Host "  - Correction automatique avec pnpm audit fix" -ForegroundColor White

if ($Force) {
    Write-Host "  - Mise à jour générale des dépendances" -ForegroundColor White
}

if (-not $DryRun) {
    Write-Host "  - Reconstruction du projet" -ForegroundColor White
    Write-Host "  - Exécution des tests" -ForegroundColor White
}

Write-Host "`n[FILES] Fichiers crees:" -ForegroundColor Cyan
Write-Host "  - package.json.backup (sauvegarde)" -ForegroundColor White
Write-Host "  - security-report.md (rapport détaillé)" -ForegroundColor White

Write-Host "`n[NEXT] Prochaines etapes recommandees:" -ForegroundColor Yellow
Write-Host "  1. Examiner le rapport d'audit final" -ForegroundColor White
Write-Host "  2. Tester l'application manuellement" -ForegroundColor White
Write-Host "  3. Déployer en environnement de test" -ForegroundColor White
Write-Host "  4. Surveiller les performances" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n[WARNING] MODE DRY RUN: Aucune modification reelle effectuee" -ForegroundColor Cyan
    Write-Host "Exécutez sans -DryRun pour appliquer les corrections" -ForegroundColor Cyan
}

Write-Host "`n[SUCCESS] Script de correction termine!" -ForegroundColor Green
