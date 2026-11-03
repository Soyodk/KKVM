#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="$ROOT_DIR/.runtime"
SERVER_DIR="$RUNTIME_DIR/server"
TEMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

for command_name in curl tar; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Dependência ausente: %s\n' "$command_name" >&2
        exit 1
    fi
done

if [[ "$(uname -m)" != "x86_64" ]]; then
    printf 'Este setup requer Codespace Linux x86_64; arquitetura detectada: %s\n' "$(uname -m)" >&2
    exit 1
fi

mkdir -p "$SERVER_DIR"

if [[ ! -x "$SERVER_DIR/mta-server64" ]]; then
    printf 'Baixando servidor MTA oficial...\n'
    curl -fL --retry 3 https://linux.multitheftauto.com/dl/multitheftauto_linux_x64.tar.xz -o "$TEMP_DIR/mta-server.tar.xz"
    tar -xJf "$TEMP_DIR/mta-server.tar.xz" -C "$TEMP_DIR"
    cp -a "$TEMP_DIR/multitheftauto_linux_x64/." "$SERVER_DIR/"
fi

if [[ ! -d "$SERVER_DIR/mods/deathmatch/resources/[gamemodes]" ]]; then
    printf 'Baixando recursos padrão oficiais do MTA...\n'
    mkdir -p "$SERVER_DIR/mods/deathmatch/resources"
    curl -fL --retry 3 https://codeload.github.com/multitheftauto/mtasa-resources/tar.gz/refs/heads/master -o "$TEMP_DIR/mtasa-resources.tar.gz"
    tar -xzf "$TEMP_DIR/mtasa-resources.tar.gz" --strip-components=1 -C "$SERVER_DIR/mods/deathmatch/resources"
fi

mkdir -p "$SERVER_DIR/mods/deathmatch"
cp "$ROOT_DIR/config/mtaserver.conf" "$SERVER_DIR/mods/deathmatch/mtaserver.conf"
if [[ ! -f "$SERVER_DIR/mods/deathmatch/acl.xml" ]]; then
    printf 'Baixando ACL padrão oficial do MTA...\n'
    curl -fL --retry 3 https://raw.githubusercontent.com/multitheftauto/mtasa-blue/master/Server/mods/deathmatch/acl.xml -o "$SERVER_DIR/mods/deathmatch/acl.xml"
fi

ACL_FILE="$SERVER_DIR/mods/deathmatch/acl.xml"
sed -i '/autoGroup_goiaba_auto_start/d; /autoACL_goiaba_auto_start/d' "$ACL_FILE"
sed -i '/<object name="resource.goiaba_auto_start">/d; /<object name="resource.goiaba_login">/d' "$ACL_FILE"
sed -i '/<group name="Moderator">/a\        <object name="resource.goiaba_auto_start"></object>\n        <object name="resource.goiaba_login"></object>' "$ACL_FILE"
sed -i '/^    <acl name="Moderator">/,/^    <\/acl>/ { /<right name="function.addAccount"/d; }' "$ACL_FILE"
sed -i '/^    <acl name="Moderator">$/a\        <right name="function.addAccount" access="true"></right>' "$ACL_FILE"
if ! grep -Fq '<object name="user.ruaan">' "$ACL_FILE"; then
    sed -i '/<group name="Admin">/a\        <object name="user.ruaan"></object>' "$ACL_FILE"
fi

