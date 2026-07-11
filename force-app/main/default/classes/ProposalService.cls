/**
 * ProposalService
 *
 * Nucleo do motor de proposta: monta o modelo da cotacao (cabecalho, linhas e
 * totais) a partir de uma Opportunity e das suas OpportunityLineItems. Logica
 * pura, sem estado, sem SOQL nem DML no caminho de calculo, segura para lote.
 *
 * O desconto da proposta e o percentual da Oportunidade (Discount_Percent__c), a
 * mesma fonte de verdade unica que o relatorio de descontos e o motor de comissao
 * ja leem, para que o documento enviado ao cliente bata com o numero aprovado no
 * sistema. As linhas mostram quantidade, preco e total; o desconto incide sobre o
 * subtotal.
 *
 * Increment 1 do backlog: modelo + totais.
 */
public inherited sharing class ProposalService {

    // Campos expostos como propriedades para serem lidos tanto pelo LWC (@AuraEnabled)
    // quanto pela pagina Visualforce (que so enxerga getters/propriedades, nao campos).

    /** Uma linha da proposta. */
    public class Line {
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal lineTotal { get; set; } // quantidade x preco unitario
    }

    /** O documento da proposta pronto para renderizar. */
    public class Proposal {
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public String opportunityName { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Date closeDate { get; set; }
        @AuraEnabled public List<Line> lines { get; set; }
        @AuraEnabled public Decimal discountPercent { get; set; } // desconto da oportunidade (fonte unica)
        @AuraEnabled public Decimal subtotal { get; set; } // soma das linhas, antes do desconto
        @AuraEnabled public Decimal discountAmount { get; set; } // valor do desconto sobre o subtotal
        @AuraEnabled public Decimal grandTotal { get; set; } // subtotal ja com o desconto

        public Proposal() {
            this.lines = new List<Line>();
            this.subtotal = 0;
            this.discountAmount = 0;
            this.grandTotal = 0;
            this.discountPercent = 0;
        }
    }

    /**
     * Monta a proposta de uma Opportunity a partir das suas linhas.
     * Puro: nao consulta nem grava; recebe os registros ja carregados pelo
     * selector. Desconto nulo conta como zero. Valores em duas casas.
     */
    public Proposal build(Opportunity opp, List<OpportunityLineItem> lineItems) {
        if (opp == null) {
            throw new ProposalException('Oportunidade nao informada.');
        }
        Proposal result = new Proposal();
        result.opportunityId = opp.Id;
        result.opportunityName = opp.Name;
        result.accountName = opp.Account != null ? opp.Account.Name : null;
        result.closeDate = opp.CloseDate;
        result.discountPercent = opp.Discount_Percent__c == null ? 0 : opp.Discount_Percent__c;

        for (OpportunityLineItem oli : (lineItems == null ? new List<OpportunityLineItem>() : lineItems)) {
            Line line = new Line();
            line.productName = oli.Product2 != null ? oli.Product2.Name : null;
            line.quantity = oli.Quantity == null ? 0 : oli.Quantity;
            line.unitPrice = oli.UnitPrice == null ? 0 : oli.UnitPrice;
            line.lineTotal = (line.quantity * line.unitPrice).setScale(2, System.RoundingMode.HALF_UP);

            result.lines.add(line);
            result.subtotal += line.lineTotal;
        }

        result.subtotal = result.subtotal.setScale(2, System.RoundingMode.HALF_UP);
        result.discountAmount = (result.subtotal * result.discountPercent / 100)
            .setScale(2, System.RoundingMode.HALF_UP);
        result.grandTotal = (result.subtotal - result.discountAmount).setScale(2, System.RoundingMode.HALF_UP);
        return result;
    }

    public class ProposalException extends Exception {}
}
