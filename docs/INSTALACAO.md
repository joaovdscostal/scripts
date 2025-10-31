# 📦 Instruções de Instalação no Servidor VPS

## Método 1: Upload via SCP (Recomendado)

### 1. Comprimir os arquivos localmente

```bash
# No seu computador local
cd /Users/nds/Workspace/scripts
tar -czf vps-backup.tar.gz vps-backup/
```

### 2. Enviar para o servidor

```bash
# Substitua user e IP pelo seu servidor
scp vps-backup.tar.gz root@SEU_SERVIDOR_IP:/tmp/
```

### 3. No servidor, extrair e instalar

```bash
# Conectar ao servidor
ssh root@SEU_SERVIDOR_IP

# Extrair
cd /tmp
tar -xzf vps-backup.tar.gz

# Mover para local definitivo
mv vps-backup /opt/backup-scripts

# Dar permissões
cd /opt/backup-scripts
chmod +x *.sh

# Verificar requisitos
./check-requirements.sh

# Configurar
cp backup.conf.example backup.conf
nano backup.conf
```

---

## Método 2: Clone via Git

### Se você subir para um repositório Git privado

```bash
# No servidor
ssh root@SEU_SERVIDOR_IP

# Clonar repositório
cd /opt
git clone SEU_REPOSITORIO_GIT backup-scripts

# Dar permissões
cd backup-scripts
chmod +x *.sh

# Configurar
cp backup.conf.example backup.conf
nano backup.conf
```

---

## Método 3: Cópia Manual Arquivo por Arquivo

### Via SFTP ou Painel de Controle

1. Conecte via SFTP ao servidor
2. Crie o diretório `/opt/backup-scripts`
3. Faça upload de todos os arquivos:
   - backup-vps.sh
   - restore-vps.sh
   - generate-inventory.sh
   - backup-manager.sh
   - check-requirements.sh
   - backup.conf (ou backup.conf.example)
   - README.md
   - QUICKSTART.md
   - INDEX.md

4. Conecte via SSH e execute:

```bash
cd /opt/backup-scripts
chmod +x *.sh
```

---

## Método 4: Script de Instalação Automatizada

### Criar um script de instalação única

```bash
# No seu computador, criar install.sh
cat > install.sh << 'EOF'
#!/bin/bash
set -e

echo "Instalando Sistema de Backup VPS..."

# Criar diretório
mkdir -p /opt/backup-scripts
cd /opt/backup-scripts

# Baixar arquivos (se estiverem em algum servidor web)
# OU copiar de /tmp se você fez upload antes

# Dar permissões
chmod +x *.sh

# Criar diretório de backups
mkdir -p /root/backups

# Verificar requisitos
./check-requirements.sh

echo ""
echo "Instalação concluída!"
echo "Configure o arquivo backup.conf antes de usar:"
echo "  nano /opt/backup-scripts/backup.conf"
EOF

# Enviar e executar
scp install.sh root@SEU_SERVIDOR_IP:/tmp/
ssh root@SEU_SERVIDOR_IP 'bash /tmp/install.sh'
```

---

## Pós-Instalação: Configuração Inicial

### 1. Verificar Requisitos

```bash
cd /opt/backup-scripts
./check-requirements.sh
```

### 2. Configurar backup.conf

```bash
# Copiar exemplo
cp backup.conf.example backup.conf

# Editar configurações
nano backup.conf
```

**Configurações MÍNIMAS obrigatórias:**

```bash
# Senha do banco de dados
DB_PASSWORD="SuaSenhaAqui"

# Se usar Spring Boot
SPRINGBOOT_APPS=(
    "nome-app:/caminho/app.jar:/caminho/service"
)

# Se usar Node.js
NODEJS_APPS=(
    "nome-app:/caminho/app"
)

# Se usar sites estáticos
STATIC_APPS_DIRS=(
    "/var/www/html/seu-site"
)

# Se usar Tomcat
TOMCAT_HOME="/opt/tomcat9"
```

### 3. Testar Backup

```bash
# Fazer primeiro backup
./backup-vps.sh

# Verificar resultado
ls -lh /root/backups/

# Ver log
cat /root/backups/*/backup.log
```

### 4. Configurar S3 (Opcional mas Recomendado)

