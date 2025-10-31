# Configurar DigitalOcean Spaces com Rclone

Este guia mostra como configurar o rclone para fazer backup automático no DigitalOcean Spaces.

## Pré-requisitos

1. **Conta DigitalOcean** com Spaces habilitado
2. **Rclone instalado** no servidor

```bash
# Instalar rclone se não estiver instalado
curl https://rclone.org/install.sh | sudo bash

# Verificar instalação
rclone version
```

## Passo 1: Criar um Space no DigitalOcean

1. Acesse o [DigitalOcean Console](https://cloud.digitalocean.com/)
2. Vá em **Spaces** no menu lateral
3. Clique em **Create a Space**
4. Configure:
   - **Datacenter Region**: Escolha a região (ex: `nyc3`, `sfo3`, `ams3`, `sgp1`)
   - **Space Name**: Nome do seu space (ex: `backup-vps`)
   - **Enable CDN**: (opcional, não necessário para backups)
5. Clique em **Create Space**

## Passo 2: Gerar Chaves de API (Spaces Keys)

1. No menu lateral, vá em **API**
2. Role até a seção **Spaces access keys**
3. Clique em **Generate New Key**
4. Dê um nome (ex: `backup-vps-key`)
5. Guarde as credenciais:
   - **Access Key ID** (ex: `DO00ABC123XYZ456`)
   - **Secret Access Key** (ex: `abc123xyz456...`) ⚠️ **SALVE AGORA! Não poderá ver novamente**

## Passo 3: Configurar Rclone

Execute o comando de configuração interativa:

```bash
rclone config
```

### Configuração Passo a Passo

```
n) New remote
name> digitalocean

Choose a number from below, or type in your own value
Storage> s3
  (escolha o número correspondente a "Amazon S3 Compliant Storage Providers")

Choose your S3 provider
provider> DigitalOcean
  (escolha o número para DigitalOcean Spaces)

Get AWS credentials from runtime (environment variables or EC2/ECS meta data if no env vars)
env_auth> 1
  (escolha 1 = false, vamos inserir manualmente)

AWS Access Key ID
access_key_id> DO00ABC123XYZ456
  (cole sua Access Key ID do Passo 2)

AWS Secret Access Key (password)
secret_access_key> abc123xyz456...
  (cole sua Secret Access Key do Passo 2)

Region to connect to
region>
  (deixe em branco, pressionando Enter)

Endpoint for DigitalOcean Spaces API
endpoint> nyc3.digitaloceanspaces.com
  (substitua 'nyc3' pela região do seu Space)
  Regiões comuns:
  - nyc3.digitaloceanspaces.com (Nova York)
  - sfo3.digitaloceanspaces.com (São Francisco)
  - ams3.digitaloceanspaces.com (Amsterdã)
  - sgp1.digitaloceanspaces.com (Singapura)

Location constraint - must be set to match the Region
location_constraint>
  (deixe em branco, pressionando Enter)

Canned ACL used when creating buckets and storing or copying objects
acl> private
  (escolha "private" para manter backups privados)

Edit advanced config?
y/n> n
  (escolha n = não)

Configuration complete. Keep this "digitalocean" remote?
y/e/d> y
  (escolha y = sim)

q) Quit config
```

## Passo 4: Testar a Conexão

```bash
# Listar os Spaces
rclone lsd digitalocean:

# Deve mostrar algo como:
#     -1 2024-10-31 10:00:00        -1 backup-vps

# Criar um arquivo de teste
echo "teste" > /tmp/teste.txt

# Enviar para o Space
rclone copy /tmp/teste.txt digitalocean:backup-vps/teste/

# Listar arquivos no Space
rclone ls digitalocean:backup-vps/

# Remover arquivo de teste
rclone delete digitalocean:backup-vps/teste/teste.txt
```

## Passo 5: Configurar o backup.conf

Edite o arquivo `/root/scripts/vps-backup/backup.conf`:

```bash
# ============================================================================
# BACKUP PARA DIGITALOCEAN SPACES VIA RCLONE
# ============================================================================

# Habilitar backup no Spaces
S3_BACKUP=true

# Nome do remote (o que você configurou no rclone)
RCLONE_REMOTE="digitalocean"

# Nome do seu Space
S3_BUCKET="backup-vps"

# Caminho dentro do Space (opcional)
S3_PATH="backups/vps-producao"

# Quantos backups manter (limpa os mais antigos)
S3_RETENTION_COUNT=10
```

## Passo 6: Testar o Backup

Execute um backup de teste:

```bash
cd /root/scripts/vps-backup
./backup-vps.sh
```

Verifique se o backup foi enviado:

```bash
rclone ls digitalocean:backup-vps/backups/vps-producao/
```

## Estrutura Final no Spaces

Depois dos backups, seu Space terá esta estrutura:

```
backup-vps/                          (seu Space)
└── backups/
    └── vps-producao/
        ├── 20251031_020000.tar.gz
        ├── 20251101_020000.tar.gz
        ├── 20251102_020000.tar.gz
        └── ...
```

## Comandos Úteis do Rclone

```bash
# Listar Spaces
rclone lsd digitalocean:

# Listar arquivos em um Space
rclone ls digitalocean:backup-vps/

# Ver tamanho total usado
rclone size digitalocean:backup-vps/

# Download de um backup
rclone copy digitalocean:backup-vps/backups/vps-producao/20251031_020000.tar.gz /root/restore/

# Ver configuração atual
rclone config show digitalocean

# Reconfigurar remote
rclone config update digitalocean

# Testar conexão e velocidade
rclone check digitalocean:backup-vps/
```

## Custos DigitalOcean Spaces

- **Armazenamento**: $5/mês para 250GB inclusos, depois $0.02/GB
- **Transferência**: 1TB incluído, depois $0.01/GB
- **Sem cobrança por requisições** (ao contrário da AWS S3)

💡 **Dica**: Mantenha `S3_RETENTION_COUNT` configurado para evitar acúmulo de backups antigos e custos desnecessários.

## Segurança

### ⚠️ IMPORTANTE: Proteja suas credenciais

1. **Permissões do arquivo de configuração do rclone:**
   ```bash
   chmod 600 ~/.config/rclone/rclone.conf
   ```

2. **Backup das credenciais:**
   - Guarde as chaves de API em um gerenciador de senhas
   - Faça backup do arquivo `~/.config/rclone/rclone.conf`

3. **Rotação de chaves:**
   - Considere rotacionar as Spaces Keys periodicamente
   - Atualize o rclone após gerar novas chaves

## Troubleshooting

### Erro: "Failed to create file system"
- Verifique o endpoint (região correta)
- Verifique as credenciais (Access Key e Secret Key)

### Erro: "NoSuchBucket"
- Verifique se o nome do Space está correto em `S3_BUCKET`
- Lembre-se: o nome do Space não deve incluir o endpoint

### Backup lento
- Verifique a velocidade de upload do servidor: `speedtest-cli`
- Considere compactar antes com `COMPRESS_BACKUPS=true`
- Escolha uma região mais próxima do servidor

### Ver logs detalhados
```bash
rclone copy /caminho/arquivo digitalocean:backup-vps/ -vv
```

## Migração de S3 para Spaces

Se você já usa AWS S3, pode copiar backups existentes:

```bash
# Copiar de S3 para Spaces
rclone copy s3:meu-bucket-s3/ digitalocean:backup-vps/ --progress
```

## Monitoramento

Adicione ao cron para receber relatórios:

```bash
# Verificar tamanho usado diariamente
0 8 * * * rclone size digitalocean:backup-vps/ | mail -s "Espaço usado Spaces" admin@exemplo.com
```

---

## Links Úteis

- [DigitalOcean Spaces Docs](https://docs.digitalocean.com/products/spaces/)
- [Rclone Documentation](https://rclone.org/s3/)
- [DigitalOcean Spaces Pricing](https://www.digitalocean.com/pricing/spaces)

---

✅ **Pronto!** Seus backups agora serão enviados automaticamente para o DigitalOcean Spaces.
