# GitHub Pages Deployment Script for Windows (PowerShell)
# Usage: .\deploy.ps1 [repository-name]

param(
    [string]$RepoName = "super-auto-pets-clone"
)

Write-Host "🚀 Starting GitHub Pages Deployment..." -ForegroundColor Green
Write-Host "Repository name: $RepoName" -ForegroundColor Cyan

# Check if Flutter is installed
Write-Host "`n📦 Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✓ Flutter found: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Clean previous build
Write-Host "`n🧹 Cleaning previous build..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "`n📥 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build web app
Write-Host "`n🔨 Building web app for GitHub Pages..." -ForegroundColor Yellow
$baseHref = "/$RepoName/"
flutter build web --base-href $baseHref --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Build successful!" -ForegroundColor Green

# Verify 404.html exists
$build404 = "build\web\404.html"
if (-not (Test-Path $build404)) {
    Write-Host "`n⚠️  404.html not found in build/web, copying from web/..." -ForegroundColor Yellow
    Copy-Item "web\404.html" -Destination $build404 -Force
}

# Check if git is initialized
Write-Host "`n📂 Checking git repository..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    Write-Host "⚠️  Git repository not initialized. Initializing..." -ForegroundColor Yellow
    git init
    git remote add origin "https://github.com/YOUR_USERNAME/$RepoName.git" 2>$null
}

# Check current branch
$currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

# Instructions for manual deployment
Write-Host "`n📋 Build configured. Your app is ready to deploy!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Create gh-pages branch: git checkout --orphan gh-pages" -ForegroundColor White
Write-Host "2. Copy build/web/* to root: Copy-Item build\web\* -Destination . -Recurse -Force" -ForegroundColor White
Write-Host "3. Commit: git add . && git commit -m 'Deploy to GitHub Pages'" -ForegroundColor White
Write-Host "4. Push: git push -u origin gh-pages" -ForegroundColor White
Write-Host "5. Configure GitHub Pages in repository Settings → Pages" -ForegroundColor White
Write-Host "`nYour app will be available at: https://YOUR_USERNAME.github.io/$RepoName/" -ForegroundColor Cyan
