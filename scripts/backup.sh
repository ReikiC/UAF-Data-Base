#!/bin/bash
# Universal Agent Database Backup Script
#
# Usage:
#   ./scripts/backup.sh                    # Interactive backup
#   ./scripts/backup.sh auto               # Automated backup (with retention)
#   ./scripts/backup.sh manual description  # Manual backup with description

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
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

backup_database() {
    local backup_type=$1
    local description=$2

    if [ "$backup_type" = "auto" ]; then
        local filename="auto-${TIMESTAMP}.dump"
    else
        local filename="manual-${TIMESTAMP}"
        if [ -n "$description" ]; then
            filename="${filename}-${description}"
        fi
        filename="${filename}.dump"
    fi

    local backup_path="${BACKUP_DIR}/${filename}"

    log_info "Starting backup: $filename"
    log_info "Database: $DB_NAME"

    if docker exec "${DB_CONTAINER}" pg_dump -U "$DB_USER" -Fc "$DB_NAME" > "$backup_path"; then
        local size=$(du -h "$backup_path" | cut -f1)
        log_info "Backup completed: $backup_path ($size)"
        echo "$backup_path"
    else
        log_error "Backup failed"
        exit 1
    fi
}

cleanup_old_backups() {
    log_info "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."

    local old_backups=$(find "${BACKUP_DIR}" -name "auto-*.dump" -type f -mtime +${RETENTION_DAYS})

    if [ -z "$old_backups" ]; then
        log_info "No old backups to clean up"
        return
    fi

    echo "$old_backups" | while read -r backup; do
        log_warn "Removing old backup: $(basename "$backup")"
        rm "$backup"
    done

    local count=$(echo "$old_backups" | wc -l)
    log_info "Removed $count old backup(s)"
}

show_backup_list() {
    log_info "Current backups:"
    echo ""
    printf "%-40s %-15s %10s\n" "Filename" "Date" "Size"
    printf "%-40s %-15s %10s\n" "--------------------------------" "---------------" "----------"

    find "${BACKUP_DIR}" -name "*.dump" -type f | sort -r | while read -r backup; do
        local filename=$(basename "$backup")
        local date=$(stat -f "%Sm" -t "%Y-%m-%d" "$backup" 2>/dev/null || stat -c "%y" "$backup" | cut -d'.' -f1)
        local size=$(du -h "$backup" | cut -f1)
        printf "%-40s %-15s %10s\n" "$filename" "$date" "$size"
    done
}

# Main
main() {
    local backup_type=$1
    local description=${2:-""}

    log_info "Universal Agent Database Backup"
    echo "================================"

    check_container
    create_backup_dir

    if [ "$backup_type" = "auto" ]; then
        backup_database "auto"
        cleanup_old_backups
    elif [ "$backup_type" = "manual" ]; then
        backup_database "manual" "$description"
    else
        # Interactive mode
        echo ""
        echo "Select backup type:"
        echo "  1) Manual backup"
        echo "  2) Automated backup (with cleanup)"
        echo "  3) List backups"
        echo "  4) Exit"
        echo ""
        read -p "Choose [1-4]: " choice

        case $choice in
            1)
                read -p "Description (optional): " desc
                backup_database "manual" "$desc"
                ;;
            2)
                backup_database "auto"
                cleanup_old_backups
                ;;
            3)
                show_backup_list
                ;;
            4)
                log_info "Exiting"
                exit 0
                ;;
            *)
                log_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

# Run main
main "$@"
