#!/usr/bin/env sh
# start-backend.sh — patch config.ini with environment variables, then start
# the AgenticSeek Python API backend.
#
# The upstream agenticSeek reads provider settings exclusively from config.ini
# rather than from environment variables.  This script rewrites the relevant
# config.ini fields at container startup so that the Docker / Unraid environment
# variables (PROVIDER_NAME, PROVIDER_MODEL, PROVIDER_SERVER_ADDRESS, AGENT_NAME)
# are always respected.
#
# Critical behaviour around is_local / PROVIDER_SERVER_ADDRESS
# ─────────────────────────────────────────────────────────────
# The upstream ollama provider has two connection modes controlled by is_local:
#
#   is_local = True  → only the PORT is taken from server_address; the hostname
#                       is replaced by DOCKER_INTERNAL_URL (defaults to
#                       "http://localhost").  The supplied hostname is ignored.
#
#   is_local = False → host = "http://<server_address>" — the full address is
#                       used as-is.
#
# Therefore, when PROVIDER_SERVER_ADDRESS points to a non-localhost host we must
# set is_local = False so the remote address is honoured.

set -e

CONFIG=/app/config.ini

# ---------------------------------------------------------------------------
# patch_ini <SECTION> <key> <value>
# Sets key=value inside [SECTION] in CONFIG using Python's configparser so that
# the file remains valid INI regardless of special characters in value.
# ---------------------------------------------------------------------------
patch_ini() {
    _section="$1"
    _key="$2"
    _value="$3"
    python3 -c "
import configparser, sys
section, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
config = configparser.ConfigParser()
config.read('$CONFIG')
if not config.has_section(section):
    config.add_section(section)
config.set(section, key, value)
with open('$CONFIG', 'w') as fh:
    config.write(fh)
" "$_section" "$_key" "$_value"
}

# ---------------------------------------------------------------------------
# PROVIDER_NAME
# ---------------------------------------------------------------------------
if [ -n "${PROVIDER_NAME}" ]; then
    patch_ini MAIN provider_name "${PROVIDER_NAME}"
    echo "[start-backend] provider_name    = ${PROVIDER_NAME}"
fi

# ---------------------------------------------------------------------------
# PROVIDER_MODEL
# ---------------------------------------------------------------------------
if [ -n "${PROVIDER_MODEL}" ]; then
    patch_ini MAIN provider_model "${PROVIDER_MODEL}"
    echo "[start-backend] provider_model   = ${PROVIDER_MODEL}"
fi

# ---------------------------------------------------------------------------
# PROVIDER_SERVER_ADDRESS
#
# Strip any http:// or https:// scheme — config.ini expects bare host:port, and
# the upstream code prepends "http://" itself when is_local=False.
#
# Also infer is_local: set to False whenever the host is not 127.0.0.1 /
# localhost so that ollama_fn (and other providers) use the full address rather
# than overriding the hostname with localhost.
# ---------------------------------------------------------------------------
if [ -n "${PROVIDER_SERVER_ADDRESS}" ]; then
    # Strip scheme
    addr="${PROVIDER_SERVER_ADDRESS#http://}"
    addr="${addr#https://}"

    patch_ini MAIN provider_server_address "${addr}"
    echo "[start-backend] provider_server_address = ${addr}"

    # Determine is_local from the host portion of the address.
    # Handle IPv6 bracket notation ([::1]:port) separately from plain host:port.
    if echo "$addr" | grep -q '^\['; then
        # IPv6 bracket notation, e.g. [::1]:11434 or [fe80::1]:11434
        host_part="${addr#[}"
        host_part="${host_part%%]*}"
    else
        host_part="${addr%%:*}"
    fi
    case "$host_part" in
        127.0.0.1|localhost|0.0.0.0|::1)
            patch_ini MAIN is_local "True"
            echo "[start-backend] is_local         = True  (local address detected)"
            ;;
        *)
            patch_ini MAIN is_local "False"
            echo "[start-backend] is_local         = False (remote address detected — full address will be used)"
            ;;
    esac
fi

# ---------------------------------------------------------------------------
# AGENT_NAME
# ---------------------------------------------------------------------------
if [ -n "${AGENT_NAME}" ]; then
    patch_ini MAIN agent_name "${AGENT_NAME}"
    echo "[start-backend] agent_name       = ${AGENT_NAME}"
fi

# ---------------------------------------------------------------------------
# Debug: print the effective [MAIN] section so it appears in container logs
# ---------------------------------------------------------------------------
echo "[start-backend] Effective config.ini [MAIN] section:"
python3 -c "
import configparser
config = configparser.ConfigParser()
config.read('$CONFIG')
for key, val in config.items('MAIN'):
    print(f'  {key} = {val}')
"

exec python3 /app/api.py
