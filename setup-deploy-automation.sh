#!/bin/zsh

# ==========================================
# Script para Configurar Deploy Automático
# ==========================================
#
# Uso: ./setup-deploy-automation.sh NOME_DO_PROJETO
#
# Exemplo: ./setup-deploy-automation.sh code-erp
#

set -e  # Para na primeira falha

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações de projetos - Branch principal
declare -A PROJETOS_BRANCH
PROJETOS_BRANCH=(
    ["code-erp"]="main"
    ["multt"]="main"
    ["route-365"]="main"
    ["contabil"]="master"
    ["poker"]="master"
    ["emprestimo"]="main"
    ["cidadania"]="master"
    ["codetech"]="master"
    ["epubliq"]="main"
    ["formeseguro"]="main"
    ["clubearte"]="main"
)

# Configurações de projetos - Servidor de deploy
declare -A PROJETOS_SERVER
PROJETOS_SERVER=(
    ["code-erp"]="157.230.231.220"
    ["multt"]="147.93.66.129"
    ["route-365"]="157.230.231.220"
    ["contabil"]="157.230.231.220"
    ["poker"]=""
    ["emprestimo"]=""
    ["cidadania"]=""
    ["codetech"]="147.93.66.129"
    ["epubliq"]="147.93.66.129"
    ["formeseguro"]=""
    ["clubearte"]="157.230.231.220"
)

# Servidor padrão (fallback)
DEFAULT_SERVER=""

# Função para exibir uso
usage() {
    echo -e "${RED}Uso: $0 NOME_DO_PROJETO${NC}"
    echo ""
    echo "Projetos disponíveis:"
    for projeto in "${!PROJETOS_BRANCH[@]}"; do
        local server="${PROJETOS_SERVER[$projeto]:-$DEFAULT_SERVER}"
        echo "  - $projeto (branch: ${PROJETOS_BRANCH[$projeto]}, server: $server)"
    done
    exit 1
}

