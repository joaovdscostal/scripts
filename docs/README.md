# Documentação dos Scripts

Esta pasta contém a documentação e instruções para uso dos scripts de automação.

## Arquivos de Documentação

- **CLAUDE.md** - Instruções e visão geral do repositório para Claude Code

## Sistema de Backup e Restore VPS

### Notificações via WhatsApp

Ambos os scripts de **backup** (`backup-vps.sh`) e **restore** (`restore-vps.sh`) foram configurados para enviar notificações via WhatsApp ao invés de email. As notificações incluem:

#### Notificação de Sucesso (Backup)
- ✅ Data e hora do backup
- 📦 Tamanho total do backup
- 📍 Localização do arquivo de backup
- ✅ Status de sucesso

#### Notificação de Sucesso (Restore)
- ✅ Data e hora do restore
- 📦 Nome do backup restaurado
- 🔧 Lista de componentes restaurados
- 📝 Localização do log
- ✅ Status de sucesso

#### Notificação de Erro (Backup/Restore)
- ❌ Data e hora do erro
- 🔢 Código de saída e linha do erro
- 📝 Localização do arquivo de log

### Configuração

Edite o arquivo `vps-backup/backup.conf`:

```bash
# Habilitar/desabilitar notificações
SEND_WHATSAPP_NOTIFICATION=true

# Número do WhatsApp (formato internacional)
WHATSAPP_NUMBER="5522999604234"

# Credenciais da API (já configuradas)
WHATSAPP_API_URL="http://137.184.190.52:8084/message/sendText/1ea41cef-c560-41a9-b25c-257a850560b3"
WHATSAPP_API_KEY="zYzP7ocstxh3Sscefew4FZTCu4ehnM8v4hu"
```

### Sistema de Logs para Cron

Quando os scripts são executados via cron, os logs são salvos em dois lugares:

#### Backup (`backup-vps.sh`)
1. **Log detalhado**: `/root/backups/[data]/backup.log` - Log completo de cada backup
2. **Log do último backup**: `/root/backups/ultimo_backup.log` - Sobrescrito a cada execução (útil para debugging rápido)

#### Restore (`restore-vps.sh`)
1. **Log detalhado**: `/var/log/restore-vps-[data].log` - Log completo de cada restore
2. **Log do último restore**: `/root/backups/ultimo_restore.log` - Sobrescrito a cada execução (útil para debugging rápido)

### Exemplo de Configuração no Cron

```bash
# Backup completo diário às 2:00 AM
0 2 * * * /root/scripts/vps-backup/backup-vps.sh >> /root/backups/ultimo_backup.log 2>&1

# Backup apenas de banco de dados a cada 6 horas
0 */6 * * * BACKUP_MODE="database" /root/scripts/vps-backup/backup-vps.sh >> /root/backups/ultimo_backup.log 2>&1
```

### Desabilitar Notificações

Para desabilitar as notificações via WhatsApp, edite o arquivo `backup.conf`:

```bash
SEND_WHATSAPP_NOTIFICATION=false
```

## Estrutura de Diretórios

```
scripts/
├── docs/                          # Documentação
│   ├── README.md                  # Este arquivo
│   └── CLAUDE.md                  # Instruções para Claude Code
├── vps-backup/                    # Scripts de backup
│   ├── backup-vps.sh             # Script principal
│   ├── backup.conf               # Arquivo de configuração
│   └── check-requirements.sh     # Verificação de dependências
└── [outros scripts...]
```

## Suporte

Para problemas ou dúvidas sobre os scripts:
1. Verifique o log em `/root/backups/ultimo_backup.log`
2. Revise as configurações em `backup.conf`
3. Teste a execução manual antes de adicionar ao cron
