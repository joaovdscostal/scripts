# 🚀 Como Usar o Template de Deploy

Este guia mostra como replicar o deploy automatizado para **todos os seus projetos**.

## 📋 Lista de Projetos (do seu publicar.sh)

Projetos que podem usar este template:
- ✅ route-365 (já configurado)
- ⏳ code-erp
- ⏳ multt
- ⏳ contabil
- ⏳ poker
- ⏳ emprestimo
- ⏳ cidadania
- ⏳ codetech
- ⏳ epubliq
- ⏳ formeseguro
- ⏳ clubearte

## 🔧 Configuração Passo a Passo

### Para CADA projeto, siga estes passos:

### 1️⃣ Copiar Template

```bash
# Exemplo para code-erp
cd /Users/nds/Workspace/sts/code-erp

# Criar diretório workflows
mkdir -p .github/workflows

# Copiar template
cp /Users/nds/Workspace/scripts/deploy-workflow-template.yml \
   .github/workflows/deploy-producao.yml
```

### 2️⃣ Editar Variáveis

Abra `.github/workflows/deploy-producao.yml` e configure:

```yaml
env:
  PROJECT_NAME: code-erp                    # Nome do projeto
  SERVER_HOST: code-erp.appjvs.com.br      # Host do servidor
  SERVER_USER: root                         # Usuário SSH
  TOMCAT_PATH: /root/appservers/apache-tomcat-9/webapps/code-erp
  VERSION_FILE: src/producao.properties     # Onde está a versão
```

**Como descobrir os valores?**

Consulte seu arquivo `publicar.sh` linha 3-15:

```bash
# Formato: "projeto|ambiente|remoto|branch"
"code-erp|producao|producao|main"
#   ↓         ↓        ↓       ↓
# PROJECT  (não     (não    BRANCH
#  NAME    usado)   usado)  PRINCIPAL
```

Para o HOST, geralmente é: `{PROJECT_NAME}.appjvs.com.br`

### 3️⃣ Verificar Branch Principal

```bash
# Verificar qual é a branch principal
cd /Users/nds/Workspace/sts/code-erp
git branch

# Se for 'master' em vez de 'main', editar no workflow:
# on:
#   push:
#     branches:
#       - master  # <-- mudar aqui
```

### 4️⃣ Configurar Secret no GitHub

**IMPORTANTE:** Fazer apenas UMA VEZ por repositório GitHub!

```bash
# 1. Copiar chave privada
cat ~/.ssh/id_rsa

# 2. Ir ao GitHub do projeto:
# https://github.com/SEU_USUARIO/code-erp/settings/secrets/actions

# 3. Clicar "New repository secret"
# Nome: SSH_PRIVATE_KEY
# Valor: [colar a chave privada completa]

# 4. Salvar
```

### 5️⃣ Testar Conexão SSH

```bash
# Testar se consegue conectar com a chave
ssh -i ~/.ssh/id_rsa root@code-erp.appjvs.com.br "echo OK"

# Se retornar "OK", está configurado corretamente
```

### 6️⃣ Commit e Push

```bash
cd /Users/nds/Workspace/sts/code-erp

git add .github/workflows/deploy-producao.yml
git commit -m "Configure automated deployment with GitHub Actions"
git push origin main  # ou master
```

### 7️⃣ Verificar Funcionamento

1. Ir em: `https://github.com/SEU_USUARIO/code-erp/actions`
2. Ver se o workflow executou
3. Verificar se teve sucesso ✅

## 🎯 Configuração Rápida com Script

Criei um script para automatizar a configuração:

```bash
cd /Users/nds/Workspace/scripts
./setup-deploy-automation.sh code-erp
```

(Vou criar esse script agora)

## 📊 Tabela de Configuração Rápida

