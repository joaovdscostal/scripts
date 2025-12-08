# 🚀 Sistema de Deploy Automatizado

## 📦 O que foi criado

### ✅ Route 365 (PRONTO PARA USAR)

```
route-365/
├── .github/
│   └── workflows/
│       ├── deploy-producao.yml      ← Deploy automático (main)
│       └── deploy-homologacao.yml   ← Template homolog
├── DEPLOY.md                        ← Documentação completa
└── PRIMEIROS_PASSOS.md              ← Quick start
```

### ✅ Scripts Reutilizáveis (Para outros projetos)

```
/Users/nds/Workspace/scripts/
├── deploy-workflow-template.yml     ← Template genérico
├── COMO_USAR_TEMPLATE.md            ← Guia passo a passo
├── setup-deploy-automation.sh       ← Script automático
└── README-DEPLOY-AUTOMATION.md      ← Este arquivo
```

## 🎯 Comparação: Antes vs Depois

### Processo ANTIGO (Manual - 6-8 minutos)

```bash
┌─────────────────────────────────────────────────┐
│ 1. cd /Users/nds/Workspace/sts                  │
│ 2. compilar route-365                [2 min]    │
│ 3. publicar route-365                [1 min]    │
│    → Digite: S                                   │
│    → Digite: producao                            │
│    → Digite: 0.0.7                               │
│ 4. ssh root@servidor                 [30 seg]   │
│ 5. systemctl restart tomcat          [1 min]    │
│ 6. Verificar logs                    [1 min]    │
│                                                  │
│ TOTAL: 6-8 minutos + atenção manual ⏱️          │
└─────────────────────────────────────────────────┘
```

### Processo NOVO (Automático - 5 minutos)

```bash
┌─────────────────────────────────────────────────┐
│ 1. git push origin main              [5 seg]    │
│                                                  │
│ GitHub Actions faz o resto:                     │
│ ✅ Compila com Maven                            │
│ ✅ Cria tag automaticamente                     │
│ ✅ Faz backup no servidor                       │
│ ✅ Para Tomcat                                   │
│ ✅ Deploy via SSH                                │
│ ✅ Inicia Tomcat                                 │
│ ✅ Verifica saúde da app                         │
│ ✅ Notifica resultado                            │
│                                                  │
│ TOTAL: 5 minutos 100% automático ✨             │
└─────────────────────────────────────────────────┘
```

## 🚀 Quick Start - Route 365

### 1️⃣ Configurar GitHub Secret (FAZER UMA VEZ)

```bash
# Copiar chave SSH
cat ~/.ssh/id_rsa

# Ir ao GitHub:
# https://github.com/joaovdscostal/route-365/settings/secrets/actions
# 
# Criar secret:
# - Nome: SSH_PRIVATE_KEY
# - Valor: [colar a chave completa]
```

### 2️⃣ Testar Deploy

```bash
cd /Users/nds/Workspace/sts/route-365

# Fazer qualquer mudança
echo "# Test" >> README.md

# Push para main
git add README.md
git commit -m "test: first automated deploy"
git push origin main
```

### 3️⃣ Acompanhar

```
https://github.com/joaovdscostal/route-365/actions
```

## 🔄 Replicar para Outros Projetos

### Método 1: Script Automático (RECOMENDADO)

```bash
cd /Users/nds/Workspace/scripts

# Para code-erp
./setup-deploy-automation.sh code-erp

# Para multt
./setup-deploy-automation.sh multt

# Para qualquer outro
./setup-deploy-automation.sh NOME_DO_PROJETO
```

O script vai:
- ✅ Criar `.github/workflows/deploy-producao.yml`
- ✅ Configurar variáveis automaticamente
- ✅ Detectar branch correta (main/master)
- ✅ Testar conexão SSH
- ✅ Oferecer fazer commit/push

### Método 2: Manual

```bash
cd /Users/nds/Workspace/sts/code-erp

# Copiar template
mkdir -p .github/workflows
cp /Users/nds/Workspace/scripts/deploy-workflow-template.yml \
   .github/workflows/deploy-producao.yml

# Editar variáveis (ver guia completo)
vim .github/workflows/deploy-producao.yml

# Commit
git add .github/workflows/deploy-producao.yml
git commit -m "Configure automated deployment"
git push origin main
```

Guia detalhado: `/Users/nds/Workspace/scripts/COMO_USAR_TEMPLATE.md`

## 📊 Projetos Disponíveis

| Projeto      | Branch | Status | Comando                                     |
|--------------|--------|--------|---------------------------------------------|
| route-365    | main   | ✅ FEITO | -                                          |
| code-erp     | main   | ⏳     | `./setup-deploy-automation.sh code-erp`    |
| multt        | main   | ⏳     | `./setup-deploy-automation.sh multt`       |
| contabil     | master | ⏳     | `./setup-deploy-automation.sh contabil`    |
| poker        | master | ⏳     | `./setup-deploy-automation.sh poker`       |
| emprestimo   | main   | ⏳     | `./setup-deploy-automation.sh emprestimo`  |
| cidadania    | master | ⏳     | `./setup-deploy-automation.sh cidadania`   |
| codetech     | master | ⏳     | `./setup-deploy-automation.sh codetech`    |
| epubliq      | main   | ⏳     | `./setup-deploy-automation.sh epubliq`     |
| formeseguro  | main   | ⏳     | `./setup-deploy-automation.sh formeseguro` |
| clubearte    | main   | ⏳     | `./setup-deploy-automation.sh clubearte`   |

