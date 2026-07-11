import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

/**
 * generateProposalPdf
 *
 * Quick Action headless na record page da Oportunidade. Um clique abre a
 * proposta comercial em PDF (pagina Visualforce ProposalPdf) em uma nova aba,
 * ja com o Id da Oportunidade, para o inside sales gerar o documento sem sair
 * da tela da venda.
 *
 * Nao renderiza UI: o metodo invoke() e chamado quando o usuario aciona o
 * botao e apenas navega para a pagina PDF. A montagem do documento (itens,
 * desconto, totais) fica no ProposalService/ProposalPdfController.
 */
export default class GenerateProposalPdf extends NavigationMixin(
    LightningElement
) {
    @api recordId;

    @api
    invoke() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/apex/ProposalPdf?id=${this.recordId}`
            }
        });
    }
}
