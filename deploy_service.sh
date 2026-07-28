#!/bin/bash
# Systemd service file for VocalForSanatan Backend (Linux)

echo "=== Creating systemd service for VocalForSanatan Backend ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Get the deployment path from user
read -p "Enter the full path to VocalForSanatan folder (e.g., /home/username/VocalForSanatan): " DEPLOY_PATH

# Validate path
if [ ! -d "$DEPLOY_PATH/publish_be" ]; then
    echo "ERROR: publish_be folder not found at $DEPLOY_PATH/publish_be"
    exit 1
fi

# Create service file
SERVICE_FILE="/etc/systemd/system/vocalforsanatan.service"

cat > $SERVICE_FILE << EOF
[Unit]
Description=VocalForSanatan Backend API
After=network.target

[Service]
WorkingDirectory=$DEPLOY_PATH/publish_be
ExecStart=/usr/bin/dotnet $DEPLOY_PATH/publish_be/localink_be.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=UPLOADS_PATH=$DEPLOY_PATH

[Install]
WantedBy=multi-user.target
EOF

echo "Service file created at: $SERVICE_FILE"

# Reload systemd
systemctl daemon-reload

# Enable and start service
systemctl enable vocalforsanatan
systemctl start vocalforsanatan

echo ""
echo "=== Service Status ==="
systemctl status vocalforsanatan

echo ""
echo "=== Deployment Complete ==="
echo "Service name: vocalforsanatan"
echo "Working directory: $DEPLOY_PATH/publish_be"
echo "Uploads folder: $DEPLOY_PATH/Uploads"
echo ""
echo "Useful commands:"
echo "  - Check status: sudo systemctl status vocalforsanatan"
echo "  - View logs: sudo journalctl -u vocalforsanatan -f"
echo "  - Restart: sudo systemctl restart vocalforsanatan"
echo "  - Stop: sudo systemctl stop vocalforsanatan"