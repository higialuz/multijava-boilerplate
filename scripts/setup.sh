#!/bin/bash
set -e

# ─────────────────────────────────────────────
# multijava — Server Bootstrap Script
# Runs on a fresh Amazon Linux 2023 EC2 instance
# ─────────────────────────────────────────────

echo ""
echo "======================================"
echo "  multijava setup"
echo "======================================"
echo ""

# ── Prompt for config ──────────────────────
read -p "GitHub repo URL (e.g. git@github.com:user/multijava.git): " REPO_URL
read -p "Your domain (e.g. app.yourdomain.com): " DOMAIN
read -p "Django secret key (any long random string): " SECRET_KEY

PROJECT_DIR="$HOME/multijava"

# ── System dependencies ────────────────────
echo ""
echo "→ Installing system dependencies..."
sudo dnf update -y -q
sudo dnf install -y git nginx python3 python3-pip java-21-amazon-corretto certbot python3-certbot-nginx -q

# Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - -q
sudo dnf install -y nodejs -q

# ── Clone repo ─────────────────────────────
echo "→ Cloning repository..."
if [ -d "$PROJECT_DIR" ]; then
  echo "  Directory exists, pulling latest..."
  git -C "$PROJECT_DIR" pull origin main
else
  git clone "$REPO_URL" "$PROJECT_DIR"
fi

# ── Python venv + deps ─────────────────────
echo "→ Setting up Python environment..."
python3 -m venv "$PROJECT_DIR/system/venv"
source "$PROJECT_DIR/system/venv/bin/activate"
pip install -q -r "$PROJECT_DIR/system/requirements.txt"
pip install -q gunicorn

# ── React build ────────────────────────────
echo "→ Building React frontend..."
cd "$PROJECT_DIR/frontend"
npm ci --silent
npm run build --silent
cd "$HOME"

# ── .env file ──────────────────────────────
echo "→ Creating .env..."
cat > "$PROJECT_DIR/system/.env" << ENVEOF
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,$DOMAIN
ENVEOF

# ── Gunicorn systemd service ───────────────
echo "→ Installing Gunicorn service..."
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << SVCEOF
[Unit]
Description=gunicorn daemon for multijava
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$PROJECT_DIR/system
ExecStart=$PROJECT_DIR/system/venv/bin/gunicorn core.wsgi:application --bind 127.0.0.1:8000 --workers 2
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

# ── Nginx config ───────────────────────────
echo "→ Configuring Nginx..."
sudo python3 -c "
open('/etc/nginx/conf.d/multijava.conf','w').write('''server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
''')
"

sudo systemctl enable nginx
sudo systemctl start nginx

# ── HTTPS certificate ──────────────────────
echo "→ Issuing HTTPS certificate..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"

# ── Done ───────────────────────────────────
echo ""
echo "======================================"
echo "  Setup complete!"
echo "  https://$DOMAIN"
echo "======================================"
echo ""
echo "Next: push to main to trigger your first CI/CD deploy."
echo ""
