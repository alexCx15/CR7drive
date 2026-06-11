📌 ¿De qué trata este proyecto?

CR7drive automatiza la creación, compresión y subida de copias de seguridad desde un servidor Linux directamente a Google Drive. Corre nativamente en Bash Scripting y utiliza la API oficial de Google Drive.

✨ Características

📦 Empaquetado Seguro: Comprime la carpeta de origen en .tar.gz con fecha/hora.

☁️ Integración Nativa: Subida directa a Google Drive vía API.

🔄 Autenticación Autónoma: Script integrado para refrescar el Access Token silenciosamente.

🧹 Rotación (7 días): Elimina automáticamente archivos de respaldo antiguos en la nube.

📧 Notificaciones SMTP: Alertas por correo (Postfix) al administrador.

📁 Estructura del Proyecto

backup_gdrive/
├── config/       # (Ignorado de GitHub) credentials.json y token.json
├── scripts/      # Scripts principales de Bash (.sh)
├── temp/         # Carpeta de almacenamiento temporal
└── logs/         # Historial de actividades del sistema


⚠️ Seguridad

Los archivos credentials.json y token.json NO están incluidos en este repositorio por seguridad. Debes generar tus propias credenciales OAuth 2.0 desde Google Cloud Console.
