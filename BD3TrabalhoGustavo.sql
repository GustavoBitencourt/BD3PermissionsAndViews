-- crie uma visão que contenha codigo, descricao e valor de itens.
-- Logo após atualize o valor de todos os itens em 10%. Descreva se 
-- houve modificações na tabela itens após atualizar a visão.

CREATE VIEW visao_itens_desconto AS
SELECT codigo, descricao, valor * 0.10 AS valor_com_desconto
FROM itens;

SELECT * FROM visao_itens_desconto;

-- Os valores não foram atualizados na tabela, apenas na visão.
-----------------------------------------------------------------------

-- Crie um usuário  com senha chamado ana. Logo após, dê privilégios
-- de acesso para ana à tabela itens. Tente acessar pelo cmd a tabela 
-- clientes e descreva o que ocorreu.

CREATE USER ana WITH PASSWORD 'senha5';
GRANT SELECT ON itens TO ana;

--Ao tentar acessar a tabela clientes com o usuário ana, retornou
--permissão negada
---------------------------------------------------------------------------

-- Crie uma visão que contenha os clientes e seus respectivos telefones,
-- se o cliente não possuir telefone, indique com um texto "Sem telefone"

CREATE VIEW visao_telefones AS
SELECT clientes.codcliente, clientes.nome,
  CASE WHEN fones_clientes.num_telefone IS NULL THEN 'Sem telefone'
  ELSE fones_clientes.num_telefone
  END AS num_telefone
FROM clientes
LEFT JOIN fones_clientes ON clientes.codcliente = fones_clientes.cliente;


SELECT * FROM visao_telefones;
-----------------------------------------------------------------------------------
-- Crie um usuário com permissão apenas para visualizar a tabela fornecedores. 
-- Se este usuário tentar visualizar outras tabelas, utilize o RAISE NOTICE para dar a mensagem "Ação proibida"

CREATE USER usuario_visualizador WITH PASSWORD 'senha5';

GRANT SELECT ON TABLE fornecedores TO usuario_visualizador;

CREATE OR REPLACE FUNCTION acao_proibida() RETURNS TRIGGER AS $$
BEGIN RAISE NOTICE 'Ação proibida';
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
---------------------------------------------------------------------------------------
--Crie uma view que contenha a descrição do item e o numero de unidades vendidas em 2023

CREATE OR REPLACE VIEW vendas_2023 AS
SELECT i.descricao AS descricao_item,
SUM(v.quantidade) AS unidades_vendidas
FROM venda_itens v
JOIN itens i ON v.codigo = i.codigo
JOIN vendas ve ON v.codvenda = ve.codigo
WHERE EXTRACT(YEAR FROM ve.dt_venda) = 2023
GROUP BY i.descricao;

SELECT * FROM vendas_2023;
--------------------------------------------------------------------------
-- Crie um usuario e senha e dê permissão de acesso a view vendas_2023.

CREATE USER carina WITH PASSWORD 'senha5';

GRANT SELECT ON vendas_2023 TO carina;
----------------------------------------------------------------------------
-- Crie uma view que liste as informações de todas as vendas, incluindo
-- o código da venda, a data da venda, o valor total, nome do cliente 
-- e nome do funcionário que realizou a venda.

CREATE OR REPLACE VIEW todas_as_vendas AS
SELECT v.numero AS codigo_venda,
os.data AS data_venda,
os.valor_total AS valor_total,
c.nome AS nome_cliente,
f.nome AS nome_funcionario
FROM vendas v
JOIN ordens_servico os ON v.numero = os.numero
JOIN clientes c ON os.codcliente = c.codcliente
JOIN funcionarios f ON os.codfunc = f.codfunc;

SELECT * FROM todas_as_vendas;
-----------------------------------------------------------------
-- Dê permissão para que o usuário Roberto possa apenas inserir dados na tabela clientes.

CREATE USER roberto WITH PASSWORD 'senha5';

GRANT INSERT ON TABLE clientes TO roberto;
-------------------------------------------------------------
-- Crie uma visão materializada com as seguintes informações: 
-- num_boleto, data_vencimento, valor, desconto, compra, data_lancamento.
-- Em seguida adicione um novo atualize o desconto de todos os boletos lançados em 2016 para 20%.

CREATE MATERIALIZED VIEW visao_boletos AS
SELECT cp.num_boleto, cp.data_vencimento, cp.valor, cp.desconto, cp.compra, cp.data_lancamento
FROM contas_pagar cp;

UPDATE visao_boletos
SET desconto = 20
WHERE EXTRACT(YEAR FROM data_lancamento) = 2016;

REFRESH MATERIALIZED VIEW visao_boletos;
------------------------------------------------------------------
-- Crie um grupo chamado coletores com permissão para acessar, excluir e atualizar
-- os itens da tabela contas_receber.
-- Em seguida adicione um usuário ao grupo e mostre todos os dados da tabela.

CREATE GROUP coletores;

GRANT SELECT, DELETE, UPDATE ON TABLE contas_receber TO coletores;

CREATE USER usuario_coletores WITH PASSWORD 'senha5';

