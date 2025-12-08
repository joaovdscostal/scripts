# 🔄 Como Funciona o Merge de Arquivos no Deploy

## 🎯 Comportamento Detalhado

### Cenário 1: Adicionar arquivo novo via Git

**Situação:**
- Servidor tem: `arquivos/cliente1.pdf`, `arquivos/cliente2.pdf`
- Você adiciona no git: `arquivos/novo-formulario.pdf`
- Faz push

**O que acontece:**
```bash
1. Build compila com:
   - arquivos/novo-formulario.pdf (do git)

2. Deploy extrai em /tmp/deploy_temp/:
   - arquivos/novo-formulario.pdf

3. Merge inteligente (rsync --ignore-existing):
   - Mantém: arquivos/novo-formulario.pdf (novo do git)
   - Copia do servidor: arquivos/cliente1.pdf
   - Copia do servidor: arquivos/cliente2.pdf

4. Resultado final no servidor:
   ✅ arquivos/novo-formulario.pdf (novo)
   ✅ arquivos/cliente1.pdf (preservado)
   ✅ arquivos/cliente2.pdf (preservado)
```

**Resposta: SIM, seu arquivo novo vai pro servidor sem apagar os existentes!** ✅

---

### Cenário 2: Cliente faz upload durante a semana

**Situação:**
- Segunda: Servidor tem `arquivos/doc1.pdf`
- Terça: Cliente faz upload de `arquivos/contrato.pdf`
- Quarta: Você faz deploy de uma correção de bug

**O que acontece:**
```bash
1. Build compila com:
   - arquivos/ (vazio ou só com doc1.pdf do git)

2. Deploy extrai em /tmp/deploy_temp/:
   - arquivos/ (vazio ou com doc1.pdf)

3. Merge inteligente:
   - Copia do servidor: arquivos/contrato.pdf (upload do cliente)
   - Mantém: arquivos/doc1.pdf (se vier do git)

4. Resultado final:
   ✅ arquivos/contrato.pdf (preservado!)
   ✅ arquivos/doc1.pdf
```

**Resposta: Uploads feitos no servidor são preservados!** ✅

---

### Cenário 3: Atualizar arquivo que já existe

**Situação:**
- Servidor tem: `arquivos/template.pdf` (versão 1)
- Você atualiza no git: `arquivos/template.pdf` (versão 2)
- Faz push

**O que acontece:**
```bash
1. Build compila com:
   - arquivos/template.pdf (versão 2 do git)

2. Deploy extrai em /tmp/deploy_temp/:
   - arquivos/template.pdf (versão 2)

3. Merge inteligente (--ignore-existing):
   - Arquivo já existe em /tmp/deploy_temp/
   - NÃO sobrescreve com a versão do servidor
   - Mantém a versão 2 do git

4. Resultado final:
   ✅ arquivos/template.pdf (versão 2 atualizada!)
```

**Resposta: Arquivos atualizados no git SUBSTITUEM os do servidor!** ✅

---

### Cenário 4: Conflito - mesmo nome, criado em ambos

**Situação:**
- Segunda: Você adiciona no git `arquivos/relatorio.pdf`
- Terça: Cliente faz upload de `arquivos/relatorio.pdf` (arquivo diferente)
- Quarta: Você faz deploy

**O que acontece:**
```bash
1. Build compila com:
   - arquivos/relatorio.pdf (seu arquivo do git)

2. Deploy extrai em /tmp/deploy_temp/:
   - arquivos/relatorio.pdf (versão do git)

3. Merge inteligente:
   - Arquivo já existe em /tmp/deploy_temp/ (do git)
   - NÃO sobrescreve com a versão do servidor
   - PRIORIDADE para a versão do GIT

4. Resultado final:
   ✅ arquivos/relatorio.pdf (versão do git)
   ❌ Versão do cliente foi perdida
```

**⚠️ ATENÇÃO: Em caso de conflito, a versão do GIT ganha!**

**Solução:** Evitar commitar arquivos com nomes que clientes possam usar.

---

## 📋 Regras do Merge (rsync --ignore-existing)

