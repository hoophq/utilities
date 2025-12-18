#!/usr/bin/env bash

# Hoop Config Manager
# Utility to manage and swap between multiple hoop configurations

set -e

CONFIG_DIR="$HOME/.hoop"
CONFIG_FILE="$CONFIG_DIR/config.toml"
CONFIGS_STORE="$CONFIG_DIR/configs"

# Ensure configs store directory exists
mkdir -p "$CONFIGS_STORE"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Hoop Config Manager - Manage multiple hoop configurations

Usage:
    $(basename $0) save <name>       Save current config with a name
    $(basename $0) add <name>        Create a new config interactively
    $(basename $0) load <name>       Load a saved config
    $(basename $0) list              List all saved configs
    $(basename $0) current           Show current active config
    $(basename $0) delete <name>     Delete a saved config
    $(basename $0) help              Show this help message

Examples:
    $(basename $0) save production   Save current config as 'production'
    $(basename $0) add staging       Create a new 'staging' config
    $(basename $0) load dev          Switch to 'dev' config
    $(basename $0) list              Show all saved configs
EOF
}

save_config() {
    local name="$1"

    if [ -z "$name" ]; then
        echo -e "${RED}Error: Config name required${NC}"
        echo "Usage: $(basename $0) save <name>"
        exit 1
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: No config file found at $CONFIG_FILE${NC}"
        exit 1
    fi

    cp "$CONFIG_FILE" "$CONFIGS_STORE/$name.toml"
    echo -e "${GREEN}✓${NC} Saved current config as '${BLUE}$name${NC}'"
}

add_config() {
    local name="$1"

    if [ -z "$name" ]; then
        echo -e "${RED}Error: Config name required${NC}"
        echo "Usage: $(basename $0) add <name>"
        exit 1
    fi

    local config_path="$CONFIGS_STORE/$name.toml"

    if [ -f "$config_path" ]; then
        echo -e "${RED}Error: Config '$name' already exists${NC}"
        echo "Use 'delete $name' first if you want to replace it"
        exit 1
    fi

    echo -e "${BLUE}Creating new config '${name}'${NC}"
    echo ""

    # Prompt for API URL
    read -p "API URL (e.g., https://demo.hoop.dev): " api_url
    if [ -z "$api_url" ]; then
        echo -e "${RED}Error: API URL is required${NC}"
        exit 1
    fi

    # Extract hostname from API URL for default gRPC URL
    local hostname=$(echo "$api_url" | sed -E 's|^https?://||' | sed -E 's|/.*$||' | sed -E 's|:.*$||')
    local default_grpc="grpcs://${hostname}:8443"

    # Prompt for gRPC URL (optional)
    read -p "gRPC URL [${default_grpc}]: " grpc_url
    grpc_url=${grpc_url:-$default_grpc}

    # Prompt for TLS CA (optional)
    read -p "TLS CA path (optional, press Enter to skip): " tls_ca

    # Prompt for skip TLS verify
    read -p "Skip TLS verification? (true/false) [false]: " skip_tls
    skip_tls=${skip_tls:-false}

    # Create the config file
    cat > "$config_path" << EOF
api_url = "$api_url"
grpc_url = "$grpc_url"
EOF

    if [ -n "$tls_ca" ]; then
        echo "tls_ca = \"$tls_ca\"" >> "$config_path"
    fi

    echo "skip_tls_verify = $skip_tls" >> "$config_path"

    echo ""
    echo -e "${GREEN}✓${NC} Created config '${BLUE}$name${NC}'"
    echo ""
    echo -e "${YELLOW}Preview:${NC}"
    cat "$config_path"
}

load_config() {
    local name="$1"

    if [ -z "$name" ]; then
        echo -e "${RED}Error: Config name required${NC}"
        echo "Usage: $(basename $0) load <name>"
        exit 1
    fi

    local config_path="$CONFIGS_STORE/$name.toml"

    if [ ! -f "$config_path" ]; then
        echo -e "${RED}Error: Config '$name' not found${NC}"
        echo "Available configs:"
        list_configs
        exit 1
    fi

    # Backup current config
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    fi

    cp "$config_path" "$CONFIG_FILE"
    echo -e "${GREEN}✓${NC} Switched to config '${BLUE}$name${NC}'"
    echo ""
    show_current_config
}

list_configs() {
    if [ ! -d "$CONFIGS_STORE" ] || [ -z "$(ls -A $CONFIGS_STORE)" ]; then
        echo -e "${YELLOW}No saved configs found${NC}"
        return
    fi

    echo -e "${BLUE}Saved configurations:${NC}"
    echo ""

    for config in "$CONFIGS_STORE"/*.toml; do
        if [ -f "$config" ]; then
            local name=$(basename "$config" .toml)
            local api_url=$(grep "^api_url" "$config" | cut -d'"' -f2)
            echo -e "  • ${GREEN}$name${NC}"
            if [ -n "$api_url" ]; then
                echo -e "    API: $api_url"
            fi
        fi
    done
}

get_current_config_name() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        return
    fi

    # Compare current config with all saved configs
    for config in "$CONFIGS_STORE"/*.toml; do
        if [ -f "$config" ]; then
            if diff -q "$CONFIG_FILE" "$config" > /dev/null 2>&1; then
                basename "$config" .toml
                return
            fi
        fi
    done

    echo "custom"
}

show_current_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}No active config found${NC}"
        return
    fi

    echo -e "${BLUE}Current configuration:${NC}"
    echo ""

    local api_url=$(grep "^api_url" "$CONFIG_FILE" | cut -d'"' -f2)
    local grpc_url=$(grep "^grpc_url" "$CONFIG_FILE" | cut -d'"' -f2)
    local tls_ca=$(grep "^tls_ca" "$CONFIG_FILE" | cut -d'"' -f2)
    local skip_tls=$(grep "^skip_tls_verify" "$CONFIG_FILE" | awk '{print $3}')

    echo -e "  API URL:       ${GREEN}$api_url${NC}"
    echo -e "  gRPC URL:      $grpc_url"
    [ -n "$tls_ca" ] && echo -e "  TLS CA:        $tls_ca"
    echo -e "  Skip TLS:      $skip_tls"
}

show_status() {
    local current_name=$(get_current_config_name)

    if [ -z "$current_name" ]; then
        echo -e "${YELLOW}No active config${NC}"
    else
        if [ "$current_name" = "custom" ]; then
            echo -e "${BLUE}Currently loaded:${NC} ${YELLOW}custom (unsaved)${NC}"
        else
            echo -e "${BLUE}Currently loaded:${NC} ${GREEN}$current_name${NC}"
        fi
    fi

    echo ""
    list_configs
}

delete_config() {
    local name="$1"

    if [ -z "$name" ]; then
        echo -e "${RED}Error: Config name required${NC}"
        echo "Usage: $(basename $0) delete <name>"
        exit 1
    fi

    local config_path="$CONFIGS_STORE/$name.toml"

    if [ ! -f "$config_path" ]; then
        echo -e "${RED}Error: Config '$name' not found${NC}"
        exit 1
    fi

    rm "$config_path"
    echo -e "${GREEN}✓${NC} Deleted config '${BLUE}$name${NC}'"
}

# Main command routing
case "${1:-}" in
    save)
        save_config "$2"
        ;;
    add)
        add_config "$2"
        ;;
    load)
        load_config "$2"
        ;;
    list)
        list_configs
        ;;
    current)
        show_current_config
        ;;
    delete)
        delete_config "$2"
        ;;
    help|--help|-h)
        usage
        ;;
    "")
        show_status
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        usage
        exit 1
        ;;
esac
