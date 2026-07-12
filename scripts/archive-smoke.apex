// Smoke real do arquivamento da proposta: exercita ProposalArchiveController.archive
// de ponta a ponta - renderiza o PDF via getContentAsPDF (que nao roda dentro de test
// method) e grava ContentVersion + ContentDocumentLink - contra dados semeados e
// descartados por rollback.
// Uso: sf apex run --file scripts/archive-smoke.apex -o witor-dev
System.Savepoint sp = Database.setSavepoint();
try {
    Id stdPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
    Account acc = new Account(Name = 'ZZTEST-Smoke Arquivo Proposta');
    insert acc;
    Opportunity opp = new Opportunity(
        Name = 'ZZTEST-Smoke Arquivo Oportunidade',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(20),
        AccountId = acc.Id,
        Pricebook2Id = stdPbId
    );
    insert opp;
    Product2 prod = new Product2(Name = 'ZZTEST-Abrasivo Smoke Arquivo', IsActive = true);
    insert prod;
    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = stdPbId,
        Product2Id = prod.Id,
        UnitPrice = 250,
        IsActive = true
    );
    insert pbe;
    insert new OpportunityLineItem(
        OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Quantity = 4, UnitPrice = 250
    );
    opp.Discount_Percent__c = 12;
    update opp;

    Id docId = ProposalArchiveController.archive(opp.Id);
    System.assertNotEquals(null, docId, 'archive deve devolver o ContentDocumentId');

    ContentVersion cv = [
        SELECT Title, PathOnClient, ContentSize
        FROM ContentVersion
        WHERE ContentDocumentId = :docId
        LIMIT 1
    ];
    System.debug('Arquivo: ' + cv.Title + ' (' + cv.ContentSize + ' bytes)');
    System.assert(cv.ContentSize > 1000, 'PDF real arquivado deve ter tamanho de documento renderizado');

    Integer links = [
        SELECT COUNT() FROM ContentDocumentLink
        WHERE ContentDocumentId = :docId AND LinkedEntityId = :opp.Id
    ];
    System.assertEquals(1, links, 'arquivo ligado a Oportunidade');
    System.debug('SMOKE OK: proposta arquivada e ligada a Oportunidade.');
} finally {
    Database.rollback(sp);
}