# Funções de output
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# Verificar argumentos
if [ $# -lt 1 ]; then
    error "Faltou especificar o projeto"
    usage
fi

PROJETO=$1

# Verificar se projeto existe
if [ -z "${PROJETOS_BRANCH[$PROJETO]}" ]; then
    error "Projeto '$PROJETO' não encontrado na lista"
    usage
fi

BRANCH=${PROJETOS_BRANCH[$PROJETO]}
SERVER_HOST="${PROJETOS_SERVER[$PROJETO]:-$DEFAULT_SERVER}"
PROJECT_DIR="/Users/nds/Workspace/sts/$PROJETO"
WORKFLOW_DIR="$PROJECT_DIR/.github/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/deploy-producao.yml"

echo ""
info "Configurando deploy automático para: $PROJETO"
info "Branch principal: $BRANCH"
info "Servidor: $SERVER_HOST"
echo ""

# ==========================================
# 1. Validações iniciais
# ==========================================

[ ! -d "$PROJECT_DIR" ] && error "Diretório não encontrado: $PROJECT_DIR"
success "Diretório do projeto encontrado"

[ ! -d "$PROJECT_DIR/.git" ] && error "Não é um repositório git: $PROJECT_DIR"
success "Repositório git válido"

# ==========================================
# 2. Detectar versão e configurações
# ==========================================

if [ ! -f "$PROJECT_DIR/src/producao.properties" ]; then
    warning "Arquivo src/producao.properties não encontrado"
    VERSION="0.0.1"
else
    success "Arquivo producao.properties encontrado"
    VERSION=$(grep -oP 'versao=\K.*' "$PROJECT_DIR/src/producao.properties" 2>/dev/null || echo "0.0.1")
    info "Versão atual: $VERSION"
fi

# ==========================================
# 3. Criar .deployignore se não existir
# ==========================================

DEPLOYIGNORE_FILE="$PROJECT_DIR/.deployignore"

if [ ! -f "$DEPLOYIGNORE_FILE" ]; then
    info "Criando .deployignore..."
    cat > "$DEPLOYIGNORE_FILE" << 'DEPLOYIGNORE'
# Arquivos e pastas que NÃO devem ser sobrescritos no deploy
# Estes itens serão preservados do servidor durante o deploy automatizado
#
# IMPORTANTE:
# - Uma entrada por linha
# - Pastas terminam com /
# - Arquivos específicos sem /
# - Linhas começando com # são ignoradas

# Uploads e arquivos de clientes
arquivos/
img/

# Configurações customizadas no servidor
WEB-INF/web.xml

# Adicione outras pastas conforme necessário:
# uploads/
# documentos/
# fotos/
DEPLOYIGNORE
    success ".deployignore criado"
    warning "Revise o arquivo .deployignore e adicione outras pastas que precisam ser preservadas"
else
    info ".deployignore já existe"
fi

# ==========================================
# 4. Criar workflow
# ==========================================

mkdir -p "$WORKFLOW_DIR"
success "Diretório workflows criado"

if [ -f "$WORKFLOW_FILE" ]; then
    warning "Arquivo workflow já existe: $WORKFLOW_FILE"
    echo -n "Deseja sobrescrever? (s/N): "
    read -r RESPOSTA

    if [[ ! "$RESPOSTA" =~ ^[Ss]$ ]]; then
        info "Operação cancelada"
        exit 0
    fi
fi

info "Criando workflow..."

cat > "$WORKFLOW_FILE" << WORKFLOWEOF
name: Deploy Produção

on:
  push:
    branches:
      - $BRANCH
  workflow_dispatch:

env:
  PROJECT_NAME: $PROJETO
  TOMCAT_PATH: /root/appservers/apache-tomcat-9/webapps/$PROJETO
  SERVER_USER: root
  SERVER_HOST: $SERVER_HOST

jobs:
  build:
    name: 🔨 Build
    runs-on: ubuntu-latest
    permissions:
      contents: write
    outputs:
      version: \${{ steps.version.outputs.version }}
      tag: \${{ steps.version.outputs.tag }}

    steps:
      - name: Checkout código
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Java 11
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '11'
          cache: 'maven'

      - name: Ler versão
        id: version
        run: |
          VERSION=\$(grep -oP 'versao=\\K.*' src/producao.properties)
          echo "version=\$VERSION" >> \$GITHUB_OUTPUT
          echo "tag=producao-\$VERSION" >> \$GITHUB_OUTPUT
          echo "📦 Versão: \$VERSION"

      - name: Compilar projeto
        run: |
          echo "🔨 Compilando..."
          if [ -f .classpath ]; then
            sed -i 's/including="\\*\\*\\/\\*.java"//g' .classpath
          fi
          mvn clean install -U -DskipTests

          if [ ! -d "target/\${{ env.PROJECT_NAME }}-1.0" ]; then
            echo "❌ Erro na compilação"
            exit 1
          fi
          echo "✅ Compilação OK"

      - name: Preparar artefatos
        run: |
          echo "📦 Empacotando..."
          cd target/\${{ env.PROJECT_NAME }}-1.0
          tar -czf ../\${{ env.PROJECT_NAME }}.tar.gz .
          echo "✅ Artefatos prontos"

      - name: Criar tag
        run: |
          TAG="\${{ steps.version.outputs.tag }}"
          DATE=\$(date +"%d-%m-%Y")

          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"

          git tag -d \$TAG 2>/dev/null || true
          git push origin :refs/tags/\$TAG 2>/dev/null || true

          git tag -a \$TAG -m "Release \$TAG - \$DATE"
          git push origin \$TAG
          echo "✅ Tag \$TAG criada"

      - name: Upload artefatos
        uses: actions/upload-artifact@v4
        with:
          name: app-build
          path: target/\${{ env.PROJECT_NAME }}.tar.gz
          retention-days: 1

  deploy:
    name: 🚀 Deploy
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Checkout (para ler .deployignore)
        uses: actions/checkout@v4

      - name: Download artefatos
        uses: actions/download-artifact@v4
        with:
          name: app-build

      - name: Configurar SSH
        run: |
          mkdir -p ~/.ssh
          echo "\${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H \${{ env.SERVER_HOST }} >> ~/.ssh/known_hosts

      - name: Backup no servidor
        run: |
          echo "💾 Criando backup..."
          ssh \${{ env.SERVER_USER }}@\${{ env.SERVER_HOST }} << 'EOF'
            BACKUP_DIR="/root/backups/\${{ env.PROJECT_NAME }}"
            mkdir -p \$BACKUP_DIR

            if [ -d "\${{ env.TOMCAT_PATH }}" ]; then
              # Remove backup anterior
              echo "🗑️  Removendo backup anterior..."
              rm -f \$BACKUP_DIR/backup_*.tar.gz

              # Cria novo backup (sempre com mesmo nome)
              echo "💾 Criando backup atual..."
              cd \${{ env.TOMCAT_PATH }}/..
              tar -czf \$BACKUP_DIR/backup_latest.tar.gz \${{ env.PROJECT_NAME }}

              echo "✅ Backup criado: backup_latest.tar.gz"
              ls -lh \$BACKUP_DIR/backup_latest.tar.gz
            else
              echo "⚠️  Sem backup (primeira instalação)"
            fi
          EOF

      - name: Parar Tomcat
        run: |
          echo "🛑 Parando Tomcat..."
          ssh \${{ env.SERVER_USER }}@\${{ env.SERVER_HOST }} << 'EOF'
            /root/tomcat.sh stop

            for i in {1..30}; do
              if ! pgrep -f "tomcat" > /dev/null; then
                echo "✅ Tomcat parado"
                exit 0
              fi
              sleep 1
            done

            echo "⚠️  Forçando parada..."
            pkill -9 -f "tomcat" || true
            sleep 2
            echo "✅ Tomcat parado"
          EOF

      - name: Enviar arquivos
        run: |
          echo "📤 Enviando para servidor..."
          scp \${{ env.PROJECT_NAME }}.tar.gz \\
            \${{ env.SERVER_USER }}@\${{ env.SERVER_HOST }}:/tmp/

      - name: Preparar lista de preservação
        run: |
          # Lê .deployignore e cria script de preservação
          if [ -f .deployignore ]; then
            echo "📋 Lendo .deployignore..."
            grep -v '^#' .deployignore | grep -v '^[[:space:]]*$' > /tmp/preserve_list.txt
            cat /tmp/preserve_list.txt
          else
            # Fallback: preserva arquivos/ e img/ por padrão
            echo "arquivos/" > /tmp/preserve_list.txt
            echo "img/" >> /tmp/preserve_list.txt
          fi

      - name: Enviar lista de preservação
        run: |
          scp /tmp/preserve_list.txt \${{ env.SERVER_USER }}@\${{ env.SERVER_HOST }}:/tmp/

      - name: Extrair no servidor (preservando arquivos)
        run: |
          echo "📦 Instalando com preservação automática..."
          ssh \${{ env.SERVER_USER }}@\${{ env.SERVER_HOST }} << 'EOF'
            TEMP_DIR="/tmp/\${{ env.PROJECT_NAME }}_deploy_\$\$"
            mkdir -p \$TEMP_DIR

            # Extrai nova versão em diretório temporário
            cd \$TEMP_DIR
            tar -xzf /tmp/\${{ env.PROJECT_NAME }}.tar.gz
            rm /tmp/\${{ env.PROJECT_NAME }}.tar.gz

            # Preserva arquivos conforme .deployignore
            if [ -d "\${{ env.TOMCAT_PATH }}" ] && [ -f "/tmp/preserve_list.txt" ]; then
              echo "📁 Preservando arquivos críticos..."

              while IFS= read -r item; do
                # Remove espaços e trailing /
                item=\$(echo "\$item" | xargs)

                if [[ "\$item" == */ ]]; then
                  # É um diretório - faz MERGE inteligente
                  folder="\${item%/}"
                  if [ -d "\${{ env.TOMCAT_PATH }}/\$folder" ]; then
                    echo "  → Mesclando \$folder/ (preservando arquivos existentes)"

                    # Cria diretório se não existe
                    mkdir -p "\$TEMP_DIR/\$folder"

                    # Copia arquivos do servidor que NÃO existem na nova versão
                    # Usa rsync para fazer merge inteligente
                    rsync -a --ignore-existing "\${{ env.TOMCAT_PATH }}/\$folder/" "\$TEMP_DIR/\$folder/"

                    echo "    ✓ Arquivos novos do git mantidos"
                    echo "    ✓ Arquivos do servidor preservados"
                  fi
                else
                  # É um arquivo - preserva do servidor
                  if [ -f "\${{ env.TOMCAT_PATH }}/\$item" ]; then
                    echo "  → Preservando \$item"
                    mkdir -p "\$(dirname "\$TEMP_DIR/\$item")"
                    # Força sobrescrever com a versão do servidor
                    cp -f "\${{ env.TOMCAT_PATH }}/\$item" "\$TEMP_DIR/\$item"
                  fi
                fi
              done < /tmp/preserve_list.txt

              rm /tmp/preserve_list.txt
            fi

            # Substitui log4j.properties pelo de produção
            if [ -f "\$TEMP_DIR/WEB-INF/classes/log4j.producao.properties" ]; then
              echo "🔧 Configurando log4j para produção..."
              cp \$TEMP_DIR/WEB-INF/classes/log4j.producao.properties \\
                 \$TEMP_DIR/WEB-INF/classes/log4j.properties
            fi

            # Move nova versão para o lugar final
            rm -rf \${{ env.TOMCAT_PATH }}
            mv \$TEMP_DIR \${{ env.TOMCAT_PATH }}

            chown -R root:root \${{ env.TOMCAT_PATH }}
            echo "✅ Instalação concluída (arquivos preservados)"
          EOF

  startup:
    name: ▶️ Iniciar
    runs-on: ubuntu-latest
    needs: deploy

    steps:
      - name: Configurar SSH
        run: |
          mkdir -p ~/.ssh
          echo "\${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H \${{ env.SERVER_HOST }} >> ~/.ssh/known_hosts

      - name: Iniciar Tomcat
        run: |
          echo "▶️  Iniciando Tomcat..."
          ssh \${{ env.SERVER_USER }}@\${{ env.SERVER_HOST }} << 'EOF'
            rm -f /root/appservers/apache-tomcat-9/logs/catalina.out
            /root/tomcat.sh start

            echo "Aguardando inicialização (até 5 minutos)..."
            for i in {1..300}; do
              if grep -q "Server startup in" /root/appservers/apache-tomcat-9/logs/catalina.out 2>/dev/null; then
                echo "✅ Tomcat iniciado!"
                exit 0
              fi

              if grep -q "SEVERE" /root/appservers/apache-tomcat-9/logs/catalina.out 2>/dev/null; then
                echo "❌ Erro na inicialização"
                tail -n 50 /root/appservers/apache-tomcat-9/logs/catalina.out
                exit 1
              fi

              sleep 1
            done

            echo "⚠️  Timeout (5 minutos)"
            tail -n 50 /root/appservers/apache-tomcat-9/logs/catalina.out
            exit 1
          EOF

      - name: Verificar aplicação
        run: |
          echo "🔍 Verificando aplicação..."
          sleep 10

          HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" https://\${{ env.SERVER_HOST }}/ || echo "000")

          if [ "\$HTTP_CODE" -eq 200 ] || [ "\$HTTP_CODE" -eq 302 ]; then
            echo "✅ Aplicação OK (HTTP \$HTTP_CODE)"
          else
            echo "⚠️  HTTP \$HTTP_CODE"
            echo "Verifique: https://\${{ env.SERVER_HOST }}/"
          fi

  notify:
    name: 📢 Notificar
    runs-on: ubuntu-latest
    needs: [build, deploy, startup]
    if: always()

    steps:
      - name: Notificar sucesso
        if: needs.startup.result == 'success'
        continue-on-error: true
        run: |
          echo "✅ Deploy v\${{ needs.build.outputs.version }} concluído!"
          echo "🏷️  Tag: \${{ needs.build.outputs.tag }}"
          echo "🌐 URL: https://\${{ env.SERVER_HOST }}/"

          curl --location --request POST 'https://webzap.appjvs.com.br/api/proxy/message/sendText/zap-default' \\
            --header 'Content-Type: application/json' \\
            --header "apikey: \${{ secrets.WHATSAPP_APIKEY }}" \\
            --data "{
              \\"number\\": \\"\${{ secrets.WHATSAPP_PHONE }}\\",
              \\"text\\": \\"✅ *Deploy OK!*\\n\\n📦 *Projeto:* \${{ env.PROJECT_NAME }}\\n🏷️ *Versão:* \${{ needs.build.outputs.version }}\\n👤 *Por:* \${{ github.actor }}\\n📅 *Data:* \$(date +'%d/%m/%Y %H:%M')\\n\\n🎉 Disponível!\\"
            }" || echo "⚠️  Notificação falhou"

      - name: Notificar falha
        if: needs.startup.result == 'failure' || needs.build.result == 'failure' || needs.deploy.result == 'failure'
        continue-on-error: true
        run: |
          echo "❌ Deploy falhou!"

          curl --location --request POST 'https://webzap.appjvs.com.br/api/proxy/message/sendText/zap-default' \\
            --header 'Content-Type: application/json' \\
            --header "apikey: \${{ secrets.WHATSAPP_APIKEY }}" \\
            --data "{
              \\"number\\": \\"\${{ secrets.WHATSAPP_PHONE }}\\",
              \\"text\\": \\"❌ *Deploy Falhou!*\\n\\n📦 *Projeto:* \${{ env.PROJECT_NAME }}\\n👤 *Por:* \${{ github.actor }}\\n🔗 *Logs:* https://github.com/\${{ github.repository }}/actions/runs/\${{ github.run_id }}\\n📅 *Data:* \$(date +'%d/%m/%Y %H:%M')\\n\\n⚠️ Verificar!\\"
            }" || echo "⚠️  Notificação falhou"
