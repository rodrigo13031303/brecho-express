# Prompt Book - Brechó Express

## Objetivo
Manter um conjunto organizado de prompts oficiais para tarefas de IA, documentação e implementação, alinhado à visão do projeto, à Linguagem Ubíqua e às decisões arquiteturais consolidadas.

## Prompts oficiais

### 1. Prompt oficial para modelagem de entidades
Use o Data Dictionary como referência obrigatória antes de criar qualquer entidade nova. Respeite a Linguagem Ubíqua, mantenha o nome técnico em inglês e o nome comercial em português quando necessário, e documente a entidade antes de qualquer implementação.

### 2. Prompt oficial para revisão de Data Dictionary
Revise a estrutura de uma entidade ou módulo do Data Dictionary com base nas referências oficiais do projeto. Não invente atributos, regras ou relacionamentos fora do que já foi documentado. Consulte o Data Dictionary antes de sugerir qualquer alteração.

### 3. Prompt oficial para geração de DBML
Gere o DBML a partir do Data Dictionary e das convenções do projeto. Não crie SQL antes do DBML. Respeite os nomes técnicos, o uso de PUBLIC_ID como CHAR(32), e a nomenclatura oficial do domínio.

### 4. Prompt oficial para geração de Oracle SQL
Gere o Oracle SQL somente após o DBML e a documentação oficial. Não crie tabelas sem existir no Data Dictionary. Não use DELETE físico para entidades de negócio. Utilize os padrões de nomenclatura e constraints definidos pelo projeto.

### 5. Prompt oficial para geração de Packages Oracle
Crie packages Oracle seguindo o padrão *_API_PKG para operações consumidas pela API e *_RULE_PKG para regras de negócio. Nunca crie package genérico como PKG_UTIL e mantenha a separação de responsabilidades.

### 6. Prompt oficial para geração de APIs ORDS
Gere endpoints ORDS alinhados ao domínio, usando PUBLIC_ID para comunicação externa e sem expor o ID interno. ORDS deve chamar packages Oracle e não executar SQL solto.

### 7. Prompt oficial para Flutter
Desenvolva a camada Flutter respeitando a arquitetura do projeto. Nunca acesse SQL nem conheça a estrutura interna do banco. Use repositories/providers para consumir APIs e preserve a Linguagem Ubíqua na interface, utilizando termos como Achado e Brechó.

### 8. Prompt oficial para revisão arquitetural
Avalie uma mudança ou implementação com base na arquitetura do Brechó Express. Verifique se ela respeita Data Dictionary, Linguagem Ubíqua, PUBLIC_ID como CHAR(32), ausência de DELETE físico, separação entre *_API_PKG e *_RULE_PKG, e a regra de que o Flutter não contém regra de negócio nem acesso direto ao banco.

## Regras obrigatórias para todos os prompts
- Respeitar a Linguagem Ubíqua.
- Consultar o Data Dictionary antes de criar qualquer tabela.
- Não criar SQL antes do DBML.
- Usar PUBLIC_ID como CHAR(32).
- Não expor ID interno.
- Não usar DELETE físico.
- Não colocar regra de negócio no Flutter.
- Não criar package genérica.
