# Flutter Web Deployment Script for Firebase Hosting
# Run this script to build and deploy your app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Web Deployment to Firebase" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean previous build
Write-Host "Step 1: Cleaning previous build..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Clean failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Clean completed" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pub get failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 3: Build web app
Write-Host "Step 3: Building Flutter web app..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Build completed successfully" -ForegroundColor Green
Write-Host ""

# Step 4: Deploy to Firebase
Write-Host "Step 4: Deploying to Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Deployment completed successfully" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your app is now live on Firebase Hosting!" -ForegroundColor Green
Write-Host "Check the URL above to access your deployed app." -ForegroundColor Yellow
