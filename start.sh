#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="$ROOT_DIR/.runtime"
SERVER_DIR="$RUNTIME_DIR/server"

"$ROOT_DIR/setup.sh"
mkdir -p "$RUNTIME_DIR"

start_process() {
    local name="$1"
    local pid_file="$RUNTIME_DIR/$name.pid"
    shift

    if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
        printf '%s já está em execução (PID %s).\n' "$name" "$(<"$pid_file")"
        return
    fi

    rm -f "$pid_file"
    nohup "$@" >> "$RUNTIME_DIR/$name.log" 2>&1 </dev/null &
    printf '%s\n' "$!" > "$pid_file"
    printf '%s iniciado (PID %s). Log: .runtime/%s.log\n' "$name" "$(<"$pid_file")" "$name"
}

start_process mta "$SERVER_DIR/mta-server64" -n -u -D "$SERVER_DIR"

if ! command -v python3 >/dev/null 2>&1; then
    printf 'python3 é necessário para servir os arquivos de download MTA.\n' >&2
    exit 1
fi

HTTP_CACHE_DIR="$SERVER_DIR/mods/deathmatch/resource-cache/http-client-files"
mkdir -p "$HTTP_CACHE_DIR"
start_process http-cache python3 "$ROOT_DIR/http_cache_server.py" --root "$HTTP_CACHE_DIR" --host 0.0.0.0 --port 22003

if ! command -v pwrp >/dev/null 2>&1; then
    printf 'Portwarp CLI (pwrp) não encontrado. Instale e autentique o Portwarp antes de iniciar.\n' >&2
    exit 1
fi

pwrp stop MTA >/dev/null 2>&1 || true
pwrp connect MTA --detach

printf 'Portwarp conectado ao túnel MTA. Portas locais do jogo: UDP/TCP 22003.\n'