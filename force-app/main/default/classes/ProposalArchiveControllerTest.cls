/**
 * ProposalArchiveControllerTest
 *
 * Cobre o arquivamento da proposta como arquivo (ContentVersion) ligado a
 * Oportunidade: caminho feliz (PDF stub, pois getContentAsPDF nao roda em test)
 * gera 1 ContentVersion + 1 ContentDocumentLink no registro certo; caminho sem
 * acesso lanca excecao e nao grava nada. O smoke real de renderizacao roda por
 * anonymous apex (scripts/archive-smoke.apex).
 */
@IsTest
private class ProposalArchiveControllerTest {

    private static Opportunity seedOpportunityWithLines() {
        Account acc = new Account(Name = 'ZZTEST-Cliente Arquivo Proposta');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'ZZTEST-Oportunidade Arquivo Proposta',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = acc.Id
        );
        insert opp;

        Product2 prod = new Product2(Name = 'ZZTEST-Abrasivo Arquivo', IsActive = true);
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

        opp.Discount_Percent__c = 10;
        update opp;
        return opp;
    }

    @IsTest
    static void archivesPdfAsFileLinkedToOpportunity() {
        Opportunity opp = seedOpportunityWithLines();

        Test.startTest();
        Id docId = ProposalArchiveController.archive(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, docId, 'ContentDocument criado no arquivamento');

        List<ContentVersion> versions = [
            SELECT Id, Title, PathOnClient, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId = :docId
        ];
        System.assertEquals(1, versions.size(), 'exatamente uma versao de conteudo');
        System.assert(
            versions[0].Title.startsWith('Proposta_'),
            'titulo padronizado com prefixo Proposta_'
        );
        System.assert(
            versions[0].PathOnClient.endsWith('.pdf'),
            'arquivo salvo com extensao .pdf'
        );

        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :docId AND LinkedEntityId = :opp.Id
        ];
        System.assertEquals(1, links.size(), 'arquivo ligado exatamente uma vez a Oportunidade');
        System.assertEquals('V', links[0].ShareType, 'compartilhamento como viewer');
    }

    @IsTest
    static void unknownOpportunityThrowsAndArchivesNothing() {
        Integer before = [SELECT COUNT() FROM ContentDocument];

        Boolean threw = false;
        Test.startTest();
        try {
            ProposalArchiveController.archive('006000000000000AAA');
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Oportunidade inexistente/sem acesso lanca excecao');
        System.assertEquals(
            before,
            [SELECT COUNT() FROM ContentDocument],
            'nenhum arquivo gravado no caminho de erro'
        );
    }
}
