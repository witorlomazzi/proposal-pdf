import { createElement } from 'lwc';
import GenerateProposalPdf from 'c/generateProposalPdf';
import archive from '@salesforce/apex/ProposalArchiveController.archive';

// Mock de lightning/navigation: captura o pageReference passado ao Navigate.
// (a variavel precisa comecar com "mock" para o jest.mock poder referencia-la)
const mockNavigate = jest.fn();
jest.mock(
    'lightning/navigation',
    () => {
        const Navigate = Symbol('Navigate');
        const GenerateUrl = Symbol('GenerateUrl');
        const NavigationMixin = (Base) =>
            class extends Base {
                [Navigate](...args) {
                    mockNavigate(...args);
                }
                [GenerateUrl]() {}
            };
        NavigationMixin.Navigate = Navigate;
        NavigationMixin.GenerateUrl = GenerateUrl;
        return { NavigationMixin };
    },
    { virtual: true }
);

// Mock do metodo Apex de arquivamento.
jest.mock(
    '@salesforce/apex/ProposalArchiveController.archive',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const RECORD_ID = '0065g00000ABCDEAA3';

function createComponent() {
    const element = createElement('c-generate-proposal-pdf', {
        is: GenerateProposalPdf
    });
    element.recordId = RECORD_ID;
    document.body.appendChild(element);
    return element;
}

describe('c-generate-proposal-pdf', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('arquiva a proposta na oportunidade e depois abre o PDF', async () => {
        archive.mockResolvedValue('069000000000000AAA');
        const element = createComponent();

        await element.invoke();

        expect(archive).toHaveBeenCalledTimes(1);
        expect(archive).toHaveBeenCalledWith({ opportunityId: RECORD_ID });
        expect(mockNavigate).toHaveBeenCalledTimes(1);
        const pageReference = mockNavigate.mock.calls[0][0];
        expect(pageReference.type).toBe('standard__webPage');
        expect(pageReference.attributes.url).toBe(
            `/apex/ProposalPdf?id=${RECORD_ID}`
        );
    });

    it('ainda abre o PDF mesmo se o arquivamento falhar', async () => {
        archive.mockRejectedValue(new Error('sem acesso'));
        const element = createComponent();

        await element.invoke();

        expect(mockNavigate).toHaveBeenCalledTimes(1);
        expect(mockNavigate.mock.calls[0][0].attributes.url).toBe(
            `/apex/ProposalPdf?id=${RECORD_ID}`
        );
    });

    it('nao renderiza nenhuma UI (acao headless)', () => {
        const element = createComponent();
        expect(element.shadowRoot.children.length).toBe(0);
    });
});