PACK_ARCHIVE="$ROOT_DIR/[ND]GOIABARP.rar"
PACK_MARKER="$RUNTIME_DIR/.goiabarp-installed"
if [[ -f "$PACK_ARCHIVE" && ! -f "$PACK_MARKER" ]]; then
    if ! command -v bsdtar >/dev/null 2>&1 || ! command -v sqlite3 >/dev/null 2>&1; then
        printf 'Para instalar o pacote RAR, instale bsdtar e sqlite3.\n' >&2
        exit 1
    fi

    PACK_STAGE="$TEMP_DIR/goiaba-pack"
    PACK_ROOT="$PACK_STAGE/[ND]GOIABARP"
    RESOURCE_DIR="$SERVER_DIR/mods/deathmatch/resources"
    mkdir -p "$PACK_STAGE" "$RESOURCE_DIR"
    printf 'Extraindo recursos do pacote Goiaba RP...\n'
    bsdtar --no-same-owner --no-same-permissions -xf "$PACK_ARCHIVE" -C "$PACK_STAGE"
    cp -a "$PACK_ROOT/[mods]/." "$RESOURCE_DIR/"
    cp -a "$PACK_ROOT/[mapas]/." "$RESOURCE_DIR/"
    cp -a "$PACK_ROOT/alpha_fix_shader-main" "$RESOURCE_DIR/"

    DUPLICATE_MAP="$RESOURCE_DIR/[ Lua ]/Lodz_Astronauta"
    if [[ -d "$DUPLICATE_MAP" && -d "$RESOURCE_DIR/Lodz_Astronauta" ]]; then
        mkdir -p "$RUNTIME_DIR/package-disabled"
        if [[ -d "$RUNTIME_DIR/package-disabled/Lodz_Astronauta-group-copy" ]]; then
            rm -rf "$DUPLICATE_MAP"
        else
            mv "$DUPLICATE_MAP" "$RUNTIME_DIR/package-disabled/Lodz_Astronauta-group-copy"
        fi
    fi

    LOGIN_DB="$RESOURCE_DIR/goiaba_login/dados.db"
    if [[ -f "$LOGIN_DB" ]]; then
        sqlite3 "$LOGIN_DB" 'DELETE FROM accounts;'
    fi

    find "$RESOURCE_DIR" -type f -name '*.lua' -print0 | xargs -0 -r perl -pi -e \
        's#https?://discord(app)?\.com/api/webhooks/[^\s"\x27]+#https://discord.com/api/webhooks/RECONFIGURE#g; s#((?:\[\s*)?(?:Authorization|\x27Authorization\x27|"Authorization")(?:\s*\])?\s*=\s*)(\x27|")[^\x27"]*\2#$1$2RECONFIGURE$2#gi; s#(tokenMP\s*=\s*)(\x27|")[^\x27"]*\2#$1$2RECONFIGURE$2#gi; s#http://91\.108\.125\.169:[0-9]+#http://127.0.0.1:1#g; s#(mtasa://)91\.108\.125\.169#$1127.0.0.1#g'

    RECIVEWEB_CONFIG="$RESOURCE_DIR/goiaba_reciveweb/config.lua"
    if [[ -f "$RECIVEWEB_CONFIG" ]]; then
        sed -E -i "s/(ID_STORE[[:space:]]*=[[:space:]]*)[^,;]+/\\1''/" "$RECIVEWEB_CONFIG"
    fi

    LOGIN_SERVER="$RESOURCE_DIR/goiaba_login/caioS.lua"
    if [[ -f "$LOGIN_SERVER" ]]; then
        sed -i 's#fetchRemote("http://91\.108\.125\.169:1722/api/email/send", sendOptions, function(...) end)#outputDebugString("Password recovery email endpoint disabled; configure your own service", 2)#' "$LOGIN_SERVER"
    fi

    touch "$PACK_MARKER"
    printf 'Recursos importados. Integrações externas antigas foram desativadas.\n'
fi

RESOURCE_DIR="$SERVER_DIR/mods/deathmatch/resources"
OWNER_RESOURCE_DIR="$RESOURCE_DIR/owner_perks"
mkdir -p "$OWNER_RESOURCE_DIR/assets/models"
cp -a "$ROOT_DIR/owner-perks/." "$OWNER_RESOURCE_DIR/"

for model in 411 541 415 585 522 461 521 468; do
    for extension in dff txd; do
        model_file="$SERVER_DIR/mods/deathmatch/resources/goiaba_mods/assets/mods/$model.$extension"
        if [[ ! -f "$model_file" ]]; then
            printf 'Modelo customizado ausente: %s\n' "$model_file" >&2
            exit 1
        fi
        cp "$model_file" "$OWNER_RESOURCE_DIR/assets/models/$model.$extension"
    done
done

DEALERSHIP_DB="$RESOURCE_DIR/goiaba_Concessionaria/assets/database/dados.db"
if [[ -f "$DEALERSHIP_DB" ]]; then
    sqlite3 "$DEALERSHIP_DB" "DELETE FROM Vehicles_Concessionaria WHERE user = 'ruaan' AND model IN (516, 560);"
fi

AUTOSTART_DB="$RESOURCE_DIR/goiaba_auto_start/resources.db"
if [[ -f "$AUTOSTART_DB" ]]; then
    if ! command -v sqlite3 >/dev/null 2>&1; then
        printf 'sqlite3 é necessário para registrar o recurso de benefícios no autostart.\n' >&2
        exit 1
    fi
    sqlite3 "$AUTOSTART_DB" "INSERT INTO scripts(name) SELECT 'owner_perks' WHERE NOT EXISTS (SELECT 1 FROM scripts WHERE name = 'owner_perks');"
fi

if ! sed -n '/<group name="Admin">/,/<\/group>/p' "$ACL_FILE" | grep -Fq '<object name="user.ruaan">'; then
    sed -i '/<group name="Admin">/a\        <object name="user.ruaan"></object>' "$ACL_FILE"
fi
if ! sed -n '/<group name="Console">/,/<\/group>/p' "$ACL_FILE" | grep -Fq '<object name="user.ruaan">'; then
    sed -i '/<group name="Console">/a\        <object name="user.ruaan"></object>' "$ACL_FILE"
fi

printf 'Setup concluído. Arquivos locais: %s\n' "$RUNTIME_DIR"