WORKFLOWEOF

success "Workflow criado: $WORKFLOW_FILE"

# ==========================================
# 5. Adicionar ao git
# ==========================================

cd "$PROJECT_DIR"

if ! git ls-files --error-unmatch .deployignore > /dev/null 2>&1; then
    git add .deployignore
    info ".deployignore adicionado ao git"
fi

if ! git ls-files --error-unmatch .github/workflows/deploy-producao.yml > /dev/null 2>&1; then
    git add .github/workflows/deploy-producao.yml
    info "Workflow adicionado ao git"
fi

# ==========================================
# 6. Próximos passos
# ==========================================

echo ""
echo "=========================================="
success "Configuração concluída!"
echo "=========================================="
echo ""
echo "📋 Arquivos criados:"
echo "   ✅ .deployignore"
echo "   ✅ .github/workflows/deploy-producao.yml"
echo ""
echo "=========================================="
echo "📄 Hook post-receive atual no servidor"
echo "=========================================="
echo ""
echo "Arquivo: /root/repositorio/${PROJETO}.git/hooks/post-receive"
echo ""

# Tenta buscar o conteúdo do post-receive do servidor
HOOK_PATH="/root/repositorio/${PROJETO}.git/hooks/post-receive"
echo -e "${BLUE}Conectando em $SERVER_HOST...${NC}"
echo ""

