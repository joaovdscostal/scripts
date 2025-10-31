#!/bin/bash
# ============================================================================
# SCRIPT DE TESTE DE NOTIFICAÇÃO WHATSAPP
# ============================================================================
# Este script testa o envio de notificações via WhatsApp
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
echo "TESTE DE NOTIFICAÇÃO WHATSAPP"
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

if [ "${SEND_WHATSAPP_NOTIFICATION:-false}" = true ]; then
    log_ok "SEND_WHATSAPP_NOTIFICATION=true"
else
    log_error "SEND_WHATSAPP_NOTIFICATION=false ou não definido"
    log_warning "Edite backup.conf e defina: SEND_WHATSAPP_NOTIFICATION=true"
    exit 1
fi

if [ -n "${WHATSAPP_NUMBER:-}" ]; then
    log_ok "WHATSAPP_NUMBER: ${WHATSAPP_NUMBER}"
else
    log_error "WHATSAPP_NUMBER não definido"
    exit 1
fi

if [ -n "${WHATSAPP_API_URL:-}" ]; then
    log_ok "WHATSAPP_API_URL configurado"
else
    log_error "WHATSAPP_API_URL não definido"
    exit 1
fi

if [ -n "${WHATSAPP_API_KEY:-}" ]; then
    log_ok "WHATSAPP_API_KEY configurado"
else
    log_error "WHATSAPP_API_KEY não definido"
    exit 1
fi

echo ""

# ============================================================================
# VERIFICAR CURL
# ============================================================================

echo "2. Verificando Curl"
echo "----------------------------------------"

if command -v curl &> /dev/null; then
    CURL_VERSION=$(curl --version | head -1)
    log_ok "curl instalado: $CURL_VERSION"
else
    log_error "curl não encontrado"
    log_error "Instale com: sudo apt install curl"
    exit 1
fi

echo ""

# ============================================================================
# TESTAR CONECTIVIDADE
# ============================================================================

echo "3. Testando Conectividade com API"
echo "----------------------------------------"

log_info "Testando conexão com ${WHATSAPP_API_URL}..."

