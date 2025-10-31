# 🧩 Backup e Restore Modular

## Visão Geral

O sistema de backup agora suporta **backups modulares**, permitindo que você faça backups seletivos de apenas partes específicas do servidor. Isso é útil para:

- ✅ Backups mais rápidos e específicos
- ✅ Menor uso de espaço em disco
- ✅ Flexibilidade em estratégias de backup
- ✅ Restores parciais sem afetar outros componentes

---

## 📦 Modos de Backup

Configure o modo de backup no arquivo `backup.conf` usando a variável `BACKUP_MODE`:

### 1. Backup Completo (`full`)

**O que inclui:**
- ✅ Banco de dados MariaDB
- ✅ Aplicações Spring Boot
- ✅ Apache Tomcat (com webapps)
- ✅ Aplicações Node.js (PM2)
- ✅ Aplicações estáticas (HTML/CSS/JS)
- ✅ Nginx (configurações)
- ✅ Certificados SSL
- ✅ Scripts customizados
- ✅ Cron jobs

**Quando usar:**
- Backup semanal/mensal completo
- Antes de grandes atualizações
- Para recuperação de desastres

**Configuração:**
```bash
# backup.conf
BACKUP_MODE="full"
```

**Tamanho típico:** 500MB - 5GB (depende do tamanho do banco e webapps)

---

### 2. Backup de Infraestrutura (`infra`)

**O que inclui:**
- ✅ Aplicações Spring Boot (JARs e configs)
- ✅ Apache Tomcat (bin/, conf/, lib/ - SEM webapps)
- ✅ Aplicações Node.js (código-fonte)
- ✅ Aplicações estáticas (sites HTML)
- ✅ Nginx (configurações)
- ✅ Certificados SSL
- ✅ Scripts customizados
- ✅ Cron jobs

**O que NÃO inclui:**
- ❌ Banco de dados MariaDB
- ❌ Webapps do Tomcat

**Quando usar:**
- Backup de configurações e instalações
- Quando banco e webapps estão versionados
- Backup durante janela de manutenção
- Para migrar configurações entre servidores

**Configuração:**
```bash
# backup.conf
BACKUP_MODE="infra"
```

**Tamanho típico:** 50MB - 500MB (muito menor que backup completo)

---

### 3. Backup de Banco de Dados (`database`)

**O que inclui:**
- ✅ Banco de dados MariaDB (todos os bancos ou selecionados)

**O que NÃO inclui:**
- ❌ Aplicações
- ❌ Configurações
- ❌ Scripts

**Quando usar:**
- Backup diário do banco de dados
- Antes de executar migrations
- Antes de grandes alterações no banco
- Para recuperação rápida de dados

**Configuração:**
```bash
# backup.conf
BACKUP_MODE="database"
```

**Tamanho típico:** 100MB - 10GB (depende do tamanho dos bancos)

---

### 4. Backup de Webapps (`webapps`)

**O que inclui:**
- ✅ SOMENTE o diretório `webapps/` do Tomcat

**O que NÃO inclui:**
- ❌ Banco de dados
- ❌ Outras aplicações
- ❌ Configurações do Tomcat

**Quando usar:**
- Após deploy de novas versões
- Backup rápido antes de atualizar aplicações
- Para rollback rápido de webapps

**Configuração:**
```bash
# backup.conf
BACKUP_MODE="webapps"
```

**Tamanho típico:** 10MB - 2GB (depende do tamanho das webapps)

---

### 5. Modo Legado (configurações individuais)

**O que faz:**
Quando `BACKUP_MODE=""` (vazio), o script usa as configurações individuais do backup.conf:

```bash
BACKUP_MODE=""

# Configurações individuais são usadas:
BACKUP_DATABASE=true
BACKUP_SPRINGBOOT=true
BACKUP_TOMCAT=true
TOMCAT_BACKUP_WEBAPPS=true
BACKUP_NODEJS=true
BACKUP_STATIC_APPS=true
BACKUP_NGINX=true
# ... etc
```

**Quando usar:**
- Quando você precisa de controle total
- Para backups personalizados complexos
- Compatibilidade com scripts antigos

---

## 🔄 Opções de Restore

O script `restore-vps.sh` oferece **12 opções** de restore:

### Restauração Rápida

**[1] Tudo (restore completo)**
- Restaura todos os componentes do backup

**[2] Tudo EXCETO banco de dados**
- Restaura tudo, mas preserva o banco de dados atual
- Útil quando o banco está OK mas as aplicações estão com problemas

**[3] Infraestrutura (tudo exceto banco e webapps)**
- Restaura configurações, binários, scripts
- Preserva banco de dados e webapps atuais
- Perfeito para recuperar configurações do servidor

