/**
 * ProposalArchiveController
 *
 * Arquiva a proposta comercial gerada como arquivo (Salesforce Files) vinculado
 * a Oportunidade, para virar historico do que foi enviado ao cliente. Reusa a
 * pagina Visualforce ProposalPdf (mesma renderizacao do documento aberto pelo
 * vendedor) e o ProposalSelector (para validar acesso a Oportunidade); nao toca
 * no motor da proposta (Service/Selector/Controller/PdfController intocados).
 *
 * Persistencia via ContentVersion + ContentDocumentLink (objetos padrao ja
 * materializados), NAO campo custom novo e NAO Attachment legado: esquiva o bug
 * de materializacao de CustomField da org e demonstra a tecnica "arquivo gerado
 * vira historico do registro".
 *
 * Increment V2 do backlog: anexar a proposta na Oportunidade.
 */
public with sharing class ProposalArchiveController {

    /**
     * Gera o PDF da proposta da Oportunidade e o grava como arquivo ligado a ela.
     * Devolve o Id do ContentDocument criado. Lanca AuraHandledException (sem
     * gravar nada) quando a Oportunidade nao existe ou o usuario nao tem acesso.
     */
    @AuraEnabled
    public static Id archive(Id opportunityId) {
        try {
            ProposalSelector selector = new ProposalSelector();
            Opportunity opp = selector.opportunityById(opportunityId);
            if (opp == null) {
                throw new AuraHandledException(
                    'Oportunidade nao encontrada ou sem permissao de acesso.'
                );
            }

            Blob pdf = renderPdf(opportunityId);
            String title = buildTitle(opp.Name);

            ContentVersion cv = new ContentVersion(
                Title = title,
                PathOnClient = title + '.pdf',
                VersionData = pdf
            );
            insert as user cv;

            Id contentDocumentId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                WITH USER_MODE
                LIMIT 1
            ].ContentDocumentId;

            insert as user new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = opportunityId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );

            return contentDocumentId;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Renderiza a pagina ProposalPdf como PDF para o Id da Oportunidade.
     * getContentAsPDF() lanca dentro de test method (limitacao da plataforma),
     * entao em teste usamos um stub deterministico; o smoke real de renderizacao
     * roda por anonymous apex (scripts/archive-smoke.apex).
     */
    private static Blob renderPdf(Id opportunityId) {
        if (Test.isRunningTest()) {
            return Blob.valueOf('ZZTEST-STUB-PDF-' + opportunityId);
        }
        PageReference ref = Page.ProposalPdf;
        ref.getParameters().put('id', opportunityId);
        return ref.getContentAsPDF();
    }

    /** Titulo do arquivo com data/hora da emissao: Proposta_<NomeOpp>_<yyyyMMdd_HHmm>. */
    private static String buildTitle(String opportunityName) {
        return 'Proposta_' +
            opportunityName +
            '_' +
            Datetime.now().format('yyyyMMdd_HHmm');
    }
}
