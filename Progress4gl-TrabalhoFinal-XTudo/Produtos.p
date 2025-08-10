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

DEFINE QUERY qProdutos FOR Produtos SCROLLING.

DEFINE BUFFER bProduto  FOR Produtos.

DEFINE FRAME f-produtos
    bt-pri
    bt-ant 
    bt-prox 
    bt-ult SPACE(3) 
    bt-add bt-mod bt-del SPACE(3)
    bt-save bt-canc SPACE(3)
    bt-exp
    bt-sair  SKIP(1)
    Produtos.CodProduto COLON 20
    Produtos.NomProduto COLON 20 
    Produtos.ValProduto COLON 20
    WITH SIDE-LABELS THREE-D SIZE 100 BY 9
    VIEW-AS DIALOG-BOX TITLE "Produtos".

ON 'choose' OF bt-pri 
    DO:
        GET FIRST qProdutos.
        RUN piMostra.
    END.

ON 'choose' OF bt-ant 
    DO:
        GET PREV qProdutos.
        RUN piMostra.
    END.

ON 'choose' OF bt-prox 
    DO:
        GET NEXT qProdutos.
        RUN piMostra.
    END.

ON 'choose' OF bt-ult 
    DO:
        GET LAST qProdutos.
        RUN piMostra.
    END.

ON 'choose' OF bt-add 
    DO:
        ASSIGN 
            Action = "add".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        CLEAR FRAME f-produtos.
        DISPLAY NEXT-VALUE(seqproduto) @ Produtos.CodProduto WITH FRAME f-produtos. 
    END.

ON 'choose' OF bt-mod 
    DO:
        ASSIGN 
            Action = "mod".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        DISPLAY Produtos.CodProduto WITH FRAME f-produtos.
        RUN piMostra.
    END.
    
ON 'choose' OF bt-del IN FRAME f-produtos DO:
    DEFINE VARIABLE lConfirma AS LOGICAL NO-UNDO.

    IF CAN-FIND(FIRST Itens WHERE Itens.CodProduto = Produtos.CodProduto) THEN DO:
        MESSAGE "Este produto nao pode ser eliminado pois esta sendo utilizado em um ou mais pedidos."
            VIEW-AS ALERT-BOX ERROR TITLE "Nao foi possivel eliminar".
        RETURN NO-APPLY. 
    END.

    MESSAGE "Tem certeza que deseja eliminar o produto:" SKIP
            Produtos.NomProduto + "?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO
        UPDATE lConfirma.

    IF lConfirma = YES THEN DO:
        DELETE Produtos NO-ERROR.

        GET NEXT qProdutos.
        IF NOT AVAILABLE Produtos THEN GET PREV qProdutos.
        
        RUN piMostra.
    END.
END.

ON 'choose' OF bt-exp IN FRAME f-produtos DO:
    DEFINE VARIABLE cJsonFile   AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cCsvFile    AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE oJsonArray  AS JsonArray  NO-UNDO.
    DEFINE VARIABLE oJsonObject AS JsonObject NO-UNDO.

    ASSIGN
        cJsonFile = SESSION:TEMP-DIRECTORY + "Produtos.json"
        cCsvFile  = SESSION:TEMP-DIRECTORY + "Produtos.csv".

    oJsonArray = NEW JsonArray().
    FOR EACH Produtos NO-LOCK:
        oJsonObject = NEW JsonObject().
        oJsonObject:Add("CodProduto", Produtos.CodProduto).
        oJsonObject:Add("NomProduto", Produtos.NomProduto).
        oJsonObject:Add("ValProduto", Produtos.ValProduto).
        oJsonArray:Add(oJsonObject).
    END.
    oJsonArray:WriteFile(cJsonFile, TRUE).

    OUTPUT TO VALUE(cCsvFile).
    PUT UNFORMATTED "CodProduto;NomProduto;ValProduto" SKIP.
    FOR EACH Produtos NO-LOCK:
        PUT UNFORMATTED
            Produtos.CodProduto ";"
            Produtos.NomProduto ";"
            Produtos.ValProduto
            SKIP.
    END.
    OUTPUT CLOSE.

    MESSAGE "Arquivos exportados com sucesso para a pasta temporaria."
        VIEW-AS ALERT-BOX INFORMATION TITLE "Exportacao Concluida".
    
    OS-COMMAND SILENT VALUE("explorer.exe " + cJsonFile).
    OS-COMMAND SILENT VALUE("explorer.exe " + cCsvFile).
END.

ON 'choose' OF bt-save 
    DO:
        IF Action = "add" THEN 
        DO:
            CREATE bProduto.
            ASSIGN 
                bProduto.CodProduto = INPUT Produtos.CodProduto.
        END.
        IF  Action = "mod" THEN 
        DO:
            FIND FIRST bProduto 
                WHERE bProduto.CodProduto = Produtos.CodProduto
                EXCLUSIVE-LOCK NO-ERROR.
        END.
    
        ASSIGN 
            bProduto.NomProduto = INPUT Produtos.NomProduto
            bProduto.ValProduto = INPUT Produtos.ValProduto.

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
    
RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
APPLY "choose" TO bt-pri.

WAIT-FOR CLOSE OF THIS-PROCEDURE.


PROCEDURE piMostra:
    IF AVAILABLE Produtos THEN 
    DO:
        DISPLAY Produtos.CodProduto Produtos.NomProduto Produtos.ValProduto
            WITH FRAME f-produtos.
    END.
    ELSE 
    DO:
            MESSAGE "Nenhum registro para exibir." VIEW-AS ALERT-BOX INFORMATION.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.
    
    IF  AVAILABLE Produtos THEN 
    DO:
        ASSIGN 
            rRecord = ROWID(Produtos).
    END.

    IF QUERY qProdutos:IS-OPEN THEN
        CLOSE QUERY qProdutos.

    OPEN QUERY qProdutos FOR EACH Produtos.
    
    IF rRecord <> ? THEN
        REPOSITION qProdutos TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-produtos:
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

    DO WITH FRAME f-produtos:
        ASSIGN 
            Produtos.NomProduto:SENSITIVE  = pEnable
            Produtos.ValProduto:SENSITIVE  = pEnable.
    END.
END PROCEDURE.