---

### Componentes Individuais

**[4] Apenas banco de dados**
- Restaura apenas o MariaDB
- Para recuperação de dados corrompidos

**[5] Apenas webapps do Tomcat**
- Restaura apenas o diretório `webapps/`
- Para rollback rápido de deploy

**[6] Apenas aplicações Spring Boot**
- Restaura JARs, configs e services systemd

**[7] Apenas Tomcat (sem webapps)**
- Restaura instalação do Tomcat (bin/, conf/, lib/)
- Preserva webapps atuais

**[8] Apenas Node.js**
- Restaura apps Node.js e config PM2

**[9] Apenas apps estáticas**
- Restaura sites HTML/CSS/JS

**[10] Apenas Nginx**
- Restaura configurações do Nginx

**[11] Apenas certificados SSL**
- Restaura certificados Let's Encrypt

**[12] Apenas scripts customizados**
- Restaura scripts do sistema

---

## 📋 Exemplos Práticos

### Cenário 1: Backup Semanal Completo

```bash
# backup.conf
BACKUP_MODE="full"

# Crontab: Todo domingo às 2h da manhã
0 2 * * 0 /opt/backup-scripts/backup-vps.sh >> /var/log/backup.log 2>&1
```

**Resultado:**
- Backup completo de tudo
- Tamanho: ~2GB
- Tempo: ~30-60 minutos

---

### Cenário 2: Backup Diário do Banco

```bash
# backup.conf
BACKUP_MODE="database"

# Crontab: Todos os dias às 3h da manhã
0 3 * * * /opt/backup-scripts/backup-vps.sh >> /var/log/backup-db.log 2>&1
```

**Resultado:**
- Backup apenas do MariaDB
- Tamanho: ~500MB
- Tempo: ~5-15 minutos

---

### Cenário 3: Estratégia Completa de Produção

```bash
# backup.conf - deixe BACKUP_MODE vazio para usar crontab

# Crontab com múltiplos backups:

# 1. Backup completo semanal (domingos às 2h)
0 2 * * 0 BACKUP_MODE=full /opt/backup-scripts/backup-vps.sh >> /var/log/backup-full.log 2>&1

# 2. Backup de banco diário (todos os dias às 3h)
0 3 * * * BACKUP_MODE=database /opt/backup-scripts/backup-vps.sh >> /var/log/backup-db.log 2>&1

# 3. Backup de infraestrutura quinzenal (dias 1 e 15 às 4h)
0 4 1,15 * * BACKUP_MODE=infra /opt/backup-scripts/backup-vps.sh >> /var/log/backup-infra.log 2>&1

# 4. Backup de webapps após cada deploy (manual)
# BACKUP_MODE=webapps /opt/backup-scripts/backup-vps.sh
```

**Resultado:**
- Backups organizados por tipo
- Menor uso de espaço total
- Backups mais rápidos
- Flexibilidade para restore seletivo

---

### Cenário 4: Rollback Rápido de Deploy

**Situação:** Deploy de nova versão causou problemas

```bash
# 1. Antes do deploy, fazer backup das webapps
BACKUP_MODE=webapps ./backup-vps.sh

# 2. Deploy falhou? Restaurar webapps antigas
./restore-vps.sh /root/backups/20250130_150000.tar.gz
# Escolher opção [5] - Apenas webapps do Tomcat
```

**Resultado:**
- Rollback em 2-5 minutos
- Banco de dados não afetado
- Outras aplicações não afetadas

---

### Cenário 5: Migração de Configurações

**Situação:** Novo servidor precisa das mesmas configurações

```bash
# Servidor antigo: Backup de infraestrutura
BACKUP_MODE=infra ./backup-vps.sh

# Copiar backup para novo servidor
scp /root/backups/20250130_120000.tar.gz novo-servidor:/tmp/

# Novo servidor: Restaurar apenas infraestrutura
./restore-vps.sh /tmp/20250130_120000.tar.gz
# Escolher opção [3] - Infraestrutura
```

**Resultado:**
- Configurações migradas
- Banco e webapps não afetados
- Servidor configurado rapidamente

---

## 🎯 Comparação de Modos

| Modo | Banco | Webapps | Apps | Configs | Tamanho | Tempo |
|------|-------|---------|------|---------|---------|-------|
| **full** | ✅ | ✅ | ✅ | ✅ | 500MB-5GB | 30-60min |
| **infra** | ❌ | ❌ | ✅ | ✅ | 50MB-500MB | 10-20min |
| **database** | ✅ | ❌ | ❌ | ❌ | 100MB-10GB | 5-30min |
| **webapps** | ❌ | ✅ | ❌ | ❌ | 10MB-2GB | 5-15min |

