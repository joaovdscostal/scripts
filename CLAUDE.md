# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão Geral do Repositório

Esta é uma coleção de scripts bash para gerenciar projetos de aplicações web Java em um ambiente de workspace com múltiplos projetos. Os scripts automatizam fluxos de trabalho de deployment, operações de banco de dados, operações git e migrações de assets para múltiplas aplicações empresariais.

## Estrutura do Workspace

Os scripts operam em projetos localizados em diretórios específicos do workspace:
- `/Users/nds/Workspace/sts/[projeto]` - Repositórios de código-fonte
- `/Users/nds/Workspace/publicacao/[projeto]` - Diretórios com output de build para deployment
- `/Users/nds/Workspace/dados/` - Arquivos de dump de banco de dados

## Scripts Principais e Uso

### Build e Deployment

**compilar.sh** - Compila projetos Java Maven e sincroniza artefatos de build
```bash
./compilar.sh [nomes-dos-projetos...]
```
- Faz build dos projetos usando `mvn clean install -U`
- Remove restrições do `.classpath` temporariamente durante o build
- Sincroniza artefatos compilados de `target/[projeto]-1.0/` para `/Users/nds/Workspace/publicacao/[projeto]`
- Tratamento especial para o projeto `gerenciadordecursoonline` (copia vraptor-datatables JAR)

**publicar.sh** - Faz deploy de projetos para servidores remotos
```bash
./publicar.sh [nomes-dos-projetos...]
# Prompts interativos para:
# - Ambiente (producao/homologacao)
# - Confirmação
# - Criação de tag opcional
```
- Gerencia múltiplos projetos com remotes git e branches específicos por ambiente
- Cria mensagens de commit com data
- Suporta criação opcional de tags para releases em produção
- Usa force push para remotes de deployment

**compilarpadrao.sh** - Similar ao compilar.sh com workflow ligeiramente diferente

### Gerenciamento de Banco de Dados

**banco.sh** - Copia bancos de dados entre ambientes
```bash
./banco.sh -basededadosorigem [nome-db] -basededadosdestino [nome-db] -origem [ambiente] -destino [ambiente]
# Ambientes: producao, poker, jhonata, servidor-cidadania, testes, localhost, localhost-mariadb, localhost-5
```
- Faz dump de servidores MySQL remotos/locais
- Restaura em instâncias MySQL ou MariaDB locais
- Usa binários específicos de MySQL/MariaDB em `/opt/homebrew/opt/mysql@8.0/bin/` e `/usr/local/opt/mariadb@10.10/bin/`

**backup-mysql.sh** - Cria backups de banco de dados de servidores remotos
```bash
./backup-mysql.sh -basededadosorigem [nome-db] -origem [ambiente]
```
- Cria backups em `/Users/nds/Workspace/dados/backup[nome-db].sql`
- Usa flags: `--no-tablespaces --set-gtid-purged=OFF`

**restaurar.sh** - Restaura bancos de dados de arquivos de backup
```bash
./restaurar.sh -basededadosdestino [nome-db] -arquivo [nome-arquivo] -destino [ambiente]
```
- Remove automaticamente a primeira linha do arquivo de dump SQL
- Tratamento especial para bancos `code-erp` (atualiza tabela PLAYERDEPAGAMENTOGESTOR)
- Suporta substituição dinâmica de nome de base nos arquivos de dump

