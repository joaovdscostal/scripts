# 🚀 Deploy Automatizado para APIs Spring Boot

## 📦 O que foi criado

### ✅ Dimensao API (PRONTO PARA USAR)

```
dimensao-api/
├── .github/
│   └── workflows/
│       └── deploy-producao.yml      ← Deploy automático
└── DEPLOY.md                        ← Documentação completa
```

### ✅ Scripts Reutilizáveis (Para outras APIs)

```
/Users/nds/Workspace/scripts/
├── deploy-api-workflow-template.yml     ← Template genérico para APIs
├── setup-api-deploy-automation.sh       ← Script de configuração
└── README-DEPLOY-APIS.md                ← Este arquivo
```

## 🎯 Diferenças: Apps Tomcat vs APIs Spring Boot

| Característica | Apps VRaptor (Tomcat) | APIs Spring Boot |
|----------------|----------------------|------------------|
| **Empacotamento** | WAR | JAR executável |
| **Servidor** | Apache Tomcat | Embedded Tomcat/Jetty |
| **Deploy** | rsync → Tomcat restart | git pull → systemd restart |
| **Logs** | catalina.out | journalctl |
| **Controle** | /root/tomcat.sh | systemctl |
| **Build local** | Sim (rsync depois) | Não (build no servidor) |

## 🔄 Fluxo de Deploy

### Apps VRaptor (route-365, code-erp, etc):
```
┌──────────────────────────────────────────┐
│ 1. GitHub Actions compila localmente     │
│ 2. Envia WAR via SSH/SCP                 │
│ 3. Para Tomcat (/root/tomcat.sh stop)   │
│ 4. Extrai WAR no webapps                 │
│ 5. Inicia Tomcat (/root/tomcat.sh start)│
└──────────────────────────────────────────┘
```

### APIs Spring Boot (dimensao-api, etc):
```
┌──────────────────────────────────────────┐
│ 1. GitHub Actions valida código          │
│ 2. Faz git pull no servidor via SSH      │
│ 3. Para serviço (systemctl stop)         │
│ 4. Compila no servidor (mvn package)     │
│ 5. Inicia serviço (systemctl start)      │
└──────────────────────────────────────────┘
```

## 🚀 Quick Start - Dimensao API

### 1️⃣ Configurar GitHub Secret (FAZER UMA VEZ)

```bash
# Copiar chave SSH
cat ~/.ssh/id_rsa

# Ir ao GitHub:
# https://github.com/joaovdscostal/dimensao-api/settings/secrets/actions
#
# Criar secret:
# - Nome: SSH_PRIVATE_KEY
# - Valor: [colar a chave completa]
```

### 2️⃣ Testar Deploy

```bash
cd /Users/nds/Workspace/sts/dimensao-api

# Fazer qualquer mudança
echo "# Test" >> README.md

# Push para main
git add README.md
git commit -m "test: first automated API deploy"
git push origin main
```

### 3️⃣ Acompanhar

```
https://github.com/joaovdscostal/dimensao-api/actions
```

## 🔄 Replicar para Outras APIs

### Método Automático (RECOMENDADO)

```bash
cd /Users/nds/Workspace/scripts

# Para qualquer API Spring Boot
./setup-api-deploy-automation.sh NOME_DA_API

# Exemplo:
./setup-api-deploy-automation.sh dimensao-api
```

O script vai:
- ✅ Detectar configurações automaticamente (JAR, Java version, host, etc)
- ✅ Criar `.github/workflows/deploy-producao.yml`
- ✅ Configurar variáveis corretamente
- ✅ Testar conexão SSH
- ✅ Oferecer fazer commit/push

### Método Manual

```bash
cd /Users/nds/Workspace/sts/SUA_API

# Copiar template
mkdir -p .github/workflows
cp /Users/nds/Workspace/scripts/deploy-api-workflow-template.yml \
   .github/workflows/deploy-producao.yml

# Editar variáveis manualmente
vim .github/workflows/deploy-producao.yml

# Configurar:
# - PROJECT_NAME: nome-da-api
# - SERVER_HOST: api.seudominio.com.br
# - SERVICE_NAME: nome-da-api
# - JAR_NAME: nome-da-api-0.0.1-SNAPSHOT.jar
# - JAVA_VERSION: '17' (ou 11, 21)

# Commit e push
git add .github/workflows/deploy-producao.yml
git commit -m "Configure automated API deployment"
git push origin main
```

## 📊 Requisitos

Para usar este sistema de deploy automático, sua API precisa ter:

### ✅ Estrutura Necessária

1. **Projeto Maven** com `pom.xml`
2. **application.properties** com versão:
   ```properties
   api.version=0.0.1
   api.release.date=13/03/2025
   ```

3. **Serviço systemd** configurado no servidor
   ```bash
   # Arquivo: /etc/systemd/system/nome-da-api.service
   [Unit]
   Description=Nome da API
   After=network.target

   [Service]
   Type=simple
   User=root
   ExecStart=/root/apis/nome-da-api/start-nome-da-api.sh
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```

