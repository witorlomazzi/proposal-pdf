import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import archive from '@salesforce/apex/ProposalArchiveController.archive';

/**
 * generateProposalPdf
 *
 * Quick Action headless na record page da Oportunidade. Um clique arquiva a
 * proposta gerada como arquivo (Salesforce Files) na Oportunidade e, em seguida,
 * abre o mesmo documento em PDF em uma nova aba - a experiencia de hoje do
 * vendedor (um clique, PDF aberto) permanece igual, mas agora fica o historico
 * do que foi enviado.
 *
 * Nao renderiza UI: invoke() e chamado quando o usuario aciona o botao. Se o
 * arquivamento falhar, o vendedor ainda gera/abre o PDF (a falha nunca bloqueia
 * a geracao); um toast avisa que o historico nao foi salvo.
 */
export default class GenerateProposalPdf extends NavigationMixin(
    LightningElement
) {
    @api recordId;

    @api
    async invoke() {
        try {
            await archive({ opportunityId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Proposta arquivada na oportunidade',
                    message: 'O documento gerado ficou salvo em Arquivos, com data.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Proposta gerada, mas nao arquivada',
                    message:
                        'O PDF foi aberto, porem nao ficou salvo no historico. Tente novamente.',
                    variant: 'warning'
                })
            );
        }
        this.navigateToPdf();
    }

    navigateToPdf() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/apex/ProposalPdf?id=${this.recordId}`
            }
        });
    }
}
