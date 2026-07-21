# ADR-016 — Persistência de ACCOUNT

## Status

Aceito

## Contexto

O Data Dictionary define funcionalmente ACCOUNT, mas ainda não existe DDL Oracle vigente para `BEX_ACCOUNT`. O DBML legado diverge desse contrato e não deve orientar a implementação física.

A criação de `ACC_REPOSITORY_PKG` também depende da definição prévia da tabela, de seus identificadores, constraints e regras de atualização. Além disso, o projeto ainda não possui o componente seguro responsável por gerar e verificar hashes de senha.

---

## Decisão

### 1. Referência vigente

O `docs/20_DATA_DICTIONARY.md` é a referência funcional vigente de ACCOUNT. O DBML legado não representa o contrato físico atual. O futuro DDL Oracle será a materialização executável das decisões aprovadas neste ADR e nos documentos de autoridade superior.

### 2. Tabela

O nome físico da tabela é `BEX_ACCOUNT`.

### 3. Identificador técnico

O identificador técnico será declarado como:

```sql
ACC_ID NUMBER GENERATED ALWAYS AS IDENTITY
```

`ACC_ID` será gerado exclusivamente pelo Oracle, não será recebido pelas camadas superiores nem exposto externamente. Não será criada sequence manual. Os detalhes finais da identity serão definidos no futuro DDL.

### 4. Identificador público

O identificador público será declarado como `ACC_PUBLIC_ID CHAR(32) NOT NULL` e gerado por `ACC_SERVICE_PKG`, antes da chamada ao Repository, com:

```plsql
UPPER(RAWTOHEX(SYS_GUID()))
```

O Service garantirá o formato aprovado, fornecerá o valor ao Repository e o retornará às camadas superiores depois da persistência bem-sucedida. O Repository receberá `ACC_PUBLIC_ID` já gerado e apenas o persistirá: não gerará identificadores públicos, não aplicará normalização nem executará regras de domínio. Um futuro contrato poderá retornar somente informações estritamente necessárias à persistência, se houver justificativa.

`ACC_PUBLIC_ID` será imutável, protegido por unique constraint e constituirá o único identificador de ACCOUNT utilizado pelas camadas superiores. `ACC_ID` permanecerá completamente encapsulado na persistência e não será retornado pelo Repository.

### 5. E-mail

O e-mail será armazenado em `ACC_EMAIL VARCHAR2(255) NOT NULL`.

O Service normalizará e validará o valor por meio de `ACC_RULE_PKG`. O Repository persistirá o valor recebido sem repetir regras de domínio. A unique constraint física será a garantia definitiva de unicidade; uma consulta prévia de disponibilidade não substitui essa proteção.

Na troca de e-mail, `ACC_EMAIL_VERIFIED_AT` será definido como `NULL`.

### 6. Senha

`ACC_PASSWORD_HASH VARCHAR2(255) NOT NULL` armazenará uma credencial serializada contendo:

- versão do formato;
- identificador do algoritmo;
- salt criptograficamente aleatório;
- hash da composição determinística entre senha e salt.

O formato inicial será:

```text
v1$SHA512$<salt>$<hash>
```

Exemplo estrutural:

```text
v1$SHA512$A93F7C1E42D1AB98...$8D76F9A42B...
```

O exemplo não define salt fixo. Salt e hash serão serializados em representação hexadecimal consistente.

Na build instalada do Oracle AI Database 26ai Free, versão `23.26.0.0.0`, a specification disponível de `SYS.DBMS_CRYPTO` não publica `PBKDF2` nem constantes `KDF2_*`. Ela publica `DBMS_CRYPTO.HASH`, `DBMS_CRYPTO.HASH_SH512` e `DBMS_CRYPTO.RANDOMBYTES`.

Por compatibilidade com essa build, a implementação inicial adotará transitoriamente SHA-512 com salt criptograficamente aleatório. A senha será convertida para `RAW` por `UTL_I18N.STRING_TO_RAW(p_password, 'AL32UTF8')`. O hash será calculado com `DBMS_CRYPTO.HASH` e `DBMS_CRYPTO.HASH_SH512` sobre a composição determinística da senha em RAW seguida do salt de tamanho fixo. O salt será gerado exclusivamente por `DBMS_CRYPTO.RANDOMBYTES`.

