#!/bin/bash

# Script para verificar DNS conforme instruções da KingHost SMTP Transacional
# Uso: ./verificar-kinghost-smtp.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Verificação DNS - KingHost SMTP${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Contador de validações
total=0
ok=0
falhas=0

echo -e "${CYAN}Verificando configurações solicitadas pela KingHost...${NC}\n"

# ======================
# TESTE 1: CNAME envios
# ======================
echo -e "${YELLOW}[1/3] CNAME: envios.formeseguro.com.br${NC}"
total=$((total + 1))

esperado="smtpdlv.com.br"
resultado=$(dig +short CNAME envios.formeseguro.com.br | sed 's/\.$//')

if [ "$resultado" == "$esperado" ]; then
    echo -e "${GREEN}✓ CNAME configurado corretamente${NC}"
    echo -e "  Aponta para: ${GREEN}$resultado${NC}"
    ok=$((ok + 1))
else
    echo -e "${RED}✗ CNAME incorreto ou ausente${NC}"
    echo -e "  Esperado: ${YELLOW}$esperado${NC}"
    echo -e "  Encontrado: ${RED}${resultado:-[vazio]}${NC}"
    falhas=$((falhas + 1))
fi
echo ""

# ======================
# TESTE 2: CNAME _dmarc
# ======================
echo -e "${YELLOW}[2/3] CNAME: _dmarc.envios.formeseguro.com.br${NC}"
total=$((total + 1))

esperado="_dmarc.smtpdlv.com.br"
resultado=$(dig +short CNAME _dmarc.envios.formeseguro.com.br | sed 's/\.$//')

if [ "$resultado" == "$esperado" ]; then
    echo -e "${GREEN}✓ CNAME _dmarc configurado corretamente${NC}"
    echo -e "  Aponta para: ${GREEN}$resultado${NC}"
    ok=$((ok + 1))
else
    echo -e "${RED}✗ CNAME _dmarc incorreto ou ausente${NC}"
    echo -e "  Esperado: ${YELLOW}$esperado${NC}"
    echo -e "  Encontrado: ${RED}${resultado:-[vazio]}${NC}"
    falhas=$((falhas + 1))
fi
echo ""

# ======================
# TESTE 3: TXT smtplw
# ======================
echo -e "${YELLOW}[3/3] TXT: smtplw.envios.formeseguro.com.br${NC}"
total=$((total + 1))

esperado="27272985162ddbb3eb68ee28465f8887"
resultado=$(dig +short TXT smtplw.envios.formeseguro.com.br | tr -d '"')

if [ "$resultado" == "$esperado" ]; then
    echo -e "${GREEN}✓ TXT configurado corretamente${NC}"
    echo -e "  Valor: ${GREEN}$resultado${NC}"
    ok=$((ok + 1))
else
    echo -e "${RED}✗ TXT incorreto ou ausente${NC}"
    echo -e "  Esperado: ${YELLOW}$esperado${NC}"
    echo -e "  Encontrado: ${RED}${resultado:-[vazio]}${NC}"
    falhas=$((falhas + 1))
fi
echo ""

# ======================
# DIAGNÓSTICO DO RETURN PATH
# ======================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Diagnóstico do Return Path${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificar se existe registro A além do CNAME
echo -e "${CYAN}Verificando resolução completa de envios.formeseguro.com.br:${NC}\n"

# Pegar CNAME
cname_result=$(dig +short CNAME envios.formeseguro.com.br | sed 's/\.$//')
echo -e "  CNAME: ${YELLOW}$cname_result${NC}"

# Pegar IP final
ip_final=$(dig +short envios.formeseguro.com.br | grep "^[0-9]" | head -1)
echo -e "  IP final: ${CYAN}$ip_final${NC}"

# Verificar MX
mx_result=$(dig +short MX envios.formeseguro.com.br)
if [ -n "$mx_result" ]; then
    echo -e "  MX encontrado: ${GREEN}✓${NC}"
else
    echo -e "  MX: ${YELLOW}Nenhum${NC}"
fi
echo ""

# Verificar se há registro A direto (sem CNAME)
a_direto=$(dig +short +norecurse A envios.formeseguro.com.br | grep "^[0-9]")
if [ -n "$a_direto" ]; then
    echo -e "${GREEN}✓ Registro A direto encontrado: $a_direto${NC}"
    echo -e "${GREEN}  (Isso resolve o problema do Return Path!)${NC}"
    tem_a_direto=1
else
    echo -e "${YELLOW}⚠ Não há registro A direto (apenas CNAME)${NC}"
    tem_a_direto=0
fi
echo ""

# ======================
# RESUMO FINAL
# ======================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  RESUMO${NC}"
echo -e "${BLUE}========================================${NC}\n"

if [ $ok -eq $total ]; then
    echo -e "${GREEN}✓ Configurações KingHost: $ok/$total OK${NC}\n"
else
    echo -e "${RED}✗ Configurações KingHost: $ok/$total OK ($falhas falhas)${NC}\n"
fi

# Análise do problema Return Path
if [ $tem_a_direto -eq 0 ]; then
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   PROBLEMA IDENTIFICADO: Return Path  ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}O que está acontecendo:${NC}"
    echo -e "  • KingHost pede para configurar como ${CYAN}CNAME${NC}"
    echo -e "  • Mas o painel deles valida se há ${CYAN}registro A${NC} também"
    echo -e "  • CNAMEs sozinhos não funcionam para Return Path (RFC 5321)"
    echo ""

    echo -e "${GREEN}SOLUÇÃO (configuração híbrida):${NC}\n"

    echo -e "No Cloudflare, você precisa ter ${CYAN}AMBOS${NC} os registros:\n"

    echo -e "${GREEN}1. Manter o CNAME (para KingHost validar):${NC}"
    echo -e "   Tipo: ${CYAN}CNAME${NC}"
    echo -e "   Nome: ${CYAN}envios${NC}"
    echo -e "   Valor: ${CYAN}smtpdlv.com.br${NC}\n"

    echo -e "${GREEN}2. ADICIONAR um registro A (para Return Path funcionar):${NC}"
    echo -e "   Tipo: ${CYAN}A${NC}"
    echo -e "   Nome: ${CYAN}envios${NC}"
    echo -e "   IPv4: ${CYAN}$ip_final${NC}"
    echo -e "   Proxy: ${CYAN}DNS only (nuvem cinza)${NC}\n"

    echo -e "${YELLOW}⚠ ATENÇÃO:${NC}"
    echo -e "  • No Cloudflare, você ${MAGENTA}PODE${NC} ter CNAME + A com mesmo nome"
    echo -e "  • O registro A terá prioridade para resolução"
    echo -e "  • O CNAME ficará visível para a validação da KingHost"
    echo -e "  • Isso resolve ambos os problemas!"

else
    echo -e "${GREEN}✓ Return Path está configurado corretamente!${NC}"
    echo -e "${GREEN}  Há um registro A direto, resolvendo o problema.${NC}"
fi

echo -e "\n${BLUE}========================================${NC}"

if [ $falhas -gt 0 ]; then
    exit 1
else
    exit 0
fi
