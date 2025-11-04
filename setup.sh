#!/bin/bash
# Quick setup script for first-time deployment

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Rin Deployment Quick Setup ===${NC}"
echo ""

# Check prerequisites
echo -e "${GREEN}Checking prerequisites...${NC}"

# Check Ansible
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Ansible is not installed!${NC}"
    echo "Would you like to install it now? (y/n)"
    read -r install_ansible
    if [ "$install_ansible" = "y" ]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y ansible
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install ansible
        else
            echo "Please install Ansible manually: pip install ansible"
            exit 1
        fi
    else
        exit 1
    fi
fi

echo -e "${GREEN}✓ Ansible is installed${NC}"

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git is installed${NC}"

# Create vault file if it doesn't exist
VAULT_FILE="ansible/group_vars/all/vault.yml"
if [ ! -f "$VAULT_FILE" ]; then
    echo ""
    echo -e "${YELLOW}Creating vault file from example...${NC}"
    cp "${VAULT_FILE}.example" "$VAULT_FILE"
    echo -e "${GREEN}✓ Created ${VAULT_FILE}${NC}"
fi

# Prompt for configuration
echo ""
echo -e "${BLUE}=== Configuration Setup ===${NC}"
echo ""

# Deployment type
echo "Select deployment type:"
echo "1) Cloudflare (Workers + Pages)"
echo "2) Homelab (Self-hosted server)"
read -p "Enter choice (1 or 2): " deployment_choice

case $deployment_choice in
    1)
        DEPLOYMENT_TYPE="cloudflare"
        ;;
    2)
        DEPLOYMENT_TYPE="homelab"
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Deployment type: ${DEPLOYMENT_TYPE}${NC}"
echo ""

# Collect required information
read -p "Enter your domain (e.g., cloudcurio.cc): " DOMAIN
read -p "Enter your email for SSL certificates: " EMAIL

if [ "$DEPLOYMENT_TYPE" = "homelab" ]; then
    read -p "Enter your homelab server IP: " SERVER_IP
    read -p "Enter your SSH username: " SSH_USER
fi

read -p "Enter GitHub OAuth Client ID: " GITHUB_CLIENT_ID
read -sp "Enter GitHub OAuth Client Secret: " GITHUB_CLIENT_SECRET
echo ""
read -sp "Enter JWT Secret (or press Enter to generate): " JWT_SECRET
echo ""

if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 32)
    echo -e "${GREEN}Generated JWT secret${NC}"
fi

read -p "Enter S3 Endpoint: " S3_ENDPOINT
read -p "Enter S3 Bucket Name: " S3_BUCKET
read -p "Enter S3 Access Key ID: " S3_ACCESS_KEY_ID
read -sp "Enter S3 Secret Access Key: " S3_SECRET_ACCESS_KEY
echo ""

if [ "$DEPLOYMENT_TYPE" = "cloudflare" ]; then
    read -p "Enter Cloudflare Account ID: " CLOUDFLARE_ACCOUNT_ID
    read -p "Enter Cloudflare Zone ID: " CLOUDFLARE_ZONE_ID
    read -sp "Enter Cloudflare API Token: " CLOUDFLARE_API_TOKEN
    echo ""
fi

# Update vault file
echo ""
echo -e "${GREEN}Updating configuration files...${NC}"

cat > "$VAULT_FILE" <<EOF
---
# Ansible Vault - Encrypted secrets
# Encrypt with: ansible-vault encrypt $VAULT_FILE

# GitHub OAuth Configuration
github_client_id: "$GITHUB_CLIENT_ID"
github_client_secret: "$GITHUB_CLIENT_SECRET"

# JWT Secret
jwt_secret: "$JWT_SECRET"

# S3 Configuration
s3_endpoint: "$S3_ENDPOINT"
s3_access_host: "$S3_ENDPOINT"
s3_bucket: "$S3_BUCKET"
s3_access_key_id: "$S3_ACCESS_KEY_ID"
s3_secret_access_key: "$S3_SECRET_ACCESS_KEY"

# Webhook Configuration
webhook_url: ""

# SSL Configuration (for homelab)
ssl_email: "$EMAIL"

# Cloudflare Configuration
cloudflare_zone_id: "${CLOUDFLARE_ZONE_ID:-}"
cloudflare_account_id: "${CLOUDFLARE_ACCOUNT_ID:-}"
cloudflare_api_token: "${CLOUDFLARE_API_TOKEN:-}"

# Frontend URL
frontend_url: "https://$DOMAIN"
EOF

echo -e "${GREEN}✓ Updated ${VAULT_FILE}${NC}"

# Update inventory if homelab
if [ "$DEPLOYMENT_TYPE" = "homelab" ]; then
    # We'll use environment variables instead of modifying the inventory file
    export HOMELAB_HOST="$SERVER_IP"
    export HOMELAB_USER="$SSH_USER"
    echo ""
    echo -e "${YELLOW}Note: Set these environment variables before deploying:${NC}"
    echo "  export HOMELAB_HOST=\"$SERVER_IP\""
    echo "  export HOMELAB_USER=\"$SSH_USER\""
fi

# Offer to encrypt vault
echo ""
read -p "Would you like to encrypt the vault file? (recommended) (y/n): " encrypt_choice
if [ "$encrypt_choice" = "y" ]; then
    ansible-vault encrypt "$VAULT_FILE"
    echo -e "${GREEN}✓ Vault file encrypted${NC}"
    echo -e "${YELLOW}Remember your vault password! You'll need it for deployments.${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo "Configuration saved to: $VAULT_FILE"
echo "Deployment type: $DEPLOYMENT_TYPE"
echo "Domain: $DOMAIN"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the configuration: nano $VAULT_FILE"
if [ "$DEPLOYMENT_TYPE" = "homelab" ]; then
    echo "2. Ensure SSH access to your server: ssh $SSH_USER@$SERVER_IP"
    echo "3. Deploy: ./deploy.sh homelab"
else
    echo "2. Verify Cloudflare credentials are correct"
    echo "3. Deploy: ./deploy.sh cloudflare"
fi
echo ""
echo "For more information, see: ansible/README.md"