Essa estratégia transitória não é equivalente a PBKDF2, Argon2 ou bcrypt e oferece menor resistência a ataques de força bruta caso a credencial armazenada seja obtida. Assim que houver suporte tecnológico aprovado, uma versão futura deverá migrar a geração de novas credenciais para um algoritmo de derivação de senha resistente a força bruta. A versão explícita do formato permitirá rejeição segura e evolução controlada, sem alteração estrutural de `BEX_ACCOUNT`.

Não serão utilizados `DBMS_RANDOM`, `STANDARD_HASH`, implementação manual de PBKDF2, salt fixo, salt derivado de e-mail, identificador ou data, nem criptografia reversível da senha.

A interpretação da estrutura interna da credencial será responsabilidade exclusiva de `ACC_PASSWORD_PKG`. Repository, Service, API e demais componentes tratarão o valor como opaco e não conhecerão ou manipularão diretamente versão, algoritmo, salt ou hash.

`ACC_PASSWORD_PKG` deverá:

- gerar salt criptograficamente aleatório;
- calcular o hash utilizando o algoritmo indicado;
- serializar o resultado;
- interpretar a credencial armazenada;
- validar a versão do formato;
- validar o identificador do algoritmo;
- validar a quantidade de componentes;
- validar as representações hexadecimais;
- recalcular o hash;
- comparar o resultado;
- rejeitar credenciais malformadas conforme comportamento definido em seu contrato;
- validar senhas.

O contrato específico de `ACC_PASSWORD_PKG` definirá constantes privadas para:

- versão atual do formato;
- identificador do algoritmo;
- tamanho do salt em bytes;
- tamanho do hash em bytes;
- separador do formato serializado.

Esses valores existirão em um único ponto da implementação. Uma futura versão poderá introduzir PBKDF2, Argon2, bcrypt ou algoritmo equivalente aprovado para novas credenciais, sem alteração estrutural de `BEX_ACCOUNT`. O suporte simultâneo a versões antigas dependerá de decisão explícita do contrato criptográfico futuro.

Senha em texto puro nunca será enviada ao Repository. O Repository receberá somente a credencial serializada e não gerará, interpretará ou validará seu conteúdo.

Antes da implementação completa dos casos de uso de ACCOUNT, será criado `ACC_PASSWORD_PKG`, componente do próprio módulo com specification, body, instalador e testes individuais.

`ACC_PASSWORD_PKG` não acessará `BEX_ACCOUNT`, não executará SQL, `COMMIT` ou `ROLLBACK` e não conhecerá Repository, Service, API, ORDS ou HTTP. O componente não representa login, sessão ou autorização e nunca registrará senha, salt, hash ou credencial em trace ou logs.

O comportamento nominal para credenciais malformadas pertence ao contrato específico da package. Uma eventual extração futura para o Core exigirá reutilização concreta, ADR e evolução arquitetural próprios.

### 7. Status

O status será armazenado em `ACC_STATUS VARCHAR2(30) NOT NULL`. A check constraint física aceitará exclusivamente:

- `PENDING_EMAIL_VERIFICATION`;
- `ACTIVE`;
- `BLOCKED`;
- `DISABLED`.

O Repository não validará transições. O Service e `ACC_RULE_PKG` decidirão o status conforme o caso de uso. A criação utilizará `PENDING_EMAIL_VERIFICATION`, sem default físico que oculte essa decisão.

### 8. Datas

As datas principais serão declaradas como:

```sql
ACC_CREATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL
ACC_UPDATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL
```

Na criação, `ACC_PASSWORD_CHANGED_AT` receberá `SYSTIMESTAMP` e `ACC_EMAIL_VERIFIED_AT` receberá `NULL`.

Na troca de e-mail, `ACC_EMAIL_VERIFIED_AT` será limpo e `ACC_UPDATED_AT` será atualizado. Na troca de senha, `ACC_PASSWORD_CHANGED_AT` e `ACC_UPDATED_AT` serão atualizados. Em uma alteração efetiva de status, `ACC_UPDATED_AT` será atualizado.

Quando a transição solicitada for idempotente e não houver mudança de status, não será executado `UPDATE` e `ACC_UPDATED_AT` permanecerá inalterado.

### 9. Auditoria

Serão mantidos:

```sql
ACC_CREATED_BY NUMBER NULL
ACC_UPDATED_BY NUMBER NULL
```

Esses campos serão opcionais nesta etapa. Não serão criadas foreign keys nem será presumida a entidade referenciada antes da aprovação do contrato de auditoria. Para a materialização física de ACCOUNT, esta decisão prevalece sobre a referência antecipada a `BEX_PROFILE` atualmente registrada no Data Dictionary.

### 10. Constraints físicas futuras

