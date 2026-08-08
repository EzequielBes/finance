# Bank Statement Import — Format Reference

Esta documentação define a especificação técnica dos formatos de extrato bancário CSV exportados por bancos brasileiros e japoneses suportados pelo Analisador Financeiro.

## Tabela Resumo

| Banco | País | Formato | Separador | Encoding | Data Format | Valor Sinal / Colunas |
|---|---|---|---|---|---|---|
| Nubank | BR | CSV | `,` | UTF-8 | `yyyy-MM-dd` | Negativo = débito, Positivo = crédito |
| Itaú | BR | CSV | `;` | ISO-8859-1 | `dd/MM/yyyy` | Colunas separadas (Crédito / Débito) |
| Bradesco | BR | CSV | `;` | ISO-8859-1 | `dd/MM/yyyy` | Negativo = débito, Positivo = crédito |
| Santander | BR | CSV | `;` | UTF-8 / ISO-8859-1 | `dd/MM/yyyy` | Negativo = débito, Positivo = crédito |
| Banco do Brasil | BR | CSV | `;` | ISO-8859-1 | `dd/MM/yyyy` | Negativo = débito, Positivo = crédito (campos entre aspas) |
| UFJ (MUFG) | JP | CSV | `,` | UTF-8 / Shift-JIS | `yyyy/MM/dd` | Colunas separadas (`支払金額` / `預かり金額`) |
| SMBC | JP | CSV | `,` | UTF-8 / Shift-JIS | `yyyy/MM/dd` | Colunas separadas (`お引き出し金額` / `お預け入れ金額`) |
| Mizuho | JP | CSV | `,` | UTF-8 / Shift-JIS | `yyyy/MM/dd` | Colunas separadas (`お引出し` | `お預入れ`) |
| JP Post Bank | JP | CSV | `,` | UTF-8 / Shift-JIS | `yyyy.MM.dd` | Colunas separadas (`お支払金額` / `お受取金額`) |
| Rakuten Bank | JP | CSV | `,` | UTF-8 | `yyyy/MM/dd` | Negativo = débito, Positivo = crédito |

---

## Detalhamento Técnico por Banco

### 1. Nubank (Brasil)
- **Formato:** CSV standard
- **Separador:** Vírgula `,`
- **Encoding:** UTF-8
- **Cabeçalhos a ignorar:** 0 (a primeira linha é o cabeçalho das colunas)
- **Colunas:** `Data`, `Valor`, `Identificador`, `Descrição`
- **Formato de Data:** `yyyy-MM-dd` (ex: `2024-01-15`)
- **Tratamento de Valor:** Ponto decimal (`.`). Valores negativos indicam despesas/débitos (`-150.00`) e valores positivos indicam receitas/créditos (`5000.00`).
- **Exemplo:**
  ```csv
  Data,Valor,Identificador,Descrição
  2024-01-15,-150.00,tx001,Supermercado Extra
  2024-01-14,-45.90,tx002,iFood*Restaurante
  2024-01-01,5000.00,tx004,Salário Janeiro
  ```

---

### 2. Itaú (Brasil)
- **Formato:** CSV com cabeçalho de conta
- **Separador:** Ponto-e-vírgula `;`
- **Encoding:** ISO-8859-1 (Latin-1)
- **Cabeçalhos a ignorar:** Linhas iniciais de metadados até encontrar a linha com `Data;Histórico;...`
- **Colunas:** `Data`, `Histórico`, `Docto.`, `Crédito`, `Débito`, `Saldo`
- **Formato de Data:** `dd/MM/yyyy` (ex: `15/01/2024`)
- **Tratamento de Valor:** Vírgula decimal (`,`). Valores em colunas separadas `Crédito` e `Débito`. Débitos são numéricos positivos na coluna `Débito` (devem ser convertidos para sinal negativo na aplicação).
- **Exemplo:**
  ```csv
  Lançamentos da conta:;
  ;
  Data;Histórico;Docto.;Crédito;Débito;Saldo
  15/01/2024;SUPERMERCADO EXTRA;;;150,00;4850,00
  01/01/2024;SALARIO;123456;5000,00;;5000,00
  ```

---

### 3. Bradesco (Brasil)
- **Formato:** CSV com metadados no topo
- **Separador:** Ponto-e-vírgula `;`
- **Encoding:** ISO-8859-1 (Latin-1)
- **Cabeçalhos a ignorar:** Linhas de título/agência/conta antes da linha `Data;Descrição;Documento;Valor`
- **Colunas:** `Data`, `Descrição`, `Documento`, `Valor`
- **Formato de Data:** `dd/MM/yyyy` (ex: `15/01/2024`)
- **Tratamento de Valor:** Vírgula decimal (`,`). Coluna única `Valor`, onde valor negativo indica débito (`-150,00`) e positivo indica crédito (`5000,00`).
- **Exemplo:**
  ```csv
  Extrato de Conta Corrente
  Agência: 1234  Conta: 56789-0

  Data;Descrição;Documento;Valor
  15/01/2024;SUPERMERCADO EXTRA;0001;-150,00
  01/01/2024;SALARIO;0003;5000,00
  ```

---

