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
DEFINE BUTTON bt-consulta-cidades LABEL "Consultar Cidades"SIZE 20 BY 1.3.

DEFINE VARIABLE Action AS CHARACTER NO-UNDO.

DEFINE QUERY qCliente FOR Clientes, Cidades SCROLLING.

DEFINE BUFFER bCliente     FOR clientes.
DEFINE BUFFER bCidade      FOR Cidades.
DEFINE BUFFER bPedidoCheck FOR Pedidos.

DEFINE FRAME f-clientes
    bt-pri
    bt-ant 
    bt-prox 
    bt-ult SPACE(3) 
    bt-add bt-mod bt-del SPACE(3)
    bt-save bt-canc SPACE(3)
    bt-exp
    bt-sair  SKIP(1)
    Clientes.CodCliente COLON 20
    Clientes.NomCliente     COLON 20 
    Clientes.CodEndereco COLON 20
    Clientes.CodCidade COLON 20 Cidades.NomCidade NO-LABELS  
    Clientes.Observacao VIEW-AS EDITOR SIZE 70 BY 2 SCROLLBAR-VERTICAL COLON 20
    SKIP(0.6)
    bt-consulta-cidades AT 10
    WITH SIDE-LABELS THREE-D SIZE 100 BY 13
    VIEW-AS DIALOG-BOX TITLE "Clientes".

ON 'choose' OF bt-pri 
    DO:
        GET FIRST qCliente.
        RUN piMostra.
    END.

ON 'choose' OF bt-ant 
    DO:
        GET PREV qCliente.
        RUN piMostra.
    END.

ON 'choose' OF bt-prox 
    DO:
        GET NEXT qCliente.
        RUN piMostra.
    END.

ON 'choose' OF bt-ult 
    DO:
        GET LAST qCliente.
        RUN piMostra.
    END.

ON 'choose' OF bt-add 
    DO:
        ASSIGN 
            Action = "add".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        CLEAR FRAME f-clientes.
        DISPLAY NEXT-VALUE(seqcliente) @ Clientes.CodCliente WITH FRAME f-clientes. 
        ASSIGN 
            Clientes.Observacao:SCREEN-VALUE                  = ""
            bt-consulta-cidades:VISIBLE   IN FRAME f-clientes = TRUE
            bt-consulta-cidades:SENSITIVE IN FRAME f-clientes = TRUE.
    END.

ON 'choose' OF bt-mod 
    DO:
        ASSIGN 
            Action = "mod".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        DISPLAY Clientes.CodCliente WITH FRAME f-clientes.
        RUN piMostra.
        ASSIGN 
            bt-consulta-cidades:VISIBLE   IN FRAME f-clientes = TRUE
            bt-consulta-cidades:SENSITIVE IN FRAME f-clientes = TRUE.
    END.
    
ON 'choose' OF bt-del IN FRAME f-clientes 
    DO:
        DEFINE VARIABLE lConfirma AS LOGICAL NO-UNDO.

        IF CAN-FIND(FIRST bPedidoCheck WHERE bPedidoCheck.CodCliente = Clientes.CodCliente) THEN 
        DO:
            MESSAGE "Este cliente nao pode ser eliminado pois esta sendo utilizado em um ou mais pedidos."
                VIEW-AS ALERT-BOX ERROR TITLE "Nao foi possivel eliminar".
            RETURN NO-APPLY. 
        END.

        MESSAGE "Tem certeza que deseja eliminar o cliente:" SKIP
            Clientes.NomCliente + "?"
            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO
            UPDATE lConfirma.

        IF lConfirma = YES THEN 
        DO:
            DELETE Clientes NO-ERROR.

            GET NEXT qCliente.
            IF NOT AVAILABLE Clientes THEN GET PREV qCliente.
        
            RUN piMostra.
        END.
    END.

ON 'choose' OF bt-exp IN FRAME f-clientes 
    DO:
        DEFINE VARIABLE cJsonFile   AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE cCsvFile    AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE oJsonArray  AS JsonArray  NO-UNDO.
        DEFINE VARIABLE oJsonObject AS JsonObject NO-UNDO.

        ASSIGN
            cJsonFile = SESSION:TEMP-DIRECTORY + "Clientes.json"
            cCsvFile  = SESSION:TEMP-DIRECTORY + "Clientes.csv".

        oJsonArray = NEW JsonArray().
        FOR EACH Clientes NO-LOCK, FIRST Cidades WHERE Cidades.CodCidade = Clientes.CodCidade NO-LOCK:
            oJsonObject = NEW JsonObject().
            oJsonObject:Add("CodCliente",   Clientes.CodCliente).
            oJsonObject:Add("NomCliente",   Clientes.NomCliente).
            oJsonObject:Add("CodEndereco",  Clientes.CodEndereco).
            oJsonObject:Add("CodCidade",    Clientes.CodCidade).
            oJsonObject:Add("NomCidade",    (IF AVAILABLE Cidades THEN Cidades.NomCidade ELSE "")).
            oJsonObject:Add("Observacao",   Clientes.Observacao).
            oJsonArray:Add(oJsonObject).
        END.
        oJsonArray:WriteFile(cJsonFile, TRUE).

        OUTPUT TO VALUE(cCsvFile).
        PUT UNFORMATTED 
            "CodCliente;NomCliente;CodEndereco;CodCidade;NomCidade;Observacao" SKIP.
        FOR EACH Clientes NO-LOCK, FIRST Cidades WHERE Cidades.CodCidade = Clientes.CodCidade NO-LOCK:
            PUT UNFORMATTED
                Clientes.CodCliente   ";"
                Clientes.NomCliente   ";"
                Clientes.CodEndereco  ";"
                Clientes.CodCidade    ";"
                (IF AVAILABLE Cidades THEN Cidades.NomCidade ELSE "") ";"
                Clientes.Observacao
                SKIP.
        END.
        OUTPUT CLOSE.

        MESSAGE "Arquivos exportados com sucesso para a pasta temporaria."
            VIEW-AS ALERT-BOX INFORMATION TITLE "Exportacao Concluida".
    
        OS-COMMAND SILENT VALUE("explorer.exe " + cJsonFile).
        OS-COMMAND SILENT VALUE("explorer.exe " + cCsvFile).
    END.

