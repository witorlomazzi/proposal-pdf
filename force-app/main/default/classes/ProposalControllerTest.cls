/**
 * ProposalControllerTest
 *
 * Exercita o caminho real (selector + service) com Opportunity, Produto,
 * PricebookEntry e OpportunityLineItem de verdade. Cobre o positivo (proposta
 * montada com os totais certos) e o negativo (id inexistente/sem acesso ->
 * AuraHandledException).
 */
@IsTest
private class ProposalControllerTest {

    private static Opportunity seedOpportunityWithLines() {
        Account acc = new Account(Name = 'ZZTEST-Cliente Proposta');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'ZZTEST-Oportunidade Proposta',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = acc.Id
        );
        insert opp;

        Product2 prod = new Product2(Name = 'ZZTEST-Abrasivo 40', IsActive = true);
        insert prod;

        Id stdPricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        insert new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 100
        );

        // Discount_Percent__c e a fonte de verdade do desconto, mantida por automacao (rollup no
        // trigger de OpportunityLineItem). Definimos o percentual DEPOIS de inserir a linha, com um
        // update direto na Oportunidade, que nao dispara o rollup de linha e portanto persiste.
        opp.Discount_Percent__c = 10;
        update opp;
        return opp;
    }

    @IsTest
    static void getProposalReturnsModelWithTotals() {
        Opportunity opp = seedOpportunityWithLines();

        Test.startTest();
        ProposalService.Proposal p = ProposalController.getProposal(opp.Id);
        Test.stopTest();

        System.assertEquals('ZZTEST-Oportunidade Proposta', p.opportunityName, 'nome da oportunidade');
        System.assertEquals('ZZTEST-Cliente Proposta', p.accountName, 'nome da conta');
        System.assertEquals(1, p.lines.size(), 'uma linha');
        System.assertEquals('ZZTEST-Abrasivo 40', p.lines[0].productName, 'nome do produto na linha');
        System.assertEquals(1000, p.subtotal, 'subtotal 10 x 100');
        System.assertEquals(10, p.discountPercent, 'percentual da oportunidade');
        System.assertEquals(100, p.discountAmount, 'desconto de 10%');
        System.assertEquals(900, p.grandTotal, 'total com desconto');
    }

    @IsTest
    static void getProposalUnknownIdThrows() {
        Boolean threw = false;
        try {
            ProposalController.getProposal('006000000000000');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'id inexistente deve lancar AuraHandledException');
    }

    @IsTest
    static void selectorHandlesNullId() {
        ProposalSelector sel = new ProposalSelector();
        System.assertEquals(null, sel.opportunityById(null), 'id nulo devolve null');
        System.assertEquals(0, sel.linesByOpportunity(null).size(), 'id nulo devolve lista vazia');
    }
}
