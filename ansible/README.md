# Rin Ansible Deployment Guide

This guide provides instructions for deploying Rin blog using Ansible to either Cloudflare or a homelab server.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Management](#management)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Common Requirements

- Ansible 2.9 or later
- Git
- Access to target deployment platform (Cloudflare account or homelab server)

### For Cloudflare Deployment

- Cloudflare account with API token
- Domain registered and managed by Cloudflare (cloudcurio.cc)
- Cloudflare Workers enabled on your account
- Bun runtime (will be installed if not present)

### For Homelab Deployment

- Ubuntu 20.04+ or Debian 11+ server
- SSH access to the server
- Sudo privileges on the server
- Domain pointing to your server (cloudcurio.cc)
- Minimum 2GB RAM, 2 CPU cores, 10GB disk space

## Quick Start

### 1. Install Ansible

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install ansible

# CentOS/RHEL
sudo yum install ansible

# macOS
brew install ansible

# Using pip
pip install ansible
```

### 2. Clone Repository

```bash
git clone https://github.com/openRin/Rin.git
cd Rin
```

### 3. Configure Secrets

Copy the example vault file and configure your secrets:

```bash
cd ansible
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
```

Edit `group_vars/all/vault.yml` with your actual credentials:

```yaml
# GitHub OAuth Configuration
github_client_id: "your_github_client_id"
github_client_secret: "your_github_client_secret"

# JWT Secret (generate at https://www.avast.com/random-password-generator)
jwt_secret: "your_jwt_secret_here"

# S3 Configuration
s3_endpoint: "https://your-s3-endpoint.com"
s3_access_host: "https://your-s3-access-host.com"
s3_bucket: "your-bucket-name"
s3_access_key_id: "your_s3_access_key"
s3_secret_access_key: "your_s3_secret_key"

# Webhook Configuration (optional)
webhook_url: "https://your-webhook-url.com"

# SSL Configuration (for homelab)
ssl_email: "admin@cloudcurio.cc"

# Cloudflare Configuration
cloudflare_zone_id: "your_zone_id"
cloudflare_account_id: "your_account_id"
cloudflare_api_token: "your_api_token"

# Frontend URL
frontend_url: "https://cloudcurio.cc"
```

**Security Note:** Encrypt the vault file with ansible-vault:

```bash
ansible-vault encrypt group_vars/all/vault.yml
```

When running playbooks, use `--ask-vault-pass` or provide a vault password file.

### 4. Configure Inventory

Edit `inventories/hosts.yml` to match your environment:

For homelab deployment, update:
```yaml
homelab_server:
  ansible_host: "192.168.1.100"  # Your server IP
  ansible_user: "ubuntu"          # Your SSH user
```

### 5. Deploy

Use the deployment script:

```bash
# Deploy to Cloudflare
./deploy.sh cloudflare

# Deploy to homelab
./deploy.sh homelab

# Deploy with verbose output
./deploy.sh homelab --verbose

# Dry run (check mode)
./deploy.sh homelab --check
```

Or use Ansible directly:

```bash
# Deploy to Cloudflare
cd ansible
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml -l cloudflare

# Deploy to homelab
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml -l homelab

# With vault password
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml -l homelab --ask-vault-pass
```

## Configuration

### Environment Variables

Set these environment variables before deployment (or use the vault file):

```bash
# Required for both deployments
export CLOUDFLARE_ACCOUNT_ID="your_account_id"
export CLOUDFLARE_API_TOKEN="your_api_token"
export CLOUDFLARE_ZONE_ID="your_zone_id"

# For homelab deployment
export HOMELAB_HOST="192.168.1.100"
export HOMELAB_USER="ubuntu"
```

### Inventory Configuration

The inventory file (`inventories/hosts.yml`) supports two deployment types:

1. **Cloudflare**: Deploys to Cloudflare Workers and Pages
2. **Homelab**: Deploys to a self-hosted server

You can customize various parameters in the inventory file:

- `domain`: Your domain name (cloudcurio.cc)
- `app_port`: Application port (default: 11498)
- `node_version`: Node.js version (default: 22)
- `bun_version`: Bun version (default: 1.2.13)

### Role Configuration

Each role has default variables in `roles/<role>/defaults/main.yml` that can be overridden.

## Deployment

### Cloudflare Deployment

The Cloudflare deployment will:

1. Install wrangler CLI
2. Clone the repository locally
3. Install dependencies with Bun
4. Run database migrations
5. Deploy to Cloudflare Workers
6. Configure DNS records

```bash
./deploy.sh cloudflare
```

### Homelab Deployment

The homelab deployment will:

1. Install system dependencies (Node.js, Bun, Nginx)
2. Create application user and directories
3. Clone the repository
4. Install dependencies and build the application
5. Configure systemd service
6. Setup Nginx as reverse proxy
7. Obtain SSL certificate with Certbot
8. Start the application

```bash
./deploy.sh homelab
```

### Deployment Options

You can use tags to run specific parts of the deployment:

```bash
# Only setup system dependencies
./deploy.sh homelab --tags setup

# Only deploy the application
./deploy.sh homelab --tags deploy

# Only configure web server
./deploy.sh homelab --tags webserver
```

## Management

### Using the Management Script

The `manage.sh` script provides easy access to common management tasks:

```bash
# Check application status
./manage.sh status

# Start application
./manage.sh start

# Stop application
./manage.sh stop

# Restart application
./manage.sh restart

# Run health check
./manage.sh health-check

# Backup application
./manage.sh backup

# View logs
./manage.sh logs
```

### Manual Management

You can also use Ansible playbooks directly:

```bash
cd ansible

# Run maintenance tasks
ansible-playbook playbooks/maintenance.yml -i inventories/hosts.yml -l homelab -e "action=restart"

# Run health check
ansible-playbook playbooks/health-check.yml -i inventories/hosts.yml

# Backup application
ansible-playbook playbooks/backup.yml -i inventories/hosts.yml -l homelab
```

### Service Management (Homelab)

On the homelab server, you can use systemd:

```bash
# Check status
sudo systemctl status rin

# Start service
sudo systemctl start rin

# Stop service
sudo systemctl stop rin

# Restart service
sudo systemctl restart rin

# View logs
sudo journalctl -u rin -f
```

## Testing

### Ansible Playbook Syntax Check

```bash
cd ansible
ansible-playbook playbooks/deploy.yml --syntax-check
```

### Dry Run Deployment

```bash
./deploy.sh homelab --check
```

### Health Check

```bash
./manage.sh health-check
```

### Manual Testing

After deployment, verify:

1. **Service Status**: `sudo systemctl status rin`
2. **Local Access**: `curl http://localhost:11498`
3. **Public Access**: `curl https://cloudcurio.cc`
4. **SSL Certificate**: `openssl s_client -connect cloudcurio.cc:443 -servername cloudcurio.cc`

## Monitoring

### Application Logs

```bash
# View real-time logs
sudo journalctl -u rin -f

# View last 100 lines
sudo journalctl -u rin -n 100

# View logs from today
sudo journalctl -u rin --since today
```

### Nginx Logs

```bash
# Access logs
sudo tail -f /var/log/nginx/rin_access.log

# Error logs
sudo tail -f /var/log/nginx/rin_error.log
```

### System Monitoring

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check CPU usage
top
```

## Backup and Restore

### Automated Backups

Backups are created in `/opt/rin/backups/` and retained for 30 days by default.

Run a manual backup:

```bash
./manage.sh backup
```

### Restore from Backup

```bash
# Stop the service
sudo systemctl stop rin

# Extract backup
cd /opt/rin
sudo tar -xzf backups/rin-app-YYYYMMDDTHHMMSS.tar.gz

# Start the service
sudo systemctl start rin
```

## Troubleshooting

### Common Issues

#### 1. Ansible Connection Failed

```bash
# Test SSH connection
ansible homelab -i ansible/inventories/hosts.yml -m ping

# Check SSH configuration
ssh -v user@server
```

#### 2. Service Won't Start

```bash
# Check service status
sudo systemctl status rin

# Check logs
sudo journalctl -u rin -n 50

# Check configuration
sudo /root/.bun/bin/bun wrangler dev --help
```

#### 3. SSL Certificate Issues

```bash
# Check certificate
sudo certbot certificates

# Renew certificate
sudo certbot renew

# Test certificate renewal
sudo certbot renew --dry-run
```

#### 4. Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :11498

# Kill the process
sudo kill -9 <PID>
```

### Getting Help

- Check the logs: `sudo journalctl -u rin -f`
- Review Ansible output for errors
- Check the [Rin documentation](https://docs.openrin.org)
- Join the [Discord community](https://discord.gg/JWbSTHvAPN)

## Advanced Configuration

### Custom Port

To use a different port, update the inventory:

```yaml
app_port: 8080
```

### Multiple Environments

Create separate inventory files for different environments:

```bash
inventories/
  ├── production.yml
  ├── staging.yml
  └── development.yml
```

Deploy to specific environment:

```bash
./deploy.sh homelab -i ansible/inventories/staging.yml
```

### Custom Domain

Update the domain in your inventory file:

```yaml
domain: your-custom-domain.com
```

And update your DNS records accordingly.

## Security Best Practices

1. **Encrypt Sensitive Data**: Always use `ansible-vault` to encrypt sensitive files
2. **Use SSH Keys**: Configure SSH key-based authentication
3. **Firewall Configuration**: Enable UFW and allow only necessary ports
4. **Regular Updates**: Keep your system and application updated
5. **Strong Passwords**: Use strong, unique passwords for all services
6. **Backup Regularly**: Schedule regular backups
7. **Monitor Logs**: Regularly review application and system logs

## Updating

To update Rin to the latest version:

```bash
# Pull latest changes
cd /opt/rin/rin
sudo -u rin git pull

# Rebuild and restart
sudo systemctl stop rin
sudo -u rin bun install --frozen-lockfile
sudo -u rin bun run build
sudo systemctl start rin
```

Or use the deployment script:

```bash
./deploy.sh homelab
```

## Uninstallation

To completely remove Rin:

```bash
# Stop and disable service
sudo systemctl stop rin
sudo systemctl disable rin

# Remove files
sudo rm -rf /opt/rin
sudo rm /etc/systemd/system/rin.service
sudo rm /etc/nginx/sites-enabled/rin
sudo rm /etc/nginx/sites-available/rin

# Remove user
sudo userdel -r rin

# Reload systemd
sudo systemctl daemon-reload

# Restart Nginx
sudo systemctl restart nginx
```

## License

This deployment configuration is part of the Rin project and is licensed under the MIT License.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md) for details.
