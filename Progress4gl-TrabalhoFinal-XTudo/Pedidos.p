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
DEFINE BUTTON bt-consulta-clientes LABEL "Consultar Clientes".
DEFINE BUTTON bt-add-item    LABEL "Adicionar Item".
DEFINE BUTTON bt-mod-item    LABEL "Modificar Item".
DEFINE BUTTON bt-del-item    LABEL "Eliminar Item".

DEFINE VARIABLE Action AS CHARACTER NO-UNDO.
DEFINE VARIABLE DEL AS LOGICAL      NO-UNDO.

DEFINE QUERY qPedido FOR Pedidos, Clientes, Cidades SCROLLING.
DEFINE QUERY qItens FOR Itens, Produtos SCROLLING.

DEFINE BUFFER bCliente FOR Clientes.
DEFINE BUFFER bPedido  FOR Pedidos.
DEFINE BUFFER bCidade  FOR Cidades.
DEFINE BUFFER bItem FOR Itens.

DEFINE BROWSE B-itens QUERY qItens  NO-LOCK
    DISPLAY
        Itens.CodItem LABEL "Item"
        Itens.CodProduto LABEL "C�digo"
        Produtos.NomProduto LABEL "Produto" FORMAT "x(25)"
        Itens.NumQuantidade LABEL "Quantidade"
        Produtos.ValProduto LABEL "Valor"
        Itens.ValTotal LABEL "Total" 
    WITH SEPARATORS 8 DOWN SIZE 86 BY 8.

DEFINE FRAME f-Pedidos 
    bt-pri bt-ant bt-prox bt-ult SPACE(2) bt-add bt-mod bt-del SPACE(2) bt-save bt-canc SPACE(2) bt-exp bt-sair
    SKIP(1)
    Pedidos.CodPedido COLON 20 Pedidos.DatPedido 
    Pedidos.CodCliente COLON 20 Clientes.NomCliente NO-LABELS bt-consulta-clientes
    Clientes.CodEndereco COLON 20
    Clientes.CodCidade COLON 20 Cidades.NomCidade NO-LABELS
    Pedidos.Observacao VIEW-AS EDITOR SIZE 70 BY 2 SCROLLBAR-VERTICAL COLON 20
    SKIP(1)
    B-itens COLON 5
    SKIP(0.5)
    bt-add-item COLON 5 bt-mod-item bt-del-item
    WITH SIDE-LABELS THREE-D SIZE 100 BY 21
    VIEW-AS DIALOG-BOX TITLE "Pedidos".
    
ON 'CHOOSE' OF bt-add-item
DO:
    RUN Cad-itens.p (INPUT pedidos.CodPedido, INPUT 0, INPUT 0).
    RUN piAbreQueryItens.
END.

ON 'Choose' OF bt-mod-item 
DO:
    RUN Cad-itens.p (INPUT pedidos.CodPedido, INPUT 1, INPUT itens.codItem).
    RUN piAbreQueryItens.
    
END.

ON 'choose' OF bt-del-item 
DO:
    MESSAGE "Tem certeza que deseja eliminar o pedido:" SKIP
            STRING(ITEns.coditem) + "?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO TITLE "Eliminar" UPDATE Del.
        IF DEL = YES THEN
        DO:
    FIND FIRST bitem WHERE bitem.coditem = ITEns.coditem AND bitem.codpedido = itens.codpedido.
    DELETE bitem.
    RUN piAbrequeryitens.
    END.
END.
    
ON 'choose' OF bt-pri 
    DO:
        GET FIRST qPedido.
        RUN piMostra.
    END.

ON 'choose' OF bt-ant 
    DO:
        GET PREV qPedido.
        RUN piMostra.
    END.

ON 'choose' OF bt-prox 
    DO:
        GET NEXT qPedido.
        RUN piMostra.
    END.

ON 'choose' OF bt-ult 
    DO:
        GET LAST qPedido.
        RUN piMostra.
    END.

ON 'choose' OF bt-add 
    DO:
        ASSIGN 
            Action = "add".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        CLEAR FRAME f-pedidos.
        DISPLAY NEXT-VALUE(seqPedido) @ Pedidos.CodPedido WITH FRAME f-pedidos. 
        ASSIGN 
            Pedidos.Observacao:SCREEN-VALUE = ""
            bt-consulta-clientes:VISIBLE   IN FRAME f-Pedidos = TRUE
            bt-consulta-clientes:SENSITIVE IN FRAME f-Pedidos = TRUE.
    END.

