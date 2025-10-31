#!/bin/bash
# ============================================================================
# BACKUP MANAGER - Interface para Gerenciar Backups
# ============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/backup.conf"

# Carregar configurações se disponível
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    BACKUP_ROOT="${BACKUP_ROOT:-/root/backups}"
else
    BACKUP_ROOT="/root/backups"
fi

show_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         ${GREEN}BACKUP MANAGER VPS${CYAN}                              ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    echo -e "${BLUE}[1]${NC} Fazer Backup Completo"
    echo -e "${BLUE}[2]${NC} Restaurar Backup"
    echo -e "${BLUE}[3]${NC} Listar Backups"
    echo -e "${BLUE}[4]${NC} Ver Detalhes de um Backup"
    echo -e "${BLUE}[5]${NC} Gerar Inventário do Sistema"
    echo -e "${BLUE}[6]${NC} Enviar Backup para S3"
    echo -e "${BLUE}[7]${NC} Baixar Backup do S3"
    echo -e "${BLUE}[8]${NC} Limpar Backups Antigos"
    echo -e "${BLUE}[9]${NC} Testar Configuração"
    echo -e "${BLUE}[10]${NC} Ver Logs"
    echo -e "${BLUE}[11]${NC} Agendar Backup Automático"
    echo -e "${BLUE}[0]${NC} Sair"
    echo ""
}

