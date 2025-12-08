# 📱 Notificações WhatsApp nos Deploys

## 🎯 Como Funcionar

Adicionar notificações via WhatsApp API ao final dos deploys para avisar sobre sucesso ou falha.

## 🔧 Configuração

### 1. Adicionar Secrets no GitHub

Para cada repositório, adicionar **APENAS 2 secrets**:

```
WHATSAPP_APIKEY=SUA_API_KEY_AQUI
WHATSAPP_PHONE=5522999604234  # Seu número no formato internacional (DDI+DDD+número)
```

**Onde configurar:**
- https://github.com/SEU_USUARIO/PROJETO/settings/secrets/actions

**API utilizada:** https://webzap.appjvs.com.br (Evolution API)

### 2. Adicionar Steps ao Workflow

Adicionar estes steps ao final do workflow (antes ou depois dos steps de notificação existentes):

#### Para Apps Tomcat (route-365, code-erp, etc):

```yaml
      - name: Notificar sucesso no WhatsApp
        if: success() && secrets.WHATSAPP_PHONE != ''
        continue-on-error: true
        run: |
          curl --location --request POST 'https://webzap.appjvs.com.br/api/proxy/message/sendText/zap-default' \
            --header 'Content-Type: application/json' \
            --header "apikey: ${{ secrets.WHATSAPP_APIKEY }}" \
            --data "{
              \"number\": \"${{ secrets.WHATSAPP_PHONE }}\",
              \"text\": \"✅ *Deploy Concluído!*\n\n📦 *Projeto:* ${{ env.PROJECT_NAME }}\n🏷️ *Versão:* ${{ steps.version.outputs.version }}\n🏷️ *Tag:* ${{ steps.version.outputs.tag }}\n👤 *Por:* ${{ github.actor }}\n📅 *Data:* $(date +'%d/%m/%Y %H:%M')\n\n🎉 Aplicação disponível!\"
            }" || echo "⚠️ Notificação WhatsApp falhou (não crítico)"

      - name: Notificar falha no WhatsApp
        if: failure() && secrets.WHATSAPP_PHONE != ''
        continue-on-error: true
        run: |
          curl --location --request POST 'https://webzap.appjvs.com.br/api/proxy/message/sendText/zap-default' \
            --header 'Content-Type: application/json' \
            --header "apikey: ${{ secrets.WHATSAPP_APIKEY }}" \
            --data "{
              \"number\": \"${{ secrets.WHATSAPP_PHONE }}\",
              \"text\": \"❌ *Deploy Falhou!*\n\n📦 *Projeto:* ${{ env.PROJECT_NAME }}\n👤 *Por:* ${{ github.actor }}\n🔗 *Ver logs:* https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}\n📅 *Data:* $(date +'%d/%m/%Y %H:%M')\n\n⚠️ Verificar logs!\"
            }" || echo "⚠️ Notificação WhatsApp falhou (não crítico)"
```

#### Para APIs Spring Boot (dimensao-api, etc):

```yaml
      - name: Notificar sucesso no WhatsApp
        if: success()
        run: |
          curl -X POST "${{ secrets.WHATSAPP_API_URL }}/send-message" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${{ secrets.WHATSAPP_TOKEN }}" \
            -d '{
              "phone": "${{ secrets.WHATSAPP_PHONE }}",
              "message": "✅ *API Deploy Concluído!*\n\n📦 *API:* ${{ env.PROJECT_NAME }}\n🏷️ *Versão:* ${{ steps.version.outputs.version }}\n🌐 *URL:* https://${{ env.SERVER_HOST }}/\n📊 *Swagger:* https://${{ env.SERVER_HOST }}/swagger-ui.html\n📅 *Data:* $(date +'%d/%m/%Y %H:%M')\n\n🎉 API disponível!"
            }' || echo "Falha ao enviar notificação (não crítico)"

      - name: Notificar falha no WhatsApp
        if: failure()
        run: |
          curl -X POST "${{ secrets.WHATSAPP_API_URL }}/send-message" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${{ secrets.WHATSAPP_TOKEN }}" \
            -d '{
              "phone": "${{ secrets.WHATSAPP_PHONE }}",
              "message": "❌ *API Deploy Falhou!*\n\n📦 *API:* ${{ env.PROJECT_NAME }}\n🔗 *Ver logs:* https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}\n📅 *Data:* $(date +'%d/%m/%Y %H:%M')\n\n⚠️ Verificar logs!"
            }' || echo "Falha ao enviar notificação (não crítico)"
```

## 📋 Exemplo Completo de Mensagens

### ✅ Mensagem de Sucesso:
```
✅ *Deploy Concluído com Sucesso!*

📦 *Projeto:* route-365
🏷️ *Versão:* 0.0.7
🏷️ *Tag:* producao-0.0.7
🌐 *URL:* https://route-365.appjvs.com.br
📅 *Data:* 12/11/2025 15:30

🎉 Aplicação disponível!
```