O futuro DDL deverá definir:

- primary key de `ACC_ID`;
- unique constraint de `ACC_PUBLIC_ID`;
- unique constraint de `ACC_EMAIL`;
- check constraint de `ACC_STATUS`;
- constraints `NOT NULL` previstas pelo Data Dictionary e por este ADR.

Os nomes serão definidos após a verificação das convenções oficiais vigentes. Este ADR não cria nomenclatura alternativa.

### 11. Exceções e concorrência

A consulta prévia de disponibilidade de e-mail não elimina condições de corrida. A unique constraint é a proteção definitiva.

`ACC_REPOSITORY_PKG` não converterá `DUP_VAL_ON_INDEX` em exceção de domínio. O Service será responsável pela tradução apropriada. A estratégia exata para distinguir colisão de e-mail de colisão de public ID dependerá dos nomes de constraints aprovados no DDL.

### 12. Localização do DDL e de seu teste

A materialização física de ACCOUNT será criada em:

```text
database/tables/account/bex_account.sql
```

O arquivo conterá exclusivamente a tabela `BEX_ACCOUNT`, sua identity, constraints e índices pertencentes diretamente à entidade. Ele não conterá dados de teste.

O teste individual do DDL será criado em:

```text
database/tests/account/test_bex_account.sql
```

O teste validará a existência e a definição física da tabela, incluindo colunas, tipos, tamanhos, nulabilidade, identity, constraints, defaults, estados permitidos e proteções de unicidade. Os dados criados pelo próprio teste deverão ser removidos por ele.

Esses caminhos constituem convenção local explícita da Sprint 9 para ACCOUNT e não estabelecem automaticamente uma convenção para módulos futuros.

### 13. Direção de dependências

A arquitetura permanece:

```text
ACC_API_PKG
    ↓
ACC_SERVICE_PKG
    ├── ACC_RULE_PKG
    ├── ACC_PASSWORD_PKG
    └── ACC_REPOSITORY_PKG
            ↓
        BEX_ACCOUNT
```

O Service coordenará `ACC_RULE_PKG`, `ACC_PASSWORD_PKG` e `ACC_REPOSITORY_PKG` conforme o caso de uso. Ele normalizará e validará dados, gerará o public ID, produzirá o hash antes da persistência, interpretará resultados físicos e tratará concorrência segundo os contratos aprovados. Não conhecerá ORDS ou HTTP nem montará resposta pública do Core.

`ACC_REPOSITORY_PKG` conterá somente SQL de ACCOUNT e receberá valores já preparados. Não concentrará regras de domínio, não gerará public ID ou hash, não produzirá JSON ou respostas do Core e não executará `COMMIT` ou `ROLLBACK`.

`ACC_API_PKG` será a fronteira pública PL/SQL, chamará o Service, traduzirá exceções conhecidas para o contrato público e retornará `CORE_RESPONSE_PKG.t_response_body`. Não executará SQL, não conterá regras de domínio nem gerará hash. `ACC_RULE_PKG` permanecerá pura, sem SQL, Core, JSON ou HTTP.

### 14. Ordem de implementação

A implementação seguirá obrigatoriamente:

1. `ACC_RULE_PKG`;
2. ADR de persistência de ACCOUNT;
3. DDL de `BEX_ACCOUNT`;
4. `ACC_PASSWORD_PKG`;
5. `ACC_REPOSITORY_PKG`;
6. `ACC_SERVICE_PKG`;
7. `ACC_API_PKG`;
8. validação consolidada no Oracle;
9. Git.

---

## Consequências

- o DDL de `BEX_ACCOUNT` passa a depender deste contrato antes de ser escrito;
- `ACC_REPOSITORY_PKG` não pode ser especificada antes da aprovação do DDL e dos nomes físicos necessários;
- os casos de uso que recebem senha dependem de `ACC_PASSWORD_PKG` e de seu contrato criptográfico ainda não definido;
- regras de domínio permanecem fora do Repository;
- unicidade e concorrência são protegidas pela persistência sem transformar erros técnicos em domínio dentro do Repository;
- identificadores técnicos permanecem encapsulados e somente `ACC_PUBLIC_ID` atravessa as camadas superiores;
- a geração de `ACC_PUBLIC_ID` pertence ao Service, enquanto o Repository apenas persiste valores preparados;
- os caminhos do DDL e de seu teste são aprovados localmente para ACCOUNT na Sprint 9;
- o contrato de auditoria permanece pendente, sem criação antecipada de foreign keys.
