#!/bin/bash
# ============================================================================
# SCRIPT DE TESTE - LIMPEZA DE DUPLICADOS S3
# ============================================================================
# Este script testa APENAS a lógica de remover duplicados do mesmo dia
# ============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_action() {
    echo -e "${CYAN}➜${NC} $1"
}

echo "========================================"
echo "TESTE DE LIMPEZA DE DUPLICADOS S3"
echo "========================================"
echo ""

# ============================================================================
# CARREGAR CONFIGURAÇÕES
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

echo "Configurações:"
echo "  RCLONE_REMOTE: ${RCLONE_REMOTE}"
echo "  S3_BUCKET: ${S3_BUCKET}"
echo "  S3_PATH: ${S3_PATH}"
echo "  S3_RETENTION_COUNT: ${S3_RETENTION_COUNT}"
echo ""

# ============================================================================
# LISTAR BACKUPS ATUAIS
# ============================================================================

echo "1. Listando Backups Atuais no S3"
echo "========================================"

# Testar diferentes combinações de path
log_info "Testando path: ${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/"
echo ""

set +e
set +o pipefail

# Tentar com bucket/path
S3_BACKUPS=$(rclone lsf "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/" 2>&1 | grep "^backup-vps-" | sort -r)
if [ -z "$S3_BACKUPS" ]; then
    log_warning "Vazio com: ${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/"

    # Tentar só com path
    log_info "Testando path: ${RCLONE_REMOTE}:${S3_PATH}/"
    S3_BACKUPS=$(rclone lsf "${RCLONE_REMOTE}:${S3_PATH}/" 2>&1 | grep "^backup-vps-" | sort -r)

    if [ -z "$S3_BACKUPS" ]; then
        log_warning "Vazio com: ${RCLONE_REMOTE}:${S3_PATH}/"

        # Listar tudo que tem
        log_info "Listando TUDO no remote para debug:"
        echo "Comando: rclone lsf ${RCLONE_REMOTE}: --max-depth 3"
        rclone lsf "${RCLONE_REMOTE}:" --max-depth 3 2>&1 | head -50
        echo ""
        log_error "Não foi possível encontrar backups. Verifique o path acima."
        exit 1
    else
        log_ok "Encontrado com: ${RCLONE_REMOTE}:${S3_PATH}/"
        # Atualizar variáveis para usar o path correto
        S3_FULL_PATH="${S3_PATH}"
    fi
else
    log_ok "Encontrado com: ${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/"
    S3_FULL_PATH="${S3_BUCKET}/${S3_PATH}"
fi

set -e
set -o pipefail

if [ -z "$S3_BACKUPS" ]; then
    log_warning "Nenhum backup encontrado!"
    exit 0
fi

echo "$S3_BACKUPS" | nl -w3 -s'. '
echo ""

TOTAL_FILES=$(echo "$S3_BACKUPS" | wc -l | tr -d ' ')
log_info "Total de arquivos: $TOTAL_FILES"
echo ""

# ============================================================================
# ANALISAR DUPLICADOS
# ============================================================================

echo "2. Analisando Duplicados por Data"
echo "========================================"

# Criar array associativo para contar por data
declare -A DATE_COUNT
declare -A DATE_FILES

while IFS= read -r FILENAME; do
    if [ -z "$FILENAME" ]; then
        continue
    fi

    # Extrair data (YYYYMMDD)
    FILE_DATE=$(echo "$FILENAME" | sed -n 's/backup-vps-\([0-9]\{8\}\).*/\1/p')

    if [ -n "$FILE_DATE" ]; then
        # Incrementar contador
        DATE_COUNT[$FILE_DATE]=$((${DATE_COUNT[$FILE_DATE]:-0} + 1))

        # Adicionar arquivo à lista
        if [ -z "${DATE_FILES[$FILE_DATE]:-}" ]; then
            DATE_FILES[$FILE_DATE]="$FILENAME"
        else
            DATE_FILES[$FILE_DATE]="${DATE_FILES[$FILE_DATE]}"$'\n'"$FILENAME"
        fi
    fi
done <<< "$S3_BACKUPS"

echo "Resumo por data:"
echo ""

DUPLICATES_FOUND=false

for DATE in "${!DATE_COUNT[@]}"; do
    COUNT=${DATE_COUNT[$DATE]}

    if [ $COUNT -gt 1 ]; then
        log_warning "Data $DATE: $COUNT backups (DUPLICADOS!)"
        DUPLICATES_FOUND=true

        echo "  Arquivos:"
        echo "${DATE_FILES[$DATE]}" | while read -r FILE; do
            echo "    - $FILE"
        done
        echo ""
    else
        log_ok "Data $DATE: $COUNT backup (OK)"
    fi
done | sort

echo ""

if [ "$DUPLICATES_FOUND" = false ]; then
    log_ok "Nenhum duplicado encontrado!"
    exit 0
fi

# ============================================================================
# SIMULAR LIMPEZA
# ============================================================================

