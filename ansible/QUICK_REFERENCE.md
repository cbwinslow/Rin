# Rin Ansible Quick Reference

## Quick Commands

### Initial Setup
```bash
./setup.sh                  # Interactive setup wizard
```

### Deployment
```bash
./deploy.sh cloudflare      # Deploy to Cloudflare
./deploy.sh homelab         # Deploy to homelab server
./deploy.sh homelab --check # Dry run
```

### Management
```bash
./manage.sh status          # Check application status
./manage.sh start           # Start application
./manage.sh stop            # Stop application
./manage.sh restart         # Restart application
./manage.sh backup          # Create backup
./manage.sh health-check    # Run health check
./manage.sh logs            # View logs
```

### Testing
```bash
cd ansible/tests
./run-tests.sh              # Run all tests
```

## Directory Structure

```
Rin/
├── deploy.sh               # Main deployment script
├── manage.sh               # Management script
├── setup.sh                # Setup wizard
├── DEPLOYMENT.md           # Deployment guide
└── ansible/
    ├── ansible.cfg         # Ansible configuration
    ├── README.md           # Detailed documentation
    ├── CONFIGURATION.md    # Configuration reference
    ├── inventories/
    │   └── hosts.yml       # Inventory file
    ├── group_vars/
    │   └── all/
    │       ├── vars.yml    # Common variables
    │       └── vault.yml   # Encrypted secrets
    ├── roles/
    │   ├── common/         # System setup
    │   ├── rin-app/        # Application deployment
    │   ├── cloudflare/     # Cloudflare deployment
    │   └── homelab/        # Homelab web server
    ├── playbooks/
    │   ├── deploy.yml      # Main deployment
    │   ├── maintenance.yml # Start/stop/restart
    │   ├── backup.yml      # Backup tasks
    │   └── health-check.yml # Health monitoring
    └── tests/              # Test suite
```

## Configuration Files

### Inventory (`inventories/hosts.yml`)
```yaml
homelab_server:
  ansible_host: "192.168.1.100"
  ansible_user: "ubuntu"
  domain: cloudcurio.cc
```

### Vault (`group_vars/all/vault.yml`)
```yaml
github_client_id: "..."
github_client_secret: "..."
jwt_secret: "..."
s3_endpoint: "..."
s3_bucket: "..."
# ... more secrets
```

## Ansible Commands

### Playbook Execution
```bash
cd ansible

# Deploy
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml -l homelab

# With vault password
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml --ask-vault-pass

# Dry run
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml --check

# Verbose output
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml -vvv

# Specific tags
ansible-playbook playbooks/deploy.yml -i inventories/hosts.yml --tags setup
```

### Vault Operations
```bash
# Encrypt vault file
ansible-vault encrypt group_vars/all/vault.yml

# Decrypt vault file
ansible-vault decrypt group_vars/all/vault.yml

# Edit encrypted vault
ansible-vault edit group_vars/all/vault.yml

# View encrypted vault
ansible-vault view group_vars/all/vault.yml

# Change vault password
ansible-vault rekey group_vars/all/vault.yml
```

### Ad-hoc Commands
```bash
# Ping hosts
ansible homelab -i inventories/hosts.yml -m ping

# Run command
ansible homelab -i inventories/hosts.yml -m shell -a "systemctl status rin"

# Get facts
ansible homelab -i inventories/hosts.yml -m setup

# Copy file
ansible homelab -i inventories/hosts.yml -m copy -a "src=file.txt dest=/tmp/"
```

### Inventory Commands
```bash
# List inventory
ansible-inventory -i inventories/hosts.yml --list

# Graph inventory
ansible-inventory -i inventories/hosts.yml --graph

# View host vars
ansible-inventory -i inventories/hosts.yml --host homelab_server
```

## Environment Variables