```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# Configurar
rclone config

# Testar
rclone lsd s3:
```

### 5. Agendar Backup Automático

```bash
# Editar crontab
crontab -e

# Adicionar linha (backup diário às 2h)
0 2 * * * /opt/backup-scripts/backup-vps.sh >> /var/log/backup-vps.log 2>&1
```

---

## Estrutura Final no Servidor

```
/opt/backup-scripts/
├── backup-vps.sh              ← Script principal
├── restore-vps.sh             ← Script de restore
├── generate-inventory.sh      ← Gerar inventário
├── backup-manager.sh          ← Interface visual
├── check-requirements.sh      ← Verificar requisitos
├── backup.conf                ← SUA CONFIGURAÇÃO (editar!)
├── backup.conf.example        ← Exemplo
├── README.md                  ← Documentação completa
├── QUICKSTART.md              ← Guia rápido
└── INDEX.md                   ← Índice de arquivos

/root/backups/                 ← Backups salvos aqui
└── (vazio inicialmente)

/var/log/
└── backup-vps.log             ← Log do cron
```

---

## Comandos Úteis Pós-Instalação

```bash
# Interface visual
cd /opt/backup-scripts
./backup-manager.sh

# Backup manual
./backup-vps.sh

# Ver backups
ls -lh /root/backups/

# Gerar inventário
./generate-inventory.sh

# Testar restore
./restore-vps.sh /root/backups/XXXXX.tar.gz

# Ver logs do cron
tail -f /var/log/backup-vps.log

# Verificar cron agendado
crontab -l
```

---

## Permissões e Segurança

### Proteger arquivo de configuração

```bash
# Apenas root pode ler (contém senhas)
chmod 600 /opt/backup-scripts/backup.conf
```

### Criar usuário específico para backups (opcional)

```bash
# Criar usuário
useradd -m -s /bin/bash backupuser

# Dar permissões específicas
chown -R backupuser:backupuser /opt/backup-scripts
chown -R backupuser:backupuser /root/backups

# Executar como esse usuário
sudo -u backupuser /opt/backup-scripts/backup-vps.sh
```

---

## Troubleshooting de Instalação

### Erro: "Permission denied"

```bash
# Verificar permissões
ls -la /opt/backup-scripts/*.sh

# Corrigir
chmod +x /opt/backup-scripts/*.sh
```

### Erro: "bash: ./backup-vps.sh: No such file or directory"

```bash
# Verificar se arquivos foram copiados
ls -la /opt/backup-scripts/

# Verificar diretório atual
pwd
```

### Erro: "mariabackup: command not found"

```bash
# Instalar mariabackup
sudo apt install mariadb-backup

# OU mudar método no backup.conf
# DB_BACKUP_METHOD="mysqldump"
```

---

## Checklist Final

- [ ] Todos os arquivos copiados para `/opt/backup-scripts/`
- [ ] Permissões de execução aplicadas: `chmod +x *.sh`
- [ ] Requisitos verificados: `./check-requirements.sh`
- [ ] backup.conf configurado com senhas e aplicações
- [ ] Primeiro backup testado: `./backup-vps.sh`
- [ ] Backup verificado: `ls /root/backups/`
- [ ] Log verificado sem erros
- [ ] S3 configurado (se aplicável)
- [ ] Cron agendado para backup automático
- [ ] Restore testado em ambiente de desenvolvimento
- [ ] Senhas documentadas em local seguro
- [ ] Equipe treinada nos procedimentos

---

## Próximos Passos Após Instalação

1. ✅ Sistema instalado
2. ⬜ **Testar restore completo em servidor de desenvolvimento**
3. ⬜ Documentar customizações específicas
4. ⬜ Treinar equipe nos procedimentos
5. ⬜ Estabelecer rotina de verificação mensal
6. ⬜ Configurar alertas de falha de backup

---

## Suporte

- 📖 Ver documentação: `less README.md`
- 🚀 Guia rápido: `less QUICKSTART.md`
- 📋 Índice: `less INDEX.md`
- 🔍 Verificar sistema: `./check-requirements.sh`
- 📊 Gerar inventário: `./generate-inventory.sh`

---

**Boa sorte com seus backups! 🚀**

Lembre-se: **Um backup que não foi testado não é um backup!**
