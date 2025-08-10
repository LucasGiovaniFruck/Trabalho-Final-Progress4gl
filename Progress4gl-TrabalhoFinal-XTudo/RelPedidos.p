USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.
USING Progress.Json.ObjectModel.JsonArray  FROM PROPATH.

DEFINE VARIABLE cArquivoSaida AS CHARACTER   NO-UNDO.
DEFINE VARIABLE oPedidosArray AS JsonArray   NO-UNDO.
DEFINE VARIABLE oPedidoObject AS JsonObject  NO-UNDO.
DEFINE VARIABLE oItensArray   AS JsonArray   NO-UNDO.
DEFINE VARIABLE oItemObject   AS JsonObject  NO-UNDO.
DEFINE VARIABLE dTotalPedido  AS DECIMAL     NO-UNDO.

DEFINE BUFFER bPedido  FOR Pedidos.
DEFINE BUFFER bCliente FOR Clientes.
DEFINE BUFFER bCidade  FOR Cidades.
DEFINE BUFFER bItem    FOR Itens.
DEFINE BUFFER bProduto FOR Produtos.

ASSIGN cArquivoSaida = SESSION:TEMP-DIRECTORY + "RelatorioPedidos.json".

oPedidosArray = NEW JsonArray().

FOR EACH bPedido NO-LOCK:
    FIND FIRST bCliente WHERE bCliente.CodCliente = bPedido.CodCliente NO-LOCK NO-ERROR.
    IF AVAILABLE bCliente THEN
        FIND FIRST bCidade WHERE bCidade.CodCidade = bCliente.CodCidade NO-LOCK NO-ERROR.
    
    oPedidoObject = NEW JsonObject().
    
    oPedidoObject:Add("Pedido",     bPedido.CodPedido).
    oPedidoObject:Add("Data",       bPedido.DatPedido).
    oPedidoObject:Add("NomeCliente", (IF AVAILABLE bCliente THEN STRING(bCliente.CodCliente) + "-" + bCliente.NomCliente ELSE "N/A")).
    oPedidoObject:Add("Endereco",   (IF AVAILABLE bCliente THEN bCliente.CodEndereco ELSE "") + " / " + (IF AVAILABLE bCidade THEN bCidade.NomCidade + "-" + bCidade.CodUF ELSE "")).
    oPedidoObject:Add("Observacao", bPedido.Observacao).
    
    oItensArray    = NEW JsonArray().
    dTotalPedido   = 0.
    
    FOR EACH bItem WHERE bItem.CodPedido = bPedido.CodPedido NO-LOCK:
        FIND FIRST bProduto WHERE bProduto.CodProduto = bItem.CodProduto NO-LOCK NO-ERROR.
        
        oItemObject = NEW JsonObject().
        
        oItemObject:Add("Item",       bItem.CodItem).
        oItemObject:Add("Produto",    (IF AVAILABLE bProduto THEN STRING(bProduto.CodProduto) + "-" + bProduto.NomProduto ELSE "N/A")).
        oItemObject:Add("Quantidade", bItem.NumQuantidade).
        oItemObject:Add("Valor",      (IF AVAILABLE bProduto THEN bProduto.ValProduto ELSE 0)).
        oItemObject:Add("Total",      bItem.ValTotal).
        
        oItensArray:Add(oItemObject).
        
        dTotalPedido = dTotalPedido + bItem.ValTotal.
    END. 
    
    oPedidoObject:Add("Itens", oItensArray).
    oPedidoObject:Add("TotalPedido", dTotalPedido).
    
    oPedidosArray:Add(oPedidoObject).
    
END.

oPedidosArray:WriteFile(cArquivoSaida, TRUE).

MESSAGE "Relat�rio de Pedidos foi gerado com sucesso em:" SKIP
        cArquivoSaida
    VIEW-AS ALERT-BOX INFORMATION TITLE "Relatorio Gerado".

OS-COMMAND SILENT VALUE("explorer.exe " + cArquivoSaida).