```bash
rsync -a --ignore-existing SERVIDOR/ TEMP/
```

**Tradução:** "Copie do SERVIDOR para TEMP apenas arquivos que NÃO existem em TEMP"

### Resultado:

| Arquivo está em | Git | Servidor | Resultado Final |
|-----------------|-----|----------|----------------|
| Só no Git | ✅ | ❌ | **Vai pro servidor** (novo) |
| Só no Servidor | ❌ | ✅ | **Preservado** (mantido) |
| Ambos (mesmo nome) | ✅ | ✅ | **Versão do Git** (atualizado) |

---

## 🎨 Casos de Uso Práticos

### ✅ Caso 1: Arquivos Estáticos Versionados
```
# No git:
arquivos/
  └── logos/
      └── empresa.png  (logo oficial)

# Comportamento: Logo sempre atualizada com a versão do git
```

### ✅ Caso 2: Upload de Clientes
```
# No servidor (via upload):
arquivos/
  └── contratos/
      └── cliente-123.pdf

# .deployignore:
arquivos/

# Comportamento: PDFs dos clientes preservados
```

### ✅ Caso 3: Misturado
```
# No git:
arquivos/
  └── templates/
      └── modelo.docx  (template oficial)

# No servidor (via upload):
arquivos/
  └── uploads/
      └── documento-cliente.pdf

# Resultado após deploy:
arquivos/
  ├── templates/
  │   └── modelo.docx  (atualizado do git)
  └── uploads/
      └── documento-cliente.pdf  (preservado)
```

---

## ⚠️ Situações que Exigem Atenção

### 🔴 Problema: Commitar arquivos que deveriam ser só uploads

**Errado:**
```bash
# Você commitou por engano
git add arquivos/contrato-cliente-1.pdf
git commit -m "adiciona contrato"
```

**Resultado:** Esse arquivo vai ficar no git e ser sempre "restaurado" no deploy.

**Solução:** Usar `.gitignore` adequadamente:
```
# .gitignore
arquivos/contratos/
arquivos/uploads/
img/fotos-clientes/
```

### 🟡 Cuidado: Arquivos grandes no git

**Problema:** Se você commitar muitos arquivos grandes em `arquivos/`, isso aumenta o tamanho do repositório.

**Solução:**
1. Não commitar uploads de clientes
2. Commitar apenas templates/logos/arquivos essenciais
3. Usar `.gitignore` para pastas de upload

---

## 🔧 Configuração Recomendada

### Estrutura Sugerida:

```
route-365/
├── arquivos/
│   ├── templates/      # Commitado no git
│   ├── logos/          # Commitado no git
│   └── uploads/        # NÃO commitar (apenas servidor)
│
├── img/
│   ├── layout/         # Commitado no git
│   └── fotos/          # NÃO commitar (apenas servidor)
│
├── .gitignore
└── .deployignore
```

### .gitignore:
```
# Não versionar uploads
arquivos/uploads/
img/fotos/
```

### .deployignore:
```
# Preservar tudo da pasta arquivos/ e img/
arquivos/
img/
```

**Com essa configuração:**
- ✅ Templates/logos atualizados pelo git
- ✅ Uploads de clientes preservados
- ✅ Repositório não fica pesado
- ✅ Deploy seguro

---

## 📊 Teste Rápido

Para testar o comportamento:

```bash
# 1. Adicionar arquivo novo
echo "teste" > arquivos/teste-deploy.txt
git add arquivos/teste-deploy.txt
git commit -m "test: adiciona arquivo de teste"
git push

# 2. Verificar após deploy
ssh -i ~/.ssh/id_ed25519 root@157.230.231.220 \
  "ls -lh /root/appservers/apache-tomcat-9/webapps/route-365/arquivos/"

# Deve mostrar:
# - teste-deploy.txt (novo)
# - Todos os outros arquivos que já existiam
```

---

**Criado em:** 2025-11-12
**Comando chave:** `rsync -a --ignore-existing`
**Comportamento:** Merge inteligente (git + servidor)
