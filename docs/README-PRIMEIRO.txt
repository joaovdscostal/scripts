================================================================================
   SISTEMA DE BACKUP E RESTORE PARA VPS - LEIA ISSO PRIMEIRO!
================================================================================

Você recebeu um sistema COMPLETO de backup customizável para VPS Linux.

================================================================================
ARQUIVOS INCLUÍDOS (11 arquivos, 152KB total)
================================================================================

📜 SCRIPTS EXECUTÁVEIS:
   ✓ backup-vps.sh              (25KB) - Script principal de backup
   ✓ restore-vps.sh             (19KB) - Restauração de backups
   ✓ generate-inventory.sh      (16KB) - Gera inventário do sistema
   ✓ backup-manager.sh          (15KB) - Interface interativa
   ✓ check-requirements.sh      (13KB) - Verifica requisitos

⚙️  CONFIGURAÇÃO:
   ✓ backup.conf                (6.5KB) - Configuração principal (EDITAR!)
   ✓ backup.conf.example        (4.3KB) - Exemplo de configuração

📖 DOCUMENTAÇÃO:
   ✓ README.md                  (12KB) - Documentação completa
   ✓ QUICKSTART.md              (5KB)  - Guia rápido (5 minutos)
   ✓ INDEX.md                   (9KB)  - Índice e organização
   ✓ INSTALACAO.md              (7KB)  - Instruções de instalação
   ✓ README-PRIMEIRO.txt        (este) - Este arquivo

================================================================================
COMECE POR AQUI - 3 OPÇÕES
================================================================================

🚀 OPÇÃO 1: COMEÇAR RÁPIDO (5 minutos)
   → Abra: QUICKSTART.md

📚 OPÇÃO 2: DOCUMENTAÇÃO COMPLETA
   → Abra: README.md

🗺️  OPÇÃO 3: NAVEGAÇÃO ORGANIZADA
   → Abra: INDEX.md

================================================================================
O QUE ESTE SISTEMA FAZ?
================================================================================

✓ Backup COMPLETO e customizável de:
  • APIs Spring Boot (Java 21)
  • Apache Tomcat 9
  • Aplicações Node.js (PM2)
  • Banco de dados MariaDB/MySQL
  • Nginx + Certificados SSL
  • Sites estáticos
  • Scripts customizados
  • Configurações do sistema

✓ Upload automático para S3 (via rclone)
✓ Compactação automática
✓ Rotação de backups antigos
✓ Restore seletivo ou completo
✓ Gera inventário para migração
✓ Interface interativa

================================================================================
INSTALAÇÃO RÁPIDA NO SERVIDOR
================================================================================

1. Copie TODOS os arquivos para o servidor:

   # No seu computador
   cd /Users/nds/Workspace/scripts
   tar -czf vps-backup.tar.gz vps-backup/
   scp vps-backup.tar.gz root@SEU_SERVIDOR:/tmp/

2. No servidor, extraia e instale:

   ssh root@SEU_SERVIDOR
   cd /tmp
   tar -xzf vps-backup.tar.gz
   mv vps-backup /opt/backup-scripts
   cd /opt/backup-scripts
   chmod +x *.sh

3. Verifique requisitos:

   ./check-requirements.sh

4. Configure:

   cp backup.conf.example backup.conf
   nano backup.conf

   (Edite pelo menos: DB_PASSWORD e suas aplicações)

5. Teste:

   ./backup-vps.sh

