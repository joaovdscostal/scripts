# Padrões - VRaptor

## 🔍 ANTES DE INICIAR

**IMPORTANTE**: Antes de começar a implementar ou modificar código neste projeto:

1. **Analise a estrutura de pastas**: Mapeie a organização de `src/main/java` (controller, service, dao, model, util) e `src/main/webapp`
2. **Identifique assets existentes**: Verifique arquivos em `webapp/assets/js/` e `webapp/assets/css/` para encontrar:
   - **forms.js**: Funções Ajax, validação e utilitários
   - **Bibliotecas JS**: jQuery, plugins (DataTables, Select2, modals, etc)
   - **CSS compartilhado**: Templates, layouts, estilos comuns
3. **Leia o template base JSP**: Entenda a estrutura HTML, imports de CSS/JS, headers/footers
4. **Verifique configurações**: `hibernate.cfg.xml`, `web.xml`, dependências no `pom.xml`
5. **Entenda padrões de transação**: Como `HibernateUtil` é usado nos controllers existentes
6. **Identifique componentes de UI**: Modals, datatables, formulários já implementados para reutilizar

**NUNCA reinvente funcionalidades que já existem no projeto. SEMPRE reutilize código, bibliotecas e componentes existentes.**
**NUNCA adicione arquivo js ou css em arquivos jsp, só em ultimos casos**

**Só inicie a implementação após mapear completamente a estrutura, assets e padrões do projeto.**

---

## Stack

- VRaptor 4
- Java 8+
- JSP/JSTL
- Hibernate
- MySQL

## Estrutura

```
src/main/java
├── controller
├── service      # Regras de negócio
├── dao
├── model
└── util
src/main/webapp
├── WEB-INF/jsp
└── assets
    ├── js/
    │   └── admin/
    │       └── controller/
    │           └── {controller}.js
    └── css/
        └── admin/
            └── controller/
                └── {controller}.css
```

**Backend**: `src/br/com/jvlabs/`

- `controller/` - VRaptor controllers
- `model/` - Entidades JPA/Hibernate
- `service/` - Lógica de negócio
- `dao/` - Acesso a dados
- `dto/` - Transfer objects
- `util/` - Helpers

**Frontend**: `WebContent/`

- `WEB-INF/jsp/` - Templates JSP
- `js/projeto/controller/` - Controladores JS
- `css/` - Estilos
- `arquivos/` - Uploads

## ⚠️ IMPORTANTE: Quando NÃO Compilar

**NÃO execute `mvn compile` quando alterar apenas:**

- Arquivos `.js` (JavaScript)
- Arquivos `.css` (CSS)
- Arquivos `.jsp` (JSP/HTML)

**Apenas compile (`mvn compile`) quando alterar:**

- Arquivos `.java` (Backend)

**Motivo**: O servidor de desenvolvimento (Tomcat) recarrega automaticamente JSP, CSS e JS. Compilar Maven é desnecessário e desperdiça tempo.

## Arquitetura em Camadas

### Controller

- **Responsabilidade**: Receber requisições, validar entrada, chamar services, retornar view/resultado
- **NÃO DEVE**: Conter regras de negócio, acessar DAOs diretamente, ter lógica complexa
- Usar `@Controller` e injeção com `@Inject`
- Métodos pequenos e focados
- Views: WEB-INF/jsp/{controller}/{metodo}.jsp
- Rotas: anotação `@Path`; ou entao anotacoes com os verbos de cada necesidade;
- **Controle de Transação**: Todo método que execute operações no banco DEVE gerenciar transação explicitamente:

  ```java

  try {
      HibernateUtil.beginTransaction();
      // chamar services que fazem operações no banco
      service.salvar(objeto);
  	  HibernateUtil.commit();
  } catch (Exception e) {
      HibernateUtil.rollback();
      // IMPELEMTNAR DE ACORDO COM PADROS
  }
  ```

### Service

- **Responsabilidade**: Toda a lógica de negócio e regras da aplicação
- Validações de negócio
- Orquestração entre múltiplos DAOs quando necessário
- Design Patterns aplicados aqui (Strategy, Factory, Template Method, etc)

### DAO

- **Responsabilidade**: Apenas acesso a dados (CRUD)
- Injeção com CDI `@Inject`
- Métodos devem ser autoexplicativos
- Queries nomeadas quando possível

### Model

- Entidades JPA/Hibernate
- Getters/setters
- Relacionamentos bem definidos
- Validações de campo (Bean Validation)
- sempre que criar um novo model, tem que adicionar em mapeamento.properties

