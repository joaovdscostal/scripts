# 🔧 Opções Avançadas de Configuração

## Visão Geral

Este documento explica as opções avançadas de configuração do sistema de backup.

---

## 🗄️ Backup de Banco de Dados MariaDB

### Habilitar/Desabilitar Backup de Banco

```bash
# Fazer backup de banco de dados? (true/false)
BACKUP_DATABASE=true
```

**Como funciona:**
- `true` = Faz backup do banco de dados
- `false` = NÃO faz backup do banco de dados

**Quando usar `false`:**
- ✅ Você não usa banco de dados no servidor
- ✅ O banco é muito grande e tem sistema de backup separado
- ✅ O banco está em outro servidor
- ✅ Você quer testar backup só de aplicações

**Exemplo:**

```bash
# Servidor sem banco de dados
BACKUP_DATABASE=false

# Servidor com banco (padrão)
BACKUP_DATABASE=true
DB_USER="root"
DB_PASSWORD="sua_senha"
```

---

## 🐱 Backup do Apache Tomcat

### Incluir ou Não as Webapps

```bash
# Fazer backup das webapps do Tomcat? (true/false)
TOMCAT_BACKUP_WEBAPPS=true
```

### Opção 1: Com Webapps (`true`) - Padrão

**O que é copiado:**
- ✅ Diretório `bin/` (binários)
- ✅ Diretório `conf/` (configurações)
- ✅ Diretório `lib/` (bibliotecas)
- ✅ Diretório `webapps/` (aplicações) ← **INCLUÍDO**
- ✅ Outros arquivos (LICENSE, NOTICE, etc)
- ❌ NÃO copia: `logs/`, `work/`, `temp/`

**Tamanho típico:** 50MB - 1GB (depende das webapps)

**Quando usar:**
- ✅ Você quer backup completo do Tomcat
- ✅ Suas webapps não são muito grandes
- ✅ Você quer restaurar tudo rapidamente
- ✅ **Configuração recomendada para a maioria dos casos**

**Exemplo:**

```bash
BACKUP_TOMCAT=true
TOMCAT_HOME="/opt/tomcat9"
TOMCAT_BACKUP_WEBAPPS=true  # ← Backup COM webapps
```

**Estrutura do backup:**
```
tomcat/
├── bin/
├── conf/
├── lib/
├── webapps/          ← INCLUÍDO
│   ├── ROOT/
│   ├── minha-api/
│   └── admin/
├── LICENSE
├── NOTICE
├── tomcat.service
└── backup-info.txt
```

---

### Opção 2: Sem Webapps (`false`)

**O que é copiado:**
- ✅ Diretório `bin/` (binários)
- ✅ Diretório `conf/` (configurações)
- ✅ Diretório `lib/` (bibliotecas)
- ❌ NÃO copia: `webapps/` ← **EXCLUÍDO**
- ❌ NÃO copia: `logs/`, `work/`, `temp/`

**Tamanho típico:** 10MB - 50MB (muito menor)

**Quando usar:**
- ✅ Suas webapps são muito grandes (>500MB)
- ✅ As webapps estão versionadas no Git
- ✅ Você faz deploy via CI/CD
- ✅ Você só quer salvar a instalação e configurações do Tomcat

**Exemplo:**

```bash
BACKUP_TOMCAT=true
TOMCAT_HOME="/opt/tomcat9"
TOMCAT_BACKUP_WEBAPPS=false  # ← Backup SEM webapps
```

**Estrutura do backup:**
```
tomcat/
├── bin/
├── conf/
├── lib/
├── LICENSE
├── NOTICE
├── tomcat.service
└── backup-info.txt
(webapps/ NÃO incluído)
```

---

## 📊 Comparação Rápida

| O que é copiado | Com Webapps (true) | Sem Webapps (false) |
|----------------|-------------------|-------------------|
| bin/ | ✅ | ✅ |
| conf/ | ✅ | ✅ |
| lib/ | ✅ | ✅ |
| webapps/ | ✅ | ❌ |
| logs/ | ❌ | ❌ |
| work/ | ❌ | ❌ |
| temp/ | ❌ | ❌ |
| **Tamanho** | Maior | Menor |
| **Velocidade** | Mais lento | Mais rápido |

---

## 🎯 Cenários de Uso

### Cenário 1: Servidor de Produção Padrão

**Situação:** Servidor com banco de dados e Tomcat com webapps

```bash
# backup.conf

# Fazer backup do banco
BACKUP_DATABASE=true
DB_USER="root"
DB_PASSWORD="SuaSenha123"
DB_BACKUP_METHOD="mariabackup"

# Fazer backup do Tomcat COM webapps
BACKUP_TOMCAT=true
TOMCAT_HOME="/opt/tomcat9"
TOMCAT_BACKUP_WEBAPPS=true  # ← COM webapps
BACKUP_TOMCAT_LOGS=false

# Enviar para S3
S3_BACKUP=true
```

**Resultado:**
- ✅ Backup completo de tudo
- ⏱️ Tempo: ~30-60 minutos
- 💾 Tamanho: 500MB - 2GB

---

### Cenário 2: Servidor com Deploy CI/CD

**Situação:** Webapps deployadas via Git/CI/CD, não precisa fazer backup delas

```bash
# backup.conf

# Fazer backup do banco
BACKUP_DATABASE=true
DB_USER="root"
DB_PASSWORD="SuaSenha123"

# Fazer backup do Tomcat SEM webapps
BACKUP_TOMCAT=true
TOMCAT_HOME="/opt/tomcat9"
TOMCAT_BACKUP_WEBAPPS=false  # ← SEM webapps
BACKUP_TOMCAT_LOGS=false

# Enviar para S3
S3_BACKUP=true
```

