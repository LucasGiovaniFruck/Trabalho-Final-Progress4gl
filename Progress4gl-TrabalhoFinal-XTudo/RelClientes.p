USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.
USING Progress.Json.ObjectModel.JsonArray  FROM PROPATH.

DEFINE VARIABLE cArquivoSaida AS CHARACTER   NO-UNDO.
DEFINE VARIABLE oJsonArray    AS JsonArray   NO-UNDO.
DEFINE VARIABLE oJsonObject   AS JsonObject  NO-UNDO.

DEFINE BUFFER bCliente FOR Clientes.
DEFINE BUFFER bCidade  FOR Cidades.

ASSIGN cArquivoSaida = SESSION:TEMP-DIRECTORY + "RelatorioClientes.json".

oJsonArray = NEW JsonArray().

FOR EACH bCliente NO-LOCK:
    FIND FIRST bCidade WHERE bCidade.CodCidade = bCliente.CodCidade NO-LOCK NO-ERROR.
    
    oJsonObject = NEW JsonObject().
    
    oJsonObject:Add("Codigo",     bCliente.CodCliente).
    oJsonObject:Add("Nome",       bCliente.NomCliente).
    oJsonObject:Add("Endereco",   bCliente.CodEndereco).
    oJsonObject:Add("Cidade",     STRING(bCliente.CodCidade) + "-" + (IF AVAILABLE bCidade THEN bCidade.NomCidade ELSE "N/A")).
    oJsonObject:Add("Observacao", bCliente.Observacao).
    
    oJsonArray:Add(oJsonObject).
END.

oJsonArray:WriteFile(cArquivoSaida, TRUE).

MESSAGE "Relatorio de Clientes foi gerado com sucesso em:" SKIP
        cArquivoSaida
    VIEW-AS ALERT-BOX INFORMATION TITLE "Relatorio Gerado".

OS-COMMAND SILENT VALUE("explorer.exe " + cArquivoSaida).
