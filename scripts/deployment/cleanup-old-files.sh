#!/bin/bash

# Cleanup script for old deployment files
# This script organizes and removes outdated deployment files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧹 Starting cleanup of old deployment files...${NC}"

# Create backup directory
BACKUP_DIR="deployment-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}📁 Creating backup in: $BACKUP_DIR${NC}"

# Backup old files before removing
backup_old_files() {
    echo -e "${YELLOW}📦 Backing up old files...${NC}"
    
    # Backup old deployment scripts
    if [ -f "lambda/deploy.sh" ]; then
        cp "lambda/deploy.sh" "$BACKUP_DIR/deploy-old.sh"
        echo "✅ Backed up old deploy.sh"
    fi
    
    if [ -f "lambda/update-lambda-cryptography.sh" ]; then
        cp "lambda/update-lambda-cryptography.sh" "$BACKUP_DIR/update-lambda-cryptography-old.sh"
        echo "✅ Backed up old update-lambda-cryptography.sh"
    fi
    
    # Backup old GitHub Actions workflows
    if [ -f "../../.github/workflows/deploy-lambda.yml" ]; then
        cp "../../.github/workflows/deploy-lambda.yml" "$BACKUP_DIR/deploy-lambda-old.yml"
        echo "✅ Backed up old deploy-lambda.yml"
    fi
    
    if [ -f "../../.github/workflows/deploy-lambda-simple.yml" ]; then
        cp "../../.github/workflows/deploy-lambda-simple.yml" "$BACKUP_DIR/deploy-lambda-simple-old.yml"
        echo "✅ Backed up old deploy-lambda-simple.yml"
    fi
}

# Remove old files
remove_old_files() {
    echo -e "${YELLOW}🗑️  Removing old files...${NC}"
    
    # Remove old deployment packages
    find . -name "lambda-deployment-package*.zip" -type f -delete
    echo "✅ Removed old deployment packages"
    
    # Remove old deployment directories
    find . -name "deployment*" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "✅ Removed old deployment directories"
    
    # Remove temporary files
    find . -name "*.json" -type f -not -name "*.py" -delete 2>/dev/null || true
    echo "✅ Removed temporary JSON files"
    
    # Remove old test files
    find . -name "test-*.py" -type f -delete 2>/dev/null || true
    echo "✅ Removed old test files"
}

# Organize files
organize_files() {
    echo -e "${YELLOW}📂 Organizing files...${NC}"
    
    # Create layers directory if it doesn't exist
    mkdir -p layers
    
    # Move layer scripts to layers directory
    if [ -f "../create-cryptography-layer.sh" ]; then
        mv "../create-cryptography-layer.sh" "layers/"
        echo "✅ Moved create-cryptography-layer.sh to layers/"
    fi
    
    if [ -f "../fix-cryptography-layer.sh" ]; then
        mv "../fix-cryptography-layer.sh" "layers/"
        echo "✅ Moved fix-cryptography-layer.sh to layers/"
    fi
    
    if [ -f "../use-aws-cryptography-layer.sh" ]; then
        mv "../use-aws-cryptography-layer.sh" "layers/"
        echo "✅ Moved use-aws-cryptography-layer.sh to layers/"
    fi
    
    # Create security-hub directory if it doesn't exist
    mkdir -p security-hub
    
    # Move security hub scripts
    if [ -d "../security-hub" ]; then
        mv "../security-hub"/* "security-hub/" 2>/dev/null || true
        echo "✅ Moved security hub scripts"
    fi
}

# Update file permissions
update_permissions() {
    echo -e "${YELLOW}🔐 Updating file permissions...${NC}"
    
    # Make all shell scripts executable
    find . -name "*.sh" -type f -exec chmod +x {} \;
    echo "✅ Made shell scripts executable"
    
    # Make Python files readable
    find . -name "*.py" -type f -exec chmod 644 {} \;
    echo "✅ Updated Python file permissions"
}

# Create new structure
create_new_structure() {
    echo -e "${YELLOW}🏗️  Creating new directory structure...${NC}"
    
    # Create new directories
    mkdir -p lambda
    mkdir -p layers
    mkdir -p security-hub
    mkdir -p github
    
    echo "✅ Created new directory structure"
}

# Generate summary
generate_summary() {
    echo -e "${GREEN}📋 Cleanup Summary:${NC}"
    echo "  ✅ Backed up old files to: $BACKUP_DIR"
    echo "  ✅ Removed old deployment packages"
    echo "  ✅ Organized files into proper directories"
    echo "  ✅ Updated file permissions"
    echo "  ✅ Created new directory structure"
    echo ""
    echo -e "${BLUE}📁 New Directory Structure:${NC}"
    echo "  deployment/"
    echo "  ├── README.md"
    echo "  ├── lambda/"
    echo "  │   ├── deploy-clean.sh"
    echo "  │   ├── deploy-arm64.sh"
    echo "  │   └── enhanced-auto-remediation-lambda.py"
    echo "  ├── layers/"
    echo "  │   ├── create-cryptography-layer.sh"
    echo "  │   └── fix-cryptography-layer.sh"
    echo "  ├── security-hub/"
    echo "  └── github/"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "  1. Test the new clean deployment script"
    echo "  2. Update GitHub Actions to use the new workflow"
    echo "  3. Remove old files from backup if everything works"
    echo "  4. Update documentation to reflect new structure"
}

# Main execution
main() {
    backup_old_files
    remove_old_files
    organize_files
    update_permissions
    create_new_structure
    generate_summary
    
    echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
}

# Run main function
main "$@" 