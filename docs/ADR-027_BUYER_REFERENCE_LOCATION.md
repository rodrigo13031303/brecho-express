---
document_id: ADR-027
title: Localização de referência do comprador
status: Aceito para materialização incremental
owner: Arquitetura
created_at: 2026-08-07
last_reviewed_at: 2026-08-07
authoritative_for: seleção, pesquisa e persistência da localização de referência do comprador
supersedes: nenhum
related_documents: 05_DESIGN_SYSTEM.md, 20_DATA_DICTIONARY.md, 40_ORDS_ARCHITECTURE.md
implementation_status: Parcialmente implementado
---

# ADR-027 — Localização de referência do comprador

## Status

Aceito para materialização incremental.

## Contexto

O comprador pode explorar Achados próximos de um endereço diferente da posição
física do aparelho. A Home precisa permitir localização atual, pesquisa textual
e reutilização de endereços nomeados como Casa, Trabalho ou Casa da mãe.

## Decisão

A localização de referência do catálogo é uma preferência do comprador e não
se confunde automaticamente com o endereço definitivo de entrega. Ela contém
latitude, longitude e rótulo legível e pode apontar para um `ADDRESS` do próprio
PROFILE.

A tela de escolha apresenta:

- busca textual com sugestões durante a digitação;
- ação para obter ou atualizar a localização atual;
- endereços ativos do PROFILE, priorizando o endereço padrão;
- distância aproximada das sugestões quando houver origem conhecida.

A ação de localização atual não confirma automaticamente a referência. O
endereço obtido por GPS preenche o campo de busca e aparece como sugestão para
revisão. O usuário pode corrigir número ou texto antes de tocar no resultado e
confirmar a escolha.

`ADDRESS` continua sendo a fonte dos endereços persistidos. `ADR_LABEL` aceita
nomes amigáveis como Casa, Trabalho, Casa da mãe e Casa da praia. A escolha para
navegação no catálogo é mantida localmente para restauração rápida e não muda o
endereço padrão sem ação explícita do usuário.

## Provedor de busca

A interface depende de uma abstração de pesquisa, não de um fornecedor. A
primeira materialização pode usar o geocodificador nativo do aparelho para
validar a experiência. Antes de escala comercial, será adotado um provedor com
autocomplete, cobertura, disponibilidade e contrato compatíveis, preferencialmente
Google Places por integração protegida no backend.

Chaves de serviços web não são embutidas no Flutter. Debounce, quantidade
máxima de sugestões, restrição ao Brasil e viés pela localização conhecida são
obrigatórios para relevância, desempenho e controle de custo.

## Privacidade

- a localização é solicitada somente com permissão do sistema operacional;
- pesquisa e coordenadas são usadas apenas para descoberta, distância e fluxos
  explicitamente escolhidos;
- histórico persistido no servidor contém somente endereços salvos pelo usuário;
- localização em tempo real contínua não é coletada por este fluxo.

## Consequências

- a Home deixa de limitar a escolha a GPS ou CEP;
- endereços salvos podem ser reutilizados entre catálogo e entrega;
- a troca futura do provedor não exige redesenhar a tela nem o domínio;
- o geocodificador nativo é uma etapa funcional, mas não substitui o SLA do
  provedor comercial futuro.
