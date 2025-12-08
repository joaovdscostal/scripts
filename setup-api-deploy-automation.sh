#!/bin/bash

# ==========================================
# Script para Configurar Deploy Automático de APIs Spring Boot
# ==========================================
#
# Uso: ./setup-api-deploy-automation.sh NOME_DA_API
#
# Exemplo: ./setup-api-deploy-automation.sh dimensao-api
#

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funções de output
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# Configurações conhecidas de APIs
declare -A APIS_INFO
# Formato: "nome|branch|host|service_name|jar_name|java_version"
APIS_INFO=(
    ["dimensao-api"]="main|api.vipp.art.br|dimensao-api|dimensao-api-0.0.1-SNAPSHOT.jar|17"
)

usage() {
    echo -e "${RED}Uso: $0 NOME_DA_API${NC}"
    echo ""
    echo "APIs conhecidas:"
    for api in "${!APIS_INFO[@]}"; do
        IFS="|" read -r branch host service jar java <<< "${APIS_INFO[$api]}"
        echo "  - $api (branch: $branch, java: $java)"
    done
    echo ""
    echo "Para APIs não listadas, o script tentará detectar automaticamente."
    exit 1
}

detect_api_info() {
    local api_name=$1
    local api_dir=$2

    info "Detectando informações da API..."

    # Detectar branch
    cd "$api_dir"
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    success "Branch detectada: $BRANCH"

    # Detectar JAR name do pom.xml
    if [ -f "pom.xml" ]; then
        ARTIFACT_ID=$(grep -oP '<artifactId>\K[^<]+' pom.xml | head -1)
        VERSION=$(grep -oP '<version>\K[^<]+' pom.xml | head -2 | tail -1)
        JAR_NAME="${ARTIFACT_ID}-${VERSION}.jar"
        success "JAR detectado: $JAR_NAME"
    else
        warning "pom.xml não encontrado, usando padrão"
        JAR_NAME="${api_name}-0.0.1-SNAPSHOT.jar"
    fi

    # Detectar Java version do pom.xml
    if [ -f "pom.xml" ]; then
        JAVA_VER=$(grep -oP '<java.version>\K[^<]+' pom.xml | head -1)
        if [ -z "$JAVA_VER" ]; then
            JAVA_VER="17"
        fi
        success "Java version detectada: $JAVA_VER"
    else
        JAVA_VER="17"
    fi

    # Detectar host do application.properties
    if [ -f "src/main/resources/application.properties" ]; then
        HOST=$(grep -oP 'url.base.acesso.projeto=https?://\K[^/]+' src/main/resources/application.properties | head -1)
        if [ -z "$HOST" ]; then
            warning "Host não encontrado, usando padrão"
            HOST="${api_name}.appjvs.com.br"
        else
            success "Host detectado: $HOST"
        fi
    else
        warning "application.properties não encontrado"
        HOST="${api_name}.appjvs.com.br"
    fi

    # Service name geralmente é o mesmo que o projeto
    SERVICE_NAME=$api_name

    # Retornar informações
    echo "$BRANCH|$HOST|$SERVICE_NAME|$JAR_NAME|$JAVA_VER"
}