list_backups() {
    echo -e "${GREEN}Backups Locais:${NC}"
    echo "----------------------------------------"

    if [ -d "$BACKUP_ROOT" ]; then
        COUNT=0
        for BACKUP in "$BACKUP_ROOT"/*; do
            if [ -e "$BACKUP" ]; then
                SIZE=$(du -sh "$BACKUP" 2>/dev/null | cut -f1)
                MTIME=$(stat -c %y "$BACKUP" 2>/dev/null || stat -f "%Sm" "$BACKUP" 2>/dev/null)
                BASENAME=$(basename "$BACKUP")

                echo -e "${BLUE}[$COUNT]${NC} $BASENAME"
                echo "    Tamanho: $SIZE"
                echo "    Data: $MTIME"
                echo ""

                COUNT=$((COUNT + 1))
            fi
        done

        if [ $COUNT -eq 0 ]; then
            echo "Nenhum backup encontrado"
        fi
    else
        echo "Diretório de backup não encontrado: $BACKUP_ROOT"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

backup_details() {
    echo -e "${GREEN}Digite o nome do backup (ou número):${NC}"
    read -p "> " BACKUP_ID

    # Se for número, pegar da lista
    if [[ "$BACKUP_ID" =~ ^[0-9]+$ ]]; then
        COUNT=0
        for BACKUP in "$BACKUP_ROOT"/*; do
            if [ -e "$BACKUP" ] && [ $COUNT -eq $BACKUP_ID ]; then
                BACKUP_PATH="$BACKUP"
                break
            fi
            COUNT=$((COUNT + 1))
        done
    else
        BACKUP_PATH="${BACKUP_ROOT}/${BACKUP_ID}"
    fi

    if [ ! -e "$BACKUP_PATH" ]; then
        echo -e "${RED}Backup não encontrado!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    echo ""
    echo -e "${GREEN}Detalhes do Backup:${NC}"
    echo "========================================"

    # Se for .tar.gz, extrair informações
    if [[ "$BACKUP_PATH" == *.tar.gz ]]; then
        echo "Tipo: Arquivo compactado"
        echo "Tamanho: $(du -sh "$BACKUP_PATH" | cut -f1)"
        echo ""
        echo "Conteúdo:"
        tar -tzf "$BACKUP_PATH" | head -30
        echo "..."

    elif [ -d "$BACKUP_PATH" ]; then
        echo "Tipo: Diretório"
        echo "Tamanho: $(du -sh "$BACKUP_PATH" | cut -f1)"
        echo ""

        # Mostrar log se existir
        if [ -f "$BACKUP_PATH/backup.log" ]; then
            echo "Log do backup (últimas 30 linhas):"
            echo "----------------------------------------"
            tail -30 "$BACKUP_PATH/backup.log"
        fi

        echo ""
        echo "Estrutura:"
        tree -L 2 "$BACKUP_PATH" 2>/dev/null || ls -lh "$BACKUP_PATH"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

run_backup() {
    echo -e "${GREEN}Executando backup completo...${NC}"
    echo ""

    if [ -f "${SCRIPT_DIR}/backup-vps.sh" ]; then
        "${SCRIPT_DIR}/backup-vps.sh"
    else
        echo -e "${RED}Script backup-vps.sh não encontrado!${NC}"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

run_restore() {
    list_backups

    echo -e "${GREEN}Digite o nome do backup para restaurar (ou número):${NC}"
    read -p "> " BACKUP_ID

    # Se for número, pegar da lista
    if [[ "$BACKUP_ID" =~ ^[0-9]+$ ]]; then
        COUNT=0
        for BACKUP in "$BACKUP_ROOT"/*; do
            if [ -e "$BACKUP" ] && [ $COUNT -eq $BACKUP_ID ]; then
                BACKUP_PATH="$BACKUP"
                break
            fi
            COUNT=$((COUNT + 1))
        done
    else
        BACKUP_PATH="${BACKUP_ROOT}/${BACKUP_ID}"
    fi

    if [ ! -e "$BACKUP_PATH" ]; then
        echo -e "${RED}Backup não encontrado!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    echo ""
    if [ -f "${SCRIPT_DIR}/restore-vps.sh" ]; then
        "${SCRIPT_DIR}/restore-vps.sh" "$BACKUP_PATH"
    else
        echo -e "${RED}Script restore-vps.sh não encontrado!${NC}"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

generate_inventory() {
    echo -e "${GREEN}Gerando inventário do sistema...${NC}"
    echo ""

    OUTPUT_FILE="/tmp/inventory-$(date +%Y%m%d_%H%M%S).txt"

    if [ -f "${SCRIPT_DIR}/generate-inventory.sh" ]; then
        "${SCRIPT_DIR}/generate-inventory.sh" "$OUTPUT_FILE"
        echo ""
        echo -e "${GREEN}Inventário salvo em: $OUTPUT_FILE${NC}"
        echo ""
        read -p "Deseja visualizar? (S/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            less "$OUTPUT_FILE"
        fi
    else
        echo -e "${RED}Script generate-inventory.sh não encontrado!${NC}"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

upload_to_s3() {
    if ! command -v rclone &> /dev/null; then
        echo -e "${RED}rclone não está instalado!${NC}"
        echo "Instale com: curl https://rclone.org/install.sh | sudo bash"
        read -p "Pressione Enter para continuar..."
        return
    fi

    list_backups

    echo -e "${GREEN}Digite o nome do backup para enviar (ou número):${NC}"
    read -p "> " BACKUP_ID

    # Se for número, pegar da lista
    if [[ "$BACKUP_ID" =~ ^[0-9]+$ ]]; then
        COUNT=0
        for BACKUP in "$BACKUP_ROOT"/*; do
            if [ -e "$BACKUP" ] && [ $COUNT -eq $BACKUP_ID ]; then
                BACKUP_PATH="$BACKUP"
                break
            fi
            COUNT=$((COUNT + 1))
        done
    else
        BACKUP_PATH="${BACKUP_ROOT}/${BACKUP_ID}"
    fi

    if [ ! -e "$BACKUP_PATH" ]; then
        echo -e "${RED}Backup não encontrado!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    # Carregar config S3
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    RCLONE_REMOTE="${RCLONE_REMOTE:-s3}"
    S3_BUCKET="${S3_BUCKET:-backups}"
    S3_PATH="${S3_PATH:-vps}"

    echo ""
    echo -e "${YELLOW}Destino: ${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/${NC}"
    echo ""
    read -p "Confirmar upload? (S/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${GREEN}Enviando para S3...${NC}"
        rclone copy "$BACKUP_PATH" "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/" --progress
        echo -e "${GREEN}Upload concluído!${NC}"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

download_from_s3() {
    if ! command -v rclone &> /dev/null; then
        echo -e "${RED}rclone não está instalado!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    # Carregar config S3
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    RCLONE_REMOTE="${RCLONE_REMOTE:-s3}"
    S3_BUCKET="${S3_BUCKET:-backups}"
    S3_PATH="${S3_PATH:-vps}"

    echo -e "${GREEN}Listando backups no S3...${NC}"
    echo "Origem: ${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/"
    echo ""

    rclone lsl "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/" | nl -w3 -s") "

    echo ""
    read -p "Digite o nome do arquivo para baixar: " S3_FILE

    if [ -z "$S3_FILE" ]; then
        echo -e "${RED}Nome não fornecido${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    read -p "Diretório de destino [$BACKUP_ROOT]: " DEST_DIR
    DEST_DIR=${DEST_DIR:-$BACKUP_ROOT}

    mkdir -p "$DEST_DIR"

    echo -e "${GREEN}Baixando do S3...${NC}"
    rclone copy "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/${S3_FILE}" "$DEST_DIR/" --progress

    echo -e "${GREEN}Download concluído!${NC}"
    echo "Salvo em: ${DEST_DIR}/${S3_FILE}"

    echo ""
    read -p "Pressione Enter para continuar..."
}

clean_old_backups() {
    echo -e "${YELLOW}Limpeza de Backups Antigos${NC}"
    echo "========================================"
    echo ""
    echo "Backups encontrados:"

    find "$BACKUP_ROOT" -maxdepth 1 -type f -o -type d | sort

    echo ""
    read -p "Manter backups dos últimos quantos dias? [7]: " DAYS
    DAYS=${DAYS:-7}

    echo ""
    echo -e "${YELLOW}Arquivos que serão DELETADOS (mais de $DAYS dias):${NC}"
    find "$BACKUP_ROOT" -maxdepth 1 \( -type f -o -type d \) -mtime +${DAYS}

    echo ""
    read -p "Confirmar deleção? (S/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        find "$BACKUP_ROOT" -maxdepth 1 -type f -mtime +${DAYS} -delete
        find "$BACKUP_ROOT" -maxdepth 1 -type d -mtime +${DAYS} -exec rm -rf {} \; 2>/dev/null || true
        echo -e "${GREEN}Limpeza concluída!${NC}"
    else
        echo "Operação cancelada"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

test_config() {
    echo -e "${GREEN}Testando Configuração${NC}"
    echo "========================================"
    echo ""

    # Testar arquivo de config
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✓${NC} Arquivo de configuração encontrado"
    else
        echo -e "${RED}✗${NC} Arquivo de configuração não encontrado"
    fi

    # Testar scripts
    for SCRIPT in backup-vps.sh restore-vps.sh generate-inventory.sh; do
        if [ -f "${SCRIPT_DIR}/${SCRIPT}" ]; then
            echo -e "${GREEN}✓${NC} ${SCRIPT} encontrado"
        else
            echo -e "${RED}✗${NC} ${SCRIPT} não encontrado"
        fi
    done

    # Testar comandos
    echo ""
    echo "Comandos disponíveis:"
    for CMD in tar gzip mysql mariabackup rclone nginx systemctl; do
        if command -v $CMD &> /dev/null; then
            echo -e "${GREEN}✓${NC} ${CMD}"
        else
            echo -e "${YELLOW}⚠${NC} ${CMD} (opcional ou não instalado)"
        fi
    done

    # Testar diretório de backup
    echo ""
    if [ -d "$BACKUP_ROOT" ]; then
        SPACE=$(df -h "$BACKUP_ROOT" | tail -1 | awk '{print $4}')
        echo -e "${GREEN}✓${NC} Diretório de backup: $BACKUP_ROOT"
        echo "  Espaço disponível: $SPACE"
    else
        echo -e "${RED}✗${NC} Diretório de backup não existe: $BACKUP_ROOT"
    fi

    # Testar S3
    echo ""
    if command -v rclone &> /dev/null; then
        echo "Remotes rclone configurados:"
        rclone listremotes | while read -r REMOTE; do
            echo -e "${GREEN}✓${NC} ${REMOTE}"
        done
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

view_logs() {
    echo -e "${GREEN}Logs de Backup${NC}"
    echo "========================================"
    echo ""

    LOGS=$(find "$BACKUP_ROOT" -name "backup.log" -type f | sort -r | head -5)

    if [ -z "$LOGS" ]; then
        echo "Nenhum log encontrado"
    else
        echo "Últimos 5 logs:"
        echo "$LOGS" | nl -w3 -s") "
        echo ""
        read -p "Digite o número para visualizar (ou Enter para pular): " LOG_NUM

        if [ -n "$LOG_NUM" ]; then
            LOG_FILE=$(echo "$LOGS" | sed -n "${LOG_NUM}p")
            if [ -f "$LOG_FILE" ]; then
                echo ""
                less "$LOG_FILE"
            fi
        fi
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

schedule_backup() {
    echo -e "${GREEN}Agendar Backup Automático${NC}"
    echo "========================================"
    echo ""
    echo "Crontab atual:"
    crontab -l 2>/dev/null || echo "Nenhum cron configurado"

    echo ""
    echo "Horários sugeridos:"
    echo "  [1] Diariamente às 02:00"
    echo "  [2] Diariamente às 03:00"
    echo "  [3] Duas vezes ao dia (02:00 e 14:00)"
    echo "  [4] Semanalmente (Domingo 02:00)"
    echo "  [5] Personalizado"
    echo ""
    read -p "Escolha uma opção: " SCHEDULE_OPT

    case $SCHEDULE_OPT in
        1) CRON_LINE="0 2 * * * ${SCRIPT_DIR}/backup-vps.sh >> /var/log/backup-vps.log 2>&1" ;;
        2) CRON_LINE="0 3 * * * ${SCRIPT_DIR}/backup-vps.sh >> /var/log/backup-vps.log 2>&1" ;;
        3) CRON_LINE="0 2,14 * * * ${SCRIPT_DIR}/backup-vps.sh >> /var/log/backup-vps.log 2>&1" ;;
        4) CRON_LINE="0 2 * * 0 ${SCRIPT_DIR}/backup-vps.sh >> /var/log/backup-vps.log 2>&1" ;;
        5)
            echo "Digite a expressão cron (ex: 0 2 * * *):"
            read -p "> " CRON_EXPR
            CRON_LINE="${CRON_EXPR} ${SCRIPT_DIR}/backup-vps.sh >> /var/log/backup-vps.log 2>&1"
            ;;
        *)
            echo "Opção inválida"
            read -p "Pressione Enter para continuar..."
            return
            ;;
    esac

    echo ""
    echo "Linha que será adicionada ao crontab:"
    echo "$CRON_LINE"
    echo ""
    read -p "Confirmar? (S/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
        echo -e "${GREEN}Cron configurado com sucesso!${NC}"
    else
        echo "Operação cancelada"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

# Loop principal
while true; do
    show_header
    show_menu

    read -p "Escolha uma opção: " OPTION

    case $OPTION in
        1) run_backup ;;
        2) run_restore ;;
        3) list_backups ;;
        4) backup_details ;;
        5) generate_inventory ;;
        6) upload_to_s3 ;;
        7) download_from_s3 ;;
        8) clean_old_backups ;;
        9) test_config ;;
        10) view_logs ;;
        11) schedule_backup ;;
        0) echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida"; sleep 1 ;;
    esac
done