ON 'choose' OF bt-mod 
    DO:
        ASSIGN 
            Action = "mod".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
    
        DISPLAY Pedidos.CodPedido WITH FRAME f-pedidos.
        RUN piMostra.
        ASSIGN
            bt-consulta-clientes:VISIBLE   IN FRAME f-pedidos = TRUE
            bt-consulta-clientes:SENSITIVE IN FRAME f-pedidos = TRUE.
    END.
    
ON 'choose' OF bt-del IN FRAME f-Pedidos DO:
    DEFINE VARIABLE lConfirma AS LOGICAL NO-UNDO.

    IF NOT AVAILABLE Pedidos THEN RETURN.

    MESSAGE "Confirma a exclusao do Pedido" Pedidos.CodPedido "e de TODOS os seus itens?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO
        UPDATE lConfirma.

    IF lConfirma = YES THEN DO:
        FOR EACH bItem WHERE bItem.CodPedido = Pedidos.CodPedido EXCLUSIVE-LOCK:
            DELETE bItem.
        END.

        DELETE Pedidos.

        GET NEXT qPedido.
        IF NOT AVAILABLE Pedidos THEN GET PREV qPedido.
        RUN piMostra.
    END.
END.

ON 'choose' OF bt-exp IN FRAME f-Pedidos DO:
    DEFINE VARIABLE cJsonFile    AS CHARACTER    NO-UNDO.
    DEFINE VARIABLE cCsvFile     AS CHARACTER    NO-UNDO.
    DEFINE VARIABLE oPedidosArray AS JsonArray    NO-UNDO.
    DEFINE VARIABLE oPedidoObject AS JsonObject   NO-UNDO.
    DEFINE VARIABLE oItensArray   AS JsonArray    NO-UNDO.
    DEFINE VARIABLE oItemObject   AS JsonObject   NO-UNDO.

    ASSIGN
        cJsonFile = SESSION:TEMP-DIRECTORY + "Pedidos.json"
        cCsvFile  = SESSION:TEMP-DIRECTORY + "Pedidos.csv".

    oPedidosArray = NEW JsonArray().
    FOR EACH Pedidos NO-LOCK,
        FIRST Clientes WHERE Clientes.CodCliente = Pedidos.CodCliente NO-LOCK,
        FIRST Cidades WHERE Cidades.CodCidade = Clientes.CodCidade NO-LOCK:
        
        oPedidoObject = NEW JsonObject().
        oPedidoObject:Add("CodPedido",   Pedidos.CodPedido).
        oPedidoObject:Add("DatPedido",   Pedidos.DatPedido).
        oPedidoObject:Add("CodCliente",  Pedidos.CodCliente).
        oPedidoObject:Add("NomCliente",  (IF AVAILABLE Clientes THEN Clientes.NomCliente ELSE "")).
        oPedidoObject:Add("Endereco",    (IF AVAILABLE Clientes THEN Clientes.CodEndereco ELSE "")).
        oPedidoObject:Add("Cidade",      (IF AVAILABLE Cidades THEN Cidades.NomCidade ELSE "")).
        oPedidoObject:Add("Observacao",  Pedidos.Observacao).
        
        oItensArray = NEW JsonArray().
        FOR EACH Itens WHERE Itens.CodPedido = Pedidos.CodPedido NO-LOCK,
            FIRST Produtos WHERE Produtos.CodProduto = Itens.CodProduto NO-LOCK:
            
            oItemObject = NEW JsonObject().
            oItemObject:Add("CodItem",       Itens.CodItem).
            oItemObject:Add("CodProduto",    Itens.CodProduto).
            oItemObject:Add("NomProduto",    (IF AVAILABLE Produtos THEN Produtos.NomProduto ELSE "")).
            oItemObject:Add("NumQuantidade", Itens.NumQuantidade).
            oItemObject:Add("ValProduto",    (IF AVAILABLE Produtos THEN Produtos.ValProduto ELSE 0)).
            oItemObject:Add("ValTotal",      Itens.ValTotal).
            oItensArray:Add(oItemObject).
        END.
        oPedidoObject:Add("Itens", oItensArray).
        oPedidosArray:Add(oPedidoObject).
    END.
    oPedidosArray:WriteFile(cJsonFile, TRUE).
    
    OUTPUT TO VALUE(cCsvFile).
    PUT UNFORMATTED "CodPedido;DatPedido;CodCliente;NomCliente;CodItem;CodProduto;NomProduto;NumQuantidade;ValTotal" SKIP.
    FOR EACH Pedidos NO-LOCK,
        FIRST Clientes WHERE Clientes.CodCliente = Pedidos.CodCliente NO-LOCK,
        EACH Itens WHERE Itens.CodPedido = Pedidos.CodPedido NO-LOCK,
        FIRST Produtos WHERE Produtos.CodProduto = Itens.CodProduto NO-LOCK:
        
        PUT UNFORMATTED
            Pedidos.CodPedido    ";"
            Pedidos.DatPedido    ";"
            Pedidos.CodCliente   ";"
            (IF AVAILABLE Clientes THEN Clientes.NomCliente ELSE "") ";"
            Itens.CodItem        ";"
            Itens.CodProduto     ";"
            (IF AVAILABLE Produtos THEN Produtos.NomProduto ELSE "") ";"
            Itens.NumQuantidade  ";"
            Itens.ValTotal
            SKIP.
    END.
    OUTPUT CLOSE.

    MESSAGE "Arquivos exportados com sucesso para a pasta temporaria."
        VIEW-AS ALERT-BOX INFORMATION TITLE "Exportacao Concluida".
        
    OS-COMMAND SILENT VALUE("explorer.exe " + cJsonFile).
    OS-COMMAND SILENT VALUE("explorer.exe " + cCsvFile).
