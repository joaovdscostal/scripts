#!/bin/bash
# ============================================================================
# SCRIPT DE DEBUG - CONFIGURAÇÃO RCLONE
# ============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "========================================"
echo "DEBUG RCLONE - DIGITALOCEAN SPACES"
echo "========================================"
echo ""

# Carregar config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

echo "1. Configurações do backup.conf"
echo "----------------------------------------"
log_info "RCLONE_REMOTE: ${RCLONE_REMOTE}"
log_info "S3_BUCKET: ${S3_BUCKET}"
log_info "S3_PATH: ${S3_PATH}"
echo ""

echo "2. Configuração do rclone"
echo "----------------------------------------"
log_info "Mostrando configuração do remote '${RCLONE_REMOTE}'"
echo ""
rclone config show "${RCLONE_REMOTE}" || log_error "Remote não encontrado"
echo ""

echo "3. Testando diferentes paths"
echo "----------------------------------------"

# Teste 1: Listar bucket raiz
log_info "Teste 1: Listar bucket raiz"
echo "Comando: rclone lsd ${RCLONE_REMOTE}:"
rclone lsd "${RCLONE_REMOTE}:" 2>&1 | head -20
echo ""

# Teste 2: Listar bucket específico
log_info "Teste 2: Listar dentro do bucket '${S3_BUCKET}'"
echo "Comando: rclone lsd ${RCLONE_REMOTE}:${S3_BUCKET}"
rclone lsd "${RCLONE_REMOTE}:${S3_BUCKET}" 2>&1 | head -20
echo ""

# Teste 3: Listar arquivos no path completo
log_info "Teste 3: Listar arquivos em '${S3_BUCKET}/${S3_PATH}'"
echo "Comando: rclone ls ${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}"
rclone ls "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}" 2>&1 | head -20
echo ""

# Teste 4: Tentar criar arquivo
log_info "Teste 4: Tentar enviar arquivo de teste"
echo "teste $(date)" > /tmp/rclone-test.txt
echo "Comando: rclone copy /tmp/rclone-test.txt ${RCLONE_REMOTE}:${S3_BUCKET}/test/"
rclone copy /tmp/rclone-test.txt "${RCLONE_REMOTE}:${S3_BUCKET}/test/" --verbose 2>&1 | head -10
rm -f /tmp/rclone-test.txt
echo ""

echo "4. Verificar ACL e Permissões"
echo "----------------------------------------"
log_warning "Se os testes acima falharam com 403, o problema pode ser:"
echo "  1. API Key sem permissões de escrita"
echo "  2. Bucket ACL configurado incorretamente"
echo "  3. Configuração do rclone com endpoint errado"
echo ""
log_info "Próximos passos:"
echo "  1. Vá no DigitalOcean → API → Spaces Access Keys"
echo "  2. Crie uma NOVA key com permissões: Read + Write + Delete"
echo "  3. Execute: rclone config"
echo "  4. Atualize o remote '${RCLONE_REMOTE}' com a nova Access Key e Secret Key"
echo ""

exit 0
