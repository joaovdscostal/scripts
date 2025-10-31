#!/bin/bash
# ============================================================================
# SCRIPT DE TESTE - LIMPEZA DE BACKUPS S3
# ============================================================================
# Este script testa a lógica de limpeza de backups do S3
# sem precisar rodar o backup completo
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
echo "TESTE DE LIMPEZA DE BACKUPS S3"
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

log_info "Carregando configurações de: $CONFIG_FILE"
source "$CONFIG_FILE"
echo ""

# ============================================================================
# VERIFICAR CONFIGURAÇÕES
# ============================================================================

echo "1. Verificando Configurações"
echo "----------------------------------------"

if [ -n "${RCLONE_REMOTE:-}" ]; then
    log_ok "RCLONE_REMOTE: ${RCLONE_REMOTE}"
else
    log_error "RCLONE_REMOTE não definido"
    exit 1
fi

if [ -n "${S3_PATH:-}" ]; then
    log_ok "S3_PATH: ${S3_PATH}"
else
    log_error "S3_PATH não definido"
    exit 1
fi

if [ -n "${S3_RETENTION_COUNT:-}" ]; then
    log_ok "S3_RETENTION_COUNT: ${S3_RETENTION_COUNT}"
else
    log_error "S3_RETENTION_COUNT não definido"
    exit 1
fi

echo ""

# ============================================================================
# VERIFICAR RCLONE
# ============================================================================

echo "2. Verificando Rclone"
echo "----------------------------------------"

if ! command -v rclone &> /dev/null; then
    log_error "rclone não encontrado"
    exit 1
fi

log_ok "rclone instalado: $(rclone version | head -1)"

# Verificar se remote existe
if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:$"; then
    log_error "Remote '${RCLONE_REMOTE}' não encontrado"
    log_info "Remotes disponíveis:"
    rclone listremotes
    exit 1
fi

log_ok "Remote '${RCLONE_REMOTE}' encontrado"
echo ""

# ============================================================================
# LISTAR BACKUPS NO S3
# ============================================================================

echo "3. Listando Backups no S3"
echo "----------------------------------------"

log_info "Listando arquivos em: ${RCLONE_REMOTE}:${S3_PATH}/"
echo ""

# Teste 1: Listar todos os arquivos
log_info "Teste 1: rclone lsf (listar todos os arquivos)"
echo "Comando: rclone lsf \"${RCLONE_REMOTE}:${S3_PATH}/\""
echo "----------------------------------------"
rclone lsf "${RCLONE_REMOTE}:${S3_PATH}/" || log_warning "Falha ao listar"
echo "----------------------------------------"
echo ""

# Teste 1.5: Tentar sem a barra final
log_info "Teste 1.5: rclone lsf SEM barra final"
echo "Comando: rclone lsf \"${RCLONE_REMOTE}:${S3_PATH}\""
echo "----------------------------------------"
rclone lsf "${RCLONE_REMOTE}:${S3_PATH}" || log_warning "Falha ao listar"
echo "----------------------------------------"
echo ""

# Teste 1.6: Usar ls ao invés de lsf
log_info "Teste 1.6: rclone ls (formato diferente)"
echo "Comando: rclone ls \"${RCLONE_REMOTE}:${S3_PATH}/\""
echo "----------------------------------------"
rclone ls "${RCLONE_REMOTE}:${S3_PATH}/" || log_warning "Falha ao listar"
echo "----------------------------------------"
echo ""

# Teste 1.7: Verificar se o bucket existe
log_info "Teste 1.7: Listar buckets/pastas"
echo "Comando: rclone lsd \"${RCLONE_REMOTE}:\""
echo "----------------------------------------"
rclone lsd "${RCLONE_REMOTE}:" || log_warning "Falha ao listar buckets"
echo "----------------------------------------"
echo ""

# Teste 2: Filtrar apenas backup-vps
log_info "Teste 2: Filtrar apenas arquivos backup-vps-*"
echo "Comando: rclone lsf \"${RCLONE_REMOTE}:${S3_PATH}/\" | grep \"^backup-vps-\""
echo "----------------------------------------"
set +e
FILTERED=$(rclone lsf "${RCLONE_REMOTE}:${S3_PATH}/" 2>/dev/null | grep "^backup-vps-")
GREP_EXIT=$?
set -e