**banco-de-dados/** diretório contém scripts utilitários para análise e manutenção de schema de banco de dados

### Operações Git (Multi-Projeto)

Todos os scripts git aceitam múltiplos nomes de projeto e operam em `/Users/nds/Workspace/[projeto]`:

**commit.sh** - Faz commit de mudanças em múltiplos projetos
```bash
./commit.sh [nomes-dos-projetos...]
# Solicita mensagem de commit
```

**push.sh** - Envia commits para remotes git
```bash
./push.sh [nomes-dos-projetos...]
# Solicita remote (padrão: origin) e branch (padrão: master)
```

**criarbranch.sh** - Cria ou alterna para branches
```bash
./criarbranch.sh [nomes-dos-projetos...]
# Solicita nome da branch (padrão: envio_homologacao)
```

**mudarbranch.sh** - Alterna entre branches existentes
```bash
./mudarbranch.sh [nomes-dos-projetos...]
# Solicita nome da branch (padrão: master)
```

**removebranch.sh** - Deleta branches

**checkout.sh** - Faz checkout de branches/commits específicos

**pull.sh** - Faz pull de repositórios remotos

**status.sh** - Mostra status git dos projetos

**configurarservidor.sh** - Configura remotes git para deployment
```bash
./configurarservidor.sh [nomes-dos-projetos...]
# Opera em /Users/nds/Workspace/publicacao/[projeto]
```

### Ferramentas de Migração de Código

**convert_post_to_ajax.sh** - Converte jQuery `$.post()` para `$.ajax()` em arquivos JavaScript/JSP
```bash
./convert_post_to_ajax.sh <diretório-ou-arquivo> [--dry-run] [--infer-put]
```
- Processa arquivos `.js`, `.jsp`, `.jspf`, `.tag`, `.html`, `.htm`
- Converte `$.post()` para `$.ajax()` com content-type adequado e JSON stringification
- Trata conversões `.then()` → `.done()` e `.catch()` → `.fail()`
- Inferência opcional de método PUT baseado em padrões de URL
- Cria arquivos de backup `.bak`

**replace-asset.sh** - Migra templates Laravel Blade para sintaxe JSP
```bash
./replace-asset.sh <caminho-do-arquivo>
```
- Converte `{{asset("...")}}` para linguagem de expressão JSP
- Mapeia para `${sessao.urlCss}`, `${sessao.urlJs}`, `${sessao.urlPadrao}` baseado no contexto
- Converte `{{url()}}` para `${sessao.urlPadrao}`
- Converte comentários Blade `{{-- --}}` para comentários HTML
- Converte variáveis Blade `{{ $var }}` para `${var}`
- Converte `@section` / `@endsection` para atributos JSP
- Converte caracteres acentuados para entidades HTML
- Cria arquivos de backup com timestamp
- Confirmação interativa com preview

## Configuração de Projetos

O script `publicar.sh` inclui um registro de projetos com configurações de deployment:
- **code-erp**: remote producao, branch main
- **multt**: remote producao, branch main
- **route-365**: remote producao, branch main
- **contabil**: remote producao, branch main
- **poker**: remote servidor-poker, branch master
- **emprestimo**: remote producao, branch main
- **cidadania**: Múltiplos ambientes (homologacao/testes, producao/servidor-cidadania)
- **codetech**: remote producao, branch master
- **epubliq**: remote producao, branch main

---

# Sistema de Backup VPS (vps-backup/)

## Visão Geral

Sistema completo de backup e restore para VPS com suporte a múltiplos componentes, armazenamento em S3 (DigitalOcean Spaces), notificações via WhatsApp e modos de backup flexíveis.

## Arquitetura

### Componentes Suportados

1. **Banco de Dados** (MariaDB)
   - Backup usando `mariabackup --backup`
   - Compactação com gzip
   - Restauração com `mariabackup --prepare` e `--copy-back`

2. **Aplicações Spring Boot** (Java 21)
   - Localização padrão: `/opt/apps/`
   - Backup de JARs, configurações e services systemd
   - Restore com opção de habilitar/iniciar serviços

3. **Apache Tomcat 9**
   - Localização padrão: `/root/appservers/apache-tomcat-9/`
   - Backup de webapps, conf, lib, bin e service systemd
   - Opções de restore: completo, apenas webapps, ou sem webapps

4. **Node.js/PM2**
   - Localização padrão: `/opt/nodejs/`
   - Backup de aplicações e configurações PM2
   - Restore com `npm install` automático

5. **Aplicações Estáticas**
   - Localização padrão: `/var/www/`
   - Backup de sites HTML/CSS/JS
   - Ajuste automático de permissões (www-data:www-data)

6. **Nginx**
   - Backup de configurações (`/etc/nginx`)
   - Backup de sites (sites-available/sites-enabled)
   - Backup opcional de certificados SSL (Let's Encrypt)
   - Validação de configuração antes de aplicar

7. **Repositórios Git**
   - Backup de repositórios git bare
   - Localização padrão: `/root/repositorio`
   - Lista configurável de repos (codetech.git, multt.git, etc)

8. **Scripts Customizados**
   - Backup de scripts em diretórios configuráveis
   - Backup de crontabs
   - Backup de logs de scripts (opcional)

## Arquivos de Configuração

### backup.conf

Arquivo central de configuração com todas as opções customizáveis:

```bash
# Configurações Gerais
BACKUP_ROOT="/root/backup-vps/dados"
CRON_LOG_FILE="/root/backup-vps/ultimo_backup.log"
BACKUP_RETENTION_DAYS=1  # Mantém 1 backup mais recente por dia localmente
COMPRESS_BACKUPS=true
SEND_WHATSAPP_NOTIFICATION=true

# Modo de Backup
BACKUP_MODE="infra"  # Opções: "full", "infra", "database", "webapps", ""

# WhatsApp
WHATSAPP_NUMBER="5522999604234"
WHATSAPP_API_URL="http://137.184.190.52:8084/message/sendText/..."
WHATSAPP_API_KEY="zYzP7ocstxh3Sscefew4FZTCu4ehnM8v4hu"

# Banco de Dados
BACKUP_DATABASE=true
DB_NAME="codetech"
DB_USER="root"
DB_PASSWORD="senha"
DB_HOST="localhost"

# Spring Boot
BACKUP_SPRINGBOOT=true
SPRINGBOOT_APPS_DIR="/opt/apps"

# Tomcat
BACKUP_TOMCAT=true
TOMCAT_HOME="/root/appservers/apache-tomcat-9"
BACKUP_TOMCAT_WEBAPPS=true

# Node.js
BACKUP_NODEJS=true
NODEJS_APPS_DIR="/opt/nodejs"

# Nginx
BACKUP_NGINX=true
NGINX_CONFIG_DIR="/etc/nginx"
NGINX_SITES="all"  # Opções: "all", "site1.com site2.com", ou ""
BACKUP_SSL_CERTS=false
SSL_CERTS_DIR="/etc/letsencrypt"

# Repositórios Git
BACKUP_GIT_REPOS=true
GIT_REPOS_DIR="/root/repositorio"
GIT_REPOS=(
    "codetech.git"
    "multt.git"
)

# S3 (DigitalOcean Spaces)
UPLOAD_TO_S3=true
RCLONE_REMOTE="codetech"
S3_BUCKET="codetech"
S3_PATH="backups/vps"
S3_RETENTION_COUNT=10  # Mantém últimos 10 DIAS no S3 (1 backup por dia)
```

## Scripts Principais

### backup-vps.sh

Script principal de backup com as seguintes características:

**Modos de Operação:**
- `full`: Backup completo de tudo
- `infra`: Infraestrutura (sem banco e sem webapps do Tomcat)
- `database`: Apenas banco de dados
- `webapps`: Apenas webapps do Tomcat

**Funcionalidades:**
- Trap de erro com notificação automática via WhatsApp
- Compactação em `.tar.gz` com timestamp (YYYYMMDD_HHMMSS)
- Upload automático para S3 via rclone
- Limpeza de backups antigos (local e S3)
- Retenção: mantém 1 backup por dia (mais recente)
- Logs detalhados com cores

**Limpeza de Backups:**
- **Local**: Mantém últimos N dias (configurável via `BACKUP_RETENTION_DAYS`)
- **S3**: Mantém últimos N dias (configurável via `S3_RETENTION_COUNT`)
- Remove duplicados do mesmo dia (mantém apenas o mais recente)
- Usa arquivos temporários em `/tmp/.backup_cleanup_*` para rastrear dias

**Notificações WhatsApp:**
- Sucesso: lista de componentes incluídos no backup
- Erro: detalhes do erro (linha, comando, código de saída)
- Mensagens escapam caracteres especiais para JSON válido

**Uso:**
```bash
./backup-vps.sh              # Usa configurações do backup.conf
BACKUP_MODE=full ./backup-vps.sh   # Override do modo via variável de ambiente
```

### restore-vps.sh

Script de restauração com seleção interativa de componentes:

**Opções de Restore:**
1. Tudo (restore completo)
2. Tudo exceto banco de dados
3. Infraestrutura (tudo exceto banco e webapps)
4. Apenas banco de dados
5. Apenas webapps do Tomcat
6. Apenas aplicações Spring Boot
7. Apenas Tomcat (sem webapps)
8. Apenas Node.js
9. Apenas aplicações estáticas
10. Apenas Nginx
11. Apenas scripts customizados
12. Apenas repositórios git
13. Personalizado (escolher componentes)

**Funcionalidades Especiais:**

- **Seleção S3 Interativa**: Quando executado sem parâmetros, lista últimos 5 backups do S3 e permite escolher qual restaurar
- **Suporte a Servidor Limpo**: Cria diretórios que não existem antes de copiar arquivos
- **Verificação de Serviços**: Checa se systemd services existem antes de tentar parar/iniciar
- **Confirmações de Segurança**: Pede confirmação antes de sobrescrever componentes críticos
- **Validação Nginx**: Testa configuração antes de aplicar
- **Backup Automático**: Faz backup das configurações atuais antes de sobrescrever

**Tratamento de Servidor Limpo (Adicionado em 2025-01-31):**
- **Tomcat**: Cria `/root/appservers/apache-tomcat-9/{bin,conf,lib,webapps,logs,temp,work}` se não existir
- **Nginx**: Cria `/etc/nginx` se não existir
- **Certificados SSL**: Cria diretório de certificados se não existir
- **Services**: Verifica existência antes de tentar parar/iniciar via systemctl
- **Scripts**: Só executa `chmod +x *.sh` se arquivos .sh existirem

**Uso:**
```bash
# Seleção interativa do S3
./restore-vps.sh

# Restore de arquivo local
./restore-vps.sh /path/to/backup.tar.gz
```

### Scripts de Teste

**test-cleanup-duplicates.sh**
- Testa lógica de limpeza de duplicados no S3
- Mostra simulação (dry run) antes de executar
- Lista todos os backups por data e identifica duplicados

**test-s3-cleanup.sh**
- Testa limpeza de backups no S3
- Verifica configuração rclone
- Testa diferentes comandos de listagem

**test-whatsapp.sh**
- Testa envio de notificações WhatsApp
- Mostra payload JSON e resposta da API
- Testa 3 cenários: sucesso, warning, erro

**debug-rclone.sh**
- Debug de configuração rclone
- Testa conectividade com DigitalOcean Spaces
- Verifica permissões de API key

## Detalhes Técnicos Importantes

### Formato de Arquivos de Backup

**No diretório local:**
- `backup-vps-YYYYMMDD_HHMMSS.tar.gz`

**No S3:**
- `YYYYMMDD_HHMMSS.tar.gz` (sem prefixo `backup-vps-`)

### Lógica de Retenção

A limpeza mantém apenas 1 backup por dia (o mais recente):

```bash
# Exemplo: 3 backups do mesmo dia (20250131)
20250131_080000.tar.gz  # será DELETADO
20250131_120000.tar.gz  # será DELETADO
20250131_180000.tar.gz  # será MANTIDO (mais recente)

# Se RETENTION_COUNT=2, mantém últimos 2 dias:
20250130_180000.tar.gz  # MANTIDO (dia #1)
20250131_180000.tar.gz  # MANTIDO (dia #2)
20250129_180000.tar.gz  # DELETADO (dia #3, fora da retenção)
```

Implementação usa arquivos temporários `/tmp/.backup_cleanup_*` para rastrear quais datas já foram vistas.

### Integração com rclone (DigitalOcean Spaces)

**Comandos usados:**
- `rclone ls` (não `rclone lsf`) - funciona melhor com DigitalOcean Spaces
- `rclone copy` com `--stats-one-line --stats 60s` para output limpo
- `rclone delete` para remover backups antigos

**Formato de path:**
- ✅ Correto: `codetech:codetech/backups/vps` (sem barra final)
- ❌ Errado: `codetech:codetech/backups/vps/` (com barra final)

**Permissões necessárias:**
- API Key precisa ter: Read + Write + Delete

### Notificações WhatsApp

**Formato da API:**
```bash
curl -X POST "$WHATSAPP_API_URL" \
  -H "Content-Type: application/json" \
  -H "apikey: $WHATSAPP_API_KEY" \
  -d '{"number":"5522999604234","textMessage":{"text":"mensagem"}}'
```

**Tratamento de caracteres especiais:**
- Aspas duplas: `"` → `\"`
- Aspas simples: `'` → `\'`
- Quebras de linha: usar `\n` literal (não quebra real)
- Payload deve ser uma única linha JSON

### Tratamento de Erros

**Trap de erro global:**
```bash
set -euo pipefail
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
```

Captura:
- Código de saída do comando
- Número da linha onde ocorreu o erro
- Comando que falhou

Envia notificação WhatsApp automática com todos os detalhes.

**Exceções (set +e):**
Usado em operações que podem falhar sem ser erro crítico:
- `grep` retornando 1 (nenhum match encontrado)
- `systemctl stop` quando serviço não existe
- Listagens rclone que podem retornar vazio

## Histórico de Desenvolvimento (2025-01-31)

### Problema 1: Output Verboso do rclone
**Issue:** rclone mostrava muito output durante upload com `--progress`
**Solução:** Mudado para `--stats-one-line --stats 60s`

### Problema 2: Notificações WhatsApp Falhando (HTTP 400)
**Issue:** Caracteres especiais em comandos quebravam JSON
**Solução:** Escape de aspas duplas/simples, payload em linha única

### Problema 3: Limpeza S3 Não Funcionando
**Issues múltiplos:**
1. Path com barra final não funcionava
2. Pattern de busca errado (`backup-vps-*` vs `*.tar.gz`)
3. `rclone lsf` não funcionava, precisava usar `rclone ls`
4. Regex de extração de data não funcionava com novo formato

**Soluções:**
- Removida barra final do path
- Mudado para filtrar por `.tar.gz`
- Trocado para `rclone ls` + `awk '{print $2}'`
- Atualizado regex para `s/.*\([0-9]\{8\}\)_[0-9]\{6\}\.tar\.gz/\1/p`

### Problema 4: Variáveis Não Persistindo em Loop
**Issue:** `DAYS_KEPT` não incrementava dentro do `while` loop
**Causa:** `echo "$VAR" | while` cria subshell
**Solução:** Usar here-string `while ... done <<< "$VAR"`

### Problema 5: Permissões DigitalOcean Spaces (403)
**Issue:** API key sem permissões de escrita/deleção
**Solução:** Criada nova API key com Read + Write + Delete

### Problema 6: Restore Falhando em Servidor Limpo
**Issue:**
- `/root/appservers/apache-tomcat-9/` não existia
- `systemctl stop tomcat` falhava (serviço não instalado)
- `cp` falhava (diretórios de destino não existiam)

**Soluções Implementadas:**

1. **Verificação de Diretório Tomcat:**
   - Checa se `$TOMCAT_HOME` existe
   - Oferece criar com subdirs necessários
   - Permite cancelar restore se preferir

2. **Comandos de Service Seguros:**
   - Verifica se service systemd existe com `systemctl list-unit-files`
   - Tenta script `.sh` apenas se existir
   - Ignora graciosamente se nenhum método disponível

3. **Criação de Diretórios:**
   - Adicionado `mkdir -p` antes de todos os `cp`
   - Aplicado em: bin, conf, lib, webapps, nginx, ssl-certs

4. **Correção em Scripts Customizados:**
   - `chmod +x *.sh` só executa se arquivos .sh existirem
   - Evita erro quando não há scripts no backup

### Problema 7: Seleção de Sites Nginx
**Requisito:** Permitir backup seletivo de sites nginx
**Solução:** Variável `NGINX_SITES` com opções:
- `"all"` - todos os sites
- `"site1.com site2.com"` - sites específicos
- `""` - nenhum site (apenas configs principais)

### Problema 8: Restore Interativo do S3
**Requisito:** Quando executar restore sem parâmetros, listar backups do S3
**Solução:**
- Detecta quando executado sem argumentos
- Lista últimos 5 backups do S3
- Mostra data/hora formatada
- Permite escolher qual restaurar
- Faz download via rclone antes de restaurar

### Problema 9: Backup de Repositórios Git
**Requisito:** Incluir repositórios git bare no backup de infraestrutura
**Solução:**
- Nova seção no `backup.conf` com array de repos
- Backup copia de `/root/repositorio/` para `${BACKUP_DIR}/git-repos/`
- Restore permite escolher destino e confirma sobrescritas
- Incluído automaticamente no modo "infra"
- Nova opção de menu: [12] Apenas repositórios git

## Estrutura de Diretórios no Backup

```
backup-vps-YYYYMMDD_HHMMSS/
├── database/
│   └── mariadb-backup/
│       └── [arquivos do mariabackup]
├── springboot/
│   ├── app1/
│   │   ├── app1.jar
│   │   ├── application.properties
│   │   └── app1.service
│   └── app2/
│       └── ...
├── tomcat/
│   ├── webapps/
│   ├── conf/
│   ├── lib/
│   ├── bin/
│   └── tomcat.service
├── nodejs/
│   ├── app1/
│   ├── app2/
│   └── .pm2/
├── static/
│   ├── site1/
│   └── site2/
├── nginx/
│   ├── nginx/           # Configurações principais
│   ├── sites-available/
│   ├── sites-enabled/
│   └── ssl/             # Se BACKUP_SSL_CERTS=true
├── git-repos/
│   ├── codetech.git/
│   └── multt.git/
└── system/
    ├── scripts/
    ├── crontab-root.txt
    └── backup-info.txt
```

## Instalação e Configuração

### Pré-requisitos

```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# Configurar remote DigitalOcean Spaces
rclone config
# Escolha: s3
# Provider: DigitalOcean Spaces
# Access Key ID: [sua key]
# Secret Access Key: [seu secret]
# Endpoint: nyc3.digitaloceanspaces.com (ou sua região)
```

### Setup Inicial

```bash
# Criar diretórios
mkdir -p /root/backup-vps/dados
mkdir -p /root/backup-vps/logs

# Copiar scripts
cp vps-backup/* /root/backup-vps/

# Tornar executáveis
chmod +x /root/backup-vps/*.sh

# Editar configuração
nano /root/backup-vps/backup.conf

# Testar backup
cd /root/backup-vps
./backup-vps.sh
```

### Configurar Cron

```bash
# Editar crontab
crontab -e

# Adicionar linha (backup diário às 3h da manhã)
0 3 * * * /root/backup-vps/backup-vps.sh >> /root/backup-vps/ultimo_backup.log 2>&1
```

## Troubleshooting

### Backup não envia para S3
1. Verificar configuração rclone: `rclone config show codetech`
2. Testar upload: `rclone copy /tmp/test.txt codetech:codetech/test/`
3. Verificar permissões da API key (precisa Read + Write + Delete)
4. Executar `./debug-rclone.sh` para diagnóstico completo

### Notificação WhatsApp não chega
1. Testar API: `./test-whatsapp.sh`
2. Verificar se API está acessível: `curl http://137.184.190.52:8084/`
3. Checar logs para ver resposta HTTP

### Limpeza não remove duplicados
1. Executar `./test-cleanup-duplicates.sh` para ver simulação
2. Verificar se arquivos seguem formato `YYYYMMDD_HHMMSS.tar.gz`
3. Checar logs para mensagens de erro

### Restore falha em servidor limpo
1. Verificar se diretórios base existem (`/root/appservers`, `/opt/apps`, etc)
2. Script agora cria automaticamente diretórios faltantes
3. Se serviços não existem, script apenas avisa e continua

## Boas Práticas

1. **Sempre teste o restore**: Periodicamente teste restaurar um backup em servidor de testes
2. **Monitore os logs**: Verifique `/root/backup-vps/ultimo_backup.log` após cada execução
3. **Valide configuração S3**: Execute `./test-s3-cleanup.sh` após mudanças
4. **Mantenha retenção adequada**: Balance entre espaço em disco e histórico desejado
5. **Use modo "infra" em produção**: Evite backup de banco via `mariabackup` se usar replicação
6. **Documentar repositórios git**: Mantenha lista atualizada no `backup.conf`

## Notas Importantes

### Padrões de Execução de Scripts
- A maioria dos scripts usa output colorido no terminal para mensagens de status (códigos ANSI escape)
- Scripts validam que diretórios de projeto contêm `.git` antes de operar
- Muitos scripts removem barras finais dos nomes de projeto: `FUNCAO="${FUNCAO////}"`
- Operações de force push são usadas nos scripts de deployment

### Credenciais de Banco de Dados
Scripts de banco de dados contêm credenciais hardcoded para múltiplos ambientes. Estas devem ser migradas para variáveis de ambiente ou armazenamento seguro de credenciais.

### Caminhos de Arquivos
Todos os scripts usam caminhos absolutos hardcoded para `/Users/nds/Workspace/`. Ao modificar scripts, mantenha este padrão ou refatore para usar caminhos relativos/variáveis de ambiente.

### Sistema de Build
Projetos usam Maven com estrutura de diretório padrão. O processo de build espera:
- `pom.xml` na raiz do projeto
- Output de build em `target/[nome-do-projeto]-1.0/`
- Sem diretório `EarContent` (scripts verificam e pulam se presente)
