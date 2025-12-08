# 🚀 Sistema de Deploy Automatizado

## 👋 Comece Aqui!

Este diretório contém **scripts e templates** para automatizar o deploy de seus projetos via GitHub Actions.

## 📖 Documentação Principal

**➡️ Leia primeiro:** [INDICE-DEPLOY-AUTOMATION.md](INDICE-DEPLOY-AUTOMATION.md)

O índice tem tudo que você precisa para começar!

## 🎯 Quick Links

### Apps Tomcat (VRaptor)
- Script: `./setup-deploy-automation.sh PROJETO`
- Exemplo configurado: `/Users/nds/Workspace/sts/route-365`
- Documentação: [README-DEPLOY-AUTOMATION.md](README-DEPLOY-AUTOMATION.md)

### APIs Spring Boot
- Script: `./setup-api-deploy-automation.sh API`
- Exemplo configurado: `/Users/nds/Workspace/sts/dimensao-api`
- Documentação: [README-DEPLOY-APIS.md](README-DEPLOY-APIS.md)

## ⚡ Setup Rápido

```bash
# Apps Tomcat (route-365, code-erp, multt, etc)
./setup-deploy-automation.sh NOME_DO_PROJETO

# APIs Spring Boot (dimensao-api, etc)
./setup-api-deploy-automation.sh NOME_DA_API
```

## 📚 Todos os Arquivos

- `INDICE-DEPLOY-AUTOMATION.md` - **Comece aqui** ⭐
- `README-DEPLOY-AUTOMATION.md` - Overview Apps Tomcat
- `README-DEPLOY-APIS.md` - Overview APIs Spring
- `deploy-workflow-template.yml` - Template Apps Tomcat
- `deploy-api-workflow-template.yml` - Template APIs Spring
- `setup-deploy-automation.sh` - Setup Apps Tomcat
- `setup-api-deploy-automation.sh` - Setup APIs Spring
- `COMO_USAR_TEMPLATE.md` - Guia manual Apps Tomcat
- `compilar.sh` - Script antigo (backup)
- `publicar.sh` - Script antigo (backup)

---

**Dúvidas?** Veja o [INDICE-DEPLOY-AUTOMATION.md](INDICE-DEPLOY-AUTOMATION.md)
