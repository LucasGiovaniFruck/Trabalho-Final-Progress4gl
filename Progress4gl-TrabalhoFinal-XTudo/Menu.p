CURRENT-WINDOW:WIDTH = 251.

DEFINE BUTTON bt-Cidades LABEL "Cidades" SIZE 16 BY 1.
DEFINE BUTTON bt-Produtos LABEL "Produtos" SIZE 16 BY 1.
DEFINE BUTTON bt-Clientes LABEL "Clientes" SIZE 16 BY 1.
DEFINE BUTTON bt-Pedidos LABEL "Pedidos" SIZE 16 BY 1. 
DEFINE BUTTON bt-sair LABEL "Sair" AUTO-ENDKEY SIZE 16 BY 1.
DEFINE BUTTON bt-rel-Clientes LABEL "Relatorio de Clientes" SIZE 30 BY 1.
DEFINE BUTTON bt-rel-Pedidos LABEL "Relatorio de Pedidos" SIZE 30 BY 1.

DEFINE FRAME f-menu
    bt-Cidades
    bt-Produtos
    bt-Clientes
    bt-Pedidos
    bt-sair 
    SKIP(0.1)
    bt-rel-Clientes
    bt-rel-Pedidos
    WITH SIDE-LABELS THREE-D SIZE 90 BY 4
    VIEW-AS DIALOG-BOX TITLE "Hamburgueria XTudo".
        
ON 'choose' OF bt-Cidades 
    DO:
        RUN Cidades.p.
    END.       
    
ON 'choose' OF bt-Produtos
    DO:
        RUN Produtos.p.
    END.   
    
ON 'choose' OF bt-Clientes 
    DO:
        RUN Clientes.p.
    END.        
    
ON 'choose' OF bt-Pedidos
    DO:
        RUN Pedidos.p.
    END.      
    
ON 'choose' OF bt-rel-Clientes
    DO:
        RUN RelClientes.p.
    END.        
    
ON 'choose' OF bt-rel-Pedidos
    DO:
        RUN RelPedidos.p.
    END.        
                   
ENABLE ALL WITH FRAME f-menu.
WAIT-FOR CLOSE OF THIS-PROCEDURE.