echo "3. Simulação de Limpeza (DRY RUN)"
echo "========================================"

# Limpar marcadores anteriores
rm -f /tmp/.s3_cleanup_sim_* 2>/dev/null || true

DAYS_KEPT=0
FILES_TO_KEEP=0
FILES_TO_DELETE=0

echo "Processando arquivos (ordenados do mais recente ao mais antigo):"
echo ""

while IFS= read -r FILENAME; do
    if [ -z "$FILENAME" ]; then
        continue
    fi

    # Extrair data
    FILE_DATE=$(echo "$FILENAME" | sed -n 's/backup-vps-\([0-9]\{8\}\).*/\1/p')

    if [ -n "$FILE_DATE" ]; then
        # Verificar se já vimos esta data
        if [ ! -f "/tmp/.s3_cleanup_sim_${FILE_DATE}" ]; then
            # Primeira vez vendo esta data - marcar como mantido
            touch "/tmp/.s3_cleanup_sim_${FILE_DATE}"
            DAYS_KEPT=$((DAYS_KEPT + 1))

            if [ $DAYS_KEPT -le $S3_RETENTION_COUNT ]; then
                log_ok "[MANTER] Dia $FILE_DATE (dia #${DAYS_KEPT}): $FILENAME"
                FILES_TO_KEEP=$((FILES_TO_KEEP + 1))
            else
                log_warning "[DELETAR - fora retenção] Dia $FILE_DATE: $FILENAME"
                FILES_TO_DELETE=$((FILES_TO_DELETE + 1))
            fi
        else
            # Backup duplicado do mesmo dia - deletar
            log_error "[DELETAR - duplicado] Dia $FILE_DATE: $FILENAME"
            FILES_TO_DELETE=$((FILES_TO_DELETE + 1))
        fi
    fi
done <<< "$S3_BACKUPS"

# Limpar temporários
rm -f /tmp/.s3_cleanup_sim_* 2>/dev/null || true

echo ""
echo "========================================"
echo "RESUMO"
echo "========================================"
echo "Total de arquivos: $TOTAL_FILES"
echo "Dias diferentes: $DAYS_KEPT"
log_ok "Arquivos a manter: $FILES_TO_KEEP"
log_warning "Arquivos a deletar: $FILES_TO_DELETE"
echo ""

# ============================================================================
# PERGUNTAR SE QUER EXECUTAR
# ============================================================================

if [ $FILES_TO_DELETE -eq 0 ]; then
    log_ok "Nada para deletar!"
    exit 0
fi

echo "========================================"
read -p "Deseja EXECUTAR a limpeza agora? (s/N): " -n 1 -r
echo ""
echo "========================================"

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_info "Operação cancelada. Nenhum arquivo foi deletado."
    exit 0
fi

# ============================================================================
# EXECUTAR LIMPEZA REAL
# ============================================================================

echo ""
echo "4. Executando Limpeza REAL"
echo "========================================"

# Limpar marcadores
rm -f /tmp/.s3_cleanup_real_* 2>/dev/null || true

DAYS_KEPT=0
DELETED_COUNT=0

while IFS= read -r FILENAME; do
    if [ -z "$FILENAME" ]; then
        continue
    fi

    # Extrair data
    FILE_DATE=$(echo "$FILENAME" | sed -n 's/backup-vps-\([0-9]\{8\}\).*/\1/p')

    if [ -n "$FILE_DATE" ]; then
        # Verificar se já vimos esta data
        if [ ! -f "/tmp/.s3_cleanup_real_${FILE_DATE}" ]; then
            # Primeira vez - marcar como mantido
            touch "/tmp/.s3_cleanup_real_${FILE_DATE}"
            DAYS_KEPT=$((DAYS_KEPT + 1))

            if [ $DAYS_KEPT -le $S3_RETENTION_COUNT ]; then
                log_ok "Mantendo: $FILENAME"
            else
                log_action "Deletando (fora retenção): $FILENAME"
                rclone delete "${RCLONE_REMOTE}:${S3_FULL_PATH}/${FILENAME}" --verbose
                DELETED_COUNT=$((DELETED_COUNT + 1))
            fi
        else
            # Duplicado - deletar
            log_action "Deletando (duplicado): $FILENAME"
            rclone delete "${RCLONE_REMOTE}:${S3_FULL_PATH}/${FILENAME}" --verbose
            DELETED_COUNT=$((DELETED_COUNT + 1))
        fi
    fi
done <<< "$S3_BACKUPS"

# Limpar temporários
rm -f /tmp/.s3_cleanup_real_* 2>/dev/null || true

echo ""
log_ok "Limpeza concluída! $DELETED_COUNT arquivos deletados."
echo ""

# Listar arquivos restantes
echo "5. Arquivos Restantes no S3"
echo "========================================"
rclone lsf "${RCLONE_REMOTE}:${S3_FULL_PATH}/" | grep "^backup-vps-" | nl -w3 -s'. '

echo ""
log_ok "Processo completo!"

exit 0