6. Veja o resultado:

   ls -lh /root/backups/
   cat /root/backups/*/backup.log

================================================================================
PRINCIPAIS COMPONENTES
================================================================================

BACKUP (backup-vps.sh):
  • Faz backup de todos os componentes configurados
  • Gera log detalhado
  • Compacta em .tar.gz
  • Envia para S3 (opcional)
  • Limpa backups antigos
  • Cria inventário do sistema

RESTORE (restore-vps.sh):
  • Interface interativa
  • Restore completo ou seletivo
  • Valida antes de aplicar
  • Faz backup das configs atuais
  • Suporta .tar.gz ou diretório

MANAGER (backup-manager.sh):
  • Menu interativo com 11 opções
  • Lista e gerencia backups
  • Upload/download S3
  • Visualiza logs
  • Agenda cron

INVENTORY (generate-inventory.sh):
  • Gera relatório completo do sistema
  • Lista software instalado e versões
  • Comandos para replicar ambiente
  • Útil para migração

CHECK (check-requirements.sh):
  • Verifica se sistema está pronto
  • Lista o que falta instalar
  • Testa configurações

================================================================================
CONFIGURAÇÃO MÍNIMA (backup.conf)
================================================================================

Você DEVE configurar pelo menos:

1. Senha do banco de dados:
   DB_PASSWORD="sua_senha_aqui"

2. Suas aplicações Spring Boot (se tiver):
   SPRINGBOOT_APPS=(
       "nome-app:/caminho/app.jar:/caminho/service"
   )

3. Suas aplicações Node.js (se tiver):
   NODEJS_APPS=(
       "nome-app:/caminho/app"
   )

4. Seus sites estáticos (se tiver):
   STATIC_APPS_DIRS=(
       "/var/www/html/site"
   )

5. Tomcat (se tiver):
   TOMCAT_HOME="/opt/tomcat9"

6. S3 para backup remoto (recomendado):
   S3_BACKUP=true
   RCLONE_REMOTE="s3"
   S3_BUCKET="seu-bucket"

================================================================================
COMANDOS MAIS USADOS
================================================================================

# Fazer backup
./backup-vps.sh

# Interface visual
./backup-manager.sh

# Restaurar
./restore-vps.sh /root/backups/XXXXX.tar.gz

# Gerar inventário
./generate-inventory.sh

# Verificar sistema
./check-requirements.sh

# Listar backups
ls -lh /root/backups/

# Ver logs
cat /root/backups/*/backup.log

# Agendar backup diário
crontab -e
# Adicionar: 0 2 * * * /opt/backup-scripts/backup-vps.sh >> /var/log/backup-vps.log 2>&1

================================================================================
SUPORTE S3 (ALTAMENTE RECOMENDADO)
================================================================================

1. Instalar rclone:
   curl https://rclone.org/install.sh | sudo bash

2. Configurar:
   rclone config
   (Escolha: n → nome: s3 → tipo: Amazon S3 → provider: AWS)

3. Habilitar no backup.conf:
   S3_BACKUP=true
   RCLONE_REMOTE="s3"
   S3_BUCKET="seu-bucket"
   S3_PATH="backups/vps"

================================================================================
IMPORTANTE - TESTE O RESTORE!
================================================================================

⚠️  UM BACKUP QUE NÃO FOI TESTADO NÃO É UM BACKUP! ⚠️

Sempre teste o restore em um servidor de desenvolvimento antes
de confiar no backup em produção!

================================================================================
ESTRUTURA DE ARQUIVOS
================================================================================

SERVIDOR:
  /opt/backup-scripts/     ← Instale aqui
  /root/backups/           ← Backups salvos aqui
  /var/log/backup-vps.log  ← Log do cron

BACKUP GERADO:
  20250130_120000.tar.gz (ou diretório)
  ├── backup.log
  ├── database/
  ├── springboot/
  ├── tomcat/
  ├── nodejs/
  ├── static/
  ├── nginx/
  ├── system/
  └── inventory/

================================================================================
PRÓXIMOS PASSOS
================================================================================

1. [ ] Ler INSTALACAO.md para instruções de transferência
2. [ ] Transferir arquivos para servidor
3. [ ] Executar check-requirements.sh
4. [ ] Configurar backup.conf
5. [ ] Fazer primeiro backup de teste
6. [ ] Configurar S3 (recomendado)
7. [ ] Testar restore em ambiente dev
8. [ ] Agendar backup automático

================================================================================
DÚVIDAS?
================================================================================

→ Instalação: INSTALACAO.md
→ Guia rápido: QUICKSTART.md
→ Documentação completa: README.md
→ Índice organizado: INDEX.md
→ Verificar sistema: ./check-requirements.sh

================================================================================
BOA SORTE COM SEUS BACKUPS! 🚀
================================================================================

Desenvolvido para: Servidor VPS com múltiplas aplicações
Compatível com: Ubuntu 20.04+, Debian 10+
Tamanho total: 152KB (11 arquivos)
Versão: 1.0

================================================================================
