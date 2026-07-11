// Smoke real da pagina ProposalPdf: renderiza o PDF de ponta a ponta (getContentAsPDF,
// que nao roda dentro de test method) contra dados semeados e descartados por rollback.
// Uso: sf apex run --file scripts/pdf-smoke.apex -o witor-dev
System.Savepoint sp = Database.setSavepoint();
try {
    Id stdPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
    Account acc = new Account(Name = 'ZZTEST-Smoke Proposta PDF');
    insert acc;
    Opportunity opp = new Opportunity(
        Name = 'ZZTEST-Smoke Oportunidade PDF',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(20),
        AccountId = acc.Id,
        Pricebook2Id = stdPbId
    );
    insert opp;
    Product2 prod = new Product2(Name = 'ZZTEST-Abrasivo Smoke', IsActive = true);
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

    PageReference ref = Page.ProposalPdf;
    ref.getParameters().put('id', opp.Id);
    Blob pdf = ref.getContentAsPDF();
    System.debug('PDF bytes gerados: ' + pdf.size());
    System.assert(pdf.size() > 1000, 'PDF real deve ter tamanho compativel com um documento renderizado');
    System.debug('SMOKE OK: proposta renderizada como PDF.');
} finally {
    Database.rollback(sp);
}
