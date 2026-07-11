# Proposal PDF

Gera a proposta comercial em PDF a partir da propria Oportunidade no Salesforce: itens, quantidades, preco, desconto da venda, validade, condicoes comerciais e totais. Um clique na Oportunidade e o documento sai pronto para o cliente, com o mesmo numero que foi aprovado no sistema.

> Cenario ficticio de demonstracao. A "Vetra Distribuidora" e uma empresa inventada para exercitar praticas de engenharia Salesforce em um contexto realista. Nenhum dado aqui e de cliente real.

## A dor

Na Vetra, o desconto por volume ja e calculado dentro do Salesforce e a alcada de desconto ja corre no sistema. Mas o documento da proposta que ia para o cliente ainda nascia a mao: Paula, do inside sales, abria o Word e copiava item por item, quantidade, preco, o desconto aplicado e as condicoes comerciais. Eram dezenas de minutos por proposta e, pior, o valor copiado nem sempre batia com o que estava no sistema. Uma casa trocada e a proposta saia errada, com o desconto que o gestor nunca aprovou.

## A solucao

Um botao "Gerar proposta (PDF)" na Oportunidade. Um clique abre o documento renderizado a partir dos dados da propria venda, sem recopia manual. O percentual de desconto vem de `Opportunity.Discount_Percent__c`, a mesma fonte de verdade unica que o relatorio de descontos e o motor de comissao ja leem, entao o PDF enviado ao cliente bate com o numero aprovado no sistema.

- **Um clique na Oportunidade**: a Quick Action "Gerar proposta (PDF)" abre a proposta em nova aba, sem sair da tela da venda.
- **Fonte de verdade unica**: o percentual de desconto e o da Oportunidade, nao um numero digitado de novo no documento.
- **Validade e condicoes configuraveis**: a validade (emissao + N dias) e o bloco de condicoes comerciais vem de Custom Label, ajustaveis sem tocar em codigo e sem campo custom novo.
- **Bulk-safe e deterministico**: o nucleo de calculo e puro, sem SOQL nem DML no caminho, coberto por teste de faixa, desconto nulo, lista vazia e caminho bulk com 200 linhas.

## Arquitetura

Segue o padrao Service/Selector/Controller da fabrica, com leitura pura e sem gravar na Oportunidade (nao dispara automacao de objeto compartilhado nem depende de campo custom novo).

- `ProposalService`: nucleo de calculo, sem estado. `build(Opportunity, List<OpportunityLineItem>)` monta o modelo, os totais, a validade e as condicoes comerciais. Puro: recebe os registros ja carregados, nao consulta nem grava.
- `ProposalSelector`: leitura da Oportunidade e das linhas numa unica query cada, `WITH USER_MODE` e com bind, respeitando as permissoes de quem abre a proposta.
- `ProposalController`: ponto de entrada `@AuraEnabled(cacheable=true)`, read-only, embrulha erro em `AuraHandledException`.
- `ProposalPdfController`: extension do standard controller da Opportunity que entrega o modelo a pagina Visualforce. Monta o documento uma unica vez e guarda, para que os varios getters da pagina nao repitam a consulta.
- `ProposalPdf` (Visualforce, `renderAs="pdf"`): transforma o modelo em documento com layout de cotacao (cabecalho, linhas, totais, validade e condicoes).
- `generateProposalPdf` (LWC headless): Quick Action na record page da Oportunidade; `NavigationMixin` abre `/apex/ProposalPdf?id={recordId}` em nova aba com um clique.

Configuracao por Custom Label (sem campo custom novo):

- `Proposal_Validity_Days`: validade da proposta em dias a partir da emissao (padrao 15).
- `Proposal_Commercial_Terms`: condicoes comerciais, itens separados por barra vertical.

## Como rodar

```sh
sf project deploy start --target-org <sua-org>
sf apex run test --class-names ProposalServiceTest ProposalControllerTest ProposalPdfControllerTest --code-coverage
```

Na Oportunidade, acione a Quick Action **Gerar proposta (PDF)**. Ou abra direto `/apex/ProposalPdf?id=<idDaOportunidade>`.

Para gerar o modelo por codigo, `ProposalController.getProposal(opportunityId)` devolve a proposta de uma Oportunidade.

## Testes

- Apex: `ProposalServiceTest`, `ProposalControllerTest` e `ProposalPdfControllerTest`, cobrindo faixa de desconto, desconto nulo, lista vazia, bulk com 200 linhas, validade e condicoes comerciais. Gate de cobertura minima de 85% na CI.
- LWC: `generateProposalPdf` com Jest (a navegacao para a pagina PDF).
- CI (GitHub Actions): roda o Jest e os testes Apex em scratch org a cada push e pull request, com o gate de cobertura.

## Status / Proxima iteracao

Entregue ponta a ponta: motor de calculo, pagina PDF, validade e condicoes comerciais, e o botao de um clique na Oportunidade. Candidatas a v2:

- Anexar o PDF gerado como ContentDocument na Oportunidade (historico do que foi enviado), nao so abrir na aba.
- Logotipo e identidade visual da Vetra no cabecalho do documento.
- Enviar a proposta por e-mail ao contato da Oportunidade direto do botao.
