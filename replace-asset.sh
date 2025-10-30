#!/bin/bash

# Script para substituir {{asset("...")}} por ${sessao.urlPadrao/urlCss/urlJs}...
# Uso: ./replace_assets.sh caminho/do/arquivo.php

# Verifica se foi fornecido um arquivo
if [ $# -eq 0 ]; then
    echo "Uso: $0 <caminho_do_arquivo>"
    echo "Exemplo: $0 /path/to/file.php"
    exit 1
fi

# Verifica se o arquivo existe
if [ ! -f "$1" ]; then
    echo "Erro: Arquivo '$1' não encontrado!"
    exit 1
fi

# Nome do arquivo
arquivo="$1"

# Criar backup do arquivo original
backup_file="${arquivo}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$arquivo" "$backup_file"
echo "Backup criado: $backup_file"

# Função para processar as substituições
processar_substituicoes() {
    local temp_file=$(mktemp)
    
    # Usar perl para processamento mais avançado com contexto das tags
    perl -0777 -pe '
        # Substituições para tags <link> (CSS)
        s/<link([^>]*href=["'"'"']?){{asset\("([^"]*?)"\)}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        s/<link([^>]*href=["'"'"']?){{asset\('"'"'([^'"'"']*?)'"'"'\)}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        
        # Substituições para assets com ?v= em tags <link>
        s/<link([^>]*href=["'"'"']?){{asset\("([^"]*?)\?v="\s*\.\s*config\([^)]*\)\s*}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        s/<link([^>]*href=["'"'"']?){{asset\("([^"]*?)\?v="\s*\.\s*config\([^)]*\)\s*\)}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        s/<link([^>]*href=["'"'"']?){{asset\("([^"]*?)\?v=[^"]*?"\)}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        s/<link([^>]*href=["'"'"']?){{asset\('"'"'([^'"'"']*?)\?v='"'"'\s*\.\s*config\([^)]*\)\s*}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        s/<link([^>]*href=["'"'"']?){{asset\('"'"'([^'"'"']*?)\?v='"'"'\s*\.\s*config\([^)]*\)\s*\)}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        s/<link([^>]*href=["'"'"']?){{asset\('"'"'([^'"'"']*?)\?v=[^'"'"']*?'"'"'\)}}([^>]*>)/<link$1\${sessao.urlCss}$2$3/g;
        
        # Substituições para tags <script> (JS)
        s/<script([^>]*src=["'"'"']?){{asset\("([^"]*?)"\)}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        s/<script([^>]*src=["'"'"']?){{asset\('"'"'([^'"'"']*?)'"'"'\)}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        
        # Substituições para assets com ?v= em tags <script>
        s/<script([^>]*src=["'"'"']?){{asset\("([^"]*?)\?v="\s*\.\s*config\([^)]*\)\s*}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        s/<script([^>]*src=["'"'"']?){{asset\("([^"]*?)\?v="\s*\.\s*config\([^)]*\)\s*\)}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        s/<script([^>]*src=["'"'"']?){{asset\("([^"]*?)\?v=[^"]*?"\)}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        s/<script([^>]*src=["'"'"']?){{asset\('"'"'([^'"'"']*?)\?v='"'"'\s*\.\s*config\([^)]*\)\s*}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        s/<script([^>]*src=["'"'"']?){{asset\('"'"'([^'"'"']*?)\?v='"'"'\s*\.\s*config\([^)]*\)\s*\)}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        s/<script([^>]*src=["'"'"']?){{asset\('"'"'([^'"'"']*?)\?v=[^'"'"']*?'"'"'\)}}([^>]*>)/<script$1\${sessao.urlJs}$2$3/g;
        
        # Substituições gerais para outros casos (urlPadrao) - ASPAS DUPLAS
        s/{{asset\("([^"]*?)\?v="\s*\.\s*config\([^)]*\)\s*}}/\${sessao.urlPadrao}$1/g;
        s/{{asset\("([^"]*?)\?v="\s*\.\s*config\([^)]*\)\s*\)}}/\${sessao.urlPadrao}$1/g;
        s/{{asset\("([^"]*?)\?v=[^"]*?"\)}}/\${sessao.urlPadrao}$1/g;
        s/{{asset\("([^"]*?)"\)}}/\${sessao.urlPadrao}$1/g;
        
        # Substituições gerais para outros casos (urlPadrao) - ASPAS SIMPLES
        s/{{asset\('"'"'([^'"'"']*?)\?v='"'"'\s*\.\s*config\([^)]*\)\s*}}/\${sessao.urlPadrao}$1/g;
        s/{{asset\('"'"'([^'"'"']*?)\?v='"'"'\s*\.\s*config\([^)]*\)\s*\)}}/\${sessao.urlPadrao}$1/g;
        s/{{asset\('"'"'([^'"'"']*?)\?v=[^'"'"']*?'"'"'\)}}/\${sessao.urlPadrao}$1/g;
        s/{{asset\('"'"'([^'"'"']*?)'"'"'\)}}/\${sessao.urlPadrao}$1/g;
        
        # Para {{url()}} COM ASPAS DUPLAS
        s/{{url\("\/([^"]*?)"\)}}/\${sessao.urlPadrao}$1/g;
        s/{{url\("([^"]*?)"\)}}/\${sessao.urlPadrao}$1/g;
        
        # Para {{url()}} COM ASPAS SIMPLES
        s/{{url\('"'"'\/([^'"'"']*?)'"'"'\)}}/\${sessao.urlPadrao}$1/g;
        s/{{url\('"'"'([^'"'"']*?)'"'"'\)}}/\${sessao.urlPadrao}$1/g;
        
        # Para COMENTÁRIOS DO BLADE (incluindo multilinhas)
        s/\{\{--\s*(.*?)\s*--\}\}/<!-- $1 -->/gs;
        
        # Para VARIÁVEIS DO BLADE (com ou sem espaços)
        s/\{\{\s*\$\s*([^}]+?)\s*\}\}/\${$1}/g;
        
        # Para DIRETIVAS BLADE @section -> JSP
        # Converte @section("nome") para <jsp:attribute name="nome"> (com - -> _)
        s/\@section\(\s*["'"'"']([^"'"'"']*?)["'"'"']\s*\)/<jsp:attribute name="$1">/g;
        
        # Converte hífens para underscores nos nomes dos atributos JSP
        s/(<jsp:attribute name="[^"]*?)-([^"]*?"[^>]*>)/$1_$2/g;
        
        # Para @endsection -> </jsp:attribute>
        s/\@endsection/<\/jsp:attribute>/g;
        
        # CONVERSÃO DE CARACTERES ESPECIAIS PARA HTML ENTITIES (VERSÃO SEGURA)
        # APENAS caracteres acentuados básicos - SEM aspas tipográficas
        # Caracteres acentuados maiúsculos
        s/À/\&Agrave;/g; s/Á/\&Aacute;/g; s/Â/\&Acirc;/g; s/Ã/\&Atilde;/g;
        s/È/\&Egrave;/g; s/É/\&Eacute;/g; s/Ê/\&Ecirc;/g;
        s/Ì/\&Igrave;/g; s/Í/\&Iacute;/g; s/Î/\&Icirc;/g;
        s/Ò/\&Ograve;/g; s/Ó/\&Oacute;/g; s/Ô/\&Ocirc;/g; s/Õ/\&Otilde;/g;
        s/Ù/\&Ugrave;/g; s/Ú/\&Uacute;/g; s/Û/\&Ucirc;/g;
        s/Ç/\&Ccedil;/g; s/Ñ/\&Ntilde;/g;
        
        # Caracteres acentuados minúsculos
        s/à/\&agrave;/g; s/á/\&aacute;/g; s/â/\&acirc;/g; s/ã/\&atilde;/g;
        s/è/\&egrave;/g; s/é/\&eacute;/g; s/ê/\&ecirc;/g;
        s/ì/\&igrave;/g; s/í/\&iacute;/g; s/î/\&icirc;/g;
        s/ò/\&ograve;/g; s/ó/\&oacute;/g; s/ô/\&ocirc;/g; s/õ/\&otilde;/g;
        s/ù/\&ugrave;/g; s/ú/\&uacute;/g; s/û/\&ucirc;/g;
        s/ç/\&ccedil;/g; s/ñ/\&ntilde;/g;
        
        # Para PATHS VENDOR (apenas se já não estiver como js/vendor/)
        s/(?<!js\/)vendor\//js\/vendor\//g;
    ' "$arquivo" > "$temp_file"
    
    # Verificar se houve mudanças
    if ! diff -q "$arquivo" "$temp_file" > /dev/null 2>&1; then
        # Aplicar as mudanças
        mv "$temp_file" "$arquivo"
        echo "✅ Substituições aplicadas com sucesso!"
        
        # Mostrar um resumo das mudanças
        echo ""
        echo "📊 Resumo das substituições aplicadas:"
        echo "CSS (urlCss):"
        grep -o '\${sessao\.urlCss}[^}]*' "$arquivo" | sort | uniq -c | sort -nr || echo "  Nenhuma"
        echo "JS (urlJs):"
        grep -o '\${sessao\.urlJs}[^}]*' "$arquivo" | sort | uniq -c | sort -nr || echo "  Nenhuma"
        echo "Outros (urlPadrao):"
        grep -o '\${sessao\.urlPadrao}[^}]*' "$arquivo" | sort | uniq -c | sort -nr || echo "  Nenhuma"
        echo "Diretivas Blade:"
        grep -o '<jsp:attribute name="[^"]*">' "$arquivo" | sort | uniq -c | sort -nr || echo "  Nenhuma"
        echo "Entidades HTML:"
        grep -o '&[a-zA-Z]*;' "$arquivo" | sort | uniq -c | sort -nr | head -10 || echo "  Nenhuma"
        
    else
        rm "$temp_file"
        echo "ℹ️  Nenhuma substituição foi necessária no arquivo."
    fi
}

# Mostrar preview das mudanças antes de aplicar
echo "🔍 Preview das mudanças que serão feitas:"
echo "----------------------------------------"

# Mostrar linhas que serão alteradas
echo "Assets encontrados:"
grep -n '{{asset(' "$arquivo" | head -10 || echo "Nenhum asset encontrado"

echo ""
echo "URLs encontradas:"
grep -n '{{url(' "$arquivo" | head -5 || echo "Nenhuma URL encontrada"

echo ""
echo "Comentários Blade encontrados:"
grep -n '{{--' "$arquivo" | head -5 || echo "Nenhum comentário Blade encontrado"

echo ""
echo "Diretivas @section encontradas:"
grep -n '@section\|@endsection' "$arquivo" | head -5 || echo "Nenhuma diretiva encontrada"

echo ""
echo "Caracteres especiais encontrados:"
grep -n '[àáâãäèéêëìíîïòóôõöùúûüçñÀÁÂÃÄÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑ""]' "$arquivo" | head -5 || echo "Nenhum caractere especial encontrado"

echo ""
read -p "Deseja continuar com as substituições? (s/N): " confirmacao

case $confirmacao in
    [Ss]|[Ss][Ii][Mm])
        echo "Processando substituições..."
        processar_substituicoes
        ;;
    *)
        echo "Operação cancelada."
        rm "$backup_file"
        exit 0
        ;;
esac

echo ""
echo "✨ Processo concluído!"
echo "📁 Arquivo processado: $arquivo"
echo "💾 Backup salvo em: $backup_file"

# Verificação final - mostrar algumas linhas com as mudanças
echo ""
echo "🔍 Exemplo de algumas linhas após as mudanças:"
echo "--------------------------------------------"
echo "CSS:"
grep -n '\${sessao\.urlCss}' "$arquivo" | head -3 || echo "Nenhuma substituição CSS"
echo "JS:"
grep -n '\${sessao\.urlJs}' "$arquivo" | head -3 || echo "Nenhuma substituição JS"
echo "Outros:"
grep -n '\${sessao\.urlPadrao}' "$arquivo" | head -3 || echo "Nenhuma substituição padrão"
echo "JSP Attributes:"
grep -n '<jsp:attribute' "$arquivo" | head -3 || echo "Nenhuma diretiva convertida"
echo "HTML Entities (sample):"
grep -n '&[a-zA-Z]*;' "$arquivo" | head -3 || echo "Nenhuma entidade HTML"