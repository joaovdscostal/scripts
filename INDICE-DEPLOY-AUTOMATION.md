# 📚 Índice - Sistema de Deploy Automatizado

## 🎯 Escolha o Tipo do Seu Projeto

### 📦 Apps com VRaptor + Tomcat

**Exemplos:** route-365, code-erp, multt, contabil, poker, emprestimo, cidadania, codetech, epubliq, formeseguro, clubearte

**Características:**
- Empacotamento: WAR
- Servidor: Apache Tomcat
- Build: Local (GitHub Actions) + rsync para servidor
- Controle: `/root/tomcat.sh start|stop|restart`

**📖 Documentação:**
- **Quick Start:** `/Users/nds/Workspace/sts/route-365/PRIMEIROS_PASSOS.md`
- **Guia Completo:** `/Users/nds/Workspace/sts/route-365/DEPLOY.md`
- **Template:** `/Users/nds/Workspace/scripts/deploy-workflow-template.yml`
- **README:** `/Users/nds/Workspace/scripts/README-DEPLOY-AUTOMATION.md`

**🛠️ Script de Configuração:**
```bash
cd /Users/nds/Workspace/scripts
./setup-deploy-automation.sh NOME_DO_PROJETO
```

---

### 🔧 APIs Spring Boot

**Exemplos:** dimensao-api, e outras APIs Spring Boot que você tiver

**Características:**
- Empacotamento: JAR executável
- Servidor: Embedded (Spring Boot)
- Build: No servidor (git pull + mvn package)
- Controle: `systemctl start|stop|restart nome-api`

**📖 Documentação:**
- **Guia Completo:** `/Users/nds/Workspace/sts/dimensao-api/DEPLOY.md`
- **Template:** `/Users/nds/Workspace/scripts/deploy-api-workflow-template.yml`
- **README:** `/Users/nds/Workspace/scripts/README-DEPLOY-APIS.md`

**🛠️ Script de Configuração:**
```bash
cd /Users/nds/Workspace/scripts
./setup-api-deploy-automation.sh NOME_DA_API
```

---

## 📁 Estrutura de Arquivos

```
/Users/nds/Workspace/
│
├── sts/
│   ├── route-365/                    # App VRaptor (CONFIGURADO ✅)
│   │   ├── .github/workflows/
│   │   │   ├── deploy-producao.yml
│   │   │   └── deploy-homologacao.yml
│   │   ├── DEPLOY.md
│   │   └── PRIMEIROS_PASSOS.md
│   │
│   ├── dimensao-api/                 # API Spring Boot (CONFIGURADO ✅)
│   │   ├── .github/workflows/
│   │   │   └── deploy-producao.yml
│   │   └── DEPLOY.md
│   │
│   ├── code-erp/                     # Próximos a configurar...
│   ├── multt/
│   └── ... (outros projetos)
│
└── scripts/                          # 🎯 COMECE AQUI!
    ├── INDICE-DEPLOY-AUTOMATION.md   # 👈 Este arquivo
    │
    ├── README-DEPLOY-AUTOMATION.md   # Apps Tomcat - Overview
    ├── README-DEPLOY-APIS.md         # APIs Spring - Overview
    │
    ├── deploy-workflow-template.yml         # Template Apps Tomcat
    ├── deploy-api-workflow-template.yml     # Template APIs Spring
    │
    ├── setup-deploy-automation.sh           # Script Apps Tomcat
    ├── setup-api-deploy-automation.sh       # Script APIs Spring
    │
    ├── COMO_USAR_TEMPLATE.md                # Guia Apps Tomcat
    │
    ├── compilar.sh                   # Script antigo (backup)
    └── publicar.sh                   # Script antigo (backup)
```

---

## 🚀 Quick Start por Tipo

### Para Apps Tomcat (ex: code-erp, multt)

```bash
# 1. Configurar
cd /Users/nds/Workspace/scripts
./setup-deploy-automation.sh code-erp

# 2. Adicionar secret no GitHub
# Ir em: https://github.com/SEU_USER/code-erp/settings/secrets/actions
# Criar: SSH_PRIVATE_KEY (conteúdo de ~/.ssh/id_rsa)

# 3. Push e pronto!
cd /Users/nds/Workspace/sts/code-erp
git push origin main
```

### Para APIs Spring Boot (ex: sua-api)

```bash
# 1. Configurar
cd /Users/nds/Workspace/scripts
./setup-api-deploy-automation.sh sua-api

# 2. Adicionar secret no GitHub
# Ir em: https://github.com/SEU_USER/sua-api/settings/secrets/actions
# Criar: SSH_PRIVATE_KEY (conteúdo de ~/.ssh/id_rsa)

# 3. Push e pronto!
cd /Users/nds/Workspace/sts/sua-api
git push origin main
```

---

## 📊 Comparação Rápida

| Aspecto | Apps Tomcat | APIs Spring Boot |
|---------|-------------|------------------|
| **Exemplo** | route-365 | dimensao-api |
| **Framework** | VRaptor | Spring Boot |
| **Empacotamento** | WAR | JAR |
| **Build** | Local (GitHub) | Servidor |
| **Deploy** | SCP + rsync | Git pull |
| **Servidor Web** | Apache Tomcat | Embedded |
| **Controle** | tomcat.sh | systemctl |
| **Logs** | catalina.out | journalctl |
| **Porta** | Tomcat (8080) | Configurável |
| **Script Setup** | setup-deploy-automation.sh | setup-api-deploy-automation.sh |

