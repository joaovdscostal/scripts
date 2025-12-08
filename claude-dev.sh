#!/bin/bash
# ~/Workspace/scripts/claude-dev.sh

TEMPLATES_DIR="/Users/nds/Workspace/scripts/templates"
PROJECT_STANDARDS="PROJECT_STANDARDS.md"
INSTRUCTION_FILE="/tmp/claude-instruction.txt"

# Verifica se já existe PROJECT_STANDARDS.md
if [ -f "$PROJECT_STANDARDS" ]; then
    echo "✅ PROJECT_STANDARDS.md encontrado!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Cole isso no Claude quando abrir:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Leia PROJECT_STANDARDS.md antes de começar"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Salva a instrução no clipboard (Mac)
    echo "Leia PROJECT_STANDARDS.md antes de começar" | pbcopy
    echo "📋 Instrução copiada para o clipboard!"
    echo ""
    read -p "Pressione ENTER para abrir o Claude..."
    
    claude
    exit 0
fi

# Se não existe, pergunta qual template usar
echo "📋 PROJECT_STANDARDS.md não encontrado neste diretório."
echo ""
echo "Templates disponíveis:"
echo ""

# Lista os templates disponíveis
templates=()
counter=1

for template in "$TEMPLATES_DIR"/*.md; do
    if [ -f "$template" ]; then
        filename=$(basename "$template")
        echo "$counter) ${filename%.md}"
        templates+=("$template")
        ((counter++))
    fi
done

echo "0) Cancelar"
echo ""
read -p "Escolha um template [0-$((counter-1))]: " choice

# Valida a escolha
if [ "$choice" = "0" ]; then
    echo "❌ Operação cancelada."
    exit 0
fi

if [ "$choice" -lt 1 ] || [ "$choice" -ge "$counter" ]; then
    echo "❌ Opção inválida!"
    exit 1
fi

# Pega o template escolhido
selected_template="${templates[$((choice-1))]}"
template_name=$(basename "$selected_template" .md)

echo ""
echo "📄 Preview do template '$template_name':"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$selected_template"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Confirma a criação do PROJECT_STANDARDS.md? [S/n]: " confirm

if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
    echo "❌ Operação cancelada."
    exit 0
fi

# Cria o arquivo
cp "$selected_template" "$PROJECT_STANDARDS"

echo "✅ $PROJECT_STANDARDS criado com sucesso!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Cole isso no Claude quando abrir:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Leia PROJECT_STANDARDS.md antes de começar"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Copia para o clipboard
echo "Leia PROJECT_STANDARDS.md antes de começar" | pbcopy
echo "📋 Instrução copiada para o clipboard!"
echo ""
read -p "Pressione ENTER para abrir o Claude..."
claude
