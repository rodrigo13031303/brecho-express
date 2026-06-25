# Arquitetura do Brechó Express

## Visão Geral
Aplicação mobile construída em Flutter com arquitetura de aplicações baseada em Clean Architecture simplificada.

## Tecnologias Principais
- Flutter
- Riverpod
- GoRouter
- Dio
- Oracle
- ORDS

## Camadas
- Presentation: UI, páginas e widgets.
- Domain: casos de uso, entidades e repositórios.
- Data: implementação de acesso a dados via Dio / ORDS.

## Padrões
- Navegação: GoRouter para rotas declarativas.
- Estado: Riverpod para manejo de estado global e dependências.
- Clean Architecture simplificada: separar UI, lógica de negócio e dados.

## Diretrizes
- Módulos por feature: auth, home, products, profile, orders.
- Repositórios para abstração de dados.
- Providers para dependências e estado reativo.
- Tema centralizado e tokens para design system.

## Arquivo de Roteamento
`lib/app_router.dart` controla as rotas principais do aplicativo.

## Organização de Pastas
- lib/core: tema, design system, utilitários.
- lib/features: cada feature com domain, data e presentation.
- lib/app_router.dart: roteamento principal.
- lib/main.dart: entrada do app.
