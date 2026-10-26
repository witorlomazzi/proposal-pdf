# Proposal PDF

Gera a proposta comercial em PDF a partir da própria Oportunidade: itens, quantidades, preço, desconto, validade, condições comerciais e totais. Um clique abre o documento e guarda uma cópia nos Arquivos da Oportunidade, com o mesmo número aprovado no sistema.

[![CI](https://github.com/witorlomazzi/proposal-pdf/actions/workflows/ci.yml/badge.svg)](https://github.com/witorlomazzi/proposal-pdf/actions/workflows/ci.yml)

> Projeto demonstrativo, com empresa e dados fictícios. A Vetra Distribuidora é uma empresa inventada para dar contexto realista ao cenário. Experiências profissionais reais não são publicadas por confidencialidade.

**Demo no navegador:** [salesforce.flupdigital.com.br/#demo-proposal](https://salesforce.flupdigital.com.br/#demo-proposal)

## O problema

Na Vetra, o desconto por volume e a alçada de aprovação já rodam no Salesforce, mas a proposta enviada ao cliente ainda nascia à mão: alguém abria o Word e copiava item por item. Eram dezenas de minutos por proposta, e o valor copiado nem sempre batia com o sistema. Uma casa decimal trocada e o cliente recebia um desconto que o gestor nunca aprovou.

## A solução

- **Um clique na Oportunidade:** a Quick Action "Gerar proposta (PDF)" abre o documento em nova aba, sem sair da venda.
- **Fonte de verdade única:** o percentual vem de `Opportunity.Discount_Percent__c`, o mesmo campo que o relatório de descontos e o motor de comissão leem.
- **Histórico do que foi enviado:** o PDF gerado fica salvo nos Arquivos da Oportunidade. Se o arquivamento falhar, a proposta abre do mesmo jeito e um aviso informa que o histórico não foi salvo.
- **Validade e condições configuráveis:** vêm de Custom Label, ajustáveis sem código e sem campo custom novo.

## Arquitetura

| Camada | Componente | Papel |
|---|---|---|
| Serviço | `ProposalService` | Monta o modelo, os totais, a validade e as condições. Recebe registros já carregados: não consulta nem grava |
| Leitura | `ProposalSelector` | Oportunidade e linhas, uma query cada, `WITH USER_MODE` e com bind |
| Entrada | `ProposalController` | `@AuraEnabled(cacheable=true)`, somente leitura |
| Documento | `ProposalPdfController` e página `ProposalPdf` | Extension do standard controller; o Visualforce com `renderAs="pdf"` desenha o layout de cotação |
| Histórico | `ProposalArchiveController` | Renderiza a mesma página e grava `ContentVersion` e `ContentDocumentLink` na Oportunidade |
| Interface | LWC `generateProposalPdf` | Quick Action sem tela: arquiva e abre `/apex/ProposalPdf?id={recordId}` |

Configuração por Custom Label:

- `Proposal_Validity_Days`: validade em dias a partir da emissão (padrão 15).
- `Proposal_Commercial_Terms`: condições comerciais, itens separados por barra vertical.

## Decisões técnicas

| Decisão | Por quê | Custo da escolha |
|---|---|---|
| Ler da Oportunidade em vez de recalcular | O PDF mostra exatamente o número aprovado | Depende de o campo de desconto estar correto na origem |
| Serviço de cálculo puro | Testável sem banco, inclusive com 200 linhas | O selector precisa entregar tudo que o serviço usa |
| Modelo montado uma vez no `ProposalPdfController` | Os vários getters da página não repetem a consulta | Estado guardado na extension |
| Histórico em Salesforce Files, e não Attachment | Objetos padrão, sem campo custom novo | Cada geração cria um arquivo novo, com data no título |
| Falha de arquivamento não bloqueia o PDF | O vendedor não fica sem a proposta | O histórico pode ficar incompleto, e o toast avisa |

## Segurança

- Leituras com `WITH USER_MODE` e bind: quem abre a proposta só vê o que pode ver.
- O arquivamento valida o acesso à Oportunidade pelo selector antes de gravar e não grava nada quando o acesso falha.
- Nenhuma gravação na Oportunidade: gerar a proposta não dispara automações do objeto.

## Testes

- **Apex:** 17 métodos de teste em `ProposalServiceTest`, `ProposalControllerTest`, `ProposalPdfControllerTest` e `ProposalArchiveControllerTest`. Cobrem faixa de desconto, desconto nulo, lista vazia, lote de 200 linhas, validade, condições comerciais e arquivamento.
- **Jest:** 3 testes do `generateProposalPdf`: arquiva e abre o PDF, abre o PDF mesmo quando o arquivamento falha e não renderiza interface.
- **Smoke em org:** `getContentAsPDF()` não roda dentro de método de teste (limitação da plataforma). Os scripts `scripts/pdf-smoke.apex` e `scripts/archive-smoke.apex` exercitam a renderização real com dados descartados por rollback.
- **CI:** o GitHub Actions roda o Jest e o Salesforce Code Analyzer (PMD) em cada push e pull request. O deploy de validação com testes Apex roda quando o repositório tem uma org de CI configurada.

```bash
npm install --legacy-peer-deps
npm run test:unit
sf apex run test --test-level RunLocalTests --code-coverage --wait 20 -o <sua-org>
```

## Como rodar

```bash
sf project deploy start --target-org <sua-org>
sf apex run --file scripts/archive-smoke.apex -o <sua-org>
```

Na Oportunidade, acione a Quick Action **Gerar proposta (PDF)**, ou abra direto `/apex/ProposalPdf?id=<idDaOportunidade>`.

## Por onde começar a ler o código

| Arquivo | O que observar |
|---|---|
| `force-app/main/default/classes/ProposalService.cls` | Cálculo puro dos totais e da validade |
| `force-app/main/default/classes/ProposalArchiveController.cls` | PDF gravado como arquivo e o desvio de `getContentAsPDF()` em teste |
| `force-app/main/default/pages/ProposalPdf.page` | Layout do documento em Visualforce |
| `force-app/main/default/lwc/generateProposalPdf/` | Quick Action sem tela e tratamento de falha |

## Limitações e próximos passos

- Logotipo e identidade visual no cabeçalho do documento.
- Envio da proposta por e-mail ao contato da Oportunidade a partir do mesmo botão.