```bash
# Cloudflare
export CLOUDFLARE_ACCOUNT_ID="..."
export CLOUDFLARE_API_TOKEN="..."
export CLOUDFLARE_ZONE_ID="..."

# Homelab
export HOMELAB_HOST="192.168.1.100"
export HOMELAB_USER="ubuntu"

# Application
export RIN_GITHUB_CLIENT_ID="..."
export RIN_GITHUB_CLIENT_SECRET="..."
export JWT_SECRET="..."
export S3_ACCESS_KEY_ID="..."
export S3_SECRET_ACCESS_KEY="..."
```

## Common Tasks

### First Time Deployment
```bash
1. ./setup.sh                    # Run setup wizard
2. Edit ansible/group_vars/all/vault.yml
3. ansible-vault encrypt ansible/group_vars/all/vault.yml
4. ./deploy.sh homelab           # Deploy
```

### Update Application
```bash
./deploy.sh homelab              # Re-run deployment
```

### Troubleshooting
```bash
./manage.sh logs                 # View logs
./manage.sh health-check         # Run health check
./manage.sh status               # Check status

# On server
ssh user@server
sudo systemctl status rin
sudo journalctl -u rin -f
```

### Backup and Restore
```bash
# Create backup
./manage.sh backup

# Restore (on server)
cd /opt/rin
sudo systemctl stop rin
sudo tar -xzf backups/rin-app-YYYYMMDDTHHMMSS.tar.gz
sudo systemctl start rin
```

## Playbook Tags

```bash
# Available tags
--tags setup        # Only setup tasks
--tags deploy       # Only deployment tasks
--tags webserver    # Only web server setup
--tags common       # Only common tasks
--tags app          # Only app tasks
--tags cloudflare   # Only Cloudflare tasks
--tags homelab      # Only homelab tasks
```

## Service Management (Homelab)

```bash
# On the server
sudo systemctl status rin
sudo systemctl start rin
sudo systemctl stop rin
sudo systemctl restart rin
sudo systemctl enable rin
sudo systemctl disable rin

# View logs
sudo journalctl -u rin -f
sudo journalctl -u rin -n 100
sudo journalctl -u rin --since today
```

## Nginx Commands (Homelab)

```bash
# On the server
sudo nginx -t                    # Test configuration
sudo systemctl reload nginx      # Reload config
sudo systemctl restart nginx     # Restart Nginx

# Logs
sudo tail -f /var/log/nginx/rin_access.log
sudo tail -f /var/log/nginx/rin_error.log
```

## SSL Certificates (Homelab)

```bash
# On the server
sudo certbot certificates        # List certificates
sudo certbot renew               # Renew certificates
sudo certbot renew --dry-run     # Test renewal
sudo certbot delete --cert-name cloudcurio.cc  # Delete certificate
```

## Useful Variables

### In Playbooks
```yaml
{{ app_name }}                   # Application name
{{ app_base_dir }}               # Base directory
{{ app_port }}                   # Application port
{{ domain }}                     # Domain name
{{ deployment_type }}            # cloudflare or homelab
```

### In Templates
```jinja2
{{ github_client_id }}           # GitHub OAuth ID
{{ jwt_secret }}                 # JWT secret
{{ s3_endpoint }}                # S3 endpoint
{{ frontend_url }}               # Frontend URL
```

## Testing

```bash
# Syntax check
ansible-playbook playbooks/deploy.yml --syntax-check

# Dry run
ansible-playbook playbooks/deploy.yml --check

# Run tests
cd ansible/tests
./run-tests.sh
```

## Documentation

- `ansible/README.md` - Comprehensive deployment guide
- `ansible/CONFIGURATION.md` - Configuration reference
- `DEPLOYMENT.md` - Project deployment overview
- [Rin Docs](https://docs.openrin.org) - Official documentation

## Support

- [Discord](https://discord.gg/JWbSTHvAPN)
- [Telegram](https://t.me/openRin)
- [GitHub Issues](https://github.com/openRin/Rin/issues)
