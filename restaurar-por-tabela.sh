#!/bin/zsh

# ==========================================
# Script para Restaurar Dump por Tabela
# ==========================================
# Divide o dump SQL por tabela e restaura mostrando progresso
# Uso: ./restaurar-por-tabela.sh <arquivo.sql>

SCRIPT_DIR="/Users/nds/Workspace/scripts"
CONFIG_FILE="$SCRIPT_DIR/banco-config.json"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Funções de output
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
step() { echo -e "${CYAN}▶ $1${NC}"; }

# Verificar dependências
if ! command -v jq &> /dev/null; then
    error "jq não está instalado. Instale com: brew install jq"
fi

# Verificar se pv está instalado
PV_AVAILABLE=false
if command -v pv &> /dev/null; then
    PV_AVAILABLE=true
fi

# Funções para ler config
get_destino() {
    local key=$1
    local field=$2
    jq -r ".destinos[\"$key\"].$field // empty" "$CONFIG_FILE"
}

# Help
if [ $# -lt 1 ] || [[ "$1" == "--help" ]]; then
    echo ""
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Restaurar Dump por Tabela${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC}"
    echo "  ./restaurar-por-tabela.sh <arquivo.sql>"
    echo ""
    echo -e "${YELLOW}Exemplo:${NC}"
    echo "  ./restaurar-por-tabela.sh /Users/nds/Workspace/dados/backup_sysbet.sql"
    echo ""
    echo -e "${YELLOW}O que faz:${NC}"
    echo "  1. Analisa o dump e identifica todas as tabelas"
    echo "  2. Divide o dump em arquivos separados por tabela"
    echo "  3. Restaura cada tabela mostrando progresso"
    echo "  4. Limpa arquivos temporários ao finalizar"
    echo ""
    exit 0
fi

ARQUIVO_DUMP="$1"

# Validar arquivo
if [ ! -f "$ARQUIVO_DUMP" ]; then
    error "Arquivo não encontrado: $ARQUIVO_DUMP"
fi

TAMANHO_ARQUIVO=$(du -h "$ARQUIVO_DUMP" | cut -f1)
NOME_ARQUIVO=$(basename "$ARQUIVO_DUMP")

echo ""
echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Restaurar Dump por Tabela${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""
echo -e "${YELLOW}Arquivo:${NC} $NOME_ARQUIVO ($TAMANHO_ARQUIVO)"
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

# Carregar config do destino
servidordestino=$(get_destino "$destino" "servidor")
usuariodestino=$(get_destino "$destino" "usuario")
senhadestino=$(get_destino "$destino" "senha")
porta_destino=$(get_destino "$destino" "porta")
portadestino=""
[ "$porta_destino" != "null" ] && [ -n "$porta_destino" ] && portadestino="-P $porta_destino"

mysql=$(get_destino "$destino" "binarios.mysql")

# Listar bancos do destino
step "Conectando em '$destino' para listar bancos..."
echo ""

BANCOS_DESTINO=$($mysql $portadestino -h "$servidordestino" -u "$usuariodestino" -p"$senhadestino" -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$")

if [ -z "$BANCOS_DESTINO" ]; then
    warning "Não foi possível listar bancos. Digite manualmente."
    echo -n -e "${YELLOW}Nome do banco de dados: ${NC}"
    read -r basededadosdestino
    [ -z "$basededadosdestino" ] && error "Nome do banco é obrigatório"
else
    BANCOS_DEST_ARRAY=("${(@f)BANCOS_DESTINO}")

    echo -e "${YELLOW}Selecione o BANCO DE DADOS:${NC}"
    for i in {1..${#BANCOS_DEST_ARRAY[@]}}; do
        echo -e "  ${CYAN}[$i]${NC} ${BANCOS_DEST_ARRAY[$i]}"
    done
    echo ""
    echo -n -e "${YELLOW}Opção: ${NC}"
    read -r OPT_BANCO

    if [[ ! "$OPT_BANCO" =~ ^[0-9]+$ ]] || [ "$OPT_BANCO" -lt 1 ] || [ "$OPT_BANCO" -gt "${#BANCOS_DEST_ARRAY[@]}" ]; then
        error "Opção inválida"
    fi
    basededadosdestino="${BANCOS_DEST_ARRAY[$OPT_BANCO]}"
fi
echo ""

# Criar diretório temporário
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Analisando dump...${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

step "Identificando tabelas no dump..."

# Extrair lista de tabelas
TABELAS=($(grep -o "^-- Table structure for table \`[^\`]*\`" "$ARQUIVO_DUMP" | sed "s/.*\`\([^\`]*\)\`.*/\1/"))

if [ ${#TABELAS[@]} -eq 0 ]; then
    # Tentar outro padrão
    TABELAS=($(grep -o "^CREATE TABLE \`[^\`]*\`" "$ARQUIVO_DUMP" | sed "s/.*\`\([^\`]*\)\`.*/\1/" | sort -u))
fi

TOTAL_TABELAS=${#TABELAS[@]}

if [ $TOTAL_TABELAS -eq 0 ]; then
    error "Nenhuma tabela encontrada no dump"
fi

success "Encontradas $TOTAL_TABELAS tabelas"
echo ""

# Mostrar resumo
echo -e "${YELLOW}Configuração:${NC}"
echo "  ┌─────────────────────────────────────────"
echo "  │ Arquivo:  $NOME_ARQUIVO ($TAMANHO_ARQUIVO)"
echo "  │ Destino:  $destino ($servidordestino${porta_destino:+:$porta_destino})"
echo "  │ Banco:    $basededadosdestino"
echo "  │ Tabelas:  $TOTAL_TABELAS"
echo "  └─────────────────────────────────────────"
echo ""

# Perguntar se quer pular alguma tabela
echo -e "${YELLOW}Deseja pular alguma tabela? (ex: activity_logs,failed_jobs)${NC}"
echo -n -e "${CYAN}Tabelas a pular (Enter para nenhuma): ${NC}"
read -r TABELAS_PULAR

# Converter para array
PULAR_ARRAY=()
if [ -n "$TABELAS_PULAR" ]; then
    IFS=',' read -rA PULAR_ARRAY <<< "$TABELAS_PULAR"
    # Trim whitespace
    for i in {1..${#PULAR_ARRAY[@]}}; do
        PULAR_ARRAY[$i]=$(echo "${PULAR_ARRAY[$i]}" | xargs)
    done
    echo ""
    warning "Serão puladas ${#PULAR_ARRAY[@]} tabela(s): ${PULAR_ARRAY[*]}"
fi
echo ""

# Confirmação
echo -n -e "${YELLOW}Deseja continuar? (s/N): ${NC}"
read -r CONFIRMA
if [[ ! "$CONFIRMA" =~ ^[Ss]$ ]]; then
    info "Operação cancelada"
    exit 0
fi
echo ""

# Extrair header do dump (configurações iniciais)
step "Extraindo header do dump..."
sed -n '1,/^-- Table structure/p' "$ARQUIVO_DUMP" | head -n -1 > "$TEMP_DIR/00_header.sql"

# Executar header primeiro + desabilitar FK checks
step "Aplicando configurações iniciais e desabilitando FK checks..."
{
    cat "$TEMP_DIR/00_header.sql"
    echo "SET FOREIGN_KEY_CHECKS=0;"
    echo "SET UNIQUE_CHECKS=0;"
    echo "SET AUTOCOMMIT=0;"
} | $mysql $portadestino -h "$servidordestino" -u "$usuariodestino" -p"$senhadestino" "$basededadosdestino" 2>/dev/null
echo ""

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Restaurando tabelas${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

INICIO_TOTAL=$(date +%s)
TABELAS_OK=0
TABELAS_ERRO=0

# Função para verificar se tabela deve ser pulada
deve_pular() {
    local tabela=$1
    for pular in "${PULAR_ARRAY[@]}"; do
        if [ "$tabela" = "$pular" ]; then
            return 0
        fi
    done
    return 1
}

TABELAS_PULADAS=0

# Processar cada tabela
for i in {1..${#TABELAS[@]}}; do
    tabela="${TABELAS[$i]}"

    # Verificar se deve pular
    if deve_pular "$tabela"; then
        echo -e "${MAGENTA}[$i/$TOTAL_TABELAS]${NC} ${BOLD}$tabela${NC}"
        echo -e "  ${YELLOW}⏭ Pulada (conforme solicitado)${NC}"
        echo ""
        ((TABELAS_PULADAS++))
        continue
    fi

    echo -e "${MAGENTA}[$i/$TOTAL_TABELAS]${NC} ${BOLD}$tabela${NC}"

    # Extrair dados da tabela do dump
    # Pega desde "-- Table structure for table `tabela`" até a próxima tabela ou fim
    ARQUIVO_TABELA="$TEMP_DIR/tabela_${i}.sql"

    # Criar arquivo com FK checks desabilitados + dados da tabela
    {
        echo "SET FOREIGN_KEY_CHECKS=0;"
        echo "SET UNIQUE_CHECKS=0;"
        # Usar awk para extrair a seção da tabela
        awk -v tabela="$tabela" '
            BEGIN { printing = 0 }
            /^-- Table structure for table/ {
                if (printing) exit
                if (index($0, "`" tabela "`") > 0) printing = 1
            }
            /^-- Dumping data for table/ {
                if (index($0, "`" tabela "`") > 0) printing = 1
            }
            printing { print }
        ' "$ARQUIVO_DUMP"
        echo "COMMIT;"
    } > "$ARQUIVO_TABELA"

    # Verificar se extraiu algo
    if [ ! -s "$ARQUIVO_TABELA" ]; then
        echo -e "  ${YELLOW}⚠ Tabela vazia ou não encontrada${NC}"
        continue
    fi

    TAMANHO_TABELA=$(du -h "$ARQUIVO_TABELA" | cut -f1)

    # Restaurar tabela
    INICIO_TABELA=$(date +%s)

    if [ "$PV_AVAILABLE" = true ]; then
        pv -N "  Restaurando" "$ARQUIVO_TABELA" | $mysql $portadestino -h "$servidordestino" -u "$usuariodestino" -p"$senhadestino" "$basededadosdestino" 2>/tmp/restore_error_$i.txt
        RESTORE_EXIT=$?
    else
        $mysql $portadestino -h "$servidordestino" -u "$usuariodestino" -p"$senhadestino" "$basededadosdestino" < "$ARQUIVO_TABELA" 2>/tmp/restore_error_$i.txt
        RESTORE_EXIT=$?
    fi

    FIM_TABELA=$(date +%s)
    TEMPO_TABELA=$((FIM_TABELA - INICIO_TABELA))

    if [ $RESTORE_EXIT -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} Concluído em ${TEMPO_TABELA}s ($TAMANHO_TABELA)"
        ((TABELAS_OK++))
    else
        ERRO=$(cat /tmp/restore_error_$i.txt 2>/dev/null | head -3)
        echo -e "  ${RED}✗ Erro: $ERRO${NC}"
        ((TABELAS_ERRO++))
    fi

    # Limpar arquivo da tabela para liberar espaço
    rm -f "$ARQUIVO_TABELA"

    echo ""
done

FIM_TOTAL=$(date +%s)
TEMPO_TOTAL=$((FIM_TOTAL - INICIO_TOTAL))

# Formatar tempo
if [ $TEMPO_TOTAL -ge 3600 ]; then
    TEMPO_FMT="$((TEMPO_TOTAL/3600))h $((TEMPO_TOTAL%3600/60))m $((TEMPO_TOTAL%60))s"
elif [ $TEMPO_TOTAL -ge 60 ]; then
    TEMPO_FMT="$((TEMPO_TOTAL/60))m $((TEMPO_TOTAL%60))s"
else
    TEMPO_FMT="${TEMPO_TOTAL}s"
fi

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  Restauração Finalizada${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo "  📦 Banco:         $basededadosdestino"
echo "  🌐 Servidor:      $destino"
echo "  📁 Arquivo:       $TAMANHO_ARQUIVO"
echo "  📋 Tabelas:       $TOTAL_TABELAS"
echo "  ✅ Sucesso:       $TABELAS_OK"
[ $TABELAS_PULADAS -gt 0 ] && echo "  ⏭  Puladas:       $TABELAS_PULADAS"
[ $TABELAS_ERRO -gt 0 ] && echo "  ❌ Erros:         $TABELAS_ERRO"
echo "  ⏱️  Tempo total:   $TEMPO_FMT"
echo ""

# Reabilitar FK checks no final
step "Reabilitando FK checks..."
echo "SET FOREIGN_KEY_CHECKS=1; SET UNIQUE_CHECKS=1;" | $mysql $portadestino -h "$servidordestino" -u "$usuariodestino" -p"$senhadestino" "$basededadosdestino" 2>/dev/null
success "Concluído!"
echo ""