4. **Script de inicialização** (ex: `start-dimensao-api.sh`)
   ```bash
   #!/bin/bash
   export SERVER_PORT=8082
   export DB_URL="jdbc:mysql://localhost:3306/db"
   export DB_USERNAME=root
   export DB_PASSWORD=senha

   java -jar /root/apis/nome-da-api/target/nome-da-api.jar
   ```

5. **Repositório Git** no servidor em `/root/apis/nome-da-api`

## 🎁 Benefícios

### ✅ Automação Completa
- Push → Deploy automático
- Sem necessidade de SSH manual
- Sem rodar scripts no servidor

### ✅ Confiabilidade
- Backup antes de cada deploy
- Verificação de health
- Logs detalhados

### ✅ Rastreabilidade
- Histórico no GitHub Actions
- Tags automáticas por versão
- Logs do systemd preservados

### ✅ Segurança
- Chave SSH no GitHub Secrets
- Deploy somente após merge aprovado
- Rollback fácil via backup

## 🔧 Comandos Úteis

### No Servidor (Via SSH)

```bash
# Conectar
ssh root@api.vipp.art.br

# Status do serviço
sudo systemctl status dimensao-api

# Ver logs em tempo real
sudo journalctl -u dimensao-api -f

# Reiniciar serviço
sudo systemctl restart dimensao-api

# Ver últimas 100 linhas de log
sudo journalctl -u dimensao-api -n 100

# Testar API
curl localhost:8082/actuator/health

# Ver backups
ls -lh /root/backups/dimensao-api/
```

### No Local (Seu Computador)

```bash
# Deploy
git push origin main

# Ver tags criadas
git tag -l "api-*"

# Voltar para versão anterior (criar deploy)
git checkout api-0.0.1
git push origin main --force  # ⚠️ Cuidado!
```

## 🆘 Troubleshooting

### Deploy falha na compilação
**Problema:** Maven falha ao compilar no servidor

**Solução:**
```bash
# SSH no servidor e teste manualmente
ssh root@api.vipp.art.br
cd /root/apis/dimensao-api
export JAVA_HOME=/root/.sdkman/candidates/java/17.0.15-amzn
export PATH=$JAVA_HOME/bin:$PATH
mvn clean package -DskipTests
```

### Serviço não inicia
**Problema:** systemctl start falha

**Solução:**
```bash
# Ver erro específico
sudo journalctl -u dimensao-api -n 50

# Testar script diretamente
cd /root/apis/dimensao-api
./start-dimensao-api.sh

# Verificar se porta está em uso
sudo netstat -tlnp | grep 8082
```

### API não responde
**Problema:** Deploy OK mas API não responde

**Solução:**
```bash
# Verificar se processo está rodando
ps aux | grep dimensao-api

# Verificar logs
sudo journalctl -u dimensao-api -n 200

# Verificar banco de dados
mysql -u root -p -e "SHOW DATABASES;"

# Testar localmente
curl localhost:8082/actuator/health
```

## 📝 Checklist de Configuração

Para cada API:

- [ ] Copiar/criar workflow GitHub Actions
- [ ] Configurar variáveis (PROJECT_NAME, HOST, etc)
- [ ] Configurar SSH_PRIVATE_KEY no GitHub Secrets
- [ ] Verificar serviço systemd no servidor
- [ ] Verificar git repository no servidor
- [ ] Testar conexão SSH
- [ ] Fazer primeiro deploy de teste
- [ ] Verificar logs e saúde da API

## 🎯 Próximos Passos Sugeridos

### Hoje:
1. Configurar dimensao-api (primeiro teste)
2. Verificar se funcionou corretamente
3. Documentar peculiaridades

### Esta semana:
1. Identificar outras APIs Spring Boot
2. Replicar configuração
3. Testar cada uma

### Este mês:
1. Migrar todas as APIs
2. Desativar deploy.sh manual (opcional)
3. Adicionar testes automatizados

## 💡 Dicas Importantes

1. **APIs são diferentes de apps Tomcat** - Não tente usar o mesmo workflow
2. **Compile no servidor** - APIs Spring Boot devem compilar onde rodam
3. **Use systemd** - Mais robusto que rodar JAR diretamente
4. **Monitore logs** - `journalctl` é seu amigo
5. **Teste health endpoint** - `/actuator/health` é essencial

## 🔗 Relacionado

- **Apps Tomcat:** Ver `/Users/nds/Workspace/scripts/README-DEPLOY-AUTOMATION.md`
- **Template APIs:** Ver `/Users/nds/Workspace/scripts/deploy-api-workflow-template.yml`
- **Script setup:** Ver `/Users/nds/Workspace/scripts/setup-api-deploy-automation.sh`

---

**Criado em:** 2025-11-12
**Para:** Automação de deploys de APIs Spring Boot
**Status:** ✅ Pronto para uso
**Próximo passo:** Configurar secret e testar primeiro deploy
