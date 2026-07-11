/**
 * ProposalController
 *
 * Ponto de entrada fino para a proposta. Junta selector e service e devolve o
 * modelo pronto para a tela/PDF. Cacheable e read-only. Embrulha qualquer erro
 * em AuraHandledException para nao vazar detalhe interno ao usuario.
 */
public with sharing class ProposalController {

    @AuraEnabled(cacheable=true)
    public static ProposalService.Proposal getProposal(Id opportunityId) {
        try {
            ProposalSelector selector = new ProposalSelector();
            Opportunity opp = selector.opportunityById(opportunityId);
            if (opp == null) {
                throw new ProposalService.ProposalException(
                    'Oportunidade nao encontrada ou sem permissao de acesso.'
                );
            }
            List<OpportunityLineItem> lines = selector.linesByOpportunity(opportunityId);
            return new ProposalService().build(opp, lines);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
