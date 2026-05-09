# multijava

Production-ready boilerplate for full-stack applications. Clone it, run one script, and have a live HTTPS application with CI/CD in under 30 minutes.

**Stack:** Java 21 · Django 6 · React 18 · Nginx · Gunicorn · GitHub Actions · AWS EC2

---

## What's Included

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | React 18 + Tailwind CSS | Single-page application |
| Backend | Python 3.13 + Django 6 | REST API + SPA serving |
| Business logic | Java 21 + Maven | Extensible JVM service layer |
| Web server | Nginx + Gunicorn | Reverse proxy + WSGI |
| CI/CD | GitHub Actions | Auto-deploy on push to `main` |
| Infrastructure | AWS EC2 + Elastic IP | Cloud hosting |
| TLS | Let's Encrypt (Certbot) | Auto-renewing HTTPS |

---

## Quick Start

### Prerequisites
- AWS account
- Domain name
- GitHub account

### 1. Fork & clone
```bash
git clone https://github.com/YOUR_USERNAME/multijava.git
cd multijava
```

### 2. Create EC2 instance
- AMI: Amazon Linux 2023
- Type: t2.micro
- Security group: open ports 22, 80, 443
- Allocate an Elastic IP and associate it

### 3. Point your domain
Create a DNS A record pointing your domain to the Elastic IP.

### 4. Add GitHub secrets
Go to repo → Settings → Secrets → Actions:

| Secret | Value |
|--------|-------|
| `EC2_HOST` | Your Elastic IP |
| `EC2_SSH_KEY` | Contents of your `.pem` key file |

### 5. Bootstrap the server
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@YOUR_ELASTIC_IP
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/multijava/main/scripts/setup.sh | bash
```

### 6. Deploy
```bash
git push origin main
```

GitHub Actions deploys automatically. Your app is live at `https://your-domain.com`.

---

## Project Structure

```
multijava/
├── .github/workflows/deploy.yml   # CI/CD pipeline
├── frontend/                      # React application
├── java/                          # Java module
├── system/                        # Django backend
│   ├── core/settings.py
│   ├── core/urls.py
│   └── requirements.txt
├── scripts/
│   └── setup.sh                   # Server bootstrap script
└── pom.xml                        # Maven parent build
```

---

## API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health/` | Health check |
| GET | `/*` | React SPA |

Add new endpoints in `system/core/urls.py`.

---

## Local Development

**Django:**
```bash
cd system
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python manage.py runserver
```

**React:**
```bash
cd frontend
npm install && npm start
```

**Full build (Maven):**
```bash
mvn package
```

---

## CI/CD

Every push to `main` triggers:
1. SSH into EC2
2. `git pull`
3. `pip install`
4. `npm build`
5. Restart Gunicorn

Monitor at: `https://github.com/YOUR_USERNAME/multijava/actions`

---

## License

MIT