if [ $GREP_EXIT -eq 0 ]; then
    echo "$FILTERED"
    BACKUP_COUNT=$(echo "$FILTERED" | wc -l)
    log_ok "Encontrados: $BACKUP_COUNT backups"
elif [ $GREP_EXIT -eq 1 ]; then
    log_warning "Nenhum backup encontrado (grep retornou 1 - normal quando vazio)"
else
    log_error "Erro ao filtrar (código: $GREP_EXIT)"
fi
echo "----------------------------------------"
echo ""

# Teste 3: Ordenar por nome (mais recentes primeiro)
log_info "Teste 3: Ordenar backups (mais recentes primeiro)"
echo "----------------------------------------"
set +e
S3_BACKUPS=$(rclone lsf "${RCLONE_REMOTE}:${S3_PATH}/" 2>/dev/null | grep "^backup-vps-" | sort -r)
COMMAND_EXIT=$?
set -e

echo "Código de saída: $COMMAND_EXIT"
echo ""

if [ $COMMAND_EXIT -eq 0 ] || [ $COMMAND_EXIT -eq 1 ]; then
    if [ -z "$S3_BACKUPS" ]; then
        log_warning "Lista vazia (normal se não houver backups)"
    else
        echo "Backups ordenados:"
        echo "$S3_BACKUPS"
        echo ""
        log_ok "Comando executado com sucesso"
    fi
else
    log_error "Erro ao executar comando (código: $COMMAND_EXIT)"
fi
echo "----------------------------------------"
echo ""

# ============================================================================
# SIMULAR LIMPEZA
# ============================================================================

echo "4. Simulação de Limpeza (DRY RUN)"
echo "----------------------------------------"

if [ -z "$S3_BACKUPS" ]; then
    log_info "Nenhum backup para processar"
else
    log_info "Processando backups mantendo últimos ${S3_RETENTION_COUNT} dias (1 por dia)..."
    echo ""

    # Limpar marcadores anteriores
    rm -f /tmp/.s3_cleanup_test_* 2>/dev/null || true

    DAYS_KEPT=0

    # Usar construção que não cria subshell (<<< ao invés de pipe)
    while IFS= read -r FILENAME; do
        if [ -z "$FILENAME" ]; then
            continue
        fi

        # Extrair data do nome do arquivo (YYYYMMDD)
        FILE_DATE=$(echo "$FILENAME" | sed -n 's/backup-vps-\([0-9]\{8\}\).*/\1/p')

        if [ -n "$FILE_DATE" ]; then
            # Verificar se já vimos esta data
            if [ ! -f "/tmp/.s3_cleanup_test_${FILE_DATE}" ]; then
                # Primeira vez vendo esta data
                touch "/tmp/.s3_cleanup_test_${FILE_DATE}"
                DAYS_KEPT=$((DAYS_KEPT + 1))

                if [ $DAYS_KEPT -le $S3_RETENTION_COUNT ]; then
                    log_ok "[MANTER] Dia $FILE_DATE (dia #${DAYS_KEPT} de ${S3_RETENTION_COUNT}): $FILENAME"
                else
                    log_warning "[DELETAR] Dia $FILE_DATE (fora dos ${S3_RETENTION_COUNT} dias): $FILENAME"
                fi
            else
                log_warning "[DELETAR] Duplicado do dia $FILE_DATE: $FILENAME"
            fi
        else
            log_error "Não foi possível extrair data de: $FILENAME"
        fi
    done <<< "$S3_BACKUPS"

    # Limpar arquivos temporários
    rm -f /tmp/.s3_cleanup_test_* 2>/dev/null || true

    echo ""
    log_info "Total de dias diferentes encontrados: $DAYS_KEPT"
fi

echo ""
echo "========================================"
echo "TESTE CONCLUÍDO"
echo "========================================"
echo ""
echo "Próximos passos:"
echo "  - Se os testes acima passaram, a lógica está OK"
echo "  - Se encontrou erros, analise os códigos de saída"
echo "  - Para executar a limpeza real, rode o backup-vps.sh"

exit 0
