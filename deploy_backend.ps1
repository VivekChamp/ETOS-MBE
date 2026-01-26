# ============================================
# E-Scooter Mobile App - Backend Deployment (PowerShell)
# ============================================

Write-Host "🚀 Starting Backend Deployment..." -ForegroundColor Cyan

# Server details
$SERVER = "root@165.232.188.221"
$LOCAL_FILE = "d:\Me\mbl-app\E-sccoter\backend_erp\mobile_api.py"
$REMOTE_PATH = "/home/etos/frappe-bench/apps/etos_mbe/etos_mbe/etos_mbe/api.py"

# Step 1: Upload file
Write-Host "📤 Uploading mobile_api.py to server..." -ForegroundColor Yellow
scp $LOCAL_FILE "${SERVER}:${REMOTE_PATH}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ File uploaded successfully!" -ForegroundColor Green
    
    # Step 2: Restart Frappe
    Write-Host "🔄 Restarting Frappe..." -ForegroundColor Yellow
    
    $commands = @"
cd /home/etos/frappe-bench
bench restart
echo 'Frappe restarted successfully!'
"@
    
    ssh $SERVER $commands
    
    Write-Host ""
    Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Test login in mobile app"
    Write-Host "2. Check Tasks screen - should show assigned tasks"
    Write-Host "3. Check Projects screen - should show your projects"
    Write-Host "4. Try assigning a task using the assign button"
    
} else {
    Write-Host "❌ Upload failed! Please check your connection and try again." -ForegroundColor Red
    exit 1
}
