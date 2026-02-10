#!/bin/bash
# Universal Agent Database Restore Script
#
# Usage:
#   ./scripts/restore.sh                   # Interactive restore
#   ./scripts/restore.sh <backup-file>     # Restore from file

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"

# Load environment variables
if [ -f "${PROJECT_DIR}/.env" ]; then
    source "${PROJECT_DIR}/.env"
fi

# Defaults
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-universal_agent}"
DB_CONTAINER="${DB_CONTAINER:-uaf-postgres}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_container() {
    if ! docker ps | grep -q "${DB_CONTAINER}"; then
        log_error "Container ${DB_CONTAINER} is not running"
        exit 1
    fi
}

list_backups() {
    log_info "Available backups:"
    echo ""

    local backups=($(find "${BACKUP_DIR}" -name "*.dump" -type f | sort -r))
    local i=1

    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null || stat -c "%y" "$backup" | cut -d'.' -f1)
        printf "%2d) %-40s %10s  %s\n" "$i" "$filename" "$size" "$date"
        ((i++))
    done

    echo ""
}

restore_backup() {
    local backup_path=$1

    if [ ! -f "$backup_path" ]; then
        log_error "Backup file not found: $backup_path"
        exit 1
    fi

    local filename=$(basename "$backup_path")

    log_warn "You are about to restore the database from:"
    log_warn "  $filename"
    echo ""
    log_warn "This will REPLACE all existing data in the database!"
    echo ""
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "Restore cancelled"
        exit 0
    fi

    log_info "Starting restore..."
    log_info "Backup: $filename"
    log_info "Database: $DB_NAME"

    # Drop and recreate database
    log_info "Resetting database..."
    docker exec "${DB_CONTAINER}" psql -U "$DB_USER" -d postgres <<EOF
DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME};
EOF

    # Restore from backup
    log_info "Restoring data..."
    if docker exec -i "${DB_CONTAINER}" pg_restore -U "$DB_USER" -d "$DB_NAME" < "$backup_path"; then
        log_info "Restore completed successfully!"
    else
        log_error "Restore failed"
        exit 1
    fi
}

# Main
main() {
    local backup_file=$1

    log_info "Universal Agent Database Restore"
    echo "=================================="
    echo ""

    check_container

    if [ -n "$backup_file" ]; then
        # Direct restore
        if [ ! -f "$backup_file" ]; then
            # Try relative to backups dir
            backup_file="${BACKUP_DIR}/${backup_file}"
        fi
        restore_backup "$backup_file"
    else
        # Interactive mode
        list_backups

        local backups=($(find "${BACKUP_DIR}" -name "*.dump" -type f | sort -r))
        local count=${#backups[@]}

        if [ $count -eq 0 ]; then
            log_error "No backups found in $BACKUP_DIR"
            exit 1
        fi

        echo ""
        read -p "Select backup to restore [1-$count] (0 to exit): " choice

        if [ "$choice" = "0" ]; then
            log_info "Exiting"
            exit 0
        fi

        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
            log_error "Invalid choice"
            exit 1
        fi

        local selected_backup="${backups[$((choice-1))]}"
        restore_backup "$selected_backup"
    fi
}

# Run main
main "$@"