## Organização de Assets (JS/CSS)

### JavaScript

- **JS customizado por controller**: `js/admin/controller/{NomeController}.js`
- **JS compartilhado**: `js/admin/common/` ou `js/admin/util/`
- **NUNCA colocar JavaScript dentro de JSP** (exceto em casos extremamente excepcionais)
- **OBRIGATÓRIO**: Usar bibliotecas e funções já existentes no projeto:
  - **forms.js**: Funções de Ajax, validação de formulários, utilitários
  - **Modals**: Usar biblioteca de modais existente (não criar novos)
  - **jQuery**: Já disponível, usar para manipulação DOM
  - **Plugins**: DataTables, Select2, DatePicker, etc - verificar antes de adicionar novos
- **NÃO reinventar a roda**: Antes de escrever qualquer função, verificar se já existe em `forms.js` ou outros arquivos compartilhados
- **Ajax**: SEMPRE usar as funções Ajax padronizadas do `forms.js` (não usar `$.ajax` diretamente)
- **Validações**: Usar funções de validação existentes antes de criar novas
- **Listagem** : para listagem de infos, sempre dar a prioridade por usar template com jsview e js render

### CSS

- **CSS customizado por controller**: `css/admin/controller/{NomeController}.css`
- **CSS compartilhado**: `css/admin/common/` ou `css/admin/layout/`
- **NUNCA colocar CSS inline ou em `<style>` dentro de JSP** (exceto em últimos casos)
- Seguir padrões de classes e estrutura do template existente

### Antes de Implementar

1. **Analisar o template JSP base** usado no projeto
2. **Estudar o forms.js**: Verificar funções de Ajax, validação e utilitários disponíveis
3. **Verificar bibliotecas JS já disponíveis** (jQuery, plugins, modals, etc)
4. **Identificar padrões de UI existentes** (modals, datatables, formulários)
5. **Reusar componentes e estilos** já implementados
6. **Manter consistência visual e funcional**
7. **Evitar duplicação**: Se a funcionalidade já existe, usar a implementação existente

## Banco de Dados

- Hibernate com hibernate.cfg.xml
- Transações gerenciadas manualmente com `HibernateUtil.beginTransaction()`, `commit()` e `rollback()`
- Naming: camel case
- Relacionamentos sempre mapeados corretamente

## JSP - Boas Práticas

- JSTL para lógica de apresentação
- EL (Expression Language) para expressões: `${}`
- Formulários com CSRF token
- **Mínimo de lógica possível** - delegar para controllers/services
- **Sem JavaScript/CSS embutido** - usar arquivos externos
- Importar apenas os JS/CSS necessários para aquela view
- Usar tags customizadas quando apropriado

## Qualidade de Código

### Clean Code

- **Nomes descritivos**: variáveis, métodos e classes devem ser autoexplicativos
- **Métodos pequenos**: cada método deve fazer uma única coisa
- **Sem código duplicado**: extrair para métodos ou classes utilitárias
- **Responsabilidade única**: cada classe com propósito claro
- **Código limpo e legível**: evitar complexidade desnecessária

### Design Patterns

- Aplicar padrões de projeto quando apropriado (Strategy, Factory, Builder, Template Method, etc)
- Services são o lugar ideal para aplicação de patterns
- Não force patterns onde não fazem sentido

### Comentários

- **Código deve ser autoexplicativo** - comentários geralmente indicam código confuso
- Comentar apenas quando absolutamente necessário (lógica complexa inevitável, workarounds, TODOs)
- Preferir refatoração a comentários explicativos
- JavaDoc em APIs públicas e métodos complexos

### Idioma

- **Português por padrão** em todo o código
- Nomes de classes, métodos, variáveis em português
- Comentários e documentação em português
- Mensagens de erro e logs em português

## Code Review - Checklist

- [ ] Controller sem regras de negócio
- [ ] Transações gerenciadas corretamente (HibernateUtil.beginTransaction/commit/rollback)
- [ ] Lógica de negócio está no Service
- [ ] DAO apenas com queries e acesso a dados
- [ ] JS/CSS em arquivos separados na estrutura correta
- [ ] Usando funções do forms.js para Ajax e validações
- [ ] Usando biblioteca de modals existente (não criou novo)
- [ ] Reusando plugins e componentes JS já disponíveis
- [ ] Sem código duplicado
- [ ] Nomes claros e descritivos
- [ ] Código limpo e legível
- [ ] Design patterns aplicados corretamente
- [ ] Sem comentários desnecessários
- [ ] Consistente com template e padrões do projeto
