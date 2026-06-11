#!/bin/bash
# ─────────────────────────────────────────────
# auth_gdrive.sh - Script de Vinculación Inicial
# ─────────────────────────────────────────────
CONFIG_DIR="$HOME/backup_gdrive/config"
CREDS="$CONFIG_DIR/credentials.json"
TOKEN_FILE="$CONFIG_DIR/token.json"

CLIENT_ID=$(jq -r '.installed.client_id' "$CREDS")
CLIENT_SECRET=$(jq -r '.installed.client_secret' "$CREDS")
REDIRECT_URI="http://localhost"

echo "=================================================="
echo "Abra la siguiente URL en su navegador:"
echo "https://accounts.google.com/o/oauth2/v2/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=https://www.googleapis.com/auth/drive.file&access_type=offline&prompt=consent"
echo "=================================================="
echo ""
echo "NOTA: El navegador dirá 'No se puede acceder a este sitio'."
echo "Debe copiar SOLO el texto que aparece en la barra de direcciones DESPUES de 'code=' y ANTES de '&scope'."
echo ""
read -p "Pegue el codigo de autorizacion aqui: " AUTH_CODE

# Limpiar el código por si trae algún '&' accidental
AUTH_CODE=$(echo "$AUTH_CODE" | cut -d'&' -f1)

# Intercambiar código por token
curl -s -X POST https://oauth2.googleapis.com/token \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "code=${AUTH_CODE}" \
  -d "redirect_uri=${REDIRECT_URI}" \
  -d "grant_type=authorization_code" > "$TOKEN_FILE"

echo "Token guardado correctamente en $TOKEN_FILE"
