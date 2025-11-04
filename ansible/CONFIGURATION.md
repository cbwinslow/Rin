# Rin Deployment Configuration Reference

This document provides a comprehensive reference for all configuration options available in the Ansible deployment.

## Table of Contents

- [Inventory Variables](#inventory-variables)
- [Vault Variables](#vault-variables)
- [Role Variables](#role-variables)
- [Environment Variables](#environment-variables)
- [Playbook Variables](#playbook-variables)

## Inventory Variables

### Global Variables (all hosts)

```yaml
# Application settings
app_name: rin                    # Application name
app_user: rin                    # System user for the application
app_group: rin                   # System group for the application
app_port: 11498                  # Application port
frontend_port: 5173              # Frontend development port

# Application paths
app_base_dir: /opt/rin           # Base directory for application
app_repo_url: https://github.com/openRin/Rin.git  # Git repository URL
app_branch: main                 # Git branch to deploy

# Runtime versions
node_version: "22"               # Node.js version to install
bun_version: "1.2.13"            # Bun version to install

# Database configuration
db_name: rin                     # D1 database name
worker_name: rin-server          # Cloudflare worker name

# S3 Configuration
s3_region: auto                  # S3 region
s3_folder: images/               # Folder for uploaded images
s3_cache_folder: cache/          # Folder for cached files
s3_force_path_style: "false"     # Force path-style S3 URLs

# RSS Configuration
rss_title: "Rin Blog"            # RSS feed title
rss_description: "A blog powered by Rin"  # RSS feed description
```

### Cloudflare-specific Variables

```yaml
deployment_type: cloudflare
domain: cloudcurio.cc
cloudflare_zone_id: "{{ lookup('env', 'CLOUDFLARE_ZONE_ID') }}"
cloudflare_account_id: "{{ lookup('env', 'CLOUDFLARE_ACCOUNT_ID') }}"
cloudflare_api_token: "{{ lookup('env', 'CLOUDFLARE_API_TOKEN') }}"
```

### Homelab-specific Variables

```yaml
deployment_type: homelab
ansible_host: "192.168.1.100"    # Server IP address
ansible_port: 22                 # SSH port
ansible_user: ubuntu             # SSH user
domain: cloudcurio.cc            # Your domain name
```

## Vault Variables

These should be stored in `ansible/group_vars/all/vault.yml` and encrypted with `ansible-vault`.

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

## Role Variables

### Common Role

Variables for system setup and dependencies.

```yaml
# No specific variables - uses global inventory variables
```

### Rin-App Role

Variables for application deployment.

```yaml
# Application configuration
git_clone: {}                    # Git clone result (internal)
build_client: {}                 # Build result (internal)
```

### Cloudflare Role

Variables for Cloudflare deployment.

```yaml
cf_deploy: {}                    # Deployment result (internal)
dns_result: {}                   # DNS configuration result (internal)
```

### Homelab Role

Variables for homelab server setup.

```yaml
certbot_result: {}               # SSL certificate result (internal)
```

## Environment Variables

Environment variables can be used to override inventory settings.

### For Both Deployments

```bash
# Cloudflare credentials
export CLOUDFLARE_ACCOUNT_ID="your_account_id"
export CLOUDFLARE_API_TOKEN="your_api_token"
export CLOUDFLARE_ZONE_ID="your_zone_id"
```

### For Homelab Deployment

```bash
# Server connection
export HOMELAB_HOST="192.168.1.100"
export HOMELAB_USER="ubuntu"
```

### Application Configuration

```bash
# These are typically stored in vault.yml
export RIN_GITHUB_CLIENT_ID="your_client_id"
export RIN_GITHUB_CLIENT_SECRET="your_client_secret"
export JWT_SECRET="your_jwt_secret"
export S3_ACCESS_KEY_ID="your_key"
export S3_SECRET_ACCESS_KEY="your_secret"
export S3_ENDPOINT="https://your-s3-endpoint.com"
export S3_BUCKET="your-bucket"
export WEBHOOK_URL="https://your-webhook.com"
```

## Playbook Variables

### Deploy Playbook

```yaml
# No additional variables required
# Uses inventory and vault variables
```

### Maintenance Playbook

```yaml
action: status                   # Action to perform: start, stop, restart, status
```

Example usage:
```bash
ansible-playbook playbooks/maintenance.yml -e "action=restart"
```

### Backup Playbook

```yaml
backup_timestamp: "{{ ansible_date_time.iso8601_basic_short }}"
backup_dir: "{{ app_base_dir }}/backups"
backup_with_service_stop: false  # Stop service during backup
```

Example usage:
```bash
ansible-playbook playbooks/backup.yml -e "backup_with_service_stop=true"
```

### Health Check Playbook

```yaml
# No additional variables required
# Checks service status, endpoints, and SSL certificates
```

## Advanced Configuration

### Custom Ports

To use different ports, override in your inventory:

```yaml
homelab_server:
  ansible_host: "192.168.1.100"
  app_port: 8080               # Custom application port
  frontend_port: 3000          # Custom frontend port
```

### Multiple Environments

Create separate inventory files for different environments:

```
inventories/
├── production.yml
├── staging.yml
└── development.yml
```

Deploy to specific environment:
```bash
./deploy.sh homelab -i ansible/inventories/staging.yml
```

### Custom Domains

Update the domain in your inventory:

```yaml
domain: your-custom-domain.com
```

### Backup Retention

Control backup retention period:

```yaml
backup_retention_days: 60    # Keep backups for 60 days
```

### SSL Certificate Email

For Let's Encrypt notifications:

```yaml
ssl_email: "your-email@example.com"
```

## Security Considerations

1. **Always encrypt vault files**:
   ```bash
   ansible-vault encrypt ansible/group_vars/all/vault.yml
   ```

2. **Use strong, unique secrets**:
   - Generate JWT secret: `openssl rand -base64 32`
   - Use different passwords for each environment

3. **Restrict file permissions**:
   - Vault files: 600 (read/write for owner only)
   - Private keys: 400 (read-only for owner)

4. **Environment-specific credentials**:
   - Never reuse production credentials in development
   - Keep separate S3 buckets for each environment

5. **SSH Key Authentication**:
   - Use SSH keys instead of passwords
   - Disable password authentication on servers

## Troubleshooting

### Variable Precedence

Ansible uses this precedence order (highest to lowest):

1. Extra vars (`-e` in command line)
2. Task vars
3. Block vars
4. Role and include vars
5. Play vars
6. Host facts
7. Playbook host_vars
8. Playbook group_vars
9. Inventory host_vars
10. Inventory group_vars
11. Inventory vars
12. Role defaults

### Checking Variables

View all variables for a host:
```bash
ansible -m debug -a "var=hostvars[inventory_hostname]" homelab_server -i inventories/hosts.yml
```

View specific variable:
```bash
ansible -m debug -a "var=app_port" homelab_server -i inventories/hosts.yml
```

### Common Issues

1. **Variable not found**: Check spelling and precedence
2. **Vault error**: Ensure vault password is correct
3. **Template error**: Check Jinja2 syntax in templates
4. **Undefined variable**: Provide default or ensure variable is set

## Examples

### Example: Custom Database Name

```yaml
# In inventory
db_name: my_custom_db

# Or via command line
ansible-playbook playbooks/deploy.yml -e "db_name=my_custom_db"
```

### Example: Different S3 Settings

```yaml
# In vault.yml
s3_endpoint: "https://s3.us-west-1.amazonaws.com"
s3_region: "us-west-1"
s3_bucket: "my-rin-bucket"
s3_folder: "uploads/"
s3_cache_folder: "cache/"
```

### Example: Multiple Workers

```yaml
# For staging
worker_name: rin-server-staging

# For production
worker_name: rin-server-production
```

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [Rin Documentation](https://docs.openrin.org)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Jinja2 Template Documentation](https://jinja.palletsprojects.com/)
