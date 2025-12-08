#!/bin/zsh

# ==========================================
# Script para Copiar Banco de Dados
# ==========================================
# Uso: ./banco.sh -basededadosorigem [db] -basededadosdestino [db] -origem [env] -destino [env]

# Diretório do script
SCRIPT_DIR="/Users/nds/Workspace/scripts"
CONFIG_FILE="$SCRIPT_DIR/banco-config.json"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de output
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
step() { echo -e "${CYAN}▶ $1${NC}"; }

# Função de spinner/loading
spinner() {
    local pid=$1
    local msg=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        local char="${spinstr:$i:1}"
        printf "\r  ${CYAN}${char}${NC} ${msg}..."
        i=$(( (i + 1) % ${#spinstr} ))
        sleep 0.1
    done
    printf "\r"
}

# Verificar se jq está instalado
if ! command -v jq &> /dev/null; then
    error "jq não está instalado. Instale com: brew install jq"
fi

# Verificar se arquivo de config existe
if [ ! -f "$CONFIG_FILE" ]; then
    error "Arquivo de configuração não encontrado: $CONFIG_FILE"
fi

# Função para ler config do JSON
get_origem() {
    local key=$1
    local field=$2
    jq -r ".origens[\"$key\"].$field // empty" "$CONFIG_FILE"
}

get_destino() {
    local key=$1
    local field=$2
    jq -r ".destinos[\"$key\"].$field // empty" "$CONFIG_FILE"
}

get_config() {
    local field=$1
    jq -r ".config.$field // empty" "$CONFIG_FILE"
}

# Listar origens/destinos disponíveis
listar_origens() {
    jq -r '.origens | keys[]' "$CONFIG_FILE" | tr '\n' ', ' | sed 's/,$/\n/' | sed 's/,/, /g'
}

listar_destinos() {
    jq -r '.destinos | keys[]' "$CONFIG_FILE" | tr '\n' ', ' | sed 's/,$/\n/' | sed 's/,/, /g'
}

# Help
if [ $# -eq 1 ] && [[ "$1" == "--help" ]]; then
    echo ""
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Gerenciador de Banco de Dados${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC}"
    echo "  ./banco.sh                              # Modo interativo (menu de operações)"
    echo "  ./banco.sh -origem [env] -destino [env] -basededadosorigem [db] -basededadosdestino [db]"
    echo ""
    echo -e "${YELLOW}Modo Interativo:${NC}"
    echo "  [1] Backup + Restore  - Copia banco de um servidor para outro"
    echo "  [2] Apenas Backup     - Faz dump e salva em arquivo local"
    echo "  [3] Apenas Restore    - Restaura banco de um arquivo existente"
    echo ""
    echo -e "${YELLOW}Parâmetros (modo direto):${NC}"
    echo "  -basededadosorigem     Nome do banco de dados origem"
    echo "  -basededadosdestino    Nome do banco de dados destino"
    echo "  -origem                Ambiente origem"
    echo "  -destino               Ambiente destino"
    echo ""
    echo -e "${YELLOW}Origens disponíveis:${NC}"
    echo "  $(listar_origens)"
    echo ""
    echo -e "${YELLOW}Destinos disponíveis:${NC}"
    echo "  $(listar_destinos)"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  ./banco.sh                                     # Modo interativo"
    echo "  ./banco.sh -basededadosorigem meudb -basededadosdestino meudb -origem producao -destino localhost"
    echo ""
    echo -e "${YELLOW}Configuração:${NC}"
    echo "  Arquivo: $CONFIG_FILE"
    echo ""
    exit 0
fi

# Modo interativo (sem argumentos)
if [ $# -lt 1 ]; then
    echo ""
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Gerenciador de Banco de Dados${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""

    # Menu inicial - escolher operação
    echo -e "${YELLOW}Selecione a OPERAÇÃO:${NC}"
    echo -e "  ${CYAN}[1]${NC} Backup + Restore (copiar banco entre servidores)"
    echo -e "  ${CYAN}[2]${NC} Apenas Backup (salvar dump em arquivo)"
    echo -e "  ${CYAN}[3]${NC} Apenas Restore (restaurar de arquivo existente)"
    echo ""
    echo -n -e "${YELLOW}Opção [1]: ${NC}"
    read -r OPT_OPERACAO

    # Default é 1
    [ -z "$OPT_OPERACAO" ] && OPT_OPERACAO=1

    if [[ ! "$OPT_OPERACAO" =~ ^[1-3]$ ]]; then
        error "Opção inválida"
    fi

    MODO_OPERACAO=$OPT_OPERACAO
    echo ""

    # ==========================================
    # MODO 3: APENAS RESTORE - fluxo separado
    # ==========================================
    if [ "$MODO_OPERACAO" -eq 3 ]; then
        DEFAULT_PATH="/Users/nds/Workspace/dados"

        echo -e "${YELLOW}Informe o diretório onde estão os arquivos SQL:${NC}"
        echo -n -e "${CYAN}Diretório [$DEFAULT_PATH]: ${NC}"
        read -r RESTORE_DIR

        # Se vazio, usa o padrão
        [ -z "$RESTORE_DIR" ] && RESTORE_DIR="$DEFAULT_PATH"

        # Verificar se é um arquivo direto ou diretório
        if [ -f "$RESTORE_DIR" ]; then
            # Usuário informou um arquivo diretamente
            ARQUIVO_RESTORE="$RESTORE_DIR"
        elif [ -d "$RESTORE_DIR" ]; then
            # É um diretório - listar arquivos SQL
            echo ""
            step "Listando arquivos SQL em '$RESTORE_DIR'..."
            echo ""

            # Buscar arquivos .sql ordenados por data (mais recente primeiro)
            ARQUIVOS_SQL=("${(@f)$(ls -t "$RESTORE_DIR"/*.sql 2>/dev/null)}")

            if [ ${#ARQUIVOS_SQL[@]} -eq 0 ] || [ -z "${ARQUIVOS_SQL[1]}" ]; then
                error "Nenhum arquivo .sql encontrado em: $RESTORE_DIR"
            fi

            echo -e "${YELLOW}Selecione o ARQUIVO SQL:${NC}"
            for i in {1..${#ARQUIVOS_SQL[@]}}; do
                arquivo="${ARQUIVOS_SQL[$i]}"
                nome_arquivo=$(basename "$arquivo")
                tamanho=$(du -h "$arquivo" | cut -f1)
                data_mod=$(stat -f "%Sm" -t "%d/%m/%Y %H:%M" "$arquivo" 2>/dev/null || stat --format="%y" "$arquivo" 2>/dev/null | cut -d. -f1)
                echo -e "  ${CYAN}[$i]${NC} $nome_arquivo (${tamanho}, $data_mod)"
            done
            echo ""
            echo -n -e "${YELLOW}Opção: ${NC}"
            read -r OPT_ARQUIVO

            if [[ ! "$OPT_ARQUIVO" =~ ^[0-9]+$ ]] || [ "$OPT_ARQUIVO" -lt 1 ] || [ "$OPT_ARQUIVO" -gt "${#ARQUIVOS_SQL[@]}" ]; then
                error "Opção inválida"
            fi
            ARQUIVO_RESTORE="${ARQUIVOS_SQL[$OPT_ARQUIVO]}"
        else
            error "Caminho não encontrado: $RESTORE_DIR"
        fi

        if [ ! -f "$ARQUIVO_RESTORE" ]; then
            error "Arquivo não encontrado: $ARQUIVO_RESTORE"
        fi

        TAMANHO_ARQUIVO=$(du -h "$ARQUIVO_RESTORE" | cut -f1)
        success "Arquivo selecionado: $(basename "$ARQUIVO_RESTORE") ($TAMANHO_ARQUIVO)"
        echo ""

        # Listar destinos
        DESTINOS=("${(@f)$(jq -r '.destinos | keys[]' "$CONFIG_FILE")}")

        echo -e "${YELLOW}Selecione o DESTINO:${NC}"
        for i in {1..${#DESTINOS[@]}}; do
            servidor=$(get_destino "${DESTINOS[$i]}" "servidor")
            porta=$(get_destino "${DESTINOS[$i]}" "porta")
            porta_str=""
            [ "$porta" != "null" ] && [ -n "$porta" ] && porta_str=":$porta"
            echo -e "  ${CYAN}[$i]${NC} ${DESTINOS[$i]} ($servidor$porta_str)"
        done
        echo ""
        echo -n -e "${YELLOW}Opção: ${NC}"
        read -r OPT_DESTINO

        if [[ ! "$OPT_DESTINO" =~ ^[0-9]+$ ]] || [ "$OPT_DESTINO" -lt 1 ] || [ "$OPT_DESTINO" -gt "${#DESTINOS[@]}" ]; then
            error "Opção inválida"
        fi
        destino="${DESTINOS[$OPT_DESTINO]}"
        echo ""

        # Binários MySQL do destino
        mysql_bin=$(get_destino "$destino" "binarios.mysql")

        # Carregar config do destino para listar bancos
        servidordestino_tmp=$(get_destino "$destino" "servidor")
        usuariodestino_tmp=$(get_destino "$destino" "usuario")
        senhadestino_tmp=$(get_destino "$destino" "senha")
        porta_destino_tmp=$(get_destino "$destino" "porta")
        portadestino_tmp=""
        [ "$porta_destino_tmp" != "null" ] && [ -n "$porta_destino_tmp" ] && portadestino_tmp="-P $porta_destino_tmp"

        # Listar bancos do destino
        step "Conectando em '$destino' para listar bancos..."
        echo ""

        BANCOS_DESTINO=$($mysql_bin $portadestino_tmp -h "$servidordestino_tmp" -u "$usuariodestino_tmp" -p"$senhadestino_tmp" -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$")

        if [ -z "$BANCOS_DESTINO" ]; then
            warning "Não foi possível listar bancos. Digite manualmente."
            echo -n -e "${YELLOW}Nome do banco de dados DESTINO: ${NC}"
            read -r basededadosdestino
            [ -z "$basededadosdestino" ] && error "Nome do banco destino é obrigatório"
        else
            BANCOS_DEST_ARRAY=("${(@f)BANCOS_DESTINO}")

            echo -e "${YELLOW}Selecione o BANCO DE DADOS (destino):${NC}"
            for i in {1..${#BANCOS_DEST_ARRAY[@]}}; do
                echo -e "  ${CYAN}[$i]${NC} ${BANCOS_DEST_ARRAY[$i]}"
            done
            echo ""
            echo -n -e "${YELLOW}Opção: ${NC}"
            read -r OPT_BANCO_DEST

            if [[ ! "$OPT_BANCO_DEST" =~ ^[0-9]+$ ]] || [ "$OPT_BANCO_DEST" -lt 1 ] || [ "$OPT_BANCO_DEST" -gt "${#BANCOS_DEST_ARRAY[@]}" ]; then
                error "Opção inválida"
            fi
            basededadosdestino="${BANCOS_DEST_ARRAY[$OPT_BANCO_DEST]}"
        fi
        echo ""

        # Pular para restauração direta
        # Carregar configurações de destino
        servidordestino=$(get_destino "$destino" "servidor")
        usuariodestino=$(get_destino "$destino" "usuario")
        senhadestino=$(get_destino "$destino" "senha")
        porta_destino=$(get_destino "$destino" "porta")
        portadestino=""
        [ "$porta_destino" != "null" ] && [ -n "$porta_destino" ] && portadestino="-P $porta_destino"

        mysql=$(get_destino "$destino" "binarios.mysql")

        # Exibir configuração
        echo -e "${BLUE}===========================================${NC}"
        echo -e "${BLUE}  Restauração de Banco de Dados${NC}"
        echo -e "${BLUE}===========================================${NC}"
        echo ""
        echo -e "${YELLOW}Configuração:${NC}"
        echo "  ┌─────────────────────────────────────────"
        echo "  │ Arquivo:  $ARQUIVO_RESTORE ($TAMANHO_ARQUIVO)"
        echo "  │ Destino:  $destino ($servidordestino${porta_destino:+:$porta_destino})"
        echo "  │ Banco:    $basededadosdestino"
        echo "  └─────────────────────────────────────────"
        echo ""

        # Confirmação
        echo -n -e "${YELLOW}Deseja continuar? (s/N): ${NC}"
        read -r CONFIRMA
        if [[ ! "$CONFIRMA" =~ ^[Ss]$ ]]; then
            info "Operação cancelada"
            exit 0
        fi
        echo ""

        # Restauração
        step "Restaurando '$basededadosdestino' em '$destino'..."
        echo ""

        INICIO_RESTORE=$(date +%s)

        info "Servidor: $servidordestino"
        info "Usuário:  $usuariodestino"
        echo ""

        $mysql $portadestino -h "$servidordestino" -u "$usuariodestino" -p"$senhadestino" "$basededadosdestino" < "$ARQUIVO_RESTORE" 2>/tmp/restore_error.txt &
        RESTORE_PID=$!
        spinner $RESTORE_PID "Restaurando '$basededadosdestino'"
        wait $RESTORE_PID
        RESTORE_EXIT_CODE=$?

        if [ $RESTORE_EXIT_CODE -ne 0 ]; then
            RESTORE_ERROR=$(cat /tmp/restore_error.txt 2>/dev/null)
            echo -e "${RED}Erro do mysql:${NC}"
            echo "$RESTORE_ERROR"
            error "Falha na restauração do banco de dados"
        fi

        FIM_RESTORE=$(date +%s)
        TEMPO_RESTORE=$((FIM_RESTORE - INICIO_RESTORE))

        echo ""
        echo -e "${GREEN}===========================================${NC}"
        echo -e "${GREEN}  Restauração finalizada com sucesso!${NC}"
        echo -e "${GREEN}===========================================${NC}"
        echo ""
        echo "  📦 Banco:       $basededadosdestino"
        echo "  🌐 Servidor:    $destino"
        echo "  📁 Arquivo:     $TAMANHO_ARQUIVO"
        echo "  ⏱️  Tempo:       ${TEMPO_RESTORE}s"
        echo ""
        exit 0
    fi

    # ==========================================
    # MODOS 1 e 2: Precisam selecionar ORIGEM
    # ==========================================

    # Listar origens como array
    ORIGENS=("${(@f)$(jq -r '.origens | keys[]' "$CONFIG_FILE")}")

    echo -e "${YELLOW}Selecione a ORIGEM:${NC}"
    for i in {1..${#ORIGENS[@]}}; do
        servidor=$(get_origem "${ORIGENS[$i]}" "servidor")
        echo -e "  ${CYAN}[$i]${NC} ${ORIGENS[$i]} ($servidor)"
    done
    echo ""
    echo -n -e "${YELLOW}Opção: ${NC}"
    read -r OPT_ORIGEM

    if [[ ! "$OPT_ORIGEM" =~ ^[0-9]+$ ]] || [ "$OPT_ORIGEM" -lt 1 ] || [ "$OPT_ORIGEM" -gt "${#ORIGENS[@]}" ]; then
        error "Opção inválida"
    fi
    origem="${ORIGENS[$OPT_ORIGEM]}"
    echo ""

    # ==========================================
    # MODO 2: APENAS BACKUP - fluxo separado
    # ==========================================
    if [ "$MODO_OPERACAO" -eq 2 ]; then
        # Usar localhost como destino temporário para pegar binários
        DESTINOS=("${(@f)$(jq -r '.destinos | keys[]' "$CONFIG_FILE")}")
        destino="${DESTINOS[1]}"  # Primeiro destino disponível

        mysql_bin=$(get_destino "$destino" "binarios.mysql")
        mysqldump_bin=$(get_destino "$destino" "binarios.mysqldump")

        # Carregar config da origem para listar bancos
        servidororigem_tmp=$(get_origem "$origem" "servidor")
        usuarioorigem_tmp=$(get_origem "$origem" "usuario")
        senhaorigem_tmp=$(get_origem "$origem" "senha")
        porta_origem_tmp=$(get_origem "$origem" "porta")
        portaorigem_tmp=""
        [ "$porta_origem_tmp" != "null" ] && [ -n "$porta_origem_tmp" ] && portaorigem_tmp="-P $porta_origem_tmp"

        # Listar bancos da origem
        step "Conectando em '$origem' para listar bancos..."
        echo ""

        BANCOS_ORIGEM=$($mysql_bin $portaorigem_tmp -h "$servidororigem_tmp" -u "$usuarioorigem_tmp" -p"$senhaorigem_tmp" -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$")

        if [ -z "$BANCOS_ORIGEM" ]; then
            warning "Não foi possível listar bancos. Digite manualmente."
            echo -n -e "${YELLOW}Nome do banco de dados: ${NC}"
            read -r basededadosorigem
            [ -z "$basededadosorigem" ] && error "Nome do banco é obrigatório"
        else
            BANCOS_ARRAY=("${(@f)BANCOS_ORIGEM}")

            echo -e "${YELLOW}Selecione o BANCO DE DADOS:${NC}"
            for i in {1..${#BANCOS_ARRAY[@]}}; do
                echo -e "  ${CYAN}[$i]${NC} ${BANCOS_ARRAY[$i]}"
            done
            echo ""
            echo -n -e "${YELLOW}Opção: ${NC}"
            read -r OPT_BANCO

            if [[ ! "$OPT_BANCO" =~ ^[0-9]+$ ]] || [ "$OPT_BANCO" -lt 1 ] || [ "$OPT_BANCO" -gt "${#BANCOS_ARRAY[@]}" ]; then
                error "Opção inválida"
            fi
            basededadosorigem="${BANCOS_ARRAY[$OPT_BANCO]}"
        fi
        echo ""

        # Perguntar onde salvar
        DEFAULT_PATH="/Users/nds/Workspace/dados"
        echo -e "${YELLOW}Informe o diretório para salvar o backup:${NC}"
        echo -n -e "${CYAN}Diretório [$DEFAULT_PATH]: ${NC}"
        read -r BACKUP_DIR

        [ -z "$BACKUP_DIR" ] && BACKUP_DIR="$DEFAULT_PATH"

        # Criar diretório se não existir
        if [ ! -d "$BACKUP_DIR" ]; then
            echo -n -e "${YELLOW}Diretório não existe. Criar? (s/N): ${NC}"
            read -r CRIAR_DIR
            if [[ "$CRIAR_DIR" =~ ^[Ss]$ ]]; then
                mkdir -p "$BACKUP_DIR" || error "Não foi possível criar o diretório"
                success "Diretório criado"
            else
                error "Diretório não existe"
            fi
        fi

        # Nome do arquivo
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        ARQUIVO_BACKUP="$BACKUP_DIR/backup_${basededadosorigem}_${TIMESTAMP}.sql"
        echo ""

        # Carregar configurações de origem
        servidororigem=$(get_origem "$origem" "servidor")
        usuarioorigem=$(get_origem "$origem" "usuario")
        senhaorigem=$(get_origem "$origem" "senha")
        porta_origem=$(get_origem "$origem" "porta")
        portaorigem=""
        [ "$porta_origem" != "null" ] && [ -n "$porta_origem" ] && portaorigem="-P $porta_origem"

        DUMP_FLAGS=$(get_config "dump_flags")

        # Exibir configuração
        echo -e "${BLUE}===========================================${NC}"
        echo -e "${BLUE}  Backup de Banco de Dados${NC}"
        echo -e "${BLUE}===========================================${NC}"
        echo ""
        echo -e "${YELLOW}Configuração:${NC}"
        echo "  ┌─────────────────────────────────────────"
        echo "  │ Origem:   $origem ($servidororigem${porta_origem:+:$porta_origem})"
        echo "  │ Banco:    $basededadosorigem"
        echo "  │ Arquivo:  $ARQUIVO_BACKUP"
        echo "  └─────────────────────────────────────────"
        echo ""

        # Confirmação
        echo -n -e "${YELLOW}Deseja continuar? (s/N): ${NC}"
        read -r CONFIRMA
        if [[ ! "$CONFIRMA" =~ ^[Ss]$ ]]; then
            info "Operação cancelada"
            exit 0
        fi
        echo ""

        # Dump
        step "Iniciando backup de '$basededadosorigem'..."
        echo ""

        INICIO_DUMP=$(date +%s)

        info "Servidor: $servidororigem"
        info "Usuário:  $usuarioorigem"
        info "Flags:    $DUMP_FLAGS"
        echo ""

        $mysqldump_bin ${=DUMP_FLAGS} $portaorigem -h "$servidororigem" -u "$usuarioorigem" -p"$senhaorigem" "$basededadosorigem" > "$ARQUIVO_BACKUP" 2>/tmp/dump_error.txt &
        DUMP_PID=$!
        spinner $DUMP_PID "Fazendo backup de '$basededadosorigem'"
        wait $DUMP_PID
        DUMP_EXIT_CODE=$?
        DUMP_ERROR=$(cat /tmp/dump_error.txt 2>/dev/null)

        if [ $DUMP_EXIT_CODE -ne 0 ]; then
            echo ""
            echo -e "${RED}Erro do mysqldump:${NC}"
            echo "$DUMP_ERROR"
            rm -f "$ARQUIVO_BACKUP"
            error "Falha no backup do banco de dados (exit code: $DUMP_EXIT_CODE)"
        fi

        FIM_DUMP=$(date +%s)
        TEMPO_DUMP=$((FIM_DUMP - INICIO_DUMP))
        TAMANHO_DUMP=$(du -h "$ARQUIVO_BACKUP" | cut -f1)

        echo ""
        echo -e "${GREEN}===========================================${NC}"
        echo -e "${GREEN}  Backup finalizado com sucesso!${NC}"
        echo -e "${GREEN}===========================================${NC}"
        echo ""
        echo "  📦 Banco:    $basededadosorigem"
        echo "  🌐 Origem:   $origem"
        echo "  📁 Arquivo:  $ARQUIVO_BACKUP"
        echo "  📊 Tamanho:  $TAMANHO_DUMP"
        echo "  ⏱️  Tempo:    ${TEMPO_DUMP}s"
        echo ""
        exit 0
    fi

    # ==========================================
    # MODO 1: BACKUP + RESTORE - fluxo padrão
    # ==========================================

    # Listar destinos como array
    DESTINOS=("${(@f)$(jq -r '.destinos | keys[]' "$CONFIG_FILE")}")

    echo -e "${YELLOW}Selecione o DESTINO:${NC}"
    for i in {1..${#DESTINOS[@]}}; do
        servidor=$(get_destino "${DESTINOS[$i]}" "servidor")
        porta=$(get_destino "${DESTINOS[$i]}" "porta")
        porta_str=""
        [ "$porta" != "null" ] && [ -n "$porta" ] && porta_str=":$porta"
        echo -e "  ${CYAN}[$i]${NC} ${DESTINOS[$i]} ($servidor$porta_str)"
    done
    echo ""
    echo -n -e "${YELLOW}Opção: ${NC}"
    read -r OPT_DESTINO

    if [[ ! "$OPT_DESTINO" =~ ^[0-9]+$ ]] || [ "$OPT_DESTINO" -lt 1 ] || [ "$OPT_DESTINO" -gt "${#DESTINOS[@]}" ]; then
        error "Opção inválida"
    fi
    destino="${DESTINOS[$OPT_DESTINO]}"
    echo ""

    # Carregar config da origem para listar bancos
    servidororigem_tmp=$(get_origem "$origem" "servidor")
    usuarioorigem_tmp=$(get_origem "$origem" "usuario")
    senhaorigem_tmp=$(get_origem "$origem" "senha")
    porta_origem_tmp=$(get_origem "$origem" "porta")
    portaorigem_tmp=""
    [ "$porta_origem_tmp" != "null" ] && [ -n "$porta_origem_tmp" ] && portaorigem_tmp="-P $porta_origem_tmp"

    # Listar bancos da origem
    step "Conectando em '$origem' para listar bancos..."
    echo ""

    # Usar mysql do destino selecionado para conectar na origem
    mysql_bin=$(get_destino "$destino" "binarios.mysql")

    BANCOS_ORIGEM=$($mysql_bin $portaorigem_tmp -h "$servidororigem_tmp" -u "$usuarioorigem_tmp" -p"$senhaorigem_tmp" -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$")

    if [ -z "$BANCOS_ORIGEM" ]; then
        warning "Não foi possível listar bancos. Digite manualmente."
        echo -n -e "${YELLOW}Nome do banco de dados ORIGEM: ${NC}"
        read -r basededadosorigem
        [ -z "$basededadosorigem" ] && error "Nome do banco origem é obrigatório"
    else
        BANCOS_ARRAY=("${(@f)BANCOS_ORIGEM}")

        echo -e "${YELLOW}Selecione o BANCO DE DADOS (origem):${NC}"
        for i in {1..${#BANCOS_ARRAY[@]}}; do
            echo -e "  ${CYAN}[$i]${NC} ${BANCOS_ARRAY[$i]}"
        done
        echo ""
        echo -n -e "${YELLOW}Opção: ${NC}"
        read -r OPT_BANCO

        if [[ ! "$OPT_BANCO" =~ ^[0-9]+$ ]] || [ "$OPT_BANCO" -lt 1 ] || [ "$OPT_BANCO" -gt "${#BANCOS_ARRAY[@]}" ]; then
            error "Opção inválida"
        fi
        basededadosorigem="${BANCOS_ARRAY[$OPT_BANCO]}"
    fi
    echo ""

    # Carregar config do destino para listar bancos
    servidordestino_tmp=$(get_destino "$destino" "servidor")
    usuariodestino_tmp=$(get_destino "$destino" "usuario")
    senhadestino_tmp=$(get_destino "$destino" "senha")
    porta_destino_tmp=$(get_destino "$destino" "porta")
    portadestino_tmp=""
    [ "$porta_destino_tmp" != "null" ] && [ -n "$porta_destino_tmp" ] && portadestino_tmp="-P $porta_destino_tmp"

    # Listar bancos do destino
    step "Conectando em '$destino' para listar bancos..."
    echo ""

    BANCOS_DESTINO=$($mysql_bin $portadestino_tmp -h "$servidordestino_tmp" -u "$usuariodestino_tmp" -p"$senhadestino_tmp" -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$")

    if [ -z "$BANCOS_DESTINO" ]; then
        warning "Não foi possível listar bancos. Digite manualmente."
        echo -n -e "${YELLOW}Nome do banco de dados DESTINO [${basededadosorigem}]: ${NC}"
        read -r basededadosdestino
        [ -z "$basededadosdestino" ] && basededadosdestino="$basededadosorigem"
    else
        BANCOS_DEST_ARRAY=("${(@f)BANCOS_DESTINO}")

        echo -e "${YELLOW}Selecione o BANCO DE DADOS (destino):${NC}"
        echo -e "  ${CYAN}[0]${NC} ${basededadosorigem} (mesmo nome da origem)"
        for i in {1..${#BANCOS_DEST_ARRAY[@]}}; do
            echo -e "  ${CYAN}[$i]${NC} ${BANCOS_DEST_ARRAY[$i]}"
        done
        echo ""
        echo -n -e "${YELLOW}Opção [0]: ${NC}"
        read -r OPT_BANCO_DEST

        # Default é 0 (mesmo nome)
        [ -z "$OPT_BANCO_DEST" ] && OPT_BANCO_DEST=0

        if [ "$OPT_BANCO_DEST" -eq 0 ]; then
            basededadosdestino="$basededadosorigem"
        elif [[ ! "$OPT_BANCO_DEST" =~ ^[0-9]+$ ]] || [ "$OPT_BANCO_DEST" -lt 0 ] || [ "$OPT_BANCO_DEST" -gt "${#BANCOS_DEST_ARRAY[@]}" ]; then
            error "Opção inválida"
        else
            basededadosdestino="${BANCOS_DEST_ARRAY[$OPT_BANCO_DEST]}"
        fi
    fi
    echo ""
fi

# Parse argumentos
while [[ $# -gt 1 ]]; do
    key="$1"
    case $key in
        -basededadosdestino)
            basededadosdestino="$2"
            shift
            ;;
        -basededadosorigem)
            basededadosorigem="$2"
            shift
            ;;
        -origem)
            origem="$2"
            shift
            ;;
        -destino)
            destino="$2"
            shift
            ;;
        *)
            # unknown option
            ;;
    esac
    shift
done

# Validações
echo ""
echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Cópia de Banco de Dados${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

[ -z "$basededadosdestino" ] && error "Parâmetro -basededadosdestino é obrigatório"
[ -z "$basededadosorigem" ] && error "Parâmetro -basededadosorigem é obrigatório"
[ -z "$origem" ] && error "Parâmetro -origem é obrigatório"
[ -z "$destino" ] && error "Parâmetro -destino é obrigatório"

# Validar origem existe no JSON
if [[ -z "$(get_origem "$origem" "servidor")" ]]; then
    error "Origem '$origem' não encontrada!\n   Disponíveis: $(listar_origens)"
fi

# Validar destino existe no JSON
if [[ -z "$(get_destino "$destino" "servidor")" ]]; then
    error "Destino '$destino' não encontrado!\n   Disponíveis: $(listar_destinos)"
fi

# Carregar configurações de origem
servidororigem=$(get_origem "$origem" "servidor")
usuarioorigem=$(get_origem "$origem" "usuario")
senhaorigem=$(get_origem "$origem" "senha")
porta_origem=$(get_origem "$origem" "porta")
[ "$porta_origem" != "null" ] && [ -n "$porta_origem" ] && portaorigem="-P $porta_origem"

# Carregar configurações de destino
servidordestino=$(get_destino "$destino" "servidor")
usuariodestino=$(get_destino "$destino" "usuario")
senhadestino=$(get_destino "$destino" "senha")
porta_destino=$(get_destino "$destino" "porta")
[ "$porta_destino" != "null" ] && [ -n "$porta_destino" ] && portadestino="-P $porta_destino"

# Binários MySQL
mysqldump=$(get_destino "$destino" "binarios.mysqldump")
mysql=$(get_destino "$destino" "binarios.mysql")

# Configurações gerais
arquivosql=$(get_config "arquivosql")
DUMP_FLAGS=$(get_config "dump_flags")

# Exibir configuração
echo -e "${YELLOW}Configuração:${NC}"
echo "  ┌─────────────────────────────────────────"
echo "  │ Origem:   $origem ($servidororigem${porta_origem:+:$porta_origem})"
echo "  │ Banco:    $basededadosorigem"
echo "  │ Destino:  $destino ($servidordestino${porta_destino:+:$porta_destino})"
echo "  │ Banco:    $basededadosdestino"
echo "  └─────────────────────────────────────────"
echo ""

# Confirmação
echo -n -e "${YELLOW}Deseja continuar? (s/N): ${NC}"
read -r CONFIRMA
if [[ ! "$CONFIRMA" =~ ^[Ss]$ ]]; then
    info "Operação cancelada"
    exit 0
fi
echo ""

# Limpar arquivo anterior
rm -rf "$arquivosql"

# ==========================================
# DUMP DA ORIGEM
# ==========================================
step "Iniciando dump de '$basededadosorigem' em '$origem'..."
echo ""

INICIO_DUMP=$(date +%s)

info "Servidor: $servidororigem"
info "Usuário:  $usuarioorigem"
info "Flags:    $DUMP_FLAGS"
echo ""

# Executar dump em background com spinner
$mysqldump ${=DUMP_FLAGS} $portaorigem -h "$servidororigem" -u "$usuarioorigem" -p"$senhaorigem" "$basededadosorigem" > "$arquivosql" 2>/tmp/dump_error.txt &
DUMP_PID=$!
spinner $DUMP_PID "Fazendo dump de '$basededadosorigem'"
wait $DUMP_PID
DUMP_EXIT_CODE=$?
DUMP_ERROR=$(cat /tmp/dump_error.txt 2>/dev/null)

if [ $DUMP_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}Erro do mysqldump:${NC}"
    echo "$DUMP_ERROR"
    echo ""
    error "Falha no dump do banco de dados (exit code: $DUMP_EXIT_CODE)"
fi

FIM_DUMP=$(date +%s)
TEMPO_DUMP=$((FIM_DUMP - INICIO_DUMP))
TAMANHO_DUMP=$(du -h "$arquivosql" | cut -f1)

success "Dump concluído!"
echo "  ├─ Tempo:   ${TEMPO_DUMP}s"
echo "  └─ Tamanho: $TAMANHO_DUMP"
echo ""

# ==========================================
# RESTAURAÇÃO NO DESTINO
# ==========================================
step "Restaurando '$basededadosdestino' em '$destino'..."
echo ""

INICIO_RESTORE=$(date +%s)

info "Servidor: $servidordestino"
info "Usuário:  $usuariodestino"
echo ""

# Executar restore em background com spinner
$mysql $portadestino -h "$servidordestino" -u "$usuariodestino" -p"$senhadestino" "$basededadosdestino" < "$arquivosql" 2>/tmp/restore_error.txt &
RESTORE_PID=$!
spinner $RESTORE_PID "Restaurando '$basededadosdestino'"
wait $RESTORE_PID
RESTORE_EXIT_CODE=$?

if [ $RESTORE_EXIT_CODE -ne 0 ]; then
    RESTORE_ERROR=$(cat /tmp/restore_error.txt 2>/dev/null)
    echo -e "${RED}Erro do mysql:${NC}"
    echo "$RESTORE_ERROR"
    error "Falha na restauração do banco de dados"
fi

FIM_RESTORE=$(date +%s)
TEMPO_RESTORE=$((FIM_RESTORE - INICIO_RESTORE))

success "Restauração concluída!"
echo "  └─ Tempo: ${TEMPO_RESTORE}s"
echo ""

# ==========================================
# RESUMO FINAL
# ==========================================
TEMPO_TOTAL=$((TEMPO_DUMP + TEMPO_RESTORE))

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  Cópia finalizada com sucesso!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo "  📦 Banco:        $basededadosorigem → $basededadosdestino"
echo "  🌐 Servidores:   $origem → $destino"
echo "  📁 Arquivo:      $TAMANHO_DUMP"
echo "  ⏱️  Tempo total:  ${TEMPO_TOTAL}s (dump: ${TEMPO_DUMP}s + restore: ${TEMPO_RESTORE}s)"
echo ""
