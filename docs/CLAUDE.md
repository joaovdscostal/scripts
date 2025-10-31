# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão Geral do Repositório

Esta é uma coleção de scripts bash para gerenciar projetos de aplicações web Java em um ambiente de workspace com múltiplos projetos. Os scripts automatizam fluxos de trabalho de deployment, operações de banco de dados, operações git, migrações de assets e backups de servidores VPS.

## Estrutura do Workspace

```
scripts/
├── docs/                          # Documentação do repositório
│   ├── CLAUDE.md                  # Este arquivo
│   └── README.md                  # Documentação geral
├── vps-backup/                    # Scripts de backup de VPS
│   ├── backup-vps.sh             # Script principal de backup
│   ├── backup.conf               # Configurações de backup
│   └── check-requirements.sh     # Verificação de dependências
├── banco-de-dados/               # Scripts de análise de banco
├── [scripts principais...]        # Scripts de build, deploy e git
```

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

## Sistema de Backup VPS (NOVO!)

### backup-vps.sh
Script completo de backup para servidores VPS Linux. Características:

**Recursos:**
- Backup de bancos MariaDB (mariabackup ou mysqldump)
- Backup de aplicações Spring Boot (JARs + configs + services)
- Backup do Apache Tomcat 9 (com opção de incluir/excluir webapps)
- Backup de aplicações Node.js gerenciadas por PM2
- Backup de aplicações estáticas (HTML/CSS/JS)
- Backup de configurações Nginx + certificados SSL (Let's Encrypt)
- Inventário completo do sistema
- Notificações via WhatsApp (sucesso e erro)
- Logs persistentes para execução via cron
- Suporte a backup remoto (rsync) e S3 (via rclone)
- Compactação automática
- Retenção configurável de backups

**Modos de Backup:**
```bash
# Backup completo (padrão)
BACKUP_MODE="full" ./backup-vps.sh

# Apenas infraestrutura (sem banco e sem webapps)
BACKUP_MODE="infra" ./backup-vps.sh

# Apenas banco de dados
BACKUP_MODE="database" ./backup-vps.sh

# Apenas webapps do Tomcat
BACKUP_MODE="webapps" ./backup-vps.sh
```

**Notificações WhatsApp:**
- ✅ Notificação de sucesso com data, tamanho e localização do backup
- ❌ Notificação de erro com detalhes do problema e localização do log
- Configurável via `SEND_WHATSAPP_NOTIFICATION` no `backup.conf`

**Sistema de Logs:**
- Log detalhado: `/root/backups/[data]/backup.log` - Permanente para cada backup
- Log do último backup: `/root/backups/ultimo_backup.log` - Sobrescrito a cada execução (ideal para debugging via cron)

**Configuração para Cron:**
```bash
# Backup completo diário às 2:00 AM
0 2 * * * /root/scripts/vps-backup/backup-vps.sh

# Backup de banco a cada 6 horas
0 */6 * * * BACKUP_MODE="database" /root/scripts/vps-backup/backup-vps.sh
```

**Arquivos de Configuração:**
- `backup.conf` - Todas as configurações (credenciais, caminhos, notificações, etc.)
- Suporta variáveis de ambiente para sobrescrever configurações
