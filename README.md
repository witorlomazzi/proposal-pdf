# Proposal PDF

Gera a proposta comercial a partir da Oportunidade no Salesforce: itens, quantidades, preco, desconto da venda e total, prontos para virar um documento e ir para o cliente sem recopia manual.

> Cenario ficticio de demonstracao. A "Vetra Distribuidora" e uma empresa inventada para exercitar praticas de engenharia Salesforce em um contexto realista. Nenhum dado aqui e de cliente real.

## A dor

Na Vetra, o desconto por volume ja e calculado dentro do Salesforce e a alcada de desconto ja corre no sistema. Mas o documento da proposta que vai para o cliente ainda nasce a mao: Paula, do inside sales, abre o Word e copia item por item, quantidade, preco, o desconto aplicado e as condicoes. Sao dezenas de minutos por proposta e, pior, o valor copiado nem sempre bate com o que esta no sistema. Uma casa trocada e a proposta sai errada.

## A solucao

Um motor que monta a proposta a partir da propria Oportunidade, para depois virar um PDF de um clique (proximos incrementos). O desconto vem de `Opportunity.Discount_Percent__c`, a mesma fonte de verdade unica que o relatorio de descontos e o motor de comissao ja leem, entao o documento enviado ao cliente bate com o numero aprovado no sistema.

- **Modelo pronto para renderizar**: cabecalho (Oportunidade, Conta, data), linhas (produto, quantidade, preco, total da linha) e totais (subtotal, valor do desconto, total geral).
- **Fonte de verdade unica**: o percentual de desconto e o da Oportunidade, nao um numero digitado de novo no documento.
- **Bulk-safe e deterministico**: o nucleo de calculo e puro, sem SOQL nem DML no caminho, coberto por teste de faixa, desconto nulo, lista vazia e caminho bulk com 200 linhas.

## Arquitetura

Segue o padrao Service/Selector/Controller da fabrica, com leitura pura e sem gravar na Oportunidade (nao dispara automacao de objeto compartilhado nem depende de campo custom novo).

- `ProposalService`: nucleo de calculo, sem estado. `build(Opportunity, List<OpportunityLineItem>)` monta o modelo e os totais. Puro: recebe os registros ja carregados, nao consulta nem grava.
- `ProposalSelector`: leitura da Oportunidade e das linhas numa unica query cada, `WITH USER_MODE` e com bind, respeitando as permissoes de quem abre a proposta.
- `ProposalController`: ponto de entrada fino, `@AuraEnabled(cacheable=true)`, read-only, embrulha erro em `AuraHandledException`.

## Como rodar

```sh
sf project deploy start --target-org <sua-org>
sf apex run test --class-names ProposalServiceTest ProposalControllerTest --code-coverage
```

O `ProposalController.getProposal(opportunityId)` devolve o modelo da proposta de uma Oportunidade.

## Status / Proxima iteracao

Increment 1 entregue: o motor que monta o modelo da proposta com testes. Na fila:

- Pagina Visualforce `renderAs="pdf"` que transforma o modelo em documento com layout de cotacao.
- Validade e condicoes comerciais no documento.
- Botao "Gerar proposta (PDF)" na Oportunidade para o inside sales gerar com um clique.