| Projeto      | Branch | Host                          | Tomcat Path                                    |
|--------------|--------|-------------------------------|------------------------------------------------|
| route-365    | main   | route-365.appjvs.com.br       | /root/appservers/apache-tomcat-9/webapps/route-365 |
| code-erp     | main   | code-erp.appjvs.com.br        | /root/appservers/apache-tomcat-9/webapps/code-erp |
| multt        | main   | multt.appjvs.com.br           | /root/appservers/apache-tomcat-9/webapps/multt |
| contabil     | master | contabil.appjvs.com.br        | /root/appservers/apache-tomcat-9/webapps/contabil |
| poker        | master | poker.appjvs.com.br           | /root/appservers/apache-tomcat-9/webapps/poker |
| emprestimo   | main   | emprestimo.appjvs.com.br      | /root/appservers/apache-tomcat-9/webapps/emprestimo |
| cidadania    | master | cidadania.appjvs.com.br       | /root/appservers/apache-tomcat-9/webapps/cidadania |
| codetech     | master | codetech.appjvs.com.br        | /root/appservers/apache-tomcat-9/webapps/codetech |
| epubliq      | main   | epubliq.appjvs.com.br         | /root/appservers/apache-tomcat-9/webapps/epubliq |
| formeseguro  | main   | formeseguro.appjvs.com.br     | /root/appservers/apache-tomcat-9/webapps/formeseguro |
| clubearte    | main   | clubearte.appjvs.com.br       | /root/appservers/apache-tomcat-9/webapps/clubearte |

**Nota:** Se o host for diferente, verifique no arquivo `src/producao.properties` do projeto.

## ⚠️ Casos Especiais

### Poker (servidor diferente)
```yaml
# No publicar.sh: "poker|producao|servidor-poker|master"
# Pode ter configuração diferente de host/path
```

### Cidadania (tem homolog e prod)
```yaml
# Homolog: "cidadania|homologacao|testes|master"
# Prod: "cidadania|producao|servidor-cidadania|master"
# Criar 2 workflows: deploy-homologacao.yml e deploy-producao.yml
```

### Projetos com EAR
Se o projeto tem `EarContent/` (linha 20 do compilar.sh), pode precisar ajustes.

## 🔄 Depois de Configurar

### Fluxo Antigo (Manual)
```bash
compilar code-erp
publicar code-erp
# Digite: S, producao, 0.0.7
ssh servidor
systemctl restart tomcat
```

### Fluxo Novo (Automático)
```bash
git push origin main
# Pronto! ✅
```

## ✅ Checklist de Migração

Para cada projeto:

- [ ] Copiar template para `.github/workflows/deploy-producao.yml`
- [ ] Configurar variáveis (PROJECT_NAME, SERVER_HOST, etc)
- [ ] Verificar branch principal (main ou master)
- [ ] Configurar SSH_PRIVATE_KEY no GitHub Secrets
- [ ] Testar conexão SSH
- [ ] Commit e push
- [ ] Verificar execução no GitHub Actions
- [ ] Testar deploy funcionando
- [ ] Documentar particularidades do projeto (se houver)

## 🆘 Troubleshooting

### Erro: "Permission denied (publickey)"
- Verificar se SSH_PRIVATE_KEY está configurado no GitHub
- Testar conexão SSH manualmente
- Verificar se a chave pública está no servidor

### Erro: "target/PROJECT-1.0 not found"
- Verificar se o nome do projeto no pom.xml é PROJECT-1.0
- Pode precisar ajustar linha do workflow

### Workflow não executa
- Verificar se está na branch correta (main ou master)
- Verificar se o arquivo está em `.github/workflows/`
- Ver erros na aba Actions do GitHub

### Deploy funciona mas app não sobe
- SSH no servidor e ver logs do Tomcat
- Verificar se o path do Tomcat está correto
- Verificar se há erros na aplicação

## 📞 Próximos Passos

1. Configurar route-365 primeiro (já feito ✅)
2. Testar com um projeto menor (ex: clubearte)
3. Se funcionar, replicar para todos
4. Eventualmente desabilitar scripts antigos (compilar.sh/publicar.sh)

## 💡 Dicas

- Configure 1 projeto por vez
- Teste cada um antes de ir para o próximo
- Mantenha os scripts antigos como backup por enquanto
- Documente qualquer particularidade de cada projeto
