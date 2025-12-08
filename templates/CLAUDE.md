# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão Geral

Este diretório contém templates de padrões de código para diferentes stacks tecnológicas usadas nos projetos da organização. São documentos de referência em Markdown que definem convenções, estruturas de arquitetura e melhores práticas.

## Propósito dos Templates

Cada arquivo `.md` é um guia de padrões para uma stack específica:

- **springboot.md** - APIs Java com Spring Boot 3.x, Clean Architecture, JPA/Hibernate
- **vraptor.md** - Aplicações web Java legacy com VRaptor 4, JSP/JSTL, Hibernate
- **react.md** - Aplicações web frontend React 18+ com TypeScript, Vite, Tailwind
- **react-native.md** - Aplicações mobile com React Native, TypeScript, Expo

## Estrutura dos Templates

Cada template segue uma estrutura padrão:

1. **Stack** - Tecnologias e versões principais
2. **Arquitetura** - Padrões arquiteturais (Clean Architecture, MVC, etc)
3. **Estrutura de Pacotes/Diretórios** - Organização de código
4. **Convenções de Código** - Anotações, nomenclaturas, padrões de design
5. **Aspectos Específicos** - Banco de dados, APIs, UI, validações, etc

## Quando Usar

Ao criar ou modificar código em projetos relacionados:

1. **Novos Projetos**: Use o template correspondente como blueprint inicial
2. **Refatoração**: Alinhe código existente com os padrões documentados
3. **Code Review**: Valide se o código segue as convenções do template
4. **Onboarding**: Templates servem como documentação de referência

## Padrões Comuns Entre Stacks

### Nomenclatura de Banco de Dados
- Sempre `snake_case` para tabelas e colunas (comum em Spring Boot e VRaptor)

### Estrutura de Camadas
- Separação clara entre controller/apresentação, lógica de negócio (service) e acesso a dados (repository/DAO)

### TypeScript
- Usado em stacks modernas (React, React Native) para type safety

### REST API (Spring Boot)
- Endpoints no plural: `/api/v1/users`, `/api/v1/products`
- Status codes HTTP semânticos (201 Created, 204 No Content, etc)

## Modificando Templates

Ao atualizar um template:

1. Mantenha a estrutura padrão das seções
2. Seja conciso - templates são guias rápidos, não documentação extensa
3. Foque em convenções específicas da stack, não em práticas genéricas
4. Use exemplos de código quando necessário para clareza
5. Mantenha informações de versões atualizadas (Java 17+, React 18+, etc)

## Notas Importantes

- **VRaptor é Legacy**: O template VRaptor é para manutenção de aplicações existentes, não para novos projetos
- **Spring Boot é o Padrão Atual**: Para novas APIs backend Java
- **Clean Architecture**: Padrão adotado em Spring Boot com clara separação de responsabilidades
- **TypeScript First**: Todas as aplicações React/React Native devem usar TypeScript
