# 📦 Sistema de Backup VPS - Índice de Arquivos

## 📋 Visão Geral

Sistema completo e customizável de backup e restore para servidores VPS Linux.

## 📂 Arquivos do Sistema

### Scripts Principais

| Arquivo | Descrição | Tamanho |
|---------|-----------|---------|
| **backup-vps.sh** | Script principal de backup | ~25KB |
| **restore-vps.sh** | Script de restauração | ~19KB |
| **generate-inventory.sh** | Gera inventário detalhado do sistema | ~16KB |
| **backup-manager.sh** | Interface interativa para gerenciar backups | ~15KB |

### Configuração

| Arquivo | Descrição |
|---------|-----------|
| **backup.conf** | Arquivo de configuração principal (EDITE ESTE) |
| **backup.conf.example** | Exemplo de configuração com valores sugeridos |

### Documentação

| Arquivo | Descrição |
|---------|-----------|
| **README.md** | Documentação completa e detalhada |
| **QUICKSTART.md** | Guia rápido para começar em 5 minutos |
| **BACKUP-MODULAR.md** | 🆕 Guia completo de backups e restores modulares |
| **OPCOES-AVANCADAS.md** | Opções avançadas: banco de dados e modos Tomcat |
| **INSTALACAO.md** | Instruções de instalação no servidor |
| **INDEX.md** | Este arquivo - índice de todos os arquivos |

## 🚀 Por Onde Começar?

### 1. Primeira Vez (Instalação)
👉 Leia: **QUICKSTART.md**

### 2. Configuração Detalhada
👉 Leia: **README.md**

### 3. 🆕 Backups Modulares (Recomendado!)
👉 Leia: **BACKUP-MODULAR.md**
- Backups seletivos (infraestrutura, banco, webapps)
- Restores parciais com 12 opções
- Estratégias de backup para produção

### 4. Interface Visual
👉 Execute: `sudo ./backup-manager.sh`

### 5. Backup Manual
👉 Execute: `sudo ./backup-vps.sh`

## 📖 Fluxo de Uso Típico

```
┌─────────────────────────────────────────┐
│  1. Copiar arquivos para o servidor    │
│     → /opt/backup-scripts/              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  2. Configurar backup.conf              │
│     → Senhas, aplicações, S3, etc       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  3. Testar backup                       │
│     → sudo ./backup-vps.sh              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  4. Verificar resultado                 │
│     → ls /root/backups/                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  5. Testar restore                      │
│     → sudo ./restore-vps.sh backup.tar  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  6. Agendar backup automático           │
│     → sudo crontab -e                   │
└─────────────────────────────────────────┘
```

## 🔧 Detalhes dos Scripts

### backup-vps.sh
**Função:** Realiza backup completo do sistema

**Suporta:**
- ☕ Spring Boot (Java 21)
- 🐱 Tomcat 9
- 🟢 Node.js + PM2
- 🗄️ MariaDB (mariabackup/mysqldump)
- 🌐 Nginx + SSL
- 📄 Sites estáticos
- 🔧 Scripts customizados

**Gera:**
- Arquivo compactado (.tar.gz)
- Log detalhado
- Inventário do sistema
- Script de migração

**Upload automático:**
- S3 via rclone
- Servidor remoto via rsync

---

### restore-vps.sh
**Função:** Restaura backups de forma seletiva

**Opções:**
1. Restore completo
2. Apenas banco de dados
3. Apenas aplicações específicas
4. Personalizado (escolher componentes)

**Características:**
- Interativo com confirmações
- Restaura de .tar.gz ou diretório
- Testa configurações antes de aplicar
- Cria backups das configs atuais

---

### generate-inventory.sh
**Função:** Gera relatório completo do sistema

**Inclui:**
- Informações de hardware
- Softwares instalados e versões
- Configurações de rede
- Serviços systemd
- Cron jobs
- Usuários e grupos
- Firewall
- Comandos para replicar ambiente

**Uso:**
```bash
# Gerar inventário
sudo ./generate-inventory.sh

# Ou especificar arquivo
sudo ./generate-inventory.sh /tmp/meu-inventario.txt
```

---

### backup-manager.sh
**Função:** Interface visual para gerenciar backups

**Funcionalidades:**
- [1] Fazer backup
- [2] Restaurar
- [3] Listar backups
- [4] Ver detalhes
- [5] Gerar inventário
- [6] Upload para S3
- [7] Download do S3
- [8] Limpar backups antigos
- [9] Testar configuração
- [10] Ver logs
- [11] Agendar backup automático

**Uso:**
```bash
sudo ./backup-manager.sh
```

---

## ⚙️ Arquivo de Configuração (backup.conf)

