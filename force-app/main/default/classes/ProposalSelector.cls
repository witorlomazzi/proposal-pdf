/**
 * ProposalSelector
 *
 * Leitura da Oportunidade e das suas linhas para montar a proposta. Respeita as
 * permissoes do usuario (WITH USER_MODE) e usa bind; nao depende de campo custom
 * novo. Um metodo por objeto lido.
 */
public inherited sharing class ProposalSelector {

    /** Cabecalho da Oportunidade (com o nome da Conta). Null se nao encontrada/visivel. */
    public Opportunity opportunityById(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }
        List<Opportunity> opps = [
            SELECT Id, Name, CloseDate, Discount_Percent__c, Account.Name
            FROM Opportunity
            WHERE Id = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];
        return opps.isEmpty() ? null : opps[0];
    }

    /** Linhas da Oportunidade, na ordem de exibicao, com o nome do produto. */
    public List<OpportunityLineItem> linesByOpportunity(Id opportunityId) {
        if (opportunityId == null) {
            return new List<OpportunityLineItem>();
        }
        return [
            SELECT Id, Quantity, UnitPrice, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            WITH USER_MODE
            ORDER BY SortOrder NULLS LAST, CreatedDate
        ];
    }
}
