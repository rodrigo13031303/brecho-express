# Contexto de IA para o Brechó Express

## Objetivo
Fornecer contexto para assistentes de IA auxiliarem no desenvolvimento e documentação do projeto, com foco na arquitetura nacional e na linguagem ubíqua oficial.

## Sobre o Produto
Brechó Express é uma plataforma nacional de economia circular especializada em brechós, desapego, doações e logística inteligente. O mesmo aplicativo atende perfis de Cliente e Brechó.

## Tecnologias
- Flutter
- Riverpod
- GoRouter
- Dio
- Oracle
- ORDS

## Arquitetura
- Domain-Driven Design (DDD)
- Linguagem Ubíqua oficial
- Feature-first
- Organização por feature e domínio
- Tema e tokens centralizados

## Restrições Arquiteturais Obrigatórias para IA
- Nunca criar tabela sem existir no Data Dictionary.
- Nunca criar Oracle SQL antes do DBML.
- Nunca expor ID interno nas APIs.
- Sempre utilizar PUBLIC_ID para comunicação externa.
- PUBLIC_ID deve ser CHAR(32).
- Nunca usar DELETE físico em entidades de negócio.
- ORDS deve chamar packages Oracle.
- ORDS não deve executar SQL solto.
- Toda regra de negócio deve ficar em *_RULE_PKG.
- Operações consumidas pela API devem ficar em *_API_PKG.
- Flutter nunca acessa SQL.
- Flutter nunca conhece IDs internos.
- Flutter deve usar repositories/providers para consumir APIs.
- A interface deve usar termos comerciais da Linguagem Ubíqua, como Achado e Brechó.
- O banco deve usar nomes técnicos em inglês, como PRODUCT e STORE.

## Uso de IA
- Gerar documentação de produto alinhada ao modelo oficial.
- Sugerir design e usabilidade para marketplace de economia circular.
- Apoiar casos de teste e arquitetura baseada em DDD.
- Criar conteúdos de roadmap, requisitos e fluxos de negócio.