# Extrair o host da URL
API_HOST=$(echo "$WHATSAPP_API_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

if ping -c 1 -W 2 "$API_HOST" &> /dev/null; then
    log_ok "Host acessível: $API_HOST"
else
    log_warning "Não foi possível fazer ping em $API_HOST (pode estar bloqueado)"
fi

echo ""

# ============================================================================
# TESTE 1: MENSAGEM SIMPLES
# ============================================================================

echo "4. Teste 1: Mensagem Simples"
echo "----------------------------------------"

log_info "Enviando mensagem de teste simples..."

# Preparar mensagem
MESSAGE1="✅ Teste WhatsApp\n\nMensagem de teste enviada em $(date '+%d/%m/%Y %H:%M:%S')\n\nSe você recebeu esta mensagem, o sistema está funcionando!"

# Preparar payload em uma única linha
PAYLOAD1="{\"number\":\"$WHATSAPP_NUMBER\",\"textMessage\":{\"text\":\"$MESSAGE1\"}}"

echo ""
log_info "PAYLOAD ENVIADO:"
echo "----------------------------------------"
echo "$PAYLOAD1"
echo "----------------------------------------"
echo ""

RESPONSE=$(curl --silent --show-error --location --request POST "$WHATSAPP_API_URL" \
    --header 'Content-Type: application/json' \
    --header "apiKey: $WHATSAPP_API_KEY" \
    --data "$PAYLOAD1" 2>&1)

EXIT_CODE=$?

echo ""
log_info "Código de saída do curl: $EXIT_CODE"
log_info "RESPOSTA COMPLETA DA API:"
echo "----------------------------------------"
echo "$RESPONSE"
echo "----------------------------------------"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    # Verificar se a resposta indica sucesso ou erro
    if echo "$RESPONSE" | grep -q '"statusCode":400\|"statusCode":500\|"type":"entity.parse.failed"'; then
        log_error "API retornou erro HTTP 400/500!"
        echo ""
        echo "Possíveis causas:"
        echo "  1. Formato JSON inválido"
        echo "  2. Caracteres especiais não escapados"
        echo "  3. Payload mal formatado"
    elif echo "$RESPONSE" | grep -q -i '"error"\|"erro"\|"fail"'; then
        log_error "API retornou erro!"
        echo ""
        echo "Verifique:"
        echo "  1. WHATSAPP_API_KEY está correta"
        echo "  2. WHATSAPP_NUMBER está no formato correto (com DDI)"
        echo "  3. A API está funcionando"
    else
        log_ok "Mensagem enviada com sucesso!"
        log_info "Verifique seu WhatsApp: $WHATSAPP_NUMBER"
    fi
else
    log_error "Falha ao enviar mensagem"
    echo ""
    echo "Possíveis causas:"
    echo "  1. Sem conexão com a internet"
    echo "  2. URL da API incorreta"
    echo "  3. Firewall bloqueando a conexão"
fi

echo ""

log_info "Aguardando 3 segundos para evitar rate limit da API..."
sleep 3

# ============================================================================
# TESTE 2: MENSAGEM DE ERRO (SIMULADA)
# ============================================================================

echo "5. Teste 2: Mensagem de Erro (Simulada)"
echo "----------------------------------------"

log_info "Enviando mensagem de erro simulada..."

# Preparar mensagem (usando \n para quebras de linha)
MESSAGE2="⚠️ *Teste de Erro*\n\n📅 Data: $(date '+%d/%m/%Y %H:%M:%S')\n❌ Linha: 123\n🔢 Código: 1\n\n🔧 Comando:\n\`rclone copy teste.txt remote:bucket/\`\n\n❗ Teste de mensagem de erro\n\n📝 Este é apenas um teste!"

# Preparar payload em uma única linha
PAYLOAD2="{\"number\":\"$WHATSAPP_NUMBER\",\"textMessage\":{\"text\":\"$MESSAGE2\"}}"

echo ""
log_info "PAYLOAD ENVIADO:"
echo "----------------------------------------"
echo "$PAYLOAD2"
echo "----------------------------------------"
echo ""

RESPONSE2=$(curl --silent --show-error --location --request POST "$WHATSAPP_API_URL" \
    --header 'Content-Type: application/json' \
    --header "apiKey: $WHATSAPP_API_KEY" \
    --data "$PAYLOAD2" 2>&1)

EXIT_CODE2=$?

echo ""
log_info "Código de saída do curl: $EXIT_CODE2"
log_info "RESPOSTA COMPLETA DA API:"
echo "----------------------------------------"
echo "$RESPONSE2"
echo "----------------------------------------"
echo ""

if [ $EXIT_CODE2 -eq 0 ]; then
    # Verificar se a resposta indica sucesso ou erro
    if echo "$RESPONSE2" | grep -q '"statusCode":400\|"statusCode":500\|"type":"entity.parse.failed"'; then
        log_error "API retornou erro HTTP 400/500!"
    elif echo "$RESPONSE2" | grep -q -i '"error"\|"erro"\|"fail"'; then
        log_error "API retornou erro!"
    else
        log_ok "Mensagem de erro enviada!"
    fi
else
    log_error "Falha ao enviar mensagem de erro"
fi

echo ""

log_info "Aguardando 3 segundos para evitar rate limit da API..."
sleep 3

# ============================================================================
# TESTE 3: MENSAGEM DE SUCESSO (SIMULADA)
# ============================================================================

echo "6. Teste 3: Mensagem de Sucesso (Simulada)"
echo "----------------------------------------"

log_info "Enviando mensagem de sucesso simulada..."

# Preparar mensagem (usando \n para quebras de linha)
MESSAGE3="✅ 🔄 *Teste de Backup Concluído*\n\n📅 Data: $(date '+%d/%m/%Y %H:%M:%S')\n📦 Tamanho: 2.5GB (teste)\n📍 Local: /root/backups/teste.tar.gz\n✅ Status: Sucesso\n\nEste é apenas um teste do sistema de notificações!"

# Preparar payload em uma única linha
PAYLOAD3="{\"number\":\"$WHATSAPP_NUMBER\",\"textMessage\":{\"text\":\"$MESSAGE3\"}}"

echo ""
log_info "PAYLOAD ENVIADO:"
echo "----------------------------------------"
echo "$PAYLOAD3"
echo "----------------------------------------"
echo ""

RESPONSE3=$(curl --silent --show-error --location --request POST "$WHATSAPP_API_URL" \
    --header 'Content-Type: application/json' \
    --header "apiKey: $WHATSAPP_API_KEY" \
    --data "$PAYLOAD3" 2>&1)

EXIT_CODE3=$?

echo ""
log_info "Código de saída do curl: $EXIT_CODE3"
log_info "RESPOSTA COMPLETA DA API:"
echo "----------------------------------------"
echo "$RESPONSE3"
echo "----------------------------------------"
echo ""

if [ $EXIT_CODE3 -eq 0 ]; then
    # Verificar se a resposta indica sucesso ou erro
    if echo "$RESPONSE3" | grep -q '"statusCode":400\|"statusCode":500\|"type":"entity.parse.failed"'; then
        log_error "API retornou erro HTTP 400/500!"
    elif echo "$RESPONSE3" | grep -q -i '"error"\|"erro"\|"fail"'; then
        log_error "API retornou erro!"
    else
        log_ok "Mensagem de sucesso enviada!"
    fi
else
    log_error "Falha ao enviar mensagem de sucesso"
fi

echo ""

# ============================================================================
# RESUMO
# ============================================================================

echo "========================================"
echo "RESUMO DOS TESTES"
echo "========================================"

TOTAL_TESTS=3
PASSED_TESTS=0

if [ $EXIT_CODE -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_ok "Teste 1: Mensagem simples"
else
    log_error "Teste 1: Mensagem simples"
fi

if [ $EXIT_CODE2 -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_ok "Teste 2: Mensagem de erro"
else
    log_error "Teste 2: Mensagem de erro"
fi

if [ $EXIT_CODE3 -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_ok "Teste 3: Mensagem de sucesso"
else
    log_error "Teste 3: Mensagem de sucesso"
fi

echo ""
echo "Resultado: $PASSED_TESTS de $TOTAL_TESTS testes passaram"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    log_ok "Todas as mensagens foram enviadas!"
    log_info "Verifique seu WhatsApp: $WHATSAPP_NUMBER"
    echo ""
    echo "Se você recebeu as 3 mensagens, o sistema está funcionando perfeitamente."
    exit 0
elif [ $PASSED_TESTS -gt 0 ]; then
    log_warning "Alguns testes falharam"
    echo ""
    echo "O sistema está parcialmente funcional."
    echo "Verifique os erros acima para mais detalhes."
    exit 1
else
    log_error "Todos os testes falharam!"
    echo ""
    echo "Checklist de verificação:"
    echo "  1. Verifique as credenciais em backup.conf"
    echo "  2. Teste o curl manualmente:"
    echo "     curl -X POST $WHATSAPP_API_URL \\"
    echo "       -H 'Content-Type: application/json' \\"
    echo "       -H 'apiKey: $WHATSAPP_API_KEY' \\"
    echo "       -d '{\"number\":\"$WHATSAPP_NUMBER\",\"textMessage\":{\"text\":\"teste\"}}'"
    echo "  3. Verifique se a API está online"
    echo "  4. Verifique firewall/conexão de internet"
    exit 1
fi
