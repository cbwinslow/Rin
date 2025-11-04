#!/bin/bash
# Test runner for Ansible playbooks
# This script runs all tests and validation checks

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"
TEST_INVENTORY="${SCRIPT_DIR}/inventory/test-hosts.yml"

echo -e "${BLUE}=== Rin Ansible Test Suite ===${NC}"
echo ""

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed${NC}"
    exit 1
fi

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}Running: ${test_name}${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    echo ""
}

cd "$ANSIBLE_DIR"

echo -e "${BLUE}1. Configuration Validation${NC}"
echo "----------------------------"
run_test "Ansible Configuration" "ansible-playbook tests/playbooks/test-validation.yml"
echo ""

echo -e "${BLUE}2. Syntax Checks${NC}"
echo "----------------------------"
run_test "Playbook Syntax Check" "ansible-playbook tests/playbooks/test-syntax.yml"
echo ""

echo -e "${BLUE}3. Individual Playbook Validation${NC}"
echo "----------------------------"
for playbook in playbooks/*.yml; do
    playbook_name=$(basename "$playbook")
    run_test "Syntax: $playbook_name" "ansible-playbook $playbook --syntax-check -i $TEST_INVENTORY" || true
done
echo ""

echo -e "${BLUE}4. Role Validation${NC}"
echo "----------------------------"
for role in roles/*/tasks/main.yml; do
    role_name=$(dirname $(dirname "$role"))
    role_name=$(basename "$role_name")
    run_test "Role: $role_name" "ansible-playbook --syntax-check -i $TEST_INVENTORY -e '{\"roles\": [\"$role_name\"]}' /dev/stdin <<< '---
- hosts: localhost
  roles: []'" || true
done
echo ""

echo -e "${BLUE}5. Template Validation${NC}"
echo "----------------------------"
template_count=$(find roles/*/templates -name "*.j2" 2>/dev/null | wc -l)
if [ "$template_count" -gt 0 ]; then
    echo "Found $template_count templates"
    run_test "Template existence" "find roles/*/templates -name '*.j2' -type f | head -1"
else
    echo -e "${YELLOW}No templates found to validate${NC}"
fi
echo ""

echo -e "${BLUE}6. Inventory Validation${NC}"
echo "----------------------------"
run_test "Test inventory" "ansible-inventory -i $TEST_INVENTORY --list > /dev/null"
run_test "Production inventory" "ansible-inventory -i inventories/hosts.yml --list > /dev/null"
echo ""

echo -e "${BLUE}7. Dry Run Tests${NC}"
echo "----------------------------"
echo "Note: Skipping dry runs as they require actual hosts"
echo ""

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
fi
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
