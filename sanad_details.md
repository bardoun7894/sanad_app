# Sanad Therapy — Deployment Plan

## Project Overview
- **Project**: Sanad Admin Dashboard (Laravel + Vite + Tailwind)
- **Client**: Mohanned Rahma
- **Domain**: sanadtherapy.com (registered on Hostinger)
- **Local Port**: 8080 (Docker container `sanad-admin`)

## Server Details
- **Provider**: Contabo Cloud VPS 20 SSD
- **Location**: Hub Europe
- **IP**: 161.97.182.255
- **Customer ID**: 14795263
- **Order ID**: 14801833
- **OS**: Ubuntu
- **SSH**: `ssh root@161.97.182.255`
- **VPS Password**: 0919293262

## Account Credentials
- **Email**: mohannedrahma@gmail.com
- **Contabo/Hostinger Password**: `0919293262@#$&%MoH@#$&%`

## Current Status
- [x] Domain purchased (sanadtherapy.com on Hostinger)
- [x] VPS purchased (Contabo, €7.35/mo)
- [x] VPS provisioned and credentials received
- [x] SSH into VPS and setup environment
- [x] Install Docker & Docker Compose on VPS
- [x] Deploy Flutter web app to /var/www/sanad-web
- [x] Deploy admin dashboard (Docker container on port 8080)
- [x] Configure .env for production
- [x] Setup Nginx reverse proxy (/ = Flutter web, /admin = Laravel dashboard)
- [x] Setup Firebase credentials on server
- [x] Configure firewall (UFW: 22, 80, 443)
- [ ] Point domain DNS (Hostinger) to VPS IP (161.97.182.255)
- [ ] Setup SSL (Let's Encrypt) - needs DNS first
- [x] Deploy and verify (accessible via IP: http://161.97.182.255)

## Deployment Steps

### 1. SSH & Initial Server Setup
```bash
ssh root@161.97.182.255
apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2 nginx certbot python3-certbot-nginx git
systemctl enable docker
```

### 2. Clone & Deploy App
```bash
mkdir -p /var/www
cd /var/www
# Clone or copy sanad-admin project
# Copy .env and firebase-credentials.json
docker compose up -d --build
```

### 3. Nginx Config
```nginx
server {
    server_name sanadtherapy.com www.sanadtherapy.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 4. SSL
```bash
certbot --nginx -d sanadtherapy.com -d www.sanadtherapy.com
```

### 5. DNS (on Hostinger)
- A Record: `@` → `161.97.182.255`
- A Record: `www` → `161.97.182.255`

 

## Tech Stack
- **Backend** Flutter web 
- **Frontend**: nextjs + Tailwind CSS + landing page
- **Container**: Docker (port 8080 → 8000)
- **Auth**: Firebase

## Notes
- Client is waiting for deployment — asked for updates on Mar 31
- No auto-backup selected on Contabo (save cost)
- Server region: EU (free tier)
