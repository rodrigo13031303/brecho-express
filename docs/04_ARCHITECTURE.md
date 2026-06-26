# Arquitetura do Brechó Express

## Visão Geral
A arquitetura do Brechó Express é orientada a Domain-Driven Design (DDD), com estrutura feature-first e linguagens oficiais de domínio. A solução combina backend Oracle + ORDS e frontend Flutter, garantindo consistência entre dados, APIs e interface.

## Princípios Arquiteturais
- Domain-Driven Design (DDD) e Linguagem Ubíqua oficiais.
- Feature First para organizar funcionalidades por domínio.
- Mesma base de código para Cliente e Brechó.
- Backend Oracle + ORDS com APIs REST alinhadas ao domínio.
- Frontend Flutter com Riverpod e GoRouter.

## Tecnologias Principais
- Flutter
- Riverpod
- GoRouter
- Dio
- Oracle
- ORDS

## Camadas
- Presentation: UI, páginas, widgets, navegação e tradução de linguagem técnico/comercial.
- Domain: entidades, casos de uso, repositórios e regras de negócio.
- Data: integração com APIs, ORDS, transporte de dados e persistência.
- Core: design system, tema, rede e utilitários compartilhados.

## Padrões
- Navegação declarativa com GoRouter.
- Estado e dependências gerenciados com Riverpod.
- Feature-first para manter coesão e escalabilidade.
- Repositórios e providers para abstração de dados.
- Uso de linguagem ubíqua e documentação oficial para nomenclatura.

## Organização de Pastas
- lib/core: tema, design system, rede e utilitários.
- lib/features: domínio por feature, incluindo account, profile, store, product, cart, purchase_request, order e payment.
- lib/app_router.dart: roteamento principal.
- lib/main.dart: ponto de entrada do aplicativo.

## Integração de Domínio
- Os documentos `docs/12_DOMAIN_MODEL.md`, `docs/13_UBIQUITOUS_LANGUAGE.md` e `docs/14_BUSINESS_FLOW.md` são a fonte oficial da arquitetura e devem ser respeitados.
- APIs, banco e interface são modelados com base em conceitos como Purchase Request, Shipments, Brechó Plus e Economia Circular.
