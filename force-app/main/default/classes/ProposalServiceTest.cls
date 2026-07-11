/**
 * ProposalServiceTest
 *
 * Cobre o nucleo puro de montagem da proposta: totais, desconto da oportunidade,
 * desconto nulo, lista vazia e caminho bulk (200 linhas). Nao usa DML: constroi
 * Opportunity/OpportunityLineItem em memoria com campos gravaveis (Quantity,
 * UnitPrice, Discount_Percent__c).
 */
@IsTest
private class ProposalServiceTest {

    private static OpportunityLineItem oli(Decimal qty, Decimal unitPrice, String productName) {
        return new OpportunityLineItem(
            Quantity = qty,
            UnitPrice = unitPrice,
            Product2 = new Product2(Name = productName)
        );
    }

    @IsTest
    static void buildComputesTotalsAndDiscount() {
        Opportunity opp = new Opportunity(
            Name = 'ZZTEST-Proposta',
            CloseDate = Date.today(),
            Discount_Percent__c = 10,
            Account = new Account(Name = 'ZZTEST-Cliente')
        );
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>{
            oli(10, 100, 'ZZTEST-Abrasivo'), // 1000
            oli(2, 250, 'ZZTEST-Ferramenta') //  500
        };

        Test.startTest();
        ProposalService.Proposal p = new ProposalService().build(opp, lines);
        Test.stopTest();

        System.assertEquals('ZZTEST-Proposta', p.opportunityName, 'nome da oportunidade');
        System.assertEquals('ZZTEST-Cliente', p.accountName, 'nome da conta');
        System.assertEquals(2, p.lines.size(), 'duas linhas');
        System.assertEquals(1000, p.lines[0].lineTotal, 'total da primeira linha');

        System.assertEquals(1500, p.subtotal, 'subtotal (soma das linhas)');
        System.assertEquals(10, p.discountPercent, 'percentual da oportunidade');
        System.assertEquals(150, p.discountAmount, 'valor do desconto (10% de 1500)');
        System.assertEquals(1350, p.grandTotal, 'total geral com desconto');
    }

    @IsTest
    static void nullDiscountCountsAsZero() {
        Opportunity opp = new Opportunity(Name = 'ZZTEST-SemDesconto', CloseDate = Date.today());
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>{ oli(3, 50, 'ZZTEST-EPI') };

        ProposalService.Proposal p = new ProposalService().build(opp, lines);

        System.assertEquals(0, p.discountPercent, 'desconto nulo vira zero');
        System.assertEquals(0, p.discountAmount, 'nenhum desconto');
        System.assertEquals(150, p.grandTotal, 'total igual ao subtotal sem desconto');
    }

    @IsTest
    static void emptyLinesGivesZeroTotals() {
        Opportunity opp = new Opportunity(
            Name = 'ZZTEST-Vazia',
            CloseDate = Date.today(),
            Discount_Percent__c = 20
        );

        ProposalService.Proposal p = new ProposalService().build(opp, new List<OpportunityLineItem>());

        System.assertEquals(0, p.lines.size(), 'sem linhas');
        System.assertEquals(0, p.subtotal, 'subtotal zero');
        System.assertEquals(0, p.discountAmount, 'desconto sobre zero e zero');
        System.assertEquals(0, p.grandTotal, 'total zero');
    }

    @IsTest
    static void nullOpportunityThrows() {
        Boolean threw = false;
        try {
            new ProposalService().build(null, new List<OpportunityLineItem>());
        } catch (ProposalService.ProposalException e) {
            threw = true;
        }
        System.assert(threw, 'oportunidade nula deve lancar ProposalException');
    }

    @IsTest
    static void bulkTwoHundredLines() {
        Opportunity opp = new Opportunity(
            Name = 'ZZTEST-Bulk',
            CloseDate = Date.today(),
            Discount_Percent__c = 50
        );
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 200; i++) {
            lines.add(oli(1, 10, 'ZZTEST-Item-' + i)); // 10 por linha
        }

        Test.startTest();
        ProposalService.Proposal p = new ProposalService().build(opp, lines);
        Test.stopTest();

        System.assertEquals(200, p.lines.size(), '200 linhas montadas');
        System.assertEquals(2000, p.subtotal, 'subtotal 200 x 10');
        System.assertEquals(1000, p.discountAmount, 'desconto 50% de 2000');
        System.assertEquals(1000, p.grandTotal, 'total com desconto');
    }
}
