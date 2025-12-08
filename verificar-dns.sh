#!/bin/bash

# Script para verificar registros DNS
# Uso: ./verificar-dns.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Verificação de Registros DNS${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Função para verificar CNAME
verificar_cname() {
    local dominio=$1
    local esperado=$2

    echo -e "${YELLOW}Verificando CNAME:${NC} $dominio"

    resultado=$(dig +short CNAME "$dominio" | sed 's/\.$//')

    if [ -z "$resultado" ]; then
        echo -e "${RED}✗ Nenhum registro CNAME encontrado${NC}"
        return 1
    fi

    if [ "$resultado" == "$esperado" ]; then
        echo -e "${GREEN}✓ CNAME correto:${NC} $resultado"
        return 0
    else
        echo -e "${RED}✗ CNAME incorreto${NC}"
        echo -e "  Esperado: ${YELLOW}$esperado${NC}"
        echo -e "  Encontrado: ${RED}$resultado${NC}"
        return 1
    fi
}

# Função para verificar TXT
verificar_txt() {
    local dominio=$1
    local esperado=$2

    echo -e "${YELLOW}Verificando TXT:${NC} $dominio"

    resultado=$(dig +short TXT "$dominio" | tr -d '"')

    if [ -z "$resultado" ]; then
        echo -e "${RED}✗ Nenhum registro TXT encontrado${NC}"
        return 1
    fi

    if [ "$resultado" == "$esperado" ]; then
        echo -e "${GREEN}✓ TXT correto:${NC} $resultado"
        return 0
    else
        echo -e "${RED}✗ TXT incorreto${NC}"
        echo -e "  Esperado: ${YELLOW}$esperado${NC}"
        echo -e "  Encontrado: ${RED}$resultado${NC}"
        return 1
    fi
}

# Função para verificar Return Path (MX records)
verificar_return_path() {
    local dominio=$1

    echo -e "${YELLOW}Verificando Return Path (MX):${NC} $dominio"

    # Verificar se existe registro MX
    resultado_mx=$(dig +short MX "$dominio")

    if [ -z "$resultado_mx" ]; then
        echo -e "${RED}✗ Nenhum registro MX encontrado${NC}"

        # Verificar se tem CNAME (pode ser o problema)
        resultado_cname=$(dig +short CNAME "$dominio" | sed 's/\.$//')
        if [ -n "$resultado_cname" ]; then
            echo -e "${YELLOW}  ⚠ Domínio tem CNAME: $resultado_cname${NC}"
            echo -e "${YELLOW}  ⚠ Return Path não pode ter CNAME, apenas MX ou A/AAAA${NC}"
        fi

        return 1
    fi

    echo -e "${GREEN}✓ Registros MX encontrados:${NC}"
    echo "$resultado_mx" | while read line; do
        echo -e "  ${GREEN}→${NC} $line"
    done

    # Verificar se o CNAME aponta corretamente
    cname_result=$(dig +short CNAME "$dominio" | sed 's/\.$//')
    if [ -n "$cname_result" ]; then
        echo -e "${YELLOW}  ⚠ ATENÇÃO: Return Path tem CNAME ($cname_result)${NC}"
        echo -e "${YELLOW}  ⚠ Isso pode causar problemas - Return Path deve apontar diretamente${NC}"
        return 1
    fi

    return 0
}

# Contador de erros
erros=0

# Verificar CNAMEs
echo -e "${BLUE}--- Verificando CNAMEs ---${NC}\n"

verificar_cname "envios.formeseguro.com.br" "smtpdlv.com.br"
[ $? -ne 0 ] && ((erros++))
echo ""

verificar_cname "_dmarc.envios.formeseguro.com.br" "_dmarc.smtpdlv.com.br"
[ $? -ne 0 ] && ((erros++))
echo ""

# Verificar TXT
echo -e "${BLUE}--- Verificando TXTs ---${NC}\n"

verificar_txt "smtplw.envios.formeseguro.com.br" "27272985162ddbb3eb68ee28465f8887"
[ $? -ne 0 ] && ((erros++))
echo ""

# Verificar Return Path
echo -e "${BLUE}--- Verificando Return Path ---${NC}\n"

verificar_return_path "envios.formeseguro.com.br"
[ $? -ne 0 ] && ((erros++))
echo ""

# Informações adicionais sobre Return Path
echo -e "${BLUE}--- Diagnóstico Completo do Return Path ---${NC}\n"
echo -e "${YELLOW}Registros A/AAAA para envios.formeseguro.com.br:${NC}"
dig +short A envios.formeseguro.com.br
dig +short AAAA envios.formeseguro.com.br

echo -e "\n${YELLOW}Todos os registros DNS para envios.formeseguro.com.br:${NC}"
dig envios.formeseguro.com.br ANY +noall +answer

echo ""

# Resumo final
echo -e "${BLUE}======================================${NC}"
if [ $erros -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os registros DNS estão corretos!${NC}"
else
    echo -e "${RED}✗ Encontrados $erros erro(s) nos registros DNS${NC}"
    echo -e "\n${YELLOW}Possíveis causas do erro de Return Path:${NC}"
    echo -e "  1. Return Path (envios.formeseguro.com.br) está como CNAME"
    echo -e "  2. Deveria ser um registro MX ou A/AAAA direto"
    echo -e "  3. CNAMEs não são permitidos para Return Path"
    echo -e "\n${YELLOW}Solução sugerida:${NC}"
    echo -e "  • Remover o CNAME de envios.formeseguro.com.br"
    echo -e "  • Adicionar um registro A/AAAA apontando para o IP do servidor de email"
    echo -e "  • OU adicionar registros MX se for usado para receber emails"
fi
echo -e "${BLUE}======================================${NC}"

exit $erros