# Verificar argumentos
if [ $# -lt 1 ]; then
    error "Faltou especificar a API"
    usage
fi

API_NAME=$1
API_DIR="/Users/nds/Workspace/sts/$API_NAME"
WORKFLOW_DIR="$API_DIR/.github/workflows"
TEMPLATE="/Users/nds/Workspace/scripts/deploy-api-workflow-template.yml"

echo ""
info "Configurando deploy automático para API: $API_NAME"
echo ""

# Verificar se diretório existe
[ ! -d "$API_DIR" ] && error "Diretório não encontrado: $API_DIR"
success "Diretório da API encontrado"

# Verificar se é git
[ ! -d "$API_DIR/.git" ] && error "Não é um repositório git: $API_DIR"
success "Repositório git válido"

# Verificar se é projeto Spring Boot
if [ ! -f "$API_DIR/pom.xml" ]; then
    error "pom.xml não encontrado. Este script é para APIs Spring Boot Maven"
fi
success "Projeto Maven encontrado"

# Verificar template
[ ! -f "$TEMPLATE" ] && error "Template não encontrado: $TEMPLATE"
success "Template encontrado"

# Obter informações da API
if [ -n "${APIS_INFO[$API_NAME]}" ]; then
    info "Usando configuração pré-definida"
    IFS="|" read -r BRANCH HOST SERVICE_NAME JAR_NAME JAVA_VER <<< "${APIS_INFO[$API_NAME]}"
else
    info "API não está na lista, detectando automaticamente..."
    API_INFO=$(detect_api_info "$API_NAME" "$API_DIR")
    IFS="|" read -r BRANCH HOST SERVICE_NAME JAR_NAME JAVA_VER <<< "$API_INFO"
fi

# Mostrar informações
echo ""
info "Configuração detectada:"
echo "  Branch: $BRANCH"
echo "  Host: $HOST"
echo "  Service: $SERVICE_NAME"
echo "  JAR: $JAR_NAME"
echo "  Java: $JAVA_VER"
echo ""

# Confirmar
echo -n "Está correto? (S/n): "
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    error "Configuração cancelada. Edite o script para ajustar valores."
fi

# Criar diretório workflows
mkdir -p "$WORKFLOW_DIR"
success "Diretório workflows criado"

# Copiar e personalizar template
WORKFLOW_FILE="$WORKFLOW_DIR/deploy-producao.yml"

if [ -f "$WORKFLOW_FILE" ]; then
    warning "Arquivo workflow já existe: $WORKFLOW_FILE"
    echo -n "Deseja sobrescrever? (s/N): "
    read -r RESPOSTA
    [[ ! "$RESPOSTA" =~ ^[Ss]$ ]] && { info "Operação cancelada"; exit 0; }
fi

# Copiar template
cp "$TEMPLATE" "$WORKFLOW_FILE"

# Substituir variáveis
sed -i.bak "s/PROJECT_NAME: NOME_DA_API/PROJECT_NAME: $API_NAME/g" "$WORKFLOW_FILE"
sed -i.bak "s/SERVER_HOST: api.seudominio.com.br/SERVER_HOST: $HOST/g" "$WORKFLOW_FILE"
sed -i.bak "s|SERVER_PATH: /root/apis/NOME_DA_API|SERVER_PATH: /root/apis/$API_NAME|g" "$WORKFLOW_FILE"
sed -i.bak "s/SERVICE_NAME: NOME_DA_API/SERVICE_NAME: $SERVICE_NAME/g" "$WORKFLOW_FILE"
sed -i.bak "s/JAR_NAME: NOME_DA_API-0.0.1-SNAPSHOT.jar/JAR_NAME: $JAR_NAME/g" "$WORKFLOW_FILE"
sed -i.bak "s/JAVA_VERSION: '17'/JAVA_VERSION: '$JAVA_VER'/g" "$WORKFLOW_FILE"

# Ajustar branch se necessário
if [ "$BRANCH" != "main" ]; then
    sed -i.bak "s/- main  # OU master/- $BRANCH  # Branch principal/g" "$WORKFLOW_FILE"
    sed -i.bak "s/origin\/main/origin\/$BRANCH/g" "$WORKFLOW_FILE"
fi

rm "$WORKFLOW_FILE.bak"

success "Workflow criado: $WORKFLOW_FILE"

# Testar conexão SSH
echo ""
info "Testando conexão SSH..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "root@$HOST" "echo 'SSH OK'" 2>/dev/null; then
    success "Conexão SSH OK"
else
    warning "Não foi possível conectar via SSH"
fi

# Git add
cd "$API_DIR"
if git ls-files --error-unmatch .github/workflows/deploy-producao.yml > /dev/null 2>&1; then
    info "Workflow já está no git"
else
    git add .github/workflows/deploy-producao.yml
    info "Workflow adicionado ao git"
fi

# Próximos passos
echo ""
echo "=========================================="
success "Configuração concluída!"
echo "=========================================="
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1️⃣  Configurar secret SSH_PRIVATE_KEY no GitHub:"
echo "    https://github.com/SEU_USUARIO/$API_NAME/settings/secrets/actions"
echo ""
echo "2️⃣  Fazer commit e push:"
echo "    cd $API_DIR"
echo "    git commit -m 'Configure automated API deployment'"
echo "    git push origin $BRANCH"
echo ""
echo "3️⃣  Verificar execução:"
echo "    https://github.com/SEU_USUARIO/$API_NAME/actions"
echo ""
echo "4️⃣  Testar a API após deploy:"
echo "    https://$HOST/"
echo "    https://$HOST/swagger-ui.html"
echo ""
echo "=========================================="
echo ""

# Perguntar se quer commit
echo -n "Deseja fazer commit agora? (s/N): "
read -r FAZER_COMMIT

if [[ "$FAZER_COMMIT" =~ ^[Ss]$ ]]; then
    cd "$API_DIR"
    git add .github/workflows/deploy-producao.yml

    if git commit -m "Configure automated API deployment with GitHub Actions" 2>/dev/null; then
        success "Commit criado"

        echo -n "Deseja fazer push agora? (s/N): "
        read -r FAZER_PUSH

        if [[ "$FAZER_PUSH" =~ ^[Ss]$ ]]; then
            if git push origin "$BRANCH"; then
                success "Push realizado!"
                echo ""
                info "Acompanhe: https://github.com/SEU_USUARIO/$API_NAME/actions"
            else
                error "Erro ao fazer push"
            fi
        fi
    else
        warning "Nada para commitar"
    fi
fi

echo ""
success "Script finalizado!"
