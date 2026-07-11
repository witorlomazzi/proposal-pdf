import { createElement } from 'lwc';
import GenerateProposalPdf from 'c/generateProposalPdf';

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

describe('c-generate-proposal-pdf', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('abre a pagina PDF da proposta com o id da oportunidade', () => {
        const element = createElement('c-generate-proposal-pdf', {
            is: GenerateProposalPdf
        });
        element.recordId = '0065g00000ABCDEAA3';
        document.body.appendChild(element);

        element.invoke();

        expect(mockNavigate).toHaveBeenCalledTimes(1);
        const pageReference = mockNavigate.mock.calls[0][0];
        expect(pageReference.type).toBe('standard__webPage');
        expect(pageReference.attributes.url).toBe(
            '/apex/ProposalPdf?id=0065g00000ABCDEAA3'
        );
    });

    it('nao renderiza nenhuma UI (acao headless)', () => {
        const element = createElement('c-generate-proposal-pdf', {
            is: GenerateProposalPdf
        });
        document.body.appendChild(element);

        expect(element.shadowRoot.children.length).toBe(0);
    });
});