END.

ON 'leave' OF Pedidos.CodCliente
    DO:
        DEFINE VARIABLE lValid AS LOGICAL NO-UNDO.
        RUN piValidaClientes (INPUT Pedidos.CodCliente:SCREEN-VALUE, 
            OUTPUT lValid).
        IF  lValid = NO THEN 
        DO:
            ASSIGN
                Pedidos.CodCliente:SCREEN-VALUE   IN FRAME f-pedidos = ""
                Clientes.NomCliente:SCREEN-VALUE  IN FRAME f-pedidos = ""                
                Clientes.CodEndereco:SCREEN-VALUE IN FRAME f-pedidos = ""
                Clientes.CodCidade:SCREEN-VALUE   IN FRAME f-pedidos = ""
                Cidades.NomCidade:SCREEN-VALUE    IN FRAME f-pedidos = "".
            RETURN NO-APPLY.
        END.
        
        FIND FIRST bCidade WHERE bCidade.CodCidade = bCliente.CodCidade NO-LOCK NO-ERROR.

        ASSIGN
            Clientes.NomCliente:SCREEN-VALUE  IN FRAME f-pedidos = bCliente.NomCliente
            Clientes.CodEndereco:SCREEN-VALUE IN FRAME f-pedidos = bCliente.CodEndereco
            Clientes.CodCidade:SCREEN-VALUE   IN FRAME f-pedidos = STRING(bCliente.CodCidade)
            Cidades.NomCidade:SCREEN-VALUE    IN FRAME f-pedidos = (IF AVAILABLE bCidade THEN bCidade.NomCidade ELSE "").
    END.

ON 'choose' OF bt-save 
    DO:
        DEFINE VARIABLE lValid AS LOGICAL NO-UNDO.

        RUN piValidaClientes (INPUT Pedidos.CodCliente:SCREEN-VALUE, 
            OUTPUT lValid).
        IF  lValid = NO THEN 
        DO:
            RETURN NO-APPLY.
        END.

        IF Action = "add" THEN 
        DO:
            CREATE bPedido.
            ASSIGN 
                bPedido.CodPedido    = Pedidos.CodPedido:INPUT-VALUE
                bPedido.DatPedido    = Pedidos.DatPedido:INPUT-VALUE
                bPedido.CodCliente   = Pedidos.CodCliente:INPUT-VALUE
                bPedido.Observacao   = Pedidos.Observacao:SCREEN-VALUE.
        END.
        IF  Action = "mod" THEN 
        DO:
            GET CURRENT qPedido EXCLUSIVE-LOCK.
            IF AVAILABLE Pedidos THEN DO:
                ASSIGN 
                    Pedidos.DatPedido    = Pedidos.DatPedido:INPUT-VALUE
                    Pedidos.CodCliente   = Pedidos.CodCliente:INPUT-VALUE
                    Pedidos.Observacao   = Pedidos.Observacao:SCREEN-VALUE.
                RELEASE Pedidos.
            END.
        END.
    
        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piOpenQuery.
        ASSIGN
            bt-consulta-clientes:VISIBLE   IN FRAME f-pedidos = FALSE
            bt-consulta-clientes:SENSITIVE IN FRAME f-pedidos = FALSE.
    END.

ON 'choose' OF bt-canc 
    DO:
        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piMostra.
        ASSIGN  
            bt-consulta-clientes:VISIBLE   IN FRAME f-pedidos = FALSE
            bt-consulta-clientes:SENSITIVE IN FRAME f-pedidos = FALSE.
    END.

