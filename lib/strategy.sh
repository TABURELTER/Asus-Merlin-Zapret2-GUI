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
            opt="$custom_opt"
            ;;
        *)
            opt="${opt} --payload=tls_client_hello --lua-desync=fake --new"
            ;;
    esac
    
    echo "$opt"
}