### 4. Santander (Brasil)
- **Formato:** CSV standard
- **Separador:** Ponto-e-vírgula `;`
- **Encoding:** UTF-8 ou ISO-8859-1
- **Cabeçalhos a ignorar:** 0 (primeira linha é cabeçalho das colunas)
- **Colunas:** `Data`, `Descrição`, `Valor`, `Saldo`
- **Formato de Data:** `dd/MM/yyyy` (ex: `15/01/2024`)
- **Tratamento de Valor:** Vírgula decimal (`,`). Valor negativo representa débito (`-150,00`) e positivo crédito (`5000,00`).
- **Exemplo:**
  ```csv
  Data;Descrição;Valor;Saldo
  15/01/2024;COMPRA SUPERMERCADO EXTRA;-150,00;4850,00
  01/01/2024;CREDITO SALARIO;5000,00;5000,00
  ```

---

### 5. Banco do Brasil (Brasil)
- **Formato:** CSV com campos entre aspas duplas
- **Separador:** Ponto-e-vírgula `;`
- **Encoding:** ISO-8859-1
- **Cabeçalhos a ignorar:** 1 linha inicial (`"Banco do Brasil S.A."`)
- **Colunas:** `"Data"`, `"Dependência Origem"`, `"Histórico"`, `"Data do Balancete"`, `"Número do documento"`, `"Valor"`
- **Formato de Data:** `dd/MM/yyyy` (entre aspas)
- **Tratamento de Valor:** Vírgula decimal (`,`) entre aspas. Valor negativo indica débito (`"-150,00"`).
- **Exemplo:**
  ```csv
  "Banco do Brasil S.A."
  "Data";"Dependência Origem";"Histórico";"Data do Balancete";"Número do documento";"Valor"
  "15/01/2024";"AG.0001";"DEBITO EM CONTA SUPERMERCADO";"";"0001";"-150,00"
  "01/01/2024";"AG.0001";"CREDITO EM CONTA SALARIO";"";"";"5000,00"
  ```

---

### 6. UFJ - MUFG (Japão)
- **Formato:** CSV standard japonês
- **Separador:** Vírgula `,`
- **Encoding:** Shift-JIS ou UTF-8
- **Cabeçalhos a ignorar:** 0
- **Colunas:** `取引日` (Data), `摘要` (Descrição), `支払金額` (Pagamento/Débito), `預かり金額` (Depósito/Crédito), `差引残高` (Saldo)
- **Formato de Data:** `yyyy/MM/dd` (ex: `2024/01/15`)
- **Tratamento de Valor:** Inteiro em Yen (JPY) sem decimais. Colunas separadas para débito e crédito.
- **Exemplo:**
  ```csv
  取引日,摘要,支払金額,預かり金額,差引残高
  2024/01/15,スーパーマーケット,15000,,485000
  2024/01/01,給与振込,,250000,250000
  ```

---

### 7. SMBC - Sumitomo Mitsui (Japão)
- **Formato:** CSV standard japonês
- **Separador:** Vírgula `,`
- **Encoding:** Shift-JIS ou UTF-8
- **Cabeçalhos a ignorar:** 0
- **Colunas:** `日付` (Data), `摘要` (Descrição), `お引き出し金額` (Retirada/Débito), `お預け入れ金額` (Depósito/Crédito), `残高` (Saldo)
- **Formato de Data:** `yyyy/MM/dd` (ex: `2024/01/15`)
- **Tratamento de Valor:** Inteiro em JPY. Colunas separadas para retirada e depósito.
- **Exemplo:**
  ```csv
  日付,摘要,お引き出し金額,お預け入れ金額,残高
  2024/01/15,スーパー,15000,,485000
  2024/01/01,給与振込,,250000,250000
  ```

---

### 8. Mizuho Bank (Japão)
- **Formato:** CSV standard japonês
- **Separador:** Vírgula `,`
- **Encoding:** Shift-JIS ou UTF-8
- **Cabeçalhos a ignorar:** 0
- **Colunas:** `年月日` / `日付`, `摘要`, `お引出し`, `お預入れ`, `差引残高`
- **Formato de Data:** `yyyy/MM/dd`
- **Tratamento de Valor:** Inteiro em JPY. Colunas separadas para retirada e depósito.

---

### 9. JP Post Bank - Japan Post (Japão)
- **Formato:** CSV standard japonês com separadores por ponto na data
- **Separador:** Vírgula `,`
- **Encoding:** Shift-JIS ou UTF-8
- **Cabeçalhos a ignorar:** 0
- **Colunas:** `取引日` (Data), `お取引内容` (Descrição), `お支払金額` (Pagamento/Débito), `お受取金額` (Recebimento/Crédito), `残高` (Saldo)
- **Formato de Data:** `yyyy.MM.dd` (ex: `2024.01.15`)
- **Tratamento de Valor:** Inteiro em JPY. Colunas separadas para pagamento e recebimento.
- **Exemplo:**
  ```csv
  取引日,お取引内容,お支払金額,お受取金額,残高
  2024.01.15,お買物,1500,,48500
  2024.01.01,送金,,50000,50000
  ```

---

### 10. Rakuten Bank (Japão)
- **Formato:** CSV standard japonês
- **Separador:** Vírgula `,`
- **Encoding:** UTF-8
- **Cabeçalhos a ignorar:** 0
- **Colunas:** `取引日` (Data), `入出金先・摘要` (Descrição), `入出金(円)` (Valor Yen), `残高(円)` (Saldo Yen)
- **Formato de Data:** `yyyy/MM/dd`
- **Tratamento de Valor:** Inteiro em JPY. Coluna única `入出金(円)` onde sinal negativo é débito (`-1500`) e positivo é crédito.
