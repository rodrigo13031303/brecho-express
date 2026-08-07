---
document_id: ADR-028
title: Hierarquia e administração global de categorias
status: Aceito
owner: Catálogo
created_at: 2026-08-07
last_reviewed_at: 2026-08-07
authoritative_for: hierarquia, manutenção administrativa e remoção de categorias
supersedes: contrato plano de CATEGORY
related_documents: 20_DATA_DICTIONARY.md, 33_CATALOG_ARCHITECTURE.md, 38_IDENTITY_AUTHORIZATION_ARCHITECTURE.md, 40_ORDS_ARCHITECTURE.md
implementation_status: Em implementação
---

# Decisão

`BEX_CATEGORY` representa categorias raiz e subcategorias por meio de
`CAT_PARENT_ID`, uma chave estrangeira opcional para a própria tabela. A
profundidade não é fixada pelo banco; a aplicação apresenta a árvore e impede
ciclos. Uma categoria sem pai é raiz e pode ou não aceitar produtos.

A manutenção é exclusiva da autoridade global `ADMIN`. O administrador pode
criar e corrigir nome, slug, descrição, categoria pai, ordem de exibição e a
indicação de que a categoria aceita produtos.

## Integridade e ciclo de vida

- o pai não pode ser a própria categoria nem um de seus descendentes;
- uma categoria usada por qualquer produto, inclusive histórico, não pode ser
  excluída fisicamente nem inativada;
- uma categoria com subcategorias não pode ser excluída nem inativada;
- remover fisicamente é exceção restrita a erro de cadastro ainda sem qualquer
  relacionamento; nos demais casos corrige-se o cadastro;
- uma categoria que não aceita produtos não pode receber associação direta;
- produtos novos ou alterados só referenciam categorias `ACTIVE` que aceitam
  produtos;
- a listagem pública expõe apenas categorias ativas e identificadores
  públicos, nunca `CAT_ID`.

## Consequências

A tabela única evita estruturas diferentes para cada nível e permite ramos
como `Roupas > Masculina > Bermudas > Jeans`, sem obrigar `Móveis` a possuir
subcategorias. A API administrativa informa se cada registro pode ser
inativado ou excluído e o motivo do bloqueio.
