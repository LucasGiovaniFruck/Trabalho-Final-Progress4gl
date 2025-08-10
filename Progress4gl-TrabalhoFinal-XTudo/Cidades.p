USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.

CURRENT-WINDOW:WIDTH = 251.

DEFINE BUTTON bt-pri LABEL "<<".
DEFINE BUTTON bt-ant LABEL "<".
DEFINE BUTTON bt-prox LABEL ">".
DEFINE BUTTON bt-ult LABEL ">>".
DEFINE BUTTON bt-add LABEL "Adicionar".
DEFINE BUTTON bt-mod LABEL "Modificar".
DEFINE BUTTON bt-del LABEL "Eliminar".
DEFINE BUTTON bt-save LABEL "Salvar".
DEFINE BUTTON bt-canc LABEL "Cancelar".
DEFINE BUTTON bt-exp LABEL "Exportar".
DEFINE BUTTON bt-sair LABEL "Sair" AUTO-ENDKEY.

DEFINE VARIABLE Action AS CHARACTER NO-UNDO.

DEFINE QUERY qCidades FOR Cidades SCROLLING.

DEFINE BUFFER bCidade  FOR Cidades.
DEFINE BUFFER bCliente FOR Cliente.


DEFINE FRAME f-cidades
    bt-pri
    bt-ant 
    bt-prox 
    bt-ult SPACE(3) 
    bt-add bt-mod bt-del SPACE(3)
    bt-save bt-canc SPACE(3)
    bt-exp
    bt-sair  SKIP(1)
    Cidades.CodCidade COLON 20
    Cidades.NomCidade COLON 20 
    Cidades.CodUF COLON 20
    WITH SIDE-LABELS THREE-D SIZE 100 BY 9
    VIEW-AS DIALOG-BOX TITLE "Cidades".

ON 'choose' OF bt-pri 
    DO:
        GET FIRST qCidades.
        RUN piMostra.
    END.

ON 'choose' OF bt-ant 
    DO:
        GET PREV qCidades.
        RUN piMostra.
    END.

ON 'choose' OF bt-prox 
    DO:
        GET NEXT qCidades.
        RUN piMostra.
    END.

ON 'choose' OF bt-ult 
    DO:
        GET LAST qCidades.
        RUN piMostra.
    END.
ON 'choose' OF bt-add 
    DO:
        ASSIGN 
            Action = "add".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        CLEAR FRAME f-cidades.
        DISPLAY NEXT-VALUE(seqCidade) @ Cidades.CodCidade WITH FRAME f-cidades. 
    END.

ON 'choose' OF bt-mod 
    DO:
        ASSIGN 
            Action = "mod".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        DISPLAY Cidades.CodCidade WITH FRAME f-cidades.
        RUN piMostra.
    END.

ON 'choose' OF bt-save 
    DO:
        IF Action = "add" THEN 
        DO:
            CREATE bCidade.
            ASSIGN 
                bCidade.CodCidade = INPUT Cidades.CodCidade.
        END.
        IF  Action = "mod" THEN 
        DO:
            FIND FIRST bCidade 
                WHERE bcidade.CodCidade = Cidades.CodCidade
                EXCLUSIVE-LOCK NO-ERROR.
        END.
    
        ASSIGN 
            bCidade.NomCidade = INPUT Cidades.NomCidade
            bCidade.CodUF = INPUT Cidades.CodUF.

        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piOpenQuery.
    END.

ON 'choose' OF bt-canc 
    DO:
        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piMostra.
    END.

