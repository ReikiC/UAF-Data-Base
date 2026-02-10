#!/bin/bash
# Universal Agent Database Health Check Script
#
# Usage:
#   ./scripts/check.sh                     # Basic health check
#   ./scripts/check.sh detailed            # Detailed health check

set -e

# Configuration
DB_CONTAINER="${DB_CONTAINER:-uaf-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-universal_agent}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}==>${NC} $1"
}

check_container() {
    log_section "Container Status"
    if docker ps | grep -q "$DB_CONTAINER"; then
        log_info "Container is running: $DB_CONTAINER"
        docker ps --filter "name=$DB_CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_error "Container is not running: $DB_CONTAINER"
        exit 1
    fi
}

check_database() {
    log_section "Database Connection"
    if docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
        log_info "Database is ready: $DB_NAME"
    else
        log_error "Database is not ready"
        exit 1
    fi
}

check_version() {
    log_section "PostgreSQL Version"
    local version=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT version();" | head -n 1)
    echo "$version"
}

check_size() {
    log_section "Database Size"
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT
    datname AS database,
    pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
WHERE datname = '$DB_NAME';
"
}

check_connections() {
    log_section "Active Connections"
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT
    state,
    count(*) AS connections
FROM pg_stat_activity
WHERE datname = '$DB_NAME'
GROUP BY state
ORDER BY state;
"
}

check_tables() {
    log_section "Tables"
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
}

check_extensions() {
    log_section "Installed Extensions"
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT
    extname AS name,
    extversion AS version
FROM pg_extension
ORDER BY extname;
"
}

check_disk_usage() {
    log_section "Disk Usage"
    docker exec "$DB_CONTAINER" df -h /var/lib/postgresql/data
}

detailed_check() {
    check_container
    check_database
    check_version
    check_size
    check_connections
    check_tables
    check_extensions
    check_disk_usage
}

basic_check() {
    check_container
    check_database
    check_version
    check_size
    log_info "All checks passed!"
}

# Main
main() {
    local mode=${1:-basic}

    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║   Universal Agent Database Check   ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    if [ "$mode" = "detailed" ]; then
        detailed_check
    else
        basic_check
    fi

    echo ""
    log_info "Health check completed!"
}

# Run main
main "$@"