---

## 💡 Dicas e Recomendações

### Para Economizar Espaço

```bash
# Use backups modulares em vez de múltiplos backups completos
BACKUP_MODE="database"  # Diário
BACKUP_MODE="infra"     # Quinzenal
BACKUP_MODE="full"      # Mensal
```

### Para Backups Mais Rápidos

```bash
# Separe banco e aplicações
BACKUP_MODE="database"  # Rápido: apenas banco
BACKUP_MODE="infra"     # Rápido: sem banco e sem webapps grandes
```

### Para Máxima Segurança

```bash
# Mantenha múltiplos tipos de backup
0 2 * * 0 BACKUP_MODE=full ...      # Backup completo semanal
0 3 * * * BACKUP_MODE=database ...  # Banco diário
0 4 1 * * BACKUP_MODE=infra ...     # Infraestrutura mensal
```

### Para Testes de Deploy

```bash
# Antes do deploy
BACKUP_MODE=webapps ./backup-vps.sh

# Se falhar, rollback rápido
./restore-vps.sh <backup> # Opção [5]
```

---

## ❓ Perguntas Frequentes

**P: Posso usar BACKUP_MODE com crontab?**

R: Sim! Você pode passar como variável de ambiente:

```bash
# No crontab
0 3 * * * BACKUP_MODE=database /opt/backup-scripts/backup-vps.sh
```

**P: O que acontece se BACKUP_MODE estiver vazio?**

R: O script usa as configurações individuais do backup.conf (modo legado).

**P: Posso restaurar um backup "database" em um servidor que tem "full"?**

R: Sim! O restore é inteligente. Você pode restaurar qualquer backup parcial em qualquer servidor. O script só restaura o que está disponível no backup.

**P: Como saber o que está incluído em um backup?**

R: Cada backup inclui um arquivo `backup.log` que lista tudo que foi incluído. Além disso, backups modulares identificam o modo no nome do arquivo.

**P: Posso combinar modos?**

R: Não. Escolha um modo por execução. Use crontab para agendar múltiplos backups com modos diferentes.

**P: Qual modo devo usar?**

R: Para a maioria dos casos:
- **Produção:** Combine `full` semanal + `database` diário
- **Desenvolvimento:** Use `full` ou deixe `BACKUP_MODE=""`
- **Antes de deploy:** Use `webapps`
- **Configuração:** Use `infra`

---

## 🔍 Como Funciona (Técnico)

### No Backup (backup-vps.sh)

1. Script lê `BACKUP_MODE` do arquivo `backup.conf`
2. Se `BACKUP_MODE` não estiver vazio, sobrescreve configurações individuais:
   ```bash
   case "$BACKUP_MODE" in
       "full")
           BACKUP_DATABASE=true
           TOMCAT_BACKUP_WEBAPPS=true
           # ... tudo habilitado
           ;;
       "infra")
           BACKUP_DATABASE=false
           TOMCAT_BACKUP_WEBAPPS=false
           # ... apps habilitados
           ;;
       "database")
           BACKUP_DATABASE=true
           # ... tudo desabilitado exceto banco
           ;;
       "webapps")
           TOMCAT_WEBAPPS_ONLY=true
           # ... só webapps
           ;;
   esac
   ```
3. Script executa backup baseado nas configurações finais

### No Restore (restore-vps.sh)

1. Script extrai backup (se .tar.gz)
2. Mostra menu com 12 opções
3. Baseado na escolha, define flags:
   ```bash
   RESTORE_DB=true/false
   RESTORE_TOMCAT=true/false
   RESTORE_TOMCAT_SKIP_WEBAPPS=true/false
   RESTORE_TOMCAT_WEBAPPS_ONLY=true/false
   # ... etc
   ```
4. Para cada componente, verifica flags antes de restaurar
5. Para Tomcat, suporta 3 modos:
   - Restore completo (tudo)
   - Restore sem webapps (skip webapps)
   - Restore apenas webapps (webapps only)

---

## 📝 Resumo Rápido

```bash
# BACKUP MODULAR

# 1. Edite backup.conf
nano backup.conf

# 2. Escolha o modo
BACKUP_MODE="full"      # Tudo
BACKUP_MODE="infra"     # Sem banco e sem webapps
BACKUP_MODE="database"  # Só banco
BACKUP_MODE="webapps"   # Só webapps
BACKUP_MODE=""          # Modo legado (individual)

# 3. Execute
./backup-vps.sh

# 4. Restaure com menu interativo
./restore-vps.sh <caminho-do-backup>
# Escolha uma das 12 opções
```

---

**🎉 Aproveite os backups modulares para maior flexibilidade e eficiência!**
