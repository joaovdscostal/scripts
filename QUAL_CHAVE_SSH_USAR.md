# 🔑 Qual Chave SSH Usar no GitHub?

## ✅ Resposta Rápida

Você deve usar a **chave PRIVADA do seu computador** que você usa para acessar o servidor.

No seu caso, você tem 2 chaves ED25519:
- `~/.ssh/id_ed25519` (chave padrão)
- `~/.ssh/id_ed25519_acelera` (chave acelera)

## 🔍 Como Descobrir Qual Usar?

### Teste Manual no Terminal:

```bash
# Testar chave padrão
ssh -i ~/.ssh/id_ed25519 root@route-365.appjvs.com.br

# Testar chave acelera
ssh -i ~/.ssh/id_ed25519_acelera root@route-365.appjvs.com.br

# Qual funcionar, é essa que você usa! ✅
```

### Ou Testar Sem Especificar (SSH escolhe automaticamente):

```bash
# SSH tenta todas as chaves disponíveis
ssh root@route-365.appjvs.com.br

# Se funcionar, descobrir qual foi usada:
ssh -v root@route-365.appjvs.com.br 2>&1 | grep "Offering public key"
```

## 📋 Depois de Descobrir, Fazer:

### 1. Copiar a Chave Privada COMPLETA:

```bash
# Se for a chave padrão:
cat ~/.ssh/id_ed25519

# OU se for a chave acelera:
cat ~/.ssh/id_ed25519_acelera

# Copiar TUDO, incluindo:
# -----BEGIN OPENSSH PRIVATE KEY-----
# ... todo o conteúdo ...
# -----END OPENSSH PRIVATE KEY-----
```

### 2. Adicionar ao GitHub Secrets:

Para **CADA repositório**:

1. Ir em: `https://github.com/joaovdscostal/PROJETO/settings/secrets/actions`
2. Clicar em "New repository secret"
3. Nome: `SSH_PRIVATE_KEY`
4. Valor: Colar a chave privada completa
5. Salvar

## 🔐 Entendendo as Chaves SSH

### Como Funciona:

```
┌─────────────────────────────────────────────────────────────┐
│ SEU COMPUTADOR (Mac)                                        │
├─────────────────────────────────────────────────────────────┤
│ ~/.ssh/id_ed25519           (PRIVADA - não compartilhar)   │
│ ~/.ssh/id_ed25519.pub       (PÚBLICA - pode compartilhar)  │
└─────────────────────────────────────────────────────────────┘
                       ↓
          (GitHub Actions copia a PRIVADA)
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ GITHUB ACTIONS                                              │
├─────────────────────────────────────────────────────────────┤
│ Secret: SSH_PRIVATE_KEY    (tem a chave privada)           │
│                                                             │
│ Usa essa chave para conectar no servidor via SSH           │
└─────────────────────────────────────────────────────────────┘
                       ↓
          (Conecta no servidor usando a chave)
                       ↓
┌─────────────────────────────────────────────────────────────┐
│ SERVIDOR (route-365.appjvs.com.br)                         │
├─────────────────────────────────────────────────────────────┤
│ ~/.ssh/authorized_keys     (tem a chave PÚBLICA)           │
│                                                             │
│ Compara com a chave privada do GitHub Actions              │
│ Se bater, autoriza a conexão ✅                             │
└─────────────────────────────────────────────────────────────┘
```

### Regra de Ouro:

- **Chave PÚBLICA** (.pub) → Vai no SERVIDOR (`authorized_keys`)
- **Chave PRIVADA** (sem .pub) → Vai no GITHUB SECRETS

## ❓ FAQs

### "Tenho que criar uma chave nova?"
**Não!** Use a mesma chave que você já usa para acessar o servidor.

### "É a chave do servidor?"
**Não!** É a chave do seu computador (Mac) que acessa o servidor.

### "Posso usar a mesma chave para vários projetos?"
**Sim!** A mesma chave privada serve para todos os repositórios GitHub.

### "É seguro colocar no GitHub?"
**Sim!** O GitHub Secrets é criptografado e seguro. Só pessoas autorizadas no repo veem.

### "E se alguém pegar minha chave privada?"
**Problema sério!** Por isso:
- Nunca commitar chaves no código
- Usar apenas GitHub Secrets
- Manter backup da chave
- Considerar usar chaves diferentes por projeto (avançado)

## 🛠️ Comandos Úteis

### Ver suas chaves:
```bash
ls -la ~/.ssh/
```

### Ver chave PÚBLICA (pode mostrar):
```bash
cat ~/.ssh/id_ed25519.pub
# ou
cat ~/.ssh/id_ed25519_acelera.pub
```

### Ver chave PRIVADA (NÃO compartilhar):
```bash
cat ~/.ssh/id_ed25519
# ou
cat ~/.ssh/id_ed25519_acelera
```

### Verificar qual chave está no servidor:
```bash
# Conectar no servidor
ssh root@route-365.appjvs.com.br

# Ver chaves autorizadas
cat ~/.ssh/authorized_keys

# Deve conter a chave PÚBLICA correspondente
```

## 🎯 Resumo Visual

```
SEU MAC                    GITHUB SECRETS              SERVIDOR
   ↓                             ↓                        ↓
id_ed25519      →     SSH_PRIVATE_KEY      →      authorized_keys
(privada)              (privada)                    (pública .pub)

┌─────────┐           ┌─────────┐              ┌─────────┐
│ Guardar │  Copiar   │ Secret  │   Conecta    │ Verifica│
│   em    │  ------>  │   do    │   ------->   │   se    │
│ segredo │           │ GitHub  │              │  bate   │
└─────────┘           └─────────┘              └─────────┘
```

## ✅ Checklist

Para cada projeto GitHub:

- [ ] Descobrir qual chave SSH uso para acessar o servidor
- [ ] Copiar a chave PRIVADA completa (`cat ~/.ssh/id_ed25519`)
- [ ] Ir em GitHub → Settings → Secrets → Actions
- [ ] Criar secret `SSH_PRIVATE_KEY`
- [ ] Colar a chave privada
- [ ] Salvar
- [ ] Fazer push de teste
- [ ] Verificar se GitHub Actions consegue conectar no servidor

---

**Ainda com dúvida?** Teste manualmente qual chave funciona no servidor e use essa!
