DEFINE VARIABLE cArquivoSaida AS CHARACTER NO-UNDO.

DEFINE BUFFER bCliente FOR Clientes.
DEFINE BUFFER bCidade  FOR Cidades.
DEFINE VARIABLE cCidadeFmt AS CHARACTER FORMAT "x(25)" LABEL "Cidade".
    
DEFINE FRAME fr-report
    bCliente.CodCliente  LABEL "Codigo"     FORMAT "9999"
    bCliente.NomCliente  LABEL "Nome"       FORMAT "x(20)"
    bCliente.CodEndereco LABEL "Endereco"   FORMAT "x(28)"
    
    bCliente.Observacao  LABEL "Observacao" FORMAT "x(30)"
    WITH     
    NO-BOX     
    WIDTH 150.   

ASSIGN cArquivoSaida = SESSION:TEMP-DIRECTORY + "RelatorioClientes.txt".

OUTPUT TO VALUE(cArquivoSaida).

DISPLAY "Cadastro de Clientes:" SKIP.
DISPLAY "                       Relatorio de Clientes" SKIP(2).

FOR EACH bCliente NO-LOCK WITH FRAME fr-report:
    FIND FIRST bCidade WHERE bCidade.CodCidade = bCliente.CodCidade NO-LOCK NO-ERROR.
    
    ASSIGN cCidadeFmt = STRING(bCliente.CodCidade) + "-" + (IF AVAILABLE bCidade THEN bCidade.NomCidade ELSE "N/A").
    
    DISPLAY bCliente.CodCliente bCliente.NomCliente bCliente.CodEndereco cCidadeFmt bCliente.Observacao.
END.

OUTPUT CLOSE.

MESSAGE "Relatorio de Clentes foi gerado com sucesso em:" SKIP
        cArquivoSaida
    VIEW-AS ALERT-BOX INFORMATION TITLE "Relatorio Gerado".

OS-COMMAND SILENT VALUE("notepad.exe " + cArquivoSaida).
