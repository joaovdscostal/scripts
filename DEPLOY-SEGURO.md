# 🛡️ Deploy Seguro - Preservação de Arquivos

## ⚠️ Problema Identificado

O deploy automático estava fazendo `rm -rf` na pasta inteira, **apagando**:
- ❌ Uploads de clientes (`arquivos/`)
- ❌ Imagens enviadas (`img/`)
- ❌ Configurações customizadas (`WEB-INF/web.xml`)
- ❌ Qualquer modificação manual no servidor

## ✅ Solução Implementada

### 1. Arquivo `.deployignore`

Criado na raiz do projeto para definir o que **NÃO deve ser sobrescrito**:

```
arquivos/
img/
WEB-INF/web.xml
```

### 2. Deploy Inteligente

O workflow agora:

1. **Extrai nova versão** em diretório temporário
2. **Preserva arquivos críticos** do servidor atual:
   - Copia `arquivos/` antigo → novo
   - Copia `img/` antigo → novo
   - Copia `WEB-INF/web.xml` antigo → novo
3. **Substitui log4j**: `log4j.producao.properties` → `log4j.properties`
4. **Move nova versão** para o lugar final

### 3. Fluxo do Deploy

```bash
# Antes (PERIGOSO):
rm -rf /webapps/route-365  # ❌ Perdia tudo!
tar -xzf novo.tar.gz

# Agora (SEGURO):
tar -xzf novo.tar.gz -C /tmp/deploy_temp/
cp -r /webapps/route-365/arquivos /tmp/deploy_temp/  # ✅ Preserva
cp -r /webapps/route-365/img /tmp/deploy_temp/       # ✅ Preserva
cp /webapps/route-365/WEB-INF/web.xml /tmp/deploy_temp/WEB-INF/  # ✅ Preserva
rm -rf /webapps/route-365
mv /tmp/deploy_temp /webapps/route-365
```

## 🔧 Recuperação de Arquivos Perdidos

Se o deploy já rodou e apagou arquivos, use o script de recuperação:

```bash
cd /Users/nds/Workspace/scripts
./recuperar-arquivos.sh
```

**Opções disponíveis:**

1. **Recuperar apenas arquivos/ e img/** (recomendado)
   - Restaura uploads sem mexer no código novo

2. **Recuperar arquivos/ + img/ + web.xml**
   - Restaura uploads + configurações

3. **Restaurar backup completo**
   - Volta TUDO (código antigo + arquivos)
   - Usa quando o deploy quebrou completamente

4. **Extrair backup para análise**
   - Explora o backup sem modificar nada

### Recuperação Manual

```bash
# Ver backups disponíveis
ssh -i ~/.ssh/id_ed25519 root@157.230.231.220 \
  "ls -lh /root/backups/route-365/"

# Recuperar apenas arquivos e img
ssh -i ~/.ssh/id_ed25519 root@157.230.231.220 << 'EOF'
  cd /tmp
  tar -xzf /root/backups/route-365/backup_YYYYMMDD_HHMMSS.tar.gz

  cp -r route-365/arquivos /root/appservers/apache-tomcat-9/webapps/route-365/
  cp -r route-365/img /root/appservers/apache-tomcat-9/webapps/route-365/

  rm -rf route-365
EOF
```

## 📋 Checklist Para Novos Projetos

Ao configurar deploy automático em outro projeto:

- [ ] Criar arquivo `.deployignore` na raiz
- [ ] Identificar pastas de upload (ex: `arquivos/`, `uploads/`, `files/`)
- [ ] Identificar imagens dinâmicas (ex: `img/`, `images/`, `fotos/`)
- [ ] Identificar configs customizadas (ex: `web.xml`, `context.xml`)
- [ ] Identificar arquivo de properties de produção (ex: `log4j.producao.properties`)
- [ ] Ajustar workflow para copiar os arquivos preservados
- [ ] Testar em ambiente de homologação primeiro!

## 🎯 Exemplo de `.deployignore` Para Outros Projetos

### Projeto com uploads de múltiplos tipos:
```
arquivos/
uploads/
img/
fotos/
documentos/
anexos/
WEB-INF/web.xml
WEB-INF/classes/hibernate.cfg.xml
```

### Projeto API Spring Boot:
```
application-producao.properties
uploads/
logs/
data/
```

### Projeto com cache local:
```
arquivos/
img/
cache/
temp/
WEB-INF/web.xml
```

## 🚨 Se Perdeu Arquivos

**NÃO ENTRE EM PÂNICO!**

1. O workflow cria backup automático antes de cada deploy
2. Backups ficam em `/root/backups/PROJETO_NAME/`
3. Mantém os 5 backups mais recentes
4. Use `recuperar-arquivos.sh` para restaurar

**Ver quando foi o último backup:**
```bash
ssh -i ~/.ssh/id_ed25519 root@157.230.231.220 \
  "ls -lht /root/backups/route-365/ | head -n 5"
```

## 🔒 Segurança Adicional

### Backup Externo (Recomendado)

Fazer backup periódico dos arquivos críticos para fora do servidor:

```bash
# Backup local dos uploads
rsync -avz -e "ssh -i ~/.ssh/id_ed25519" \
  root@157.230.231.220:/root/appservers/apache-tomcat-9/webapps/route-365/arquivos/ \
  ~/Backups/route-365-arquivos/

# Backup das imagens
rsync -avz -e "ssh -i ~/.ssh/id_ed25519" \
  root@157.230.231.220:/root/appservers/apache-tomcat-9/webapps/route-365/img/ \
  ~/Backups/route-365-img/
```

### Adicionar ao Cron (Backup Automático Diário)

No servidor:
```bash
# Editar crontab
crontab -e

# Adicionar (backup diário às 3h da manhã):
0 3 * * * tar -czf /root/backups/route-365/manual_$(date +\%Y\%m\%d).tar.gz \
  /root/appservers/apache-tomcat-9/webapps/route-365/arquivos \
  /root/appservers/apache-tomcat-9/webapps/route-365/img
```

## 📞 Em Caso de Emergência

1. **Parar Tomcat imediatamente**:
   ```bash
   ssh -i ~/.ssh/id_ed25519 root@157.230.231.220 "/root/tomcat.sh stop"
   ```

2. **Restaurar último backup**:
   ```bash
   ./recuperar-arquivos.sh  # Opção 3
   ```

3. **Verificar o que foi restaurado**:
   ```bash
   ssh -i ~/.ssh/id_ed25519 root@157.230.231.220 \
     "ls -lh /root/appservers/apache-tomcat-9/webapps/route-365/arquivos/"
   ```

4. **Reiniciar Tomcat**:
   ```bash
   ssh -i ~/.ssh/id_ed25519 root@157.230.231.220 "/root/tomcat.sh start"
   ```

---

**Criado em:** 2025-11-12
**Motivação:** Deploy automático apagou arquivos de clientes
**Status:** ✅ Corrigido com preservação inteligente
