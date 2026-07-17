#!/bin/sh
# lib/strategy.sh - Strategy generation for zapret2

# Generates the multi-line NFQWS2_OPT block based on provided arguments
# Usage: Strategy_Generate_Opt <strategy_mode> <ports_tcp> [custom_opt]
Strategy_Generate_Opt() {
    local mode="$1"
    local ports_tcp="${2:-443}"
    local custom_opt="$3"
    
    # In zapret2, NFQWS2_OPT can be multiline and utilizes Lua strategies
    local opt="--filter-tcp=$ports_tcp --hostlist=<HOSTLIST>"
    
    case "$mode" in
        fake)
            # Example zapret2 fake strategy using lua-desync
            opt="${opt} --payload=tls_client_hello --lua-desync=fake --new"
            ;;
        multisplit)
            # Example zapret2 multisplit strategy
            opt="${opt} --payload=tls_client_hello --lua-desync=fake,multisplit --new"
            ;;
        custom)
            # Translate Windows batch script syntax to AsusWRT zapret paths
            # 1. Remove Windows line continuations (^)
            # 2. Replace %BIN% with /opt/zapret/files/fake/
            # 3. Replace %LISTS% with /opt/zapret/ipset/
            # 4. Fix any backslashes to forward slashes (except escaped quotes or characters if any, but standard is just replacing backslash in paths)
            
            # Using sed for multi-line replacement
            # Also clean up unassigned Windows variables like %GameFilterTCP% to prevent parsing errors
            opt=$(echo "$custom_opt" | tr '\n' ' ' | tr '\r' ' ' | sed -e 's/\^//g' \
                -e 's|%BIN%|/opt/zapret/files/fake/|g' \
                -e 's|%LISTS%|/opt/zapret/ipset/|g' \
                -e 's|\\|/|g' \
                -e 's/,[%][a-zA-Z0-9_]*[%]//g' \
                -e 's/[%][a-zA-Z0-9_]*[%]/443/g')
            ;;
        *)
            opt="${opt} --payload=tls_client_hello --lua-desync=fake --new"
            ;;
    esac
    
    echo "$opt"
}
