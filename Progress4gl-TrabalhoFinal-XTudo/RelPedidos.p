DEFINE VARIABLE cArquivoSaida AS CHARACTER NO-UNDO.
DEFINE VARIABLE dTotalPedido  AS DECIMAL   NO-UNDO.

DEFINE BUFFER bPedido  FOR Pedidos.
DEFINE BUFFER bCliente FOR Clientes.
DEFINE BUFFER bCidade  FOR Cidades.
DEFINE BUFFER bItem    FOR Itens.
DEFINE BUFFER bProduto FOR Produtos.

ASSIGN cArquivoSaida = SESSION:TEMP-DIRECTORY + "RelatorioPedidos.txt".

OUTPUT TO VALUE(cArquivoSaida).

PUT UNFORMATTED "Relatorio de Pedidos:" SKIP(2).

FOR EACH bPedido NO-LOCK:
    FIND FIRST bCliente WHERE bCliente.CodCliente = bPedido.CodCliente NO-LOCK NO-ERROR.
    IF AVAILABLE bCliente THEN
        FIND FIRST bCidade WHERE bCidade.CodCidade = bCliente.CodCidade NO-LOCK NO-ERROR.
    
    PUT UNFORMATTED "                                Pedido" SKIP.
    PUT UNFORMATTED "Pedido: " bPedido.CodPedido AT 1
                    "Data: "   bPedido.DatPedido AT 60 SKIP.
    PUT UNFORMATTED "Nome: "   (IF AVAILABLE bCliente THEN bCliente.NomCliente ELSE "Cliente nao encontrado") SKIP.
    PUT UNFORMATTED "Endereco: " (IF AVAILABLE bCliente THEN bCliente.CodEndereco ELSE "") SKIP.
    PUT UNFORMATTED "Observacao: " bPedido.Observacao SKIP(2).

    PUT UNFORMATTED "Item/Total"         AT 1
                    "Produto"            AT 20
                    "Quantidade"         AT 55
                    "Valor Unit."        AT 70 SKIP.
    PUT UNFORMATTED "--------------------------------------------------------------------------------" SKIP.
    
    dTotalPedido = 0.
    
    FOR EACH bItem WHERE bItem.CodPedido = bPedido.CodPedido NO-LOCK:
        FIND FIRST bProduto WHERE bProduto.CodProduto = bItem.CodProduto NO-LOCK NO-ERROR.
        
        PUT UNFORMATTED
            STRING(bItem.CodItem)                                        AT 1
            (IF AVAILABLE bProduto THEN bProduto.NomProduto ELSE "N/A")  AT 20
            STRING(bItem.NumQuantidade)                                  AT 55
            STRING(IF AVAILABLE bProduto THEN bProduto.ValProduto ELSE 0, ">>,>>9.99") AT 70
            SKIP.
            
        PUT UNFORMATTED
            STRING(bItem.ValTotal, ">>,>>9.99") AT 1
            SKIP.
            
        dTotalPedido = dTotalPedido + bItem.ValTotal.
    END.
    
    PUT UNFORMATTED "--------------------------------------------------------------------------------" SKIP.
    PUT UNFORMATTED "Total Pedido:" AT 55
                    STRING(dTotalPedido, ">>,>>9.99") AT 70
                    SKIP(3).
    
END.

OUTPUT CLOSE.

MESSAGE "Relatorio de Pedidos foi gerado com sucesso em:" SKIP
        cArquivoSaida
    VIEW-AS ALERT-BOX INFORMATION TITLE "Relatorio Gerado".

OS-COMMAND SILENT VALUE("notepad.exe " + cArquivoSaida).
