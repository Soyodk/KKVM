#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="$ROOT_DIR/.runtime"

for name in mta http-cache; do
    pid_file="$RUNTIME_DIR/$name.pid"
    if [[ -f "$pid_file" ]]; then
        pid="$(<"$pid_file")"
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            printf '%s parado (PID %s).\n' "$name" "$pid"
            if command -v timeout >/dev/null 2>&1 && command -v tail >/dev/null 2>&1; then
                if ! timeout 20s tail --pid="$pid" -f /dev/null; then
                    printf '%s ainda está encerrando (PID %s).\n' "$name" "$pid" >&2
                    exit 1
                fi
            fi
        else
            printf '%s já estava parado.\n' "$name"
        fi
        rm -f "$pid_file"
    else
        printf '%s não está registrado como ativo.\n' "$name"
    fi
done

if command -v pwrp >/dev/null 2>&1; then
    pwrp stop MTA >/dev/null 2>&1 || true
    printf 'Túnel MTA do Portwarp parado.\n'
fi