set +e  # Não parar em erro
HOOK_CONTENT=$(ssh -o ConnectTimeout=5 -o BatchMode=yes root@$SERVER_HOST "cat $HOOK_PATH 2>/dev/null")
SSH_EXIT_CODE=$?
set -e

if [ $SSH_EXIT_CODE -eq 0 ] && [ -n "$HOOK_CONTENT" ]; then
    echo -e "${GREEN}Conteúdo atual:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo "$HOOK_CONTENT"
    echo -e "${BLUE}----------------------------------------${NC}"
else
    echo -e "${YELLOW}⚠️  Não foi possível ler o hook do servidor.${NC}"
    echo ""
    echo "Possíveis causas:"
    echo "  - Arquivo não existe ainda"
    echo "  - Sem acesso SSH ao servidor"
    echo "  - Repositório ${PROJETO}.git não existe"
    echo ""
    echo "Caminho esperado: $HOOK_PATH"
fi
echo ""
echo "=========================================="
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1️⃣  Revisar e ajustar .deployignore:"
echo "    - Adicione outras pastas que precisam ser preservadas"
echo "    - Exemplo: uploads/, documentos/, fotos/"
echo ""
echo "2️⃣  Configurar secrets no GitHub:"
echo "    - SSH_PRIVATE_KEY (conteúdo de ~/.ssh/id_ed25519)"
echo "    - WHATSAPP_APIKEY (sua API key do WhatsApp)"
echo "    - WHATSAPP_PHONE (seu número no formato 5522999999999)"
echo ""
echo "    URL: https://github.com/joaovdscostal/$PROJETO/settings/secrets/actions"
echo ""
echo "3️⃣  Fazer commit e push:"
echo "    cd $PROJECT_DIR"
echo "    git add .deployignore .github/workflows/deploy-producao.yml"
echo "    git commit -m 'feat: configure automated deployment'"
echo "    git push origin $BRANCH"
echo ""
echo "4️⃣  Verificar execução:"
echo "    https://github.com/joaovdscostal/$PROJETO/actions"
echo ""
echo "=========================================="
echo ""

# ==========================================
# 7. Opção de commit automático
# ==========================================

echo -n "Deseja fazer commit agora? (s/N): "
read -r FAZER_COMMIT

if [[ "$FAZER_COMMIT" =~ ^[Ss]$ ]]; then
    cd "$PROJECT_DIR"

    git add .deployignore .github/workflows/deploy-producao.yml

    if git commit -m "feat: configure automated deployment with file preservation" 2>/dev/null; then
        success "Commit criado"

        echo -n "Deseja fazer push agora? (s/N): "
        read -r FAZER_PUSH

        if [[ "$FAZER_PUSH" =~ ^[Ss]$ ]]; then
            if git push origin "$BRANCH"; then
                success "Push realizado!"
                echo ""
                info "Acompanhe: https://github.com/joaovdscostal/$PROJETO/actions"
            else
                error "Erro ao fazer push"
            fi
        else
            info "Execute: git push origin $BRANCH"
        fi
    else
        warning "Nada para commitar (pode já estar commitado)"
    fi
else
    info "Execute manualmente quando estiver pronto."
fi

echo ""
success "Script finalizado!"
echo ""