### ❌ Mensagem de Falha:
```
❌ *Deploy Falhou!*

📦 *Projeto:* route-365
🔗 *Ver logs:* https://github.com/user/route-365/actions/runs/123456
📅 *Data:* 12/11/2025 15:30

⚠️ Verificar logs e corrigir!
```

## 🔧 Personalizar API WhatsApp

Se sua API do WhatsApp usar formato diferente, ajuste o curl:

### Exemplo 1: API Padrão com JSON
```bash
curl -X POST "http://sua-api:8084/send" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5511999999999",
    "body": "Sua mensagem aqui"
  }'
```

### Exemplo 2: Evolution API
```bash
curl -X POST "http://sua-api:8080/message/sendText/instance" \
  -H "apikey: SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5511999999999",
    "text": "Sua mensagem aqui"
  }'
```

### Exemplo 3: Baileys API
```bash
curl -X POST "http://sua-api:3000/send-message" \
  -H "Authorization: Bearer TOKEN" \
  -d "phone=5511999999999&message=Sua mensagem"
```

## 🎨 Emojis Úteis para Notificações

- ✅ Sucesso
- ❌ Falha
- 📦 Projeto
- 🏷️ Versão/Tag
- 🌐 URL
- 📊 Swagger/Docs
- 📅 Data
- 🎉 Celebração
- ⚠️ Atenção
- 🔗 Link
- 🚀 Deploy
- ⏱️ Tempo
- 👤 Autor
- 📝 Commit

## 🔒 Segurança

**IMPORTANTE:**
- ✅ Sempre use GitHub Secrets para credenciais
- ❌ Nunca commite tokens/keys no código
- ✅ Use `|| echo "Falha..."` para não quebrar o deploy se notificação falhar
- ✅ Considere criar um número/grupo específico para notificações

## 📞 Notificar Múltiplos Números

Para notificar várias pessoas:

```yaml
      - name: Notificar equipe no WhatsApp
        if: success()
        run: |
          PHONES=("5511999999999" "5511888888888" "5511777777777")

          for PHONE in "${PHONES[@]}"; do
            curl -X POST "${{ secrets.WHATSAPP_API_URL }}/send-message" \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer ${{ secrets.WHATSAPP_TOKEN }}" \
              -d "{
                \"phone\": \"$PHONE\",
                \"message\": \"✅ Deploy route-365 v${{ steps.version.outputs.version }} OK!\"
              }" || true
          done
```

Ou criar um grupo e enviar para o ID do grupo.

## 🎯 Notificar Apenas em Produção

Se quiser notificar só quando for deploy de produção:

```yaml
      - name: Notificar WhatsApp (só produção)
        if: success() && github.ref == 'refs/heads/main'
        run: |
          # seu curl aqui
```

## 🕐 Notificar Apenas em Horário Comercial

Para não acordar ninguém de madrugada:

```yaml
      - name: Notificar WhatsApp
        if: success()
        run: |
          HOUR=$(date +%H)

          # Só notifica entre 8h e 22h
          if [ $HOUR -ge 8 ] && [ $HOUR -lt 22 ]; then
            curl -X POST "${{ secrets.WHATSAPP_API_URL }}/send-message" \
              -H "Content-Type: application/json" \
              -d '{ ... }'
          else
            echo "Fora do horário - notificação silenciada"
          fi
```

## 📊 Exemplo com Mais Informações

Incluir autor do commit, branch, etc:

```yaml
      - name: Notificar sucesso detalhado
        if: success()
        run: |
          curl -X POST "${{ secrets.WHATSAPP_API_URL }}/send-message" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${{ secrets.WHATSAPP_TOKEN }}" \
            -d '{
              "phone": "${{ secrets.WHATSAPP_PHONE }}",
              "message": "✅ *Deploy Sucesso!*\n\n📦 *Projeto:* ${{ env.PROJECT_NAME }}\n🏷️ *Versão:* ${{ steps.version.outputs.version }}\n👤 *Autor:* ${{ github.actor }}\n🌿 *Branch:* ${{ github.ref_name }}\n💬 *Commit:* ${{ github.event.head_commit.message }}\n⏱️ *Duração:* ${{ job.duration }}s\n🌐 *URL:* https://${{ env.SERVER_HOST }}/"
            }'
```

## 🧪 Testar Notificação

Para testar se a API funciona:

```bash
# Testar localmente (substitua SUA_API_KEY e o número)
curl --location --request POST 'https://webzap.appjvs.com.br/api/proxy/message/sendText/zap-default' \
  --header 'Content-Type: application/json' \
  --header 'apikey: SUA_API_KEY' \
  --data '{
    "number": "5522999604234",
    "text": "Teste de notificação GitHub Actions"
  }'
```

Se funcionar (receber mensagem no WhatsApp), está pronto para usar nos workflows!

---

**Criado em:** 2025-11-12
**Configuração:** API WhatsApp via curl
**Importante:** Configurar secrets antes de fazer push