ON 'choose' OF bt-consulta-clientes IN FRAME f-pedidos DO:
    DEFINE QUERY qConsulta FOR Clientes SCROLLING.
    DEFINE BROWSE br-clientes QUERY qConsulta
        DISPLAY Clientes.CodCliente Clientes.NomCliente
        WITH 10 DOWN TITLE "Consulta de Clientes".
    
    DEFINE FRAME f-consulta
        br-clientes
        WITH VIEW-AS DIALOG-BOX TITLE "Consulta".

    ON WINDOW-CLOSE OF FRAME f-consulta DO:
        APPLY "CLOSE" TO FRAME f-consulta.
    END.

    OPEN QUERY qConsulta FOR EACH Clientes.
    ENABLE br-clientes WITH FRAME f-consulta.
    
    WAIT-FOR CLOSE OF FRAME f-consulta.
END. 


RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
ASSIGN  
    bt-consulta-clientes:VISIBLE   IN FRAME f-pedidos = FALSE
    bt-consulta-clientes:SENSITIVE IN FRAME f-pedidos = FALSE.
APPLY "choose" TO bt-pri.

WAIT-FOR WINDOW-CLOSE OF FRAME f-pedidos.

PROCEDURE piMostra:
    IF AVAILABLE Pedidos THEN 
    DO:
        DISPLAY Pedidos.CodPedido Pedidos.DatPedido Pedidos.CodCliente Clientes.NomCliente Clientes.CodEndereco Clientes.CodCidade Cidades.NomCidade Pedidos.Observacao
            WITH FRAME f-pedidos.
        
        RUN piAbreQueryItens.
    END.
    ELSE 
    DO:
        MESSAGE "Nenhum registro para exibir." VIEW-AS ALERT-BOX INFORMATION.
        CLEAR FRAME f-pedidos.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.
    
    IF  AVAILABLE Pedidos THEN 
    DO:
        ASSIGN 
            rRecord = ROWID(Pedidos).
    END.
    
    IF QUERY qPedido:IS-OPEN THEN
        CLOSE QUERY qPedido.

    OPEN QUERY qPedido 
        FOR EACH Pedidos, 
        FIRST Clientes WHERE Clientes.CodCliente = Pedidos.CodCliente,
        FIRST Cidades  WHERE Cidades.CodCidade  = Clientes.CodCidade.

    REPOSITION qPedido TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-pedidos:
        ASSIGN 
            bt-pri:SENSITIVE      = pEnable
            bt-ant:SENSITIVE      = pEnable
            bt-prox:SENSITIVE     = pEnable
            bt-ult:SENSITIVE      = pEnable
            bt-sair:SENSITIVE     = pEnable
            bt-add:SENSITIVE      = pEnable
            bt-mod:SENSITIVE      = pEnable
            bt-del:SENSITIVE      = pEnable
            bt-exp:SENSITIVE      = pEnable
            bt-save:SENSITIVE     = NOT pEnable
            bt-canc:SENSITIVE     = NOT pEnable
            B-ITENS:SENSITIVE     = pEnable
            bt-add-item:SENSITIVE = pEnable
            bt-mod-item:SENSITIVE = pEnable
            bt-del-item:SENSITIVE = pEnable.
    END.
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-pedidos:
        ASSIGN 
            Pedidos.DatPedido:SENSITIVE  = pEnable
            Pedidos.CodCliente:SENSITIVE = pEnable
            Pedidos.Observacao:SENSITIVE = pEnable.
    END.
END PROCEDURE.

PROCEDURE piValidaClientes:
    DEFINE INPUT PARAMETER pClientes AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER pValid AS LOGICAL NO-UNDO INITIAL NO.
    
    FIND FIRST bCliente
        WHERE bCliente.CodCliente = pClientes
        NO-LOCK NO-ERROR.
    IF  NOT AVAILABLE bCliente THEN 
    DO:
        MESSAGE "Codigo do Cliente" pClientes "nao existe!"
            VIEW-AS ALERT-BOX ERROR.
        ASSIGN 
            pValid = NO.
    END.
    ELSE 
        ASSIGN pValid = YES.
END PROCEDURE.

PROCEDURE piAbreQueryItens:
    IF QUERY qItens:IS-OPEN THEN
        CLOSE QUERY qItens.
    
    OPEN QUERY qItens FOR EACH Itens NO-LOCK WHERE Itens.CodPedido = Pedidos.CodPedido,
                         FIRST Produtos NO-LOCK WHERE Produtos.CodProduto = Itens.CodProduto.
END PROCEDURE.