### Seções Principais:

1. **Configurações Gerais**
   - Diretório de backups
   - Retenção
   - Compactação

2. **Banco de Dados**
   - Credenciais
   - Lista de bancos
   - Método (mariabackup/mysqldump)

3. **Aplicações Spring Boot**
   - Lista de APIs
   - Paths dos JARs
   - Services systemd

4. **Tomcat**
   - Diretório home
   - Backup de logs

5. **Node.js**
   - Lista de aplicações
   - Configuração PM2
   - Usuário PM2

6. **Aplicações Estáticas**
   - Lista de diretórios

7. **Nginx**
   - Configurações
   - Certificados SSL

8. **Scripts Customizados**
   - Diretórios de scripts
   - Logs

9. **S3 (Rclone)**
   - Remote name
   - Bucket
   - Path
   - Retenção

10. **Backup Remoto**
    - SSH/rsync config

---

## 📁 Estrutura de Diretórios

```
/opt/backup-scripts/           # Scripts instalados aqui
├── backup-vps.sh
├── restore-vps.sh
├── generate-inventory.sh
├── backup-manager.sh
├── backup.conf                # IMPORTANTE: Editar este
├── backup.conf.example
├── README.md
├── QUICKSTART.md
└── INDEX.md

/root/backups/                 # Backups armazenados aqui
├── 20250130_120000.tar.gz
├── 20250131_120000.tar.gz
└── ...

/var/log/                      # Logs
└── backup-vps.log
```

---

## 🎯 Casos de Uso

### Caso 1: Servidor de Desenvolvimento
```bash
# Backup simples, local
BACKUP_ROOT="/backups"
COMPRESS_BACKUPS=true
S3_BACKUP=false
BACKUP_RETENTION_DAYS=3
```

### Caso 2: Servidor de Produção
```bash
# Backup completo com S3
COMPRESS_BACKUPS=true
S3_BACKUP=true
BACKUP_RETENTION_DAYS=7
S3_RETENTION_COUNT=30
DB_BACKUP_METHOD="mariabackup"
```

### Caso 3: Migração de Servidor
```bash
# 1. No servidor antigo
sudo ./backup-vps.sh

# 2. No servidor novo
sudo ./generate-inventory.sh
# Seguir comandos do inventário
sudo ./restore-vps.sh backup.tar.gz
```

---

## 🔗 Links Rápidos

| Para | Veja |
|------|------|
| Começar rapidamente | QUICKSTART.md |
| Documentação completa | README.md |
| 🆕 Backups modulares | BACKUP-MODULAR.md |
| Opções avançadas | OPCOES-AVANCADAS.md |
| Instalar rclone | https://rclone.org/install/ |
| Configurar S3 | README.md seção "Configurar Rclone" |
| Troubleshooting | README.md seção "Troubleshooting" |
| Exemplos práticos | README.md seção "Exemplos Práticos" |

---

## ✅ Checklist de Implementação

- [ ] Copiei todos os arquivos para `/opt/backup-scripts/`
- [ ] Dei permissão de execução: `chmod +x *.sh`
- [ ] Copiei `backup.conf.example` para `backup.conf`
- [ ] Editei `backup.conf` com minhas configurações
- [ ] Testei backup manualmente: `sudo ./backup-vps.sh`
- [ ] Verifiquei o backup: `ls -lh /root/backups/`
- [ ] Instalei rclone (se usar S3)
- [ ] Configurei rclone: `rclone config`
- [ ] Testei upload S3 (se aplicável)
- [ ] Testei restore em servidor de desenvolvimento
- [ ] Agendei backup automático no cron
- [ ] Documentei senhas em local seguro

---

## 💡 Dicas

1. **Sempre teste o restore** antes de confiar no backup
2. **Use mariabackup** para backups grandes (mais rápido)
3. **Envie para S3** para proteção contra desastres
4. **Mantenha 3 cópias**: local, remoto, S3 (regra 3-2-1)
5. **Teste restore mensalmente** em servidor de desenvolvimento
6. **Documente** customizações específicas da sua infraestrutura
7. **Monitore** espaço em disco regularmente
8. **Use backup-manager.sh** para facilitar operações

---

## 🆘 Precisa de Ajuda?

1. **Ler logs**: `cat /root/backups/*/backup.log`
2. **Gerar inventário**: `sudo ./generate-inventory.sh`
3. **Testar config**: `sudo ./backup-manager.sh` → opção [9]
4. **Ver README**: `less README.md`

---

**Versão:** 1.0
**Última atualização:** Janeiro 2025
**Compatibilidade:** Ubuntu 20.04+, Debian 10+