---

## 🎓 Fluxos de Deploy

### Apps Tomcat
```
Developer Push → GitHub Actions
                      ↓
                 Compila WAR
                      ↓
                 Envia via SCP
                      ↓
              Para Tomcat (/root/tomcat.sh stop)
                      ↓
              Extrai WAR no webapps
                      ↓
              Inicia Tomcat (/root/tomcat.sh start)
                      ↓
                Produção ✅
```

### APIs Spring Boot
```
Developer Push → GitHub Actions
                      ↓
            SSH no servidor
                      ↓
            Git pull origin main
                      ↓
         Para serviço (systemctl stop)
                      ↓
         Compila JAR (mvn package)
                      ↓
         Inicia serviço (systemctl start)
                      ↓
                Produção ✅
```

---

## 🔐 Configuração Única (Para Todos)

### Secret GitHub: SSH_PRIVATE_KEY

Você precisa configurar isso **uma vez por repositório GitHub**:

```bash
# 1. Copiar sua chave privada
cat ~/.ssh/id_rsa

# 2. Para cada projeto no GitHub:
# https://github.com/SEU_USER/PROJETO/settings/secrets/actions

# 3. Criar secret:
# Nome: SSH_PRIVATE_KEY
# Valor: [colar a chave completa]
```

**Importante:**
- Cada repositório GitHub precisa do secret
- A mesma chave serve para todos
- Nunca commitar chaves no código

---

## 📝 Checklist de Migração

### Para Cada Projeto:

Apps Tomcat:
- [ ] Rodar `./setup-deploy-automation.sh PROJETO`
- [ ] Configurar `SSH_PRIVATE_KEY` no GitHub
- [ ] Fazer push de teste
- [ ] Verificar deploy no GitHub Actions
- [ ] Testar aplicação funcionando
- [ ] Marcar como migrado ✅

APIs Spring Boot:
- [ ] Verificar serviço systemd configurado
- [ ] Verificar git repo no servidor
- [ ] Rodar `./setup-api-deploy-automation.sh API`
- [ ] Configurar `SSH_PRIVATE_KEY` no GitHub
- [ ] Fazer push de teste
- [ ] Verificar deploy no GitHub Actions
- [ ] Testar API funcionando (`/actuator/health`)
- [ ] Marcar como migrado ✅

---

## 🎯 Projetos e Status

### Apps Tomcat (11 projetos)
- [x] route-365 ✅ **CONFIGURADO**
- [ ] code-erp ⏳ Próximo
- [ ] multt ⏳
- [ ] contabil ⏳
- [ ] poker ⏳
- [ ] emprestimo ⏳
- [ ] cidadania ⏳
- [ ] codetech ⏳
- [ ] epubliq ⏳
- [ ] formeseguro ⏳
- [ ] clubearte ⏳

### APIs Spring Boot
- [x] dimensao-api ✅ **CONFIGURADO**
- [ ] (outras APIs que você tiver) ⏳

---

## 🆘 Precisa de Ajuda?

### Apps Tomcat (VRaptor):
1. Ler: `/Users/nds/Workspace/sts/route-365/PRIMEIROS_PASSOS.md`
2. Documentação: `/Users/nds/Workspace/scripts/README-DEPLOY-AUTOMATION.md`

### APIs Spring Boot:
1. Ler: `/Users/nds/Workspace/sts/dimensao-api/DEPLOY.md`
2. Documentação: `/Users/nds/Workspace/scripts/README-DEPLOY-APIS.md`

### Problemas Comuns:

**"Permission denied (publickey)"**
→ Secret `SSH_PRIVATE_KEY` não configurado no GitHub

**"target/PROJETO-1.0 not found"**
→ Nome no pom.xml diferente, ajustar workflow

**"Workflow não executa"**
→ Verificar se está na branch correta (main/master)

**"Tomcat não inicia"** (Apps)
→ SSH no servidor: `tail -200 /root/appservers/apache-tomcat-9/logs/catalina.out`

**"API não inicia"** (Spring Boot)
→ SSH no servidor: `sudo journalctl -u nome-api -n 100`

---

## 💡 Dicas Importantes

1. **Comece com 1 projeto** - Teste bem antes de migrar todos
2. **Mantenha scripts antigos** - Como backup por enquanto
3. **Use os scripts de setup** - Economizam muito tempo
4. **Documente peculiaridades** - Se um projeto for diferente, anote
5. **Monitore primeiro deploy** - Acompanhe no GitHub Actions

---

## 🎉 Benefícios do Sistema

✅ **Automação Total** - Push → Deploy automático
✅ **Backup Automático** - Antes de cada deploy
✅ **Rollback Fácil** - Restaurar versão anterior rapidamente
✅ **Rastreabilidade** - Histórico completo no GitHub
✅ **Segurança** - Secrets no GitHub, sem senhas no código
✅ **Escalabilidade** - Templates prontos para N projetos
✅ **Confiabilidade** - Processo padronizado, sem erros manuais

---

**Criado em:** 2025-11-12
**Versão:** 1.0
**Status:** ✅ Pronto para uso

**Próximo passo:** Configure o secret e teste o primeiro deploy!
