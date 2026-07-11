/**
 * ProposalPdfController
 *
 * Extension do standard controller da Opportunity que entrega o modelo da
 * proposta (ProposalService.Proposal) para a pagina Visualforce ProposalPdf
 * renderizar como PDF. Read-only: le a Oportunidade e as linhas via selector
 * (WITH USER_MODE) e monta o documento com o service. O desconto vem de
 * Discount_Percent__c, a mesma fonte de verdade unica do relatorio e da comissao.
 *
 * O modelo e montado uma unica vez e guardado, para que os varios getters da
 * pagina nao repitam a consulta a cada avaliacao de expressao.
 *
 * Increment 2 do backlog: pagina renderAs=pdf.
 */
public with sharing class ProposalPdfController {

    private final Id opportunityId;
    private ProposalService.Proposal cachedProposal;
    private Boolean built = false;

    public ProposalPdfController(ApexPages.StandardController stdController) {
        this.opportunityId = stdController.getId();
    }

    /**
     * Modelo da proposta pronto para a pagina. Null quando a Oportunidade nao
     * existe ou o usuario nao tem acesso; a pagina mostra o aviso nesse caso.
     */
    public ProposalService.Proposal getProposal() {
        if (!built) {
            ProposalSelector selector = new ProposalSelector();
            Opportunity opp = selector.opportunityById(opportunityId);
            cachedProposal = opp == null
                ? null
                : new ProposalService().build(opp, selector.linesByOpportunity(opportunityId));
            built = true;
        }
        return cachedProposal;
    }

    /** Data de emissao do documento (hoje), para o cabecalho da proposta. */
    public Date getIssueDate() {
        return Date.today();
    }
}
