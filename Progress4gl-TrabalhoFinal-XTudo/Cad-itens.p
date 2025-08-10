DEFINE BUTTON bt-salv LABEL "Salvar" AUTO-ENDKEY. 
DEFINE BUTTON bt-cancel LABEL "Cancelar" AUTO-ENDKEY.
DEFINE BUTTON bt-consulta-produtos   LABEL "Consultar Produtos".
DEFINE INPUT PARAMETER cPedido AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER cPedidomod AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER I-Coditem AS INTEGER     NO-UNDO.

DEFINE VARIABLE cSequencia AS INTEGER   NO-UNDO.

DEFINE BUFFER bProduto FOR Produtos.
DEFINE BUFFER bItem FOR Itens.

DEFINE FRAME f-itens
     Produtos.CodProduto Produtos.NomProduto NO-LABELS
     SKIP(0.3)
     Itens.NumQuantidade bt-consulta-produtos
     SKIP(0.3)
     Itens.ValTotal
     SKIP(0.3)
     bt-salv
     bt-cancel
     WITH SIDE-LABELS THREE-D SIZE 70 BY 8
     VIEW-AS DIALOG-BOX TITLE "Itens".
  RUN piMostra.
  
ON 'leave' OF Itens.NumQuantidade
    DO:
            FIND FIRST bProduto WHERE bProduto.CodProduto = INPUT produtos.codproduto.
            ASSIGN
            Itens.ValTotal:SCREEN-VALUE = STRING(INPUT itens.NumQuantidade * bProduto.ValProduto).
    END. 
ON 'leave' OF Produtos.CodProduto
    DO:
        DEFINE VARIABLE lValid AS LOGICAL NO-UNDO.
        RUN piValidaProduto (INPUT Produtos.CodProduto:SCREEN-VALUE, 
            OUTPUT lValid).
        IF  lValid = NO THEN 
        DO:
            ASSIGN
                Produtos.NomProduto:SCREEN-VALUE IN FRAME f-itens = ""
                Itens.ValTotal:SCREEN-VALUE IN FRAME f-itens = "".
            RETURN NO-APPLY.
        END.
            ASSIGN
            Produtos.NomProduto:SCREEN-VALUE = bProduto.NomProduto.
    END.   
 
ON 'CHOOSE' OF bt-consulta-produtos IN FRAME f-itens DO:
    DEFINE QUERY qConsulta FOR Produtos SCROLLING.
    DEFINE BROWSE br-produtos QUERY qConsulta
        DISPLAY Produtos.CodProduto Produtos.NomProduto
        WITH 10 DOWN TITLE "Consulta de Produtos".
    
    DEFINE FRAME f-consulta br-produtos WITH VIEW-AS DIALOG-BOX TITLE "Consulta".

    ON WINDOW-CLOSE OF FRAME f-consulta DO:
        APPLY "CLOSE" TO FRAME f-consulta.
    END.

    OPEN QUERY qConsulta FOR EACH Produtos.
    ENABLE br-produtos WITH FRAME f-consulta.
    
    WAIT-FOR CLOSE OF FRAME f-consulta.
END. 
   
ON 'CHOOSE' OF bt-salv 
DO:
    IF cpedidomod = 0 THEN
    DO:
         FIND LAST itens 
        WHERE itens.CodPedido = cPedido NO-ERROR.
    IF AVAIL itens THEN DO:

        ASSIGN cSequencia = itens.CodItem + 1.
        END.
        ELSE
        ASSIGN cSequencia = 0.
    CREATE bItem.
            ASSIGN 
                bitem.CodItem = cSequencia
                bitem.CodPedido = cPedido.
    END.
    IF Cpedidomod = 1 THEN
    DO:
        FIND FIRST bitem WHERE bitem.coditem = i-coditem  AND bitem.codpedido = cpedido.
    END.
    ASSIGN 
                bitem.CodProduto = bProduto.codProduto
                bitem.NumQuantidade = INPUT itens.NumQuantidade
                bitem.ValTotal = INPUT itens.NumQuantidade * bProduto.ValProduto.
END.
   
RUN piHabilitaBotoes (INPUT TRUE). 
    WAIT-FOR CLOSE OF FRAME f-itens.
    
PROCEDURE piValidaProduto:
    DEFINE INPUT PARAMETER pProduto AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER pValid AS LOGICAL NO-UNDO INITIAL NO.
    
    FIND FIRST bProduto
        WHERE bProduto.CodProduto = pProduto
        NO-LOCK NO-ERROR.
    IF  NOT AVAILABLE bProduto THEN 
    DO:
        MESSAGE "Codigo do Produto" pProduto "nao existe!"
            VIEW-AS ALERT-BOX ERROR.
        ASSIGN 
            pValid = NO.
    END.
    ELSE 
        ASSIGN pValid = YES.
        
END PROCEDURE.

PROCEDURE piMostra:
    IF cPedidomod = 0 THEN
    DO:
       DISPLAY
    "" @ Produtos.CodProduto 
    "" @ Produtos.NomProduto 
    "" @ itens.NumQuantidade 
    "" @ itens.ValTotal
     WITH FRAME f-itens. 
    END.
    ELSE DO:
        FIND FIRST Itens WHERE itens.CodItem = i-coditem AND itens.CodPedido = CPedido.
        FIND FIRST Produtos WHERE Produtos.Codproduto = itens.codproduto.
        DISPLAY
    Produtos.CodProduto 
    Produtos.NomProduto 
    itens.NumQuantidade 
    itens.ValTotal
     WITH FRAME f-itens. 
    END.
END PROCEDURE.    

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-itens:
        ASSIGN 
            bt-salv:SENSITIVE = pEnable
            bt-cancel:SENSITIVE = pEnable
            bt-consulta-produtos:SENSITIVE = pEnable
            Produtos.CodProduto:SENSITIVE = pEnable
            Itens.NumQuantidade:SENSITIVE = pEnable.
    END.               
END PROCEDURE.