ALTER GROUP coletores ADD USER usuario_coletores;

SELECT * FROM contas_receber;
--------------------------------------------------------------------
-- Crie uma visão que mostra as vendas mensais totais. Na visão deve incluir o mês,
-- valor total das vendas e o número de produtos vendidos neste mês

CREATE OR REPLACE VIEW vendas_mensais AS
SELECT
 EXTRACT(MONTH FROM v.dt_venda) AS mes,
 EXTRACT(YEAR FROM v.dt_venda) AS ano,
 SUM(vi.quantidade) AS total_produtos_vendidos,
 SUM(v.valor_total_venda) AS valor_total_vendas
FROM vendas v
JOIN venda_itens vi ON v.codigo = vi.codvenda
GROUP BY
EXTRACT(MONTH FROM v.dt_venda),
EXTRACT(YEAR FROM v.dt_venda);

SELECT * FROM vendas_mensais;
-------------------------------------------------------------------
-- Crie um grupo chamado "Time de Vendas" adicione dois funcionários a 
-- esse grupo e de a eles a permissão de alterar dados da tabela itens.
-- Agora altere o valor de 3 dos itens da tabela e mostre a 
-- tabela itens com os valores alterados.

CREATE GROUP "Time de Vendas";

ALTER GROUP "Time de Vendas" ADD USER funcionario1, funcionario2;

GRANT UPDATE ON TABLE itens TO "Time de Vendas";

SELECT * FROM itens

UPDATE itens SET valor = valor * 1.1 WHERE codigo IN (6, 7, 8);

SELECT * FROM itens;
------------------------------------------------------------------
-- Crie uma visão dos 3 itens mais vendidos, com seu respectivo código e descrição.

CREATE OR REPLACE VIEW top_3_itens_mais_vendidos AS
SELECT codigo, descricao, quantidade_vendida
FROM (SELECT i.codigo, i.descricao, vi.codigo AS codigo_venda,
SUM(vi.quantidade) AS quantidade_vendida,
ROW_NUMBER() OVER (ORDER BY SUM(vi.quantidade) DESC) AS ranking
FROM itens i
JOIN venda_itens vi ON i.codigo = vi.codigo
GROUP BY i.codigo, i.descricao, vi.codigo) ranked_items
WHERE ranking <= 3;

SELECT * FROM top_3_itens_mais_vendidos;
--------------------------------------------------------
-- Crie 2 usuários novos com senha, logo após, crie um grupo chamado
-- "financeiro" e adicione os novos usuários ao grupo, 
-- dê permissão para que os usuários do grupo consultem, incluam,
-- alterem e excluam registros da tabela contas_pagar.

CREATE USER usuario1 WITH PASSWORD 'senha5';
CREATE USER usuario2 WITH PASSWORD 'senha5';

CREATE GROUP financeiro;

ALTER GROUP financeiro ADD USER usuario1, usuario2;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contas_pagar TO financeiro;
-------------------------------------------------------------------------
-- Crie uma visão que contenha o código, descrição, valor(em formação monetária),
-- estoque, fornecedores(coluna única), e data da ultima compra de cada item na tabela itens.

CREATE OR REPLACE VIEW detalhes_itens AS
SELECT i.codigo, i.descricao, i.valor, i.estoque, f.descricao AS fornecedor,
MAX(c.data) AS data_ultima_compra
FROM itens i
JOIN compras_itens ci ON i.codigo = ci.coditem
JOIN compras c ON ci.codcompra = c.codigo
JOIN fornecedores f ON c.codfornecedor = f.codigo
GROUP BY i.codigo, i.descricao, i.valor, i.estoque, f.descricao;

SELECT * FROM detalhes_itens;
-----------------------------------------------------------------------------
-- Crie uma visão que liste o nome de todos os itens, seus valores e de seus respectivos descontos.
-- Todos os valores devem ser exibidos no formato monetário.

CREATE VIEW detalhes_itens_com_desconto AS
SELECT i.descricao AS nome_item,
TO_CHAR(i.valor, 'R$999,999,990.00') AS valor,
TO_CHAR(i.desconto, '999,990.00%') AS desconto
FROM itens i;

SELECT * FROM detalhes_itens_com_desconto;
-----------------------------------------------------------------------
-- Crie um grupo chamado "DeptCompras" e adicione um novo usuários a ele, esse grupo deve ter permissão para visualizar, adicionar,
-- alterar e excluir registros da tabela fornecedores.

CREATE GROUP DeptCompras;

CREATE USER novo_usuario WITH PASSWORD 'senha5';

ALTER GROUP DeptCompras ADD USER novo_usuario;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE fornecedores TO DeptCompras;
------------------------------------------------------------------------------
-- Crie um usuário "funcionario" que tenha permissão apenas para visualizar nome, 
-- endereco, e tipo_cliente da tabela cliente. Esse usuário poderá repassar essa permissão 
-- para outros usuários.

CREATE USER funcionario5 WITH PASSWORD 'senha5';
	
GRANT SELECT (nome, endereco, tipo_cliente) ON TABLE clientes TO funcionario5 WITH GRANT OPTION;
