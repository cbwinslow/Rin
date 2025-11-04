#!/bin/bash
# Rin Deployment Script
# This script deploys Rin to either Cloudflare or a homelab server

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"

echo -e "${GREEN}=== Rin Deployment Script ===${NC}"
echo ""

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed${NC}"
    echo "Please install Ansible first:"
    echo "  Ubuntu/Debian: sudo apt-get install ansible"
    echo "  CentOS/RHEL: sudo yum install ansible"
    echo "  macOS: brew install ansible"
    echo "  pip: pip install ansible"
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 [cloudflare|homelab] [options]"
    echo ""
    echo "Deployment targets:"
    echo "  cloudflare    Deploy to Cloudflare Workers"
    echo "  homelab       Deploy to homelab server"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -i, --inventory FILE    Specify inventory file"
    echo "  -v, --verbose           Verbose output"
    echo "  --check                 Run in check mode (dry-run)"
    echo "  --tags TAGS             Run only tasks with specified tags"
    echo ""
    echo "Examples:"
    echo "  $0 cloudflare"
    echo "  $0 homelab --verbose"
    echo "  $0 homelab --check"
    exit 0
}

# Parse arguments
DEPLOYMENT_TARGET=""
ANSIBLE_OPTS=""
INVENTORY_FILE="${ANSIBLE_DIR}/inventories/hosts.yml"

while [[ $# -gt 0 ]]; do
    case $1 in
        cloudflare|homelab)
            DEPLOYMENT_TARGET="$1"
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        -i|--inventory)
            INVENTORY_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            ANSIBLE_OPTS="${ANSIBLE_OPTS} -vvv"
            shift
            ;;
        --check)
            ANSIBLE_OPTS="${ANSIBLE_OPTS} --check"
            shift
            ;;
        --tags)
            ANSIBLE_OPTS="${ANSIBLE_OPTS} --tags $2"
            shift 2
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_usage
            ;;
    esac
done

# Check if deployment target is specified
if [ -z "$DEPLOYMENT_TARGET" ]; then
    echo -e "${RED}Error: Deployment target not specified${NC}"
    show_usage
fi

# Check if inventory file exists
if [ ! -f "$INVENTORY_FILE" ]; then
    echo -e "${RED}Error: Inventory file not found: $INVENTORY_FILE${NC}"
    exit 1
fi

# Check for vault file
VAULT_FILE="${ANSIBLE_DIR}/group_vars/all/vault.yml"
if [ ! -f "$VAULT_FILE" ]; then
    echo -e "${YELLOW}Warning: Vault file not found: $VAULT_FILE${NC}"
    echo "Creating from example..."
    cp "${VAULT_FILE}.example" "$VAULT_FILE"
    echo -e "${YELLOW}Please edit $VAULT_FILE with your actual credentials${NC}"
    echo "You can encrypt it with: ansible-vault encrypt $VAULT_FILE"
    read -p "Press Enter to continue or Ctrl+C to abort..."
fi

echo -e "${GREEN}Deployment Configuration:${NC}"
echo "  Target: $DEPLOYMENT_TARGET"
echo "  Inventory: $INVENTORY_FILE"
echo "  Working Directory: $ANSIBLE_DIR"
echo ""

# Change to ansible directory
cd "$ANSIBLE_DIR"

# Run pre-deployment checks
echo -e "${GREEN}Running pre-deployment checks...${NC}"
ansible-playbook playbooks/health-check.yml -i "$INVENTORY_FILE" -l "$DEPLOYMENT_TARGET" ${ANSIBLE_OPTS} || true
echo ""

# Confirm deployment
read -p "Proceed with deployment? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Run deployment
echo -e "${GREEN}Starting deployment to $DEPLOYMENT_TARGET...${NC}"
ansible-playbook playbooks/deploy.yml -i "$INVENTORY_FILE" -l "$DEPLOYMENT_TARGET" ${ANSIBLE_OPTS}

# Check deployment status
DEPLOY_STATUS=$?
if [ $DEPLOY_STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=== Deployment Successful! ===${NC}"
    echo ""
    
    # Run post-deployment health check
    echo -e "${GREEN}Running post-deployment health check...${NC}"
    ansible-playbook playbooks/health-check.yml -i "$INVENTORY_FILE" -l "$DEPLOYMENT_TARGET" ${ANSIBLE_OPTS}
    
    echo ""
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo "Your Rin blog should now be available at: https://cloudcurio.cc"
else
    echo ""
    echo -e "${RED}=== Deployment Failed ===${NC}"
    echo "Please check the error messages above and try again."
    exit 1
fi
