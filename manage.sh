#!/bin/bash
# Rin Management Script
# Manage Rin application (start, stop, restart, status, backup)

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"

echo -e "${GREEN}=== Rin Management Script ===${NC}"
echo ""

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed${NC}"
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start         Start Rin application"
    echo "  stop          Stop Rin application"
    echo "  restart       Restart Rin application"
    echo "  status        Show Rin application status"
    echo "  backup        Backup Rin application"
    echo "  health-check  Run health check"
    echo "  logs          Show application logs"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -i, --inventory FILE    Specify inventory file"
    echo "  -t, --target TARGET     Specify target (cloudflare or homelab)"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 restart -t homelab"
    echo "  $0 backup"
    exit 0
}

# Parse arguments
COMMAND=""
INVENTORY_FILE="${ANSIBLE_DIR}/inventories/hosts.yml"
TARGET="homelab"
ANSIBLE_OPTS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|status|backup|health-check|logs)
            COMMAND="$1"
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        -i|--inventory)
            INVENTORY_FILE="$2"
            shift 2
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_usage
            ;;
    esac
done

# Check if command is specified
if [ -z "$COMMAND" ]; then
    echo -e "${RED}Error: Command not specified${NC}"
    show_usage
fi

# Change to ansible directory
cd "$ANSIBLE_DIR"

echo -e "${GREEN}Executing command: $COMMAND${NC}"
echo ""

case $COMMAND in
    start|stop|restart|status)
        ansible-playbook playbooks/maintenance.yml \
            -i "$INVENTORY_FILE" \
            -l "$TARGET" \
            -e "action=$COMMAND" \
            ${ANSIBLE_OPTS}
        ;;
    backup)
        echo -e "${GREEN}Starting backup...${NC}"
        ansible-playbook playbooks/backup.yml \
            -i "$INVENTORY_FILE" \
            -l "$TARGET" \
            ${ANSIBLE_OPTS}
        ;;
    health-check)
        ansible-playbook playbooks/health-check.yml \
            -i "$INVENTORY_FILE" \
            -l "$TARGET" \
            ${ANSIBLE_OPTS}
        ;;
    logs)
        echo -e "${GREEN}Fetching logs from $TARGET...${NC}"
        ansible $TARGET \
            -i "$INVENTORY_FILE" \
            -m shell \
            -a "journalctl -u rin -n 100 --no-pager" \
            -b
        ;;
esac

COMMAND_STATUS=$?
if [ $COMMAND_STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Command completed successfully!${NC}"
else
    echo ""
    echo -e "${RED}Command failed!${NC}"
    exit 1
fi
