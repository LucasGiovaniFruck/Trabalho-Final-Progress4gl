Sistema de Gestão - Hamburgueria XTudo
Feito por Lucas Giovani Fruck

Descrição do Projeto:
Este projeto consiste no desenvolvimento de um sistema de gestão para a "Hamburgueria XTudo", 
criado com a linguagem Progress ABL. O sistema oferece uma interface que permite o gerenciamento 
completo das operações do negócio, incluindo o cadastro e a manutenção de Cidades, Clientes e 
Produtos. Sua principal funcionalidade é uma tela de Pedidos, onde é possível criar novos pedidos, 
associá-los a clientes validados e adicionar, modificar ou remover itens em tempo real. O sistema 
também garante a integridade dos dados, impedindo a exclusão de registros em uso, e oferece 
funcionalidades de exportação de relatórios para os formatos JSON e CSV.

Guia de Execução e Implantação:
Este guia detalha todos os passos necessários para configurar o ambiente, ligar a base de dados e 
executar o sistema.

Pré-requisitos:
Ter o Progress OpenEdge Instalado.

Passo 1) 
Após abrir o Developer Studio;
No menu superior clique em File e depois em Import;
Na janela em que aparece, expanda a pasta General e selecione a opção Existing Projects Into Workspace;
Clique em Next;
Selecione Select root directory e após isso clique no botão Browse logo ao lado;
Navege no seu computador e selecione a pasta Progress4gl-TrabalhoFinal-Xtudo;
Clique em Finish.

Passo 2)
Clique com o botão direito em cima do seu projeto no Project Explorer;
Clique em Properties;
Expanda a aba Progress OpenEdge e clique em Database Connections;
Clique em Configure database Connections;
Clique em New;
Em Connection name escreva "xtudo";
Em Physical name clique em Browse e encontre a pasta Progress4gl-TrabalhoFinal-XTudo e abra ela;
Após isso clique em Finish e depois em Apply and Close;
Selecione a database xtudo e clique novamente em Apply and Close.

Passo 3)
No Project Explorer dentro da pasta encontre o arquivo "menu.p", clique com o botão direito e 
vá em Run As e selecione Progress OpenEdge Application.



