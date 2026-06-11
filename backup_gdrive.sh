#!/bin/bash
# ═════════════════════════════════════════════════════════════════════════════
#  backup_gdrive.sh  -  Script de Respaldo Centralizado con Notificación Mail
# ═════════════════════════════════════════════════════════════════════════════

# --- Configuración del Sistema ---
BASE_DIR="$HOME/backup_gdrive"
SCRIPT_DIR="$BASE_DIR/scripts"
LOG_FILE="$BASE_DIR/logs/backup_$(date +%Y%m).log"
TEMP_DIR="$BASE_DIR/temp"
SOURCE_DIR="$HOME/datos"          
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
GDRIVE_FOLDER="Respaldos_Linux"
EMAIL_DESTINO="alexanderrgg44@gmail.com"

# Función de registro de logs
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# --- Función para eliminar respaldos de Drive antiguos (Rotación de 7 días) ---
cleanup_old_backups() {
  local token="$1"
  local folder_id="$2"
  # Obtener fecha de corte (7 días atrás en formato ISO 8601 UTC)
  local fecha_limite=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ")
  
  log "Iniciando política de retención: Buscando respaldos más antiguos que 7 días..."
  
  local search_resp=$(curl -s -H "Authorization: Bearer $token" \
    "https://www.googleapis.com/drive/v3/files?q='${folder_id}'+in+parents+and+modifiedTime+%3C+'${fecha_limite}'+and+trashed=false&fields=files(id,name)")
  
  local files_to_delete=$(echo "$search_resp" | jq -c '.files[]?')
  
  if [ -z "$files_to_delete" ] || [ "$files_to_delete" == "null" ]; then
    log "No se encontraron respaldos obsoletos en Google Drive."
  else
    echo "$files_to_delete" | while read -r file; do
      local file_id=$(echo "$file" | jq -r '.id')
      local file_name=$(echo "$file" | jq -r '.name')
      log "Borrando respaldo obsoleto detectado: $file_name"
      curl -s -X DELETE -H "Authorization: Bearer $token" "https://www.googleapis.com/drive/v3/files/$file_id"
    done
  fi
}

log "======= INICIO DE OPERACIÓN DE RESPALDO ======="

# --- PASO 1: Compresión del Directorio Local ---
log "Comprimiendo carpeta de origen: $SOURCE_DIR..."
tar -czf "$TEMP_DIR/$BACKUP_NAME" -C "$(dirname $SOURCE_DIR)" "$(basename $SOURCE_DIR)" 2>> "$LOG_FILE"

if [ $? -ne 0 ]; then
  log "ERROR CRÍTICO: Falló el empaquetado."
  echo "El respaldo falló durante la compresión." | mail -s "🚨 ERROR Backup" "$EMAIL_DESTINO"
  exit 1
fi

# --- PASO 2: Obtener Pase de Entrada (OAuth Token) ---
ACCESS_TOKEN=$(bash "$SCRIPT_DIR/refresh_token.sh")
if [ -z "$ACCESS_TOKEN" ]; then
  log "ERROR CRÍTICO: No se pudo actualizar el token de Google API."
  echo "Fallo crítico de credenciales OAuth." | mail -s "🚨 ERROR Backup" "$EMAIL_DESTINO"
  exit 1
fi

# --- PASO 3: Gestión de la Carpeta Destino ---
log "Consultando ID de carpeta '$GDRIVE_FOLDER'..."
FOLDER_SEARCH=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "https://www.googleapis.com/drive/v3/files?q=name='$GDRIVE_FOLDER'+and+mimeType='application/vnd.google-apps.folder'+and+trashed=false&fields=files(id,name)")
FOLDER_ID=$(echo "$FOLDER_SEARCH" | jq -r '.files[0].id')

if [ "$FOLDER_ID" == "null" ] || [ -z "$FOLDER_ID" ]; then
  FOLDER_RESP=$(curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d '{"name":"'$GDRIVE_FOLDER'","mimeType":"application/vnd.google-apps.folder"}' https://www.googleapis.com/drive/v3/files)
  FOLDER_ID=$(echo "$FOLDER_RESP" | jq -r '.id')
fi

# --- PASO 4: Carga del Archivo Comprimido ---
log "Subiendo archivo '$BACKUP_NAME' a Google Drive..."
UPLOAD_RESP=$(curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -F "metadata={name:'$BACKUP_NAME',parents:['$FOLDER_ID']};type=application/json" \
  -F "file=@$TEMP_DIR/$BACKUP_NAME;type=application/gzip" \
  https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart)

FILE_ID=$(echo "$UPLOAD_RESP" | jq -r '.id')

if [ "$FILE_ID" == "null" ] || [ -z "$FILE_ID" ]; then
  log "ERROR CRÍTICO: Google Drive rechazó la subida."
  echo "El respaldo falló durante la subida." | mail -s "🚨 ERROR Backup" "$EMAIL_DESTINO"
  exit 1
fi

# --- PASO 5: Aplicar Política de Retención ---
cleanup_old_backups "$ACCESS_TOKEN" "$FOLDER_ID"

# --- PASO 6: Limpieza ---
rm -f "$TEMP_DIR/$BACKUP_NAME"
log "======= RESPALDO DIARIO COMPLETADO EXITOSAMENTE ======="

# --- Notificación SMTP ---
echo "El respaldo automático diario se ha procesado con éxito. 
Nombre del archivo subido: $BACKUP_NAME
Ruta destino en la nube: Drive -> $GDRIVE_FOLDER/" | mail -s "✅ Backup OK - $(date '+%Y-%m-%d')" "$EMAIL_DESTINO"

exit 0
