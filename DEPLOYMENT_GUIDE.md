# VocalForSanatan Backend Deployment Guide

## Overview
This guide will help you deploy the VocalForSanatan backend to your server.

## Prerequisites
- .NET 8.0 Runtime installed on the server
- SQL Server database accessible
- Server access via SSH

## Directory Structure
```
VocalForSanatan/
├── publish_be/          # Backend application (deployed from local publish_be folder)
├── Uploads/             # User uploaded files (images, documents, etc.)
└── .env                 # Environment configuration (optional, can use appsettings.json)
```

## Deployment Steps

### Step 1: Prepare Local Files
The following files are ready for deployment:
- `localink_be/publish_be/` - Published backend application
- `localink_be/.env` - Environment variables (configure with your production values)
- `deploy_to_server.ps1` - Deployment script
- `deploy_service.sh` - Linux service setup script

### Step 2: Configure Environment Variables

Edit `localink_be/.env` with your production values:

```env
# Database
DB_CONNECTION_STRING=Server=your_server;Database=localink_db;User Id=your_user;Password=your_password;

# JWT Authentication
JWT_SECRET_KEY=your_very_long_and_secure_secret_key_here_at_least_32_chars
JWT_ISSUER=VocalForSanatan
JWT_AUDIENCE=VocalForSanatanUsers
JWT_EXPIRY_MINUTES=60

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
EMAIL_FROM=noreply@vocalforsanatan.com
EMAIL_APP_NAME=VocalForSanatan

# API Keys
CAPTCHA_SECRET_KEY=your_captcha_secret
COUNTRY_CSC_API_KEY=your_country_api_key
GEOAPIFY_API_KEY=your_geoapify_api_key
GROQ_API_KEY=your_groq_ai_api_key
CURRENCY_CONVERTER_API_KEY=your_currency_api_key

# Admin Configuration
ADMIN_EMAIL=admin@vocalforsanatan.com

# Uploads Path (optional, defaults to wwwroot/uploads)
UPLOADS_PATH=/path/to/VocalForSanatan
```

### Step 3: Deploy to Server

#### Option A: Using PowerShell Script (Windows/Linux with PowerShell Core)

```powershell
.\deploy_to_server.ps1 -ServerIP "your-server-ip" -Username "your-username" -RemotePath "/home/username/VocalForSanatan"
```

#### Option B: Manual Upload (Any Server)

1. Connect to your server via SSH/FTP
2. Create the directory structure:
   ```bash
   mkdir -p VocalForSanatan/Uploads
   ```
3. Upload the `publish_be` folder contents to `VocalForSanatan/publish_be`
4. Upload the `.env` file to `VocalForSanatan/.env`
5. Set proper permissions:
   ```bash
   chmod 755 VocalForSanatan/Uploads
   ```

### Step 4: Configure as a Service

#### For Linux (using systemd):

```bash
# Make the script executable
chmod +x deploy_service.sh

# Run the script with sudo
sudo ./deploy_service.sh
```

The script will:
1. Create a systemd service file at `/etc/systemd/system/vocalforsanatan.service`
2. Configure the service to run on boot
3. Start the backend service
4. Set the UPLOADS_PATH environment variable

#### For Windows (using IIS or Windows Service):

**Option 1: Using IIS**
1. Install IIS and ASP.NET Core Hosting Bundle
2. Create a new website in IIS pointing to the `publish_be` folder
3. Configure the application pool to use No Managed Code
4. Set environment variables in IIS or web.config

**Option 2: Using Windows Service (NSSM)**
1. Download NSSM (Non-Sucking Service Manager)
2. Install the service:
   ```cmd
   nssm install VocalForSanatan "C:\Program Files\dotnet\dotnet.exe" "C:\path\to\VocalForSanatan\publish_be\localink_be.dll"
   nssm set VocalForSanatan AppDirectory "C:\path\to\VocalForSanatan\publish_be"
   nssm set VocalForSanatan Environment UPLOADS_PATH=C:\path\to\VocalForSanatan
   nssm start VocalForSanatan
   ```

### Step 5: Verify Deployment

1. Check if the service is running:
   ```bash
   # Linux
   sudo systemctl status vocalforsanatan
   
   # Windows
   nssm status VocalForSanatan
   ```

2. Test the API endpoint:
   ```bash
   curl http://your-server-ip:5000/
   # Should return: "Vocal For Sanatan API is running"
   ```

3. Check logs for errors:
   ```bash
   # Linux
   sudo journalctl -u vocalforsanatan -f
   
   # Windows
   # Check Windows Event Viewer or NSSM logs
   ```

### Step 6: Configure Firewall

Ensure port 5000 (or your configured port) is open:

```bash
# Linux (ufw)
sudo ufw allow 5000/tcp

# Linux (firewalld)
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

# Windows
netsh advfirewall firewall add rule name="VocalForSanatan" dir=in action=allow protocol=TCP localport=5000
```

## Important Notes

1. **Uploads Folder**: The `Uploads` folder is where user-uploaded files (business images, profile pictures, etc.) will be stored. Ensure it has write permissions.

2. **Database**: Make sure your database is migrated and seeded with initial data (admin user, etc.).

3. **Environment Variables**: The application reads configuration from:
   - `appsettings.json` (in publish_be folder)
   - `.env` file (if present)
   - Environment variables

4. **HTTPS**: For production, configure HTTPS using a reverse proxy (Nginx/Apache on Linux, IIS on Windows) or configure Kestrel to use HTTPS.

5. **Process Management**: The systemd service (Linux) or NSSM (Windows) will automatically restart the application if it crashes.

## Troubleshooting

### Application won't start:
- Check logs: `sudo journalctl -u vocalforsanatan -f`
- Verify .NET runtime: `dotnet --version`
- Check database connection
- Verify all environment variables are set

### Uploads not working:
- Check Uploads folder permissions: `ls -la VocalForSanatan/Uploads`
- Verify UPLOADS_PATH environment variable
- Check disk space

### Port already in use:
- Change the port in `appsettings.json` or set `ASPNETCORE_URLS` environment variable

## Maintenance

### Update the application:
1. Build new version: `dotnet publish -c Release -o publish_be`
2. Stop the service: `sudo systemctl stop vocalforsanatan`
3. Upload new files to server
4. Start the service: `sudo systemctl start vocalforsanatan`

### Backup:
- Backup the `Uploads` folder regularly
- Backup the database
- Backup the `.env` file (contains sensitive credentials)

## Support

For issues or questions, refer to the project documentation or contact the development team.