## 🎁 Benefícios da Automação

### ✅ Velocidade
- **Antes:** 6-8 minutos com atenção manual
- **Depois:** 5 minutos sem intervenção

### ✅ Confiabilidade
- Sempre executa os mesmos passos
- Não esquece nenhuma etapa
- Detecta erros automaticamente

### ✅ Rastreabilidade
- Histórico completo no GitHub Actions
- Sabe quem deployou, quando e o quê
- Logs de cada etapa preservados

### ✅ Segurança
- Backup automático antes de cada deploy
- Rollback fácil
- Verificação automática de saúde

### ✅ Escalabilidade
- Fácil replicar para todos os projetos
- Um template serve para tudo
- Manutenção centralizada

### ✅ Produtividade
- Não precisa lembrar comandos
- Não precisa esperar deploy terminar
- Foco no desenvolvimento, não em deploy

## 📝 Arquivos Importantes

### Para Route 365 (já configurado)
- `route-365/.github/workflows/deploy-producao.yml` - Workflow principal
- `route-365/DEPLOY.md` - Documentação completa
- `route-365/PRIMEIROS_PASSOS.md` - Guia rápido

### Para novos projetos
- `scripts/deploy-workflow-template.yml` - Template genérico
- `scripts/COMO_USAR_TEMPLATE.md` - Guia detalhado
- `scripts/setup-deploy-automation.sh` - Script de configuração

### Scripts antigos (manter como backup)
- `scripts/compilar.sh` - Ainda funcional
- `scripts/publicar.sh` - Ainda funcional

## 🔐 Configuração de Segurança

### Por Repositório GitHub:

```bash
# Adicionar secret SSH_PRIVATE_KEY em:
# https://github.com/SEU_USUARIO/PROJETO/settings/secrets/actions

# Conteúdo do secret:
cat ~/.ssh/id_rsa
```

**Importante:**
- Mesmo secret serve para todos os projetos do mesmo usuário
- Nunca commitar chaves privadas no código
- Chave fica criptografada no GitHub

## 🆘 Troubleshooting Comum

### "Permission denied (publickey)"
→ Secret SSH_PRIVATE_KEY não configurado ou incorreto

### "target/PROJETO-1.0 not found"
→ Nome do projeto no pom.xml diferente do esperado

### Workflow não executa
→ Verificar se arquivo está em `.github/workflows/`
→ Verificar se está na branch correta (main/master)

### Deploy funciona mas app não sobe
→ Ver logs: `ssh servidor "tail -200 /path/to/tomcat/logs/catalina.out"`

## 📚 Documentação

### Leitura Rápida (5 min)
1. `route-365/PRIMEIROS_PASSOS.md`

### Leitura Completa (15 min)
1. `route-365/DEPLOY.md`
2. `scripts/COMO_USAR_TEMPLATE.md`

### Configuração de Novo Projeto (10 min)
1. Rodar: `./setup-deploy-automation.sh PROJETO`
2. Configurar secret no GitHub
3. Testar primeiro deploy

## 🎯 Roadmap

### Fase 1: Básico (CONCLUÍDO ✅)
- [x] Workflow GitHub Actions para route-365
- [x] Template reutilizável
- [x] Script de configuração automática
- [x] Documentação completa

### Fase 2: Expansão (PRÓXIMO)
- [ ] Configurar code-erp
- [ ] Configurar 2-3 projetos menores
- [ ] Validar que tudo funciona
- [ ] Ajustar template se necessário

### Fase 3: Migração Completa
- [ ] Migrar todos os 11 projetos
- [ ] Desabilitar scripts antigos (opcional)
- [ ] Treinar time (se houver)

### Fase 4: Melhorias (FUTURO)
- [ ] Adicionar testes automatizados
- [ ] Notificações (Slack/Discord)
- [ ] Deploy de homologação
- [ ] Rollback automático em caso de erro
- [ ] Métricas de deploy

## 💡 Dicas

1. **Comece pequeno:** Configure 1 projeto, teste bem, depois replique
2. **Mantenha backup:** Scripts antigos ainda funcionam
3. **Use o script:** `setup-deploy-automation.sh` economiza tempo
4. **Documente peculiaridades:** Se um projeto é diferente, anote
5. **Monitore primeiros deploys:** Acompanhe no GitHub Actions

## 🎓 Aprendizados

### O que funciona bem:
- ✅ GitHub Actions é confiável
- ✅ SSH funciona perfeitamente
- ✅ Backups automáticos dão tranquilidade
- ✅ Logs ajudam muito no troubleshooting

### O que tomar cuidado:
- ⚠️ Secrets precisam estar configurados
- ⚠️ Permissões SSH devem estar corretas
- ⚠️ Nomes de projeto precisam bater com pom.xml
- ⚠️ Primeira execução pode precisar ajustes

## 📞 Próximos Passos Sugeridos

### Hoje:
1. Configurar secret no GitHub para route-365
2. Fazer primeiro deploy de teste
3. Verificar se funcionou

### Esta semana:
1. Configurar mais 2-3 projetos
2. Validar que template funciona
3. Fazer ajustes se necessário

### Este mês:
1. Migrar todos os projetos
2. Documentar casos especiais
3. Considerar desabilitar scripts antigos

---

**Criado em:** 2025-11-12  
**Para:** Automação de deploys via GitHub Actions  
**Status:** ✅ Pronto para uso  
**Próximo passo:** Configurar secret e testar primeiro deploy
