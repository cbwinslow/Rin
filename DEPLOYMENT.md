# Rin Deployment with Ansible

This repository includes comprehensive Ansible automation for deploying the Rin blog platform to either **Cloudflare Workers** or a **homelab server**.

## Features

- **Full Automation**: Deploy Rin with a single command
- **Multiple Targets**: Support for Cloudflare and self-hosted deployments
- **Secure**: Uses Ansible Vault for sensitive data
- **Comprehensive**: Includes deployment, management, backup, and health checks
- **Production Ready**: SSL/TLS certificates, systemd services, Nginx reverse proxy
- **Well Tested**: Includes test suite for validation

## Quick Start

### 1. Install Prerequisites

```bash
# Install Ansible
sudo apt-get install ansible  # Ubuntu/Debian
brew install ansible          # macOS
pip install ansible           # Python

# Clone this repository
git clone https://github.com/openRin/Rin.git
cd Rin
```

### 2. Configure Secrets

```bash
cd ansible
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
# Edit vault.yml with your actual credentials
nano group_vars/all/vault.yml

# Optional: Encrypt the file
ansible-vault encrypt group_vars/all/vault.yml
```

### 3. Configure Inventory

Edit `ansible/inventories/hosts.yml` to set your server details:

```yaml
homelab_server:
  ansible_host: "192.168.1.100"  # Your server IP
  ansible_user: "ubuntu"          # Your SSH user
```

### 4. Deploy

```bash
# Deploy to Cloudflare
./deploy.sh cloudflare

# Deploy to homelab server
./deploy.sh homelab
```

## What Gets Deployed

### Cloudflare Deployment

- Cloudflare Workers application
- D1 database with migrations
- Cloudflare Pages for static frontend
- DNS configuration
- Environment variables and secrets

### Homelab Deployment

- Node.js and Bun runtime
- Rin application with dependencies
- Systemd service for automatic startup
- Nginx reverse proxy with SSL/TLS
- Let's Encrypt SSL certificate
- Firewall configuration
- Log rotation and backups

## Management

Use the management script for common tasks:

```bash
# Check status
./manage.sh status

# Restart application
./manage.sh restart

# View logs
./manage.sh logs

# Create backup
./manage.sh backup

# Health check
./manage.sh health-check
```

## Project Structure

```
.
├── deploy.sh                 # Main deployment script
├── manage.sh                 # Management script
└── ansible/
    ├── ansible.cfg           # Ansible configuration
    ├── inventories/          # Inventory files
    │   └── hosts.yml         # Main inventory
    ├── group_vars/           # Group variables
    │   └── all/
    │       ├── vars.yml      # Common variables
    │       └── vault.yml     # Encrypted secrets
    ├── roles/                # Ansible roles
    │   ├── common/           # Common setup tasks
    │   ├── rin-app/          # Application deployment
    │   ├── cloudflare/       # Cloudflare deployment
    │   └── homelab/          # Homelab web server setup
    ├── playbooks/            # Ansible playbooks
    │   ├── deploy.yml        # Main deployment
    │   ├── maintenance.yml   # Start/stop/restart
    │   ├── backup.yml        # Backup tasks
    │   └── health-check.yml  # Health monitoring
    ├── tests/                # Test suite
    │   └── run-tests.sh      # Test runner
    └── README.md             # Detailed documentation
```

## Testing

Run the test suite to validate your Ansible configuration:

```bash
cd ansible/tests
./run-tests.sh
```

Tests include:
- Configuration validation
- Syntax checking
- Role structure validation
- Template validation
- Inventory validation

## Documentation

- **[Ansible Deployment Guide](ansible/README.md)** - Comprehensive deployment documentation
- **[Rin Documentation](https://docs.openrin.org)** - Official Rin documentation
- **[Original README](README.md)** - Project information

## Requirements

### For Cloudflare Deployment

- Cloudflare account with API token
- Domain managed by Cloudflare
- Node.js 22+ and Bun

### For Homelab Deployment

- Ubuntu 20.04+ or Debian 11+ server
- 2GB RAM, 2 CPU cores, 10GB disk
- SSH access with sudo privileges
- Domain pointing to your server

## Security

- All secrets are stored in Ansible Vault
- SSL/TLS certificates via Let's Encrypt
- Firewall configured with UFW
- Secure systemd service configuration
- Regular automated backups

## Configuration

Key configuration files:

- `ansible/inventories/hosts.yml` - Server and deployment configuration
- `ansible/group_vars/all/vault.yml` - Encrypted secrets
- `ansible/ansible.cfg` - Ansible settings

## Monitoring

### Application Logs

```bash
# Homelab
sudo journalctl -u rin -f

# Via management script
./manage.sh logs
```

### Health Checks

```bash
# Run health check
./manage.sh health-check

# Check specific endpoints
curl https://cloudcurio.cc
curl -I https://cloudcurio.cc
```

## Backup and Restore

Automated backups are created in `/opt/rin/backups/` (homelab) and retained for 30 days.

```bash
# Create backup
./manage.sh backup

# Restore from backup
cd /opt/rin
sudo tar -xzf backups/rin-app-YYYYMMDDTHHMMSS.tar.gz
sudo systemctl restart rin
```

## Troubleshooting

### Common Issues

1. **Connection Failed**: Check SSH access and credentials
2. **Service Won't Start**: Check logs with `./manage.sh logs`
3. **SSL Issues**: Run `sudo certbot renew --dry-run`
4. **Port in Use**: Check with `sudo lsof -i :11498`

See [ansible/README.md](ansible/README.md) for detailed troubleshooting.

## Updating

To update Rin to the latest version:

```bash
# Re-run deployment
./deploy.sh homelab

# Or manually
cd /opt/rin/rin
sudo -u rin git pull
sudo -u rin bun install
sudo -u rin bun run build
sudo systemctl restart rin
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT License - See [LICENSE](LICENSE) for details.

## Support

- [Discord Community](https://discord.gg/JWbSTHvAPN)
- [Telegram Group](https://t.me/openRin)
- [GitHub Issues](https://github.com/openRin/Rin/issues)

## Acknowledgments

- Original Rin project by [Xeu](https://xeu.life)
- Ansible automation for easy deployment
- Community contributors