**Resultado:**
- ✅ Backup de banco + instalação Tomcat (sem apps)
- ⏱️ Tempo: ~15-30 minutos
- 💾 Tamanho: 100MB - 500MB

---

### Cenário 3: Servidor Sem Banco de Dados

**Situação:** Apenas aplicações web, sem banco de dados

```bash
# backup.conf

# NÃO fazer backup do banco
BACKUP_DATABASE=false  # ← Banco desabilitado

# Fazer backup do Tomcat COM webapps
BACKUP_TOMCAT=true
TOMCAT_HOME="/opt/tomcat9"
TOMCAT_BACKUP_WEBAPPS=true  # ← COM webapps
BACKUP_TOMCAT_LOGS=false

# Enviar para S3
S3_BACKUP=true
```

**Resultado:**
- ✅ Backup apenas de aplicações
- ⏱️ Tempo: ~10-20 minutos
- 💾 Tamanho: 50MB - 1GB

---

### Cenário 4: Backup Mínimo (Desenvolvimento)

**Situação:** Servidor de desenvolvimento, backup rápido

```bash
# backup.conf

# Fazer backup do banco
BACKUP_DATABASE=true
DB_BACKUP_METHOD="mysqldump"  # Mais simples

# Fazer backup do Tomcat SEM webapps
BACKUP_TOMCAT=true
TOMCAT_BACKUP_WEBAPPS=false  # ← SEM webapps

# Não enviar para S3
S3_BACKUP=false

# Manter poucos backups
BACKUP_RETENTION_DAYS=3
```

**Resultado:**
- ✅ Backup rápido e leve
- ⏱️ Tempo: ~5-15 minutos
- 💾 Tamanho: 50MB - 300MB

---

## 💡 Dicas

### Para Economizar Espaço

```bash
# Desabilitar logs
BACKUP_TOMCAT_LOGS=false
BACKUP_NGINX_LOGS=false

# Não fazer backup das webapps (se estão no Git)
TOMCAT_BACKUP_WEBAPPS=false

# Manter menos backups
BACKUP_RETENTION_DAYS=5
S3_RETENTION_COUNT=10
```

### Para Backup Mais Rápido

```bash
# Usar mariabackup (backup físico - mais rápido)
DB_BACKUP_METHOD="mariabackup"

# Não fazer backup das webapps
TOMCAT_BACKUP_WEBAPPS=false

# Desabilitar logs
BACKUP_TOMCAT_LOGS=false
```

### Para Máxima Segurança (Backup Completo)

```bash
# Backup de tudo
BACKUP_DATABASE=true
DB_BACKUP_METHOD="mariabackup"
BACKUP_TOMCAT=true
TOMCAT_BACKUP_WEBAPPS=true  # COM webapps

# Múltiplas cópias
COMPRESS_BACKUPS=true
S3_BACKUP=true
REMOTE_BACKUP=true

# Manter mais tempo
BACKUP_RETENTION_DAYS=30
S3_RETENTION_COUNT=60
```

---

## ❓ Perguntas Frequentes

**P: Se eu não fizer backup das webapps, como faço para restaurar?**

R: Você faz deploy das webapps via Git ou CI/CD após restaurar o Tomcat.

**P: Posso mudar de opinião entre backups?**

R: Sim! Você pode alterar `TOMCAT_BACKUP_WEBAPPS` a qualquer momento. Cada backup registra o que foi incluído.

**P: O que acontece se eu desabilitar o banco mas ele existir?**

R: Nada. O script simplesmente não faz backup do banco.

**P: Preciso fazer backup dos logs?**

R: Geralmente não. Logs são temporários e ocupam muito espaço. Deixe `BACKUP_TOMCAT_LOGS=false`.

**P: Qual configuração devo usar?**

R: Para a maioria dos casos, use:
```bash
BACKUP_DATABASE=true
TOMCAT_BACKUP_WEBAPPS=true  # Backup completo
```

---

## 📝 Arquivo backup-info.txt

Cada backup do Tomcat inclui um arquivo `backup-info.txt` que registra:

```
Backup com webapps: true
Data: Thu Jan 30 15:30:00 UTC 2025
```

Isso ajuda a identificar o que foi incluído no backup.

---

## 🔄 Como Alterar as Configurações

### Passo 1: Editar o arquivo

```bash
cd /opt/backup-scripts
nano backup.conf
```

### Passo 2: Modificar as opções

```bash
# Exemplo: Desabilitar banco e webapps
BACKUP_DATABASE=false
TOMCAT_BACKUP_WEBAPPS=false
```

### Passo 3: Salvar e executar

```bash
# Salvar: Ctrl+O, Enter, Ctrl+X
./backup-vps.sh
```

### Passo 4: Verificar resultado

```bash
ls -lh /root/backups/
cat /root/backups/*/tomcat/backup-info.txt
```

---

## 📌 Resumo Rápido

```bash
# BANCO DE DADOS
BACKUP_DATABASE=true   # true = backup, false = pular

# TOMCAT
TOMCAT_BACKUP_WEBAPPS=true
  # true  = Backup COM webapps (completo)
  # false = Backup SEM webapps (só instalação)

# Sempre excluídos (independente da configuração):
# - logs/
# - work/
# - temp/
```

---

**Dúvidas? Execute o backup e veja o resultado:**

```bash
./backup-vps.sh
ls -lh /root/backups/
```
