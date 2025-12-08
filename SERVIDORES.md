# 🖥️ Servidores e IPs

## 📋 Mapeamento de Servidores

### Servidor 1: 157.230.231.220
**Hostname:** capacitare
**Tipo:** Apps Tomcat/VRaptor
**Tomcat:** `/root/appservers/apache-tomcat-9`
**Controle:** `/root/tomcat.sh start|stop|restart`

**Projetos:**
- route-365
- code-erp
- clubearte
- contabil

**Domínios:**
- route-365.appjvs.com.br → 157.230.231.220
- (outros domínios apontam para esse IP)

---

### Servidor 2: 147.93.66.129
**Hostname:** srv797845
**Tipo:** APIs Spring Boot
**Path:** `/root/apis/`
**Controle:** `systemctl` (systemd services)

**Projetos:**
- dimensao-api (serviço: dimensao-api)
- api-images-s3

**Domínios:**
- api.vipp.art.br → 147.93.66.129

---

## 🔑 Chave SSH

**Chave para acessar TODOS os servidores:**
```bash
~/.ssh/id_ed25519  # Chave privada (usar no GitHub Secret)
~/.ssh/id_ed25519.pub  # Chave pública (já está nos servidores)
```

**Testar conexão:**
```bash
# Servidor 1 (Apps Tomcat)
ssh -i ~/.ssh/id_ed25519 root@157.230.231.220

# Servidor 2 (APIs)
ssh -i ~/.ssh/id_ed25519 root@147.93.66.129
```

---

## ⚠️ Importante: Usar IP, NÃO Domínio

Os servidores **NÃO aceitam** conexão SSH por domínio, apenas por IP.

❌ **Não funciona:**
```bash
ssh root@route-365.appjvs.com.br
ssh root@api.vipp.art.br
```

✅ **Funciona:**
```bash
ssh root@157.230.231.220
ssh root@147.93.66.129
```

**Motivo:** Configuração do servidor SSH ou firewall.

---

## 📊 Resumo por Projeto

| Projeto | Servidor IP | Tipo | Path | Controle |
|---------|-------------|------|------|----------|
| route-365 | 157.230.231.220 | Tomcat | /root/appservers/apache-tomcat-9/webapps/route-365 | /root/tomcat.sh |
| code-erp | 157.230.231.220 | Tomcat | /root/appservers/apache-tomcat-9/webapps/code-erp | /root/tomcat.sh |
| clubearte | 157.230.231.220 | Tomcat | /root/appservers/apache-tomcat-9/webapps/clubearte | /root/tomcat.sh |
| contabil | 157.230.231.220 | Tomcat | /root/appservers/apache-tomcat-9/webapps/contabil | /root/tomcat.sh |
| dimensao-api | 147.93.66.129 | Spring Boot | /root/apis/dimensao-api | systemctl dimensao-api |
| api-images-s3 | 147.93.66.129 | Spring Boot | /root/apis/api-images-s3 | systemctl api-images-s3 |

---

## 🔧 Descobrir IP de Outros Projetos

Se você tiver mais projetos e não souber o IP:

### Método 1: Resolver DNS
```bash
# Descobrir IP pelo domínio
host nome-do-projeto.appjvs.com.br
# ou
nslookup nome-do-projeto.appjvs.com.br
```

### Método 2: Testar IPs conhecidos
```bash
# Testar se projeto está no servidor 1
ssh root@157.230.231.220 "ls -la /root/appservers/apache-tomcat-9/webapps/"

# Testar se projeto está no servidor 2
ssh root@147.93.66.129 "ls -la /root/apis/"
```

### Método 3: Verificar seu publicar.sh
O arquivo `/Users/nds/Workspace/scripts/publicar.sh` pode ter informações sobre remotes configurados.

---

## 📝 Atualizar Workflows

Quando configurar novos projetos, sempre use **IP** nos workflows:

### Apps Tomcat:
```yaml
env:
  SERVER_HOST: 157.230.231.220  # IP, não domínio
```

### APIs Spring Boot:
```yaml
env:
  SERVER_HOST: 147.93.66.129  # IP, não domínio
```

---

## 🆘 Troubleshooting

### "Connection timed out" ou "No route to host"
→ Você está tentando usar domínio. Use IP!

### "Permission denied (publickey)"
→ Chave SSH não está configurada. Use `~/.ssh/id_ed25519`

### Como saber qual servidor um projeto usa?
```bash
# Ver onde o projeto está configurado
grep "nome-do-projeto" /Users/nds/Workspace/scripts/publicar.sh
```

---

**Atualizado em:** 2025-11-12
**Chave SSH:** ~/.ssh/id_ed25519
**Importante:** Sempre usar IP, nunca domínio para SSH
