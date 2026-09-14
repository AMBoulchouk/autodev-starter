#!/usr/bin/env bash
# driver_helper.sh - Centralized Contract Execution & Utilities for AutoDev POSIX scripts

get_yaml_command() {
    local contract_name="$1"
    local yaml_file=".autodev/runtime.yaml"
    if [ ! -f "$yaml_file" ]; then
        echo ""
        return
    fi
    awk -v cmd="$contract_name" '
        BEGIN { in_cmds = 0 }
        /^commands:/ { in_cmds = 1; next }
        /^[a-zA-Z0-9_]+:/ && !/^commands:/ { in_cmds = 0 }
        in_cmds && $0 ~ ("^[ \t]*" cmd ":") {
            line = $0;
            sub("^[ \t]*" cmd ":[ \t]*", "", line);
            sub(/[ \t]*#.*$/, "", line);
            gsub(/^["\x27]+|["\x27]+$/, "", line);
            gsub(/^[ \t]+|[ \t]+$/, "", line);
            print line;
            exit;
        }
    ' "$yaml_file"
}

get_progress_phase() {
    local state_file=".autodev/state/progress.json"
    if [ -f "$state_file" ]; then
        grep -o '"phase"[[:space:]]*:[[:space:]]*"[^"]*"' "$state_file" | sed -E 's/.*"phase"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' || echo "unknown"
    else
        echo "bootstrap"
    fi
}

invoke_runtime_contract() {
    local contract_name="$1"
    local feature_id="${2:-}"
    local return_code_only="${3:-0}"

    if [ "$return_code_only" -eq 0 ]; then
        echo "========================================="
        echo " [autodev] Contract: $contract_name"
        echo "========================================="
    fi

    local phase
    phase=$(get_progress_phase)
    local has_runtime=0
    [ -f ".autodev/runtime.yaml" ] && has_runtime=1

    if [ "$has_runtime" -eq 0 ] && { [ "$phase" = "bootstrap" ] || [ "$phase" = "specification" ]; }; then
        echo "[autodev:$contract_name:bypass] Phase is '$phase' and runtime.yaml not yet configured. Contract does not apply yet."
        if [ "$return_code_only" -eq 0 ]; then
            echo "========================================="
            exit 0
        fi
        return 0
    fi

    if [ "$has_runtime" -eq 0 ]; then
        echo "[autodev:$contract_name:error] Missing .autodev/runtime.yaml. The Agent must configure the project driver." >&2
        if [ "$return_code_only" -eq 0 ]; then
            echo "========================================="
            exit 1
        fi
        return 1
    fi

    local cmd
    cmd=$(get_yaml_command "$contract_name")

    if [ -z "$cmd" ]; then
        echo "[autodev:$contract_name:info] Contract '$contract_name' is empty in runtime.yaml. No operation performed."
        if [ "$return_code_only" -eq 0 ]; then
            echo "========================================="
            exit 0
        fi
        return 0
    fi

    if [ -n "$feature_id" ]; then
        cmd=$(echo "$cmd" | sed "s/{FEATURE}/$feature_id/g; s/\\\$FEATURE/$feature_id/g")
    fi

    echo "[autodev:$contract_name:exec] $cmd"
    set +e
    eval "$cmd"
    local exit_code=$?
    set -e

    if [ "$return_code_only" -eq 0 ]; then
        echo "========================================="
        if [ $exit_code -ne 0 ]; then
            echo "[autodev:$contract_name:failed] Exit code: $exit_code" >&2
            exit $exit_code
        else
            echo "[autodev:$contract_name:passed] Contract completed successfully."
            exit 0
        fi
    fi

    return $exit_code
}