ON 'choose' OF bt-del IN FRAME f-cidades DO:
    DEFINE VARIABLE Del AS LOGICAL NO-UNDO.

    IF CAN-FIND(FIRST bCliente WHERE bCliente.CodCidade = Cidades.CodCidade) THEN DO:
        MESSAGE "Esta cidade nao pode ser eliminada pois esta sendo utilizada por um ou mais clientes."
            VIEW-AS ALERT-BOX ERROR TITLE "Nao foi possivel eliminar".
        RETURN NO-APPLY. 
    END.

    MESSAGE "Tem certeza que deseja eliminar a cidade:" SKIP
            Cidades.NomCidade + " - " + Cidades.CodUF + "?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO TITLE "Eliminar" UPDATE Del.

    IF Del = YES THEN DO:
        DELETE Cidades NO-ERROR.

        GET NEXT qCidades.
        IF NOT AVAILABLE Cidades THEN GET PREV qCidades.
        
        RUN piMostra.
    END.
END.

ON 'choose' OF bt-exp IN FRAME f-cidades DO:
    DEFINE VARIABLE cJsonFile AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cCsvFile  AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE oJsonArray AS JsonArray  NO-UNDO.
    DEFINE VARIABLE oJsonObject AS JsonObject NO-UNDO.

    ASSIGN
        cJsonFile = SESSION:TEMP-DIRECTORY + "Cidades.json"
        cCsvFile  = SESSION:TEMP-DIRECTORY + "Cidades.csv".

    oJsonArray = NEW JsonArray().
    FOR EACH Cidades NO-LOCK:
        oJsonObject = NEW JsonObject().
        oJsonObject:Add("CodCidade", Cidades.CodCidade).
        oJsonObject:Add("NomCidade", Cidades.NomCidade).
        oJsonObject:Add("CodUF",     Cidades.CodUF).
        oJsonArray:Add(oJsonObject).
    END.
    oJsonArray:WriteFile(cJsonFile, TRUE).

    OUTPUT TO VALUE(cCsvFile).
    PUT UNFORMATTED "CodCidade;NomCidade;CodUF" SKIP.

    FOR EACH Cidades NO-LOCK:
        PUT UNFORMATTED
            Cidades.CodCidade ";"
            Cidades.NomCidade ";"
            Cidades.CodUF
            SKIP.
    END.
    OUTPUT CLOSE.

    MESSAGE "Arquivos exportados com sucesso para a pasta temporaria."
        VIEW-AS ALERT-BOX INFORMATION TITLE "Exportacao Concluida".

    OS-COMMAND SILENT VALUE("explorer.exe " + cJsonFile).
    OS-COMMAND SILENT VALUE("explorer.exe " + cCsvFile).
END.


RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
APPLY "choose" TO bt-pri.

WAIT-FOR CLOSE OF THIS-PROCEDURE.


PROCEDURE piMostra:
    IF AVAILABLE cidades THEN 
    DO:
        DISPLAY Cidades.CodCidade Cidades.NomCidade Cidades.CodUF
            WITH FRAME f-cidades.
    END.
    ELSE 
    DO:
            MESSAGE "Nenhum registro para exibir." VIEW-AS ALERT-BOX INFORMATION.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.
    
    IF  AVAILABLE Cidades THEN 
    DO:
        ASSIGN 
            rRecord = ROWID(Cidades).
    END.

    IF QUERY qCidades:IS-OPEN THEN
        CLOSE QUERY qCidades.

    OPEN QUERY qCidades FOR EACH Cidades.
    
    IF rRecord <> ? THEN
        REPOSITION qCidades TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-cidades:
        ASSIGN 
            bt-pri:SENSITIVE  = pEnable
            bt-ant:SENSITIVE  = pEnable
            bt-prox:SENSITIVE = pEnable
            bt-ult:SENSITIVE  = pEnable
            bt-sair:SENSITIVE = pEnable
            bt-add:SENSITIVE  = pEnable
            bt-mod:SENSITIVE  = pEnable
            bt-del:SENSITIVE  = pEnable
            bt-exp:SENSITIVE  = pEnable
            bt-save:SENSITIVE = NOT pEnable
            bt-canc:SENSITIVE = NOT pEnable.
    END.
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-cidades:
        ASSIGN 
            Cidades.NomCidade:SENSITIVE  = pEnable
            Cidades.CodUF:SENSITIVE  = pEnable.
    END.
END PROCEDURE.