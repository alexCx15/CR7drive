#!/bin/bash
# ─────────────────────────────────────────────
# refresh_token.sh  -  Refresca el token OAuth2
# ─────────────────────────────────────────────
CONFIG_DIR="$HOME/backup_gdrive/config"
CREDS="$CONFIG_DIR/credentials.json"
TOKEN_FILE="$CONFIG_DIR/token.json"

CLIENT_ID=$(jq -r '.installed.client_id' "$CREDS")
CLIENT_SECRET=$(jq -r '.installed.client_secret' "$CREDS")
REFRESH_TOKEN=$(jq -r '.refresh_token' "$TOKEN_FILE")

NEW_TOKEN=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "refresh_token=${REFRESH_TOKEN}" \
  -d "grant_type=refresh_token")

# Combinar nuevo access_token con el refresh_token existente
MERGED=$(jq -s '.[0] * .[1]' "$TOKEN_FILE" <(echo "$NEW_TOKEN"))
echo "$MERGED" > "$TOKEN_FILE"

echo "$(jq -r '.access_token' $TOKEN_FILE)"
