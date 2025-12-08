#!/bin/bash

# Script para diagnosticar problema de Return Path
# Uso: ./diagnosticar-return-path.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DOMINIO="envios.formeseguro.com.br"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Diagnóstico de Return Path${NC}"
echo -e "${BLUE}  Domínio: ${CYAN}$DOMINIO${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Verificar tipo de registro
echo -e "${YELLOW}[1] Verificando tipo de registro...${NC}\n"

# Verificar CNAME diretamente (sem seguir a cadeia)
cname_result=$(dig +short CNAME "$DOMINIO")
if [ -n "$cname_result" ]; then
    echo -e "${RED}✗ PROBLEMA ENCONTRADO!${NC}"
    echo -e "${RED}  O domínio $DOMINIO está configurado como CNAME${NC}"
    echo -e "${RED}  Aponta para: ${YELLOW}$cname_result${NC}"
    echo -e "\n${RED}  ⚠ Return Path NÃO PODE ser CNAME!${NC}\n"
    tem_cname=1
else
    echo -e "${GREEN}✓ Não é CNAME${NC}\n"
    tem_cname=0
fi

# 2. Verificar registros A
echo -e "${YELLOW}[2] Verificando registros A...${NC}\n"
a_result=$(dig +short A "$DOMINIO" +norecurse | grep -v "^[a-z]")
if [ -n "$a_result" ]; then
    echo -e "${GREEN}✓ Registros A encontrados:${NC}"
    echo "$a_result" | while read ip; do
        echo -e "  ${GREEN}→${NC} $ip"
    done
else
    echo -e "${YELLOW}⚠ Nenhum registro A configurado diretamente${NC}"
fi
echo ""

# 3. Verificar MX
echo -e "${YELLOW}[3] Verificando registros MX...${NC}\n"
mx_result=$(dig +short MX "$DOMINIO")
if [ -n "$mx_result" ]; then
    echo -e "${GREEN}✓ Registros MX encontrados:${NC}"
    echo "$mx_result" | while read line; do
        echo -e "  ${GREEN}→${NC} $line"
    done
else
    echo -e "${YELLOW}⚠ Nenhum registro MX configurado${NC}"
fi
echo ""

# 4. Resolução completa (seguindo CNAME)
echo -e "${YELLOW}[4] Resolução completa (seguindo CNAME):${NC}\n"
full_result=$(dig +short "$DOMINIO")
echo -e "${CYAN}Resultado final:${NC}"
echo "$full_result" | while read line; do
    if [[ "$line" =~ \. ]] && [[ ! "$line" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "  ${YELLOW}→ CNAME:${NC} $line"
    else
        echo -e "  ${GREEN}→ IP:${NC} $line"
    fi
done
echo ""

# 5. Consulta autoritativa
echo -e "${YELLOW}[5] Servidores DNS autoritativos:${NC}\n"
ns_servers=$(dig +short NS formeseguro.com.br)
echo -e "${CYAN}Nameservers:${NC}"
echo "$ns_servers" | while read ns; do
    echo -e "  ${GREEN}→${NC} $ns"
done
echo ""

# 6. Diagnóstico e solução
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  DIAGNÓSTICO${NC}"
echo -e "${BLUE}========================================${NC}\n"

if [ $tem_cname -eq 1 ]; then
    echo -e "${RED}✗ CONFIGURAÇÃO INCORRETA${NC}\n"

    echo -e "${YELLOW}Problema identificado:${NC}"
    echo -e "  O registro ${CYAN}$DOMINIO${NC} está como ${RED}CNAME${NC}"
    echo -e "  Aponta para: ${YELLOW}$cname_result${NC}"
    echo -e "\n${YELLOW}Por que isso é um problema?${NC}"
    echo -e "  • Return Path precisa resolver diretamente para um IP"
    echo -e "  • CNAMEs adicionam uma camada extra de resolução"
    echo -e "  • Servidores de email rejeitam Return Path com CNAME"
    echo -e "  • RFC 5321 não permite CNAME para domínios de email"

    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  SOLUÇÃO${NC}"
    echo -e "${GREEN}========================================${NC}\n"

    # Obter o IP final
    ip_final=$(dig +short "$DOMINIO" | grep "^[0-9]" | head -1)

    echo -e "${CYAN}Passos para corrigir:${NC}\n"
    echo -e "1. ${YELLOW}Acesse seu painel DNS (ex: Registro.br, Cloudflare, etc)${NC}\n"

    echo -e "2. ${YELLOW}REMOVA o registro CNAME:${NC}"
    echo -e "   ${RED}Tipo: CNAME${NC}"
    echo -e "   ${RED}Nome: envios${NC}"
    echo -e "   ${RED}Valor: smtpdlv.com.br${NC}\n"

    echo -e "3. ${YELLOW}ADICIONE um registro A:${NC}"
    echo -e "   ${GREEN}Tipo: A${NC}"
    echo -e "   ${GREEN}Nome: envios${NC}"
    echo -e "   ${GREEN}Valor: $ip_final${NC}"
    echo -e "   ${GREEN}TTL: 3600${NC}\n"

    echo -e "4. ${YELLOW}Aguarde propagação DNS (5-30 minutos)${NC}\n"

    echo -e "5. ${YELLOW}Execute este script novamente para validar${NC}\n"

    echo -e "${CYAN}Comando para validar depois:${NC}"
    echo -e "  ${GREEN}./diagnosticar-return-path.sh${NC}\n"

else
    echo -e "${GREEN}✓ CONFIGURAÇÃO CORRETA${NC}\n"
    echo -e "  O domínio não é CNAME, está configurado corretamente!"
fi

echo -e "${BLUE}========================================${NC}"
