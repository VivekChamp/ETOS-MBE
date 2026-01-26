#!/bin/bash

# ============================================
# E-Scooter Mobile App - Backend Deployment Script
# ============================================

echo "🚀 Starting Backend Deployment..."

# Server details
SERVER="root@165.232.188.221"
LOCAL_FILE="d:/Me/mbl-app/E-sccoter/backend_erp/mobile_api.py"
REMOTE_PATH="/home/etos/frappe-bench/apps/etos_mbe/etos_mbe/etos_mbe/api.py"

# Step 1: Upload file
echo "📤 Uploading mobile_api.py to server..."
scp "$LOCAL_FILE" "$SERVER:$REMOTE_PATH"

if [ $? -eq 0 ]; then
    echo "✅ File uploaded successfully!"
    
    # Step 2: Restart Frappe
    echo "🔄 Restarting Frappe..."
    ssh "$SERVER" << 'EOF'
cd /home/etos/frappe-bench
bench restart
echo "✅ Frappe restarted successfully!"
EOF
    
    echo "🎉 Deployment Complete!"
    echo ""
    echo "Next steps:"
    echo "1. Test login in mobile app"
    echo "2. Check Tasks screen - should show assigned tasks"
    echo "3. Check Projects screen - should show your projects"
    echo "4. Try assigning a task using the assign button"
    
else
    echo "❌ Upload failed! Please check your connection and try again."
    exit 1
fi