ON 'leave' OF Clientes.CodCidade
    DO:
        DEFINE VARIABLE lValid AS LOGICAL NO-UNDO.
        RUN piValidaCidades (INPUT Clientes.CodCidade:SCREEN-VALUE, 
            OUTPUT lValid).
        IF  lValid = NO THEN 
        DO:
            RETURN NO-APPLY.
        END.
        DISPLAY bcidade.NomCidade @ Cidades.NomCidade WITH FRAME f-Clientes.
    END.

ON 'choose' OF bt-save 
    DO:
        DEFINE VARIABLE lValid AS LOGICAL NO-UNDO.

        RUN piValidaCidades (INPUT Clientes.CodCidade:SCREEN-VALUE, 
            OUTPUT lValid).
        IF  lValid = NO THEN 
        DO:
            RETURN NO-APPLY.
        END.

        IF Action = "add" THEN 
        DO:
            CREATE bCliente.
            ASSIGN 
                bCliente.CodCliente = INPUT Clientes.CodCliente.
        END.
        IF  Action = "mod" THEN 
        DO:
            FIND FIRST bCliente 
                WHERE bCliente.CodCliente = Clientes.CodCliente
                EXCLUSIVE-LOCK NO-ERROR.
        END.
    
        ASSIGN 
            bCliente.NomCliente  = INPUT Clientes.NomCliente
            bCliente.CodEndereco = INPUT Clientes.CodEndereco
            bCliente.CodCidade   = INPUT Clientes.CodCidade
            bCliente.Observacao  = INPUT Clientes.Observacao.

        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piOpenQuery.
        ASSIGN 
            bt-consulta-cidades:VISIBLE   IN FRAME f-clientes = FALSE
            bt-consulta-cidades:SENSITIVE IN FRAME f-clientes = FALSE.
    END.

ON 'choose' OF bt-canc 
    DO:
        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piMostra.
        ASSIGN 
            bt-consulta-cidades:VISIBLE   IN FRAME f-clientes = FALSE
            bt-consulta-cidades:SENSITIVE IN FRAME f-clientes = FALSE.
    END.

ON 'choose' OF bt-consulta-cidades 
    DO:
        DEFINE QUERY qConsulta FOR Cidades SCROLLING.
        DEFINE BROWSE br-cidades QUERY qConsulta
            DISPLAY Cidades.CodCidade Cidades.NomCidade
        WITH 10 DOWN TITLE "Consulta de Cidades".
    
        DEFINE FRAME f-consulta
            br-cidades
            WITH VIEW-AS DIALOG-BOX TITLE "Consulta".

        ON WINDOW-CLOSE OF FRAME f-consulta 
            DO:
                APPLY "CLOSE" TO FRAME f-consulta.
            END.

        OPEN QUERY qConsulta FOR EACH Cidades.
        ENABLE br-cidades WITH FRAME f-consulta.
    
        WAIT-FOR CLOSE OF FRAME f-consulta.
    END.


RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
ASSIGN 
    bt-consulta-cidades:VISIBLE   IN FRAME f-clientes = FALSE
    bt-consulta-cidades:SENSITIVE IN FRAME f-clientes = FALSE.
APPLY "choose" TO bt-pri.

WAIT-FOR WINDOW-CLOSE OF FRAME f-clientes.

PROCEDURE piMostra:
    IF AVAILABLE clientes THEN 
    DO:
        DISPLAY Clientes.CodCliente Clientes.NomCliente Clientes.CodEndereco Clientes.CodCidade Cidades.NomCidade Clientes.Observacao
            WITH FRAME f-clientes.
    END.
    ELSE 
    DO:
        MESSAGE "Nenhum registro para exibir." VIEW-AS ALERT-BOX INFORMATION.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.
    
    IF  AVAILABLE Clientes THEN 
    DO:
        ASSIGN 
            rRecord = ROWID(Clientes).
    END.
    
    IF QUERY qCliente:IS-OPEN THEN
        CLOSE QUERY qCliente.

    OPEN QUERY qCliente 
        FOR EACH Clientes, 
        FIRST Cidades WHERE Cidades.CodCidade = Clientes.CodCidade.

    REPOSITION qCliente TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-clientes:
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

    DO WITH FRAME f-clientes:
        ASSIGN 
            Clientes.NomCliente:SENSITIVE  = pEnable
            Clientes.CodEndereco:SENSITIVE = pEnable
            Clientes.CodCidade:SENSITIVE   = pEnable
            Clientes.Observacao:SENSITIVE  = pEnable.
    END.
END PROCEDURE.

PROCEDURE piValidaCidades:
    DEFINE INPUT PARAMETER pCidades AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER pValid AS LOGICAL NO-UNDO INITIAL NO.
    
    FIND FIRST bCidade
        WHERE bCidade.CodCidade = pCidades
        NO-LOCK NO-ERROR.
    IF  NOT AVAILABLE bCidade THEN 
    DO:
        MESSAGE "Codigo da Cidade" pCidades "nao existe!"
            VIEW-AS ALERT-BOX ERROR.
        ASSIGN 
            pValid = NO.
    END.
    ELSE 
        ASSIGN pValid = YES.
END PROCEDURE.