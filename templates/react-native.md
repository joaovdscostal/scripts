# Padrões - React Native

## 🔍 ANTES DE INICIAR

**IMPORTANTE**: Antes de começar a implementar ou modificar código neste projeto:

1. **Analise a estrutura de diretórios**: Mapeie `src/` - components, screens, navigation, services, hooks, types, utils
2. **Identifique componentes reutilizáveis**: Verifique `src/components/` para evitar duplicação (buttons, cards, inputs, modals, layouts)
3. **Leia configurações**: `app.json`/`app.config.js` (Expo), `package.json`, `tsconfig.json`
4. **Entenda navegação**: Estrutura de navegação (Stack, Tab, Drawer), rotas protegidas, parâmetros
5. **Verifique services existentes**: Como API é consumida, AsyncStorage, tratamento de erros, cache
6. **Identifique hooks customizados**: Em `src/hooks/` - autenticação, permissões, navegação, etc
7. **Verifique tipos TypeScript**: Navigation params, API responses em `src/types/`
8. **Analise estado global**: Context API, Redux, Zustand - entenda o padrão adotado
9. **Verifique estilos**: Se há tema definido (cores, fontes, espaçamentos), sistema de design
10. **Identifique bibliotecas nativas**: Expo modules, bibliotecas de UI (React Native Paper, etc), permissões, câmera, notificações

**Só inicie a implementação após entender a organização, componentes existentes, navegação e padrões do projeto.**

---

## Stack
- React Native
- TypeScript
- Expo (ou bare React Native)
- React Navigation

## Estrutura
```
src/
├── components/
├── screens/
├── navigation/
├── services/
├── hooks/
└── types/
```

## Convenções
- Componentes: functional components
- Navegação: React Navigation v6
- Estado global: Context API ou Redux
- Estilização: StyleSheet.create

## UI
- SafeAreaView para áreas seguras
- Platform specific code quando necessário
- Componentes nativos quando possível

## Qualidade de Código

### Clean Code

- **Nomes descritivos**: variáveis, funções e componentes devem ser autoexplicativos
- **Funções pequenas**: cada função deve fazer uma única coisa
- **Sem código duplicado**: extrair para componentes, hooks ou utilitários reutilizáveis
- **Responsabilidade única**: cada componente/screen com propósito claro
- **Código limpo e legível**: evitar complexidade desnecessária

### Design Patterns

- Aplicar padrões quando apropriado (Composition, HOC, Render Props, Compound Components, etc)
- Hooks customizados para lógica reutilizável (useAuth, useFetch, usePermissions, etc)
- Context API para estado compartilhado (tema, autenticação, preferências)
- Não force patterns onde não fazem sentido

### Comentários

- **Código deve ser autoexplicativo** - comentários geralmente indicam código confuso
- Comentar apenas quando absolutamente necessário (lógica complexa inevitável, workarounds, TODOs)
- Preferir refatoração a comentários explicativos
- JSDoc para componentes públicos e funções complexas

### Idioma

- **Português por padrão** em todo o código
- Nomes de componentes, funções, variáveis em português
- Comentários e documentação em português
- Mensagens de erro, labels e textos de UI em português
