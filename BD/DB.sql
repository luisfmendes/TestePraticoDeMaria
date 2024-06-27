
-- DROP TYPE public."uf";

CREATE TYPE public."uf" AS ENUM (
	'RO',
	'AC',
	'AM',
	'RR',
	'PA',
	'AP',
	'TO',
	'MA',
	'PI',
	'CE',
	'RN',
	'PB',
	'PE',
	'AL',
	'SE',
	'BA',
	'MG',
	'ES',
	'RJ',
	'SP',
	'PR',
	'SC',
	'RS',
	'MS',
	'MT',
	'GO',
	'DF',
	'EX');

COMMENT ON TYPE public."uf" IS 'Estados do Brasil ou EX = Exterior';


-- public.tab_cliente definition

-- Drop table

-- DROP TABLE public.tab_cliente;

CREATE TABLE public.tab_cliente (
	id_cliente int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nome_cliente varchar(100) NOT NULL,
	telefone varchar(20) NULL,
	endereco varchar(100) NOT NULL,
	cidade varchar(35) NOT NULL,
	cep varchar(20) NOT NULL,
	ativo bool NULL,
	CONSTRAINT tab_cliente_pk PRIMARY KEY (id_cliente)
);
CREATE INDEX tab_cliente_id_cliente_idx ON public.tab_cliente USING btree (id_cliente, nome_cliente);

-- public.tab_estado definition

-- Drop table

-- DROP TABLE public.tab_estado;

CREATE TABLE public.tab_estado (
	est_codigo numeric(2) NOT NULL,
	est_sigla public."uf" NOT NULL,
	est_nome varchar(20) NULL,
	est_aliq_fcp numeric(10, 2) DEFAULT 0 NULL,
	est_excecao_fcp bool DEFAULT false NULL,
	est_link_consulta_nfce text NULL,
	est_modo_envio_nfe varchar(1) NULL,
	est_modo_envio_nfce varchar(1) NULL,
	CONSTRAINT pk_estados PRIMARY KEY (est_codigo),
	CONSTRAINT uk_dupl_est_sigla UNIQUE (est_sigla)
)
WITH (
	autovacuum_enabled=true
);

-- public.tab_fornecedor definition

-- Drop table

-- DROP TABLE public.tab_fornecedor;

CREATE TABLE public.tab_fornecedor (
	id_fornecedor int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nome_contato varchar(50) NOT NULL,
	razao_social varchar(50) NOT NULL,
	cnpj varchar(20) NOT NULL,
	telefone varchar(20) NULL,
	endereco varchar(100) NULL,
	cep varchar(10) NOT NULL,
	email varchar(40) NULL,
	ativo bool DEFAULT true NOT NULL,
	CONSTRAINT tab_fornecedor_pk PRIMARY KEY (id_fornecedor),
	CONSTRAINT tab_fornecedor_un UNIQUE (cnpj)
);
CREATE INDEX tab_fornecedor_razao_social_idx ON public.tab_fornecedor USING btree (razao_social, cnpj);

-- public.tab_municipio definition

-- Drop table

-- DROP TABLE public.tab_municipio;

CREATE TABLE public.tab_municipio (
	mun_codigo int4 NOT NULL,
	mun_descricao varchar(40) NOT NULL,
	est_codigo numeric(2) NOT NULL,
	CONSTRAINT pk_municipios PRIMARY KEY (mun_codigo)
)
WITH (
	autovacuum_enabled=true
);


-- public.tab_municipio foreign keys

ALTER TABLE public.tab_municipio ADD CONSTRAINT fk_estado_municipio FOREIGN KEY (est_codigo) REFERENCES public.tab_estado(est_codigo);

-- DROP FUNCTION public.funccriaestoque();

CREATE OR REPLACE FUNCTION public.funccriaestoque()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
	insert into tab_estoque(id_produto,quantidade) 
	values(new.id_produto, 0);
return new;
end;
$function$
;

-- public.tab_produto definition

-- Drop table

-- DROP TABLE public.tab_produto;

CREATE TABLE public.tab_produto (
	id_produto int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nome_produto varchar(50) NOT NULL,
	descricao varchar(100) NULL,
	preco_venda money NOT NULL,
	preco_compra money NOT NULL,
	ativo bool NOT NULL,
	CONSTRAINT tab_produto_pk PRIMARY KEY (id_produto)
);
CREATE INDEX tab_produto_nome_produto_idx ON public.tab_produto USING btree (nome_produto, descricao);

-- Table Triggers

create trigger criaestoque after
insert
    on
    public.tab_produto for each row execute procedure funccriaestoque();


-- DROP FUNCTION public.funccompraestoque();

CREATE OR REPLACE FUNCTION public.funccompraestoque()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
	update tab_estoque 
	set    quantidade = quantidade + new.quantidade
	where  id_produto = new.id_produto ;
	return new;
end;
$function$
;

-- public.tab_compra definition

-- Drop table

-- DROP TABLE public.tab_compra;

CREATE TABLE public.tab_compra (
	id_compra int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_fornecedor int4 NOT NULL,
	data_compra date NOT NULL,
	valor_total money NULL,
	CONSTRAINT tab_compra_pk PRIMARY KEY (id_compra)
);
CREATE INDEX tab_compra_data_compra_idx ON public.tab_compra USING btree (data_compra);


-- public.tab_compra foreign keys

ALTER TABLE public.tab_compra ADD CONSTRAINT tab_compra_fk FOREIGN KEY (id_fornecedor) REFERENCES public.tab_fornecedor(id_fornecedor);

-- DROP FUNCTION public.funccalculaprecototal();

CREATE OR REPLACE FUNCTION public.funccalculaprecototal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
	update tab_compra 
	set    valor_total = valor_total + (select tp.preco_compra * tcp.quantidade 
										from tab_produto tp,
 	 										 tab_compra_produto tcp 
										where tp.id_produto = tcp.id_produto 
										and	  tcp.id_compra = id_compra
										offset ((select count(*) from tab_compra_produto aux
										  			where aux.id_compra = id_compra 
										  			and aux.id_produto = id_produto)-1)) 
	where  id_compra = new.id_compra ;
	return new;
end;
$function$
;

-- public.tab_compra_produto definition

-- Drop table

-- DROP TABLE public.tab_compra_produto;

CREATE TABLE public.tab_compra_produto (
	id_compra int4 NOT NULL,
	id_produto int4 NOT NULL,
	quantidade int4 NOT NULL
);

-- Table Triggers

create trigger atualizaestoquecompra after
insert
    on
    public.tab_compra_produto for each row execute procedure funccompraestoque();
create trigger atualizavalortotalcompra after
insert
    on
    public.tab_compra_produto for each row execute procedure funccalculaprecototal();


-- public.tab_compra_produto foreign keys

ALTER TABLE public.tab_compra_produto ADD CONSTRAINT tab_compra_produto_fk FOREIGN KEY (id_compra) REFERENCES public.tab_compra(id_compra);
ALTER TABLE public.tab_compra_produto ADD CONSTRAINT tab_compra_produto_fk_1 FOREIGN KEY (id_produto) REFERENCES public.tab_produto(id_produto);


-- public.tab_estoque definition

-- Drop table

-- DROP TABLE public.tab_estoque;

CREATE TABLE public.tab_estoque (
	id_registro int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_produto int4 NOT NULL,
	quantidade int4 NOT NULL,
	CONSTRAINT tab_estoque_pk PRIMARY KEY (id_registro),
	CONSTRAINT tab_estoque_un UNIQUE (id_produto)
);


-- public.tab_estoque foreign keys

ALTER TABLE public.tab_estoque ADD CONSTRAINT tab_estoque_fk FOREIGN KEY (id_produto) REFERENCES public.tab_produto(id_produto) ON DELETE CASCADE;


-- public.tab_pedido definition

-- Drop table

-- DROP TABLE public.tab_pedido;

CREATE TABLE public.tab_pedido (
	id_pedido int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	data_pedido date NOT NULL,
	CONSTRAINT tab_pedido_pk PRIMARY KEY (id_pedido)
);

-- DROP FUNCTION public.funcvendaestoque();

CREATE OR REPLACE FUNCTION public.funcvendaestoque()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare var_aux_estoque integer;
declare var_aux_quantidade integer;
begin
	
	select auy.quantidade 
	into var_aux_estoque 
	from tab_estoque auy
	where auy.id_produto = id_produto;
	
	select auz.quantidade
	into   var_aux_quantidade
	from   tab_pedido_item auz
	where  auz.id_produto = id_produto 
	and	   auz.id_pedido = id_pedido; 

	update tab_estoque 
	set    quantidade = quantidade - (select t.quantidade
										  from 	tab_pedido_item t
										  where t.id_pedido = new.id_pedido
										  and	t.id_produto = new.id_produto 
										  offset ((select count(*) from tab_pedido_item aux
										  			where aux.id_pedido = new.id_pedido 
										  			and aux.id_produto = new.id_produto)-1)) 
	where  tab_estoque.id_produto = new.id_produto ;
	
		if (select aux.quantidade
			from   tab_estoque aux 
			where  aux.id_produto = id_produto limit 1) < 0 then
		update tab_estoque  
		set	   quantidade = 0
		where  tab_estoque.id_produto = new.id_produto;
	
	update tab_pedido_item   
	set   tab_pedido_item.quantidade = var_aux_estoque
	where tab_pedido_item.id_pedido = new.id_pedido 
	and   tab_pedido_item.id_produto = new.id_produto; 
	commit;
	
	/*if (select aub.valor_total::numeric::int
		from   tab_venda aub
		where  aub.id_pedido = id_pedido) > 0 then
	
	update tab_venda 
	/*set valor_total = (valor_total - ((var_aux_quantidade) - (select auz.quantidade
																   from tab_pedido_item auz
																   where auz.id_pedido = id_pedido
																   and   auz.id_produto = id_produto)) * (select aua.preco_venda
																   					                      from tab_produto aua
																   					                      where aua.id_produto = id_produto))*/
	set valor_total = var_aux_quantidade
	where id_pedido = id_pedido;
	end if;*/

	update tab_venda 
	set    valor_total = valor_total + (select tp.preco_venda * tpi.quantidade 
										from tab_produto tp,
 	 										 tab_pedido_item tpi 
										where tp.id_produto = tpi.id_produto 
										and	  tpi.id_pedido = id_pedido
										offset ((select count(*) from tab_pedido_item aux
										  			where aux.id_pedido = id_pedido 
										  			and aux.id_produto = id_produto)-1)) 
										  
	where  tab_venda.id_pedido = new.id_pedido ;
		end if;
	return new;
end;
$function$
;

-- public.tab_pedido_item definition

-- Drop table

-- DROP TABLE public.tab_pedido_item;

CREATE TABLE public.tab_pedido_item (
	id_produto int4 NOT NULL,
	id_pedido int4 NOT NULL,
	quantidade int4 NOT NULL
);

-- Table Triggers

create trigger atualizaestoquevenda after
insert
    on
    public.tab_pedido_item for each row execute procedure funcvendaestoque();


-- public.tab_pedido_item foreign keys

ALTER TABLE public.tab_pedido_item ADD CONSTRAINT tab_pedido_item_fk FOREIGN KEY (id_produto) REFERENCES public.tab_produto(id_produto);
ALTER TABLE public.tab_pedido_item ADD CONSTRAINT tab_pedido_item_fk_1 FOREIGN KEY (id_pedido) REFERENCES public.tab_pedido(id_pedido);


-- public.tab_venda definition

-- Drop table

-- DROP TABLE public.tab_venda;

CREATE TABLE public.tab_venda (
	id_venda int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	id_pedido int4 NOT NULL,
	id_cliente int4 NOT NULL,
	valor_total money NOT NULL,
	CONSTRAINT tab_venda_pk PRIMARY KEY (id_venda),
	CONSTRAINT tab_venda_un UNIQUE (id_pedido)
);


-- public.tab_venda foreign keys

ALTER TABLE public.tab_venda ADD CONSTRAINT tab_venda_fk FOREIGN KEY (id_pedido) REFERENCES public.tab_pedido(id_pedido);
ALTER TABLE public.tab_venda ADD CONSTRAINT tab_venda_fk_1 FOREIGN KEY (id_cliente) REFERENCES public.tab_cliente(id_cliente);

-- public.vie_municipios source

CREATE OR REPLACE VIEW public.vie_municipios
AS SELECT tab_municipio.mun_codigo AS ibge,
    tab_municipio.mun_descricao AS descricao,
    tab_estado.est_codigo AS cod_uf,
    tab_estado.est_sigla::text AS desc_uf
   FROM tab_municipio
     LEFT JOIN tab_estado ON tab_estado.est_codigo = tab_municipio.est_codigo
  ORDER BY (tab_estado.est_sigla::text), tab_municipio.mun_descricao;

INSERT INTO public.tab_estado (est_codigo,est_sigla,est_nome,est_aliq_fcp,est_excecao_fcp,est_link_consulta_nfce,est_modo_envio_nfe,est_modo_envio_nfce) VALUES
	 (11,'RO','RONDÔNIA',0.00,false,'http://www.sefin.ro.gov.br/nfce/consulta',NULL,NULL),
	 (12,'AC','ACRE',0.00,false,'www.sefaznet.ac.gov.br/nfce/consulta',NULL,NULL),
	 (13,'AM','AMAZONAS',0.00,false,'www.sefaz.am.gov.br/nfce/consulta',NULL,NULL),
	 (14,'RR','RORAIMA',0.00,false,'http://www.sefaz.rr.gov.br/nfce/consulta',NULL,NULL),
	 (15,'PA','PARÁ',0.00,false,'www.sefa.pa.gov.br/nfce/consulta',NULL,NULL),
	 (16,'AP','AMAPÁ',0.00,false,'www.sefaz.ap.gov.br/nfce/consulta',NULL,NULL),
	 (17,'TO','TOCANTINS',0.00,false,'http://nfce.encat.org/consulte-sua-nota-qr-code-versao-2-0/www.sefaz.to.gov.br/nfce/consulta',NULL,NULL),
	 (21,'MA','MARANHÃO',0.00,false,'www.sefaz.ma.gov.br/nfce/consulta',NULL,NULL),
	 (22,'PI','PIAUÍ',0.00,false,'http://www.sefaz.pi.gov.br/nfce/consulta',NULL,NULL),
	 (23,'CE','CEARÁ',0.00,false,'http://www.sefaz.ce.gov.br/nfce/consulta',NULL,NULL);
INSERT INTO public.tab_estado (est_codigo,est_sigla,est_nome,est_aliq_fcp,est_excecao_fcp,est_link_consulta_nfce,est_modo_envio_nfe,est_modo_envio_nfce) VALUES
	 (24,'RN','RIO GRANDE DO NORTE',0.00,false,'http://www.set.rn.gov.br/nfce/consulta',NULL,NULL),
	 (25,'PB','PARAÍBA',0.00,false,'www.receita.pb.gov.br/nfce/consulta',NULL,NULL),
	 (26,'PE','PERNAMBUCO',0.00,false,'nfce.sefaz.pe.gov.br/nfce/consulta',NULL,NULL),
	 (27,'AL','ALAGOAS',0.00,false,'www.sefaz.al.gov.br/nfce/consulta',NULL,NULL),
	 (28,'SE','SERGIPE',0.00,false,'http://www.nfce.se.gov.br/nfce/consulta',NULL,NULL),
	 (31,'MG','MINAS GERAIS',0.00,false,'http://nfce.fazenda.mg.gov.br/portalnfce',NULL,NULL),
	 (32,'ES','ESPÍRITO SANTO',0.00,false,'http://www.sefaz.es.gov.br/nfce/consulta',NULL,NULL),
	 (33,'RJ','RIO DE JANEIRO',0.00,false,'http://www.fazenda.rj.gov.br/nfce/consulta',NULL,NULL),
	 (41,'PR','PARANÁ',0.00,false,'http://www.fazenda.pr.gov.br/nfce/consulta',NULL,NULL),
	 (42,'SC','SANTA CATARINA',0.00,false,NULL,NULL,NULL);
INSERT INTO public.tab_estado (est_codigo,est_sigla,est_nome,est_aliq_fcp,est_excecao_fcp,est_link_consulta_nfce,est_modo_envio_nfe,est_modo_envio_nfce) VALUES
	 (43,'RS','RIO GRANDE DO SUL',0.00,false,'http://www.sefaz.rs.gov.br/nfce/consulta',NULL,NULL),
	 (50,'MS','MATO GROSSO DO SUL',0.00,false,'www.dfe.ms.gov.br/nfce/consulta',NULL,NULL),
	 (51,'MT','MATO GROSSO',0.00,false,'http://www.sefaz.mt.gov.br/nfce/consultanfce',NULL,NULL),
	 (53,'DF','DISTRITO FEDERAL',0.00,false,'http://www.fazenda.df.gov.br/nfce/consulta',NULL,NULL),
	 (35,'SP','SÃO PAULO',0.00,false,'https://www.nfce.fazenda.sp.gov.br/consulta','A','S'),
	 (52,'GO','GOIÁS',0.00,false,'www.sefaz.go.gov.br/nfce/consulta','A',NULL),
	 (29,'BA','BAHIA',0.00,false,'www.sefaz.ba.gov.br/nfce/consulta','A',NULL),
	 (99,'EX','EXTERIOR',0.00,false,NULL,NULL,NULL);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1100015,'ALTA FLORESTA D OESTE',11),
	 (1100023,'ARIQUEMES',11),
	 (1100031,'CABIXI',11),
	 (1100049,'CACOAL',11),
	 (1100056,'CEREJEIRAS',11),
	 (1100072,'CORUMBIARA',11),
	 (1100080,'COSTA MARQUES',11),
	 (1100098,'ESPIGAO D OESTE',11),
	 (1100106,'GUAJARA-MIRIM',11),
	 (1100114,'JARU',11);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1100122,'JI-PARANA',11),
	 (1100130,'MACHADINHO D OESTE',11),
	 (1100148,'NOVA BRASILANDIA D OESTE',11),
	 (1100155,'OURO PRETO DO OESTE',11),
	 (1100189,'PIMENTA BUENO',11),
	 (1100205,'PORTO VELHO',11),
	 (1100254,'PRESIDENTE MEDICI',11),
	 (1100262,'RIO CRESPO',11),
	 (1100288,'ROLIM DE MOURA',11),
	 (1100296,'SANTA LUZIA D OESTE',11);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1100304,'VILHENA',11),
	 (1100320,'SAO MIGUEL DO GUAPORE',11),
	 (1100338,'NOVA MAMORE',11),
	 (1100346,'ALVORADA D OESTE',11),
	 (1100379,'ALTO ALEGRE DOS PARECIS',11),
	 (1100403,'ALTO PARAISO',11),
	 (1100452,'BURITIS',11),
	 (1100502,'NOVO HORIZONTE DO OESTE',11),
	 (1100601,'CACAULANDIA',11),
	 (1100700,'CAMPO NOVO DE RONDONIA',11);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1100809,'CANDEIAS DO JAMARI',11),
	 (1100908,'CASTANHEIRAS',11),
	 (1100924,'CHUPINGUAIA',11),
	 (1100940,'CUJUBIM',11),
	 (1101005,'GOVERNADOR JORGE TEIXEIRA',11),
	 (1101104,'ITAPUA DO OESTE',11),
	 (1101203,'MINISTRO ANDREAZZA',11),
	 (1101302,'MIRANTE DA SERRA',11),
	 (1101401,'MONTE NEGRO',11),
	 (1101435,'NOVA UNIAO',11);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1101450,'PARECIS',11),
	 (1101468,'PIMENTEIRAS DO OESTE',11),
	 (1101476,'PRIMAVERA DE RONDONIA',11),
	 (1101484,'SAO FELIPE D OESTE',11),
	 (1101492,'SAO FRANCISCO DO GUAPORE',11),
	 (1101500,'SERINGUEIRAS',11),
	 (1101559,'TEIXEIROPOLIS',11),
	 (1101609,'THEOBROMA',11),
	 (1101708,'URUPA',11),
	 (1101757,'VALE DO ANARI',11);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1101807,'VALE DO PARAISO',11),
	 (1200013,'ACRELANDIA',12),
	 (1200054,'ASSIS BRASIL',12),
	 (1200104,'BRASILEIA',12),
	 (1200138,'BUJARI',12),
	 (1200179,'CAPIXABA',12),
	 (1200203,'CRUZEIRO DO SUL',12),
	 (1200252,'EPITACIOLANDIA',12),
	 (1200302,'FEIJO',12),
	 (1200328,'JORDAO',12);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1200336,'MANCIO LIMA',12),
	 (1200344,'MANOEL URBANO',12),
	 (1200351,'MARECHAL THAUMATURGO',12),
	 (1200385,'PLACIDO DE CASTRO',12),
	 (1200393,'PORTO WALTER',12),
	 (1200401,'RIO BRANCO',12),
	 (1200427,'RODRIGUES ALVES',12),
	 (1200435,'SANTA ROSA DO PURUS',12),
	 (1200450,'SENADOR GUIOMARD',12),
	 (1200500,'SENA MADUREIRA',12);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1200609,'TARAUACA',12),
	 (1200708,'XAPURI',12),
	 (1200807,'PORTO ACRE',12),
	 (1300029,'ALVARAES',13),
	 (1300060,'AMATURA',13),
	 (1300086,'ANAMA',13),
	 (1300102,'ANORI',13),
	 (1300144,'APUI',13),
	 (1300201,'ATALAIA DO NORTE',13),
	 (1300300,'AUTAZES',13);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1300409,'BARCELOS',13),
	 (1300508,'BARREIRINHA',13),
	 (1300607,'BENJAMIN CONSTANT',13),
	 (1300631,'BERURI',13),
	 (1300680,'BOA VISTA DO RAMOS',13),
	 (1300706,'BOCA DO ACRE',13),
	 (1300805,'BORBA',13),
	 (1300839,'CAAPIRANGA',13),
	 (1300904,'CANUTAMA',13),
	 (1301001,'CARAUARI',13);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1301100,'CAREIRO',13),
	 (1301159,'CAREIRO DA VARZEA',13),
	 (1301209,'COARI',13),
	 (1301308,'CODAJAS',13),
	 (1301407,'EIRUNEPE',13),
	 (1301506,'ENVIRA',13),
	 (1301605,'FONTE BOA',13),
	 (1301654,'GUAJARA',13),
	 (1301704,'HUMAITA',13),
	 (1301803,'IPIXUNA',13);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1301852,'IRANDUBA',13),
	 (1301902,'ITACOATIARA',13),
	 (1301951,'ITAMARATI',13),
	 (1302009,'ITAPIRANGA',13),
	 (1302108,'JAPURA',13),
	 (1302207,'JURUA',13),
	 (1302306,'JUTAI',13),
	 (1302405,'LABREA',13),
	 (1302504,'MANACAPURU',13),
	 (1302553,'MANAQUIRI',13);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1302603,'MANAUS',13),
	 (1302702,'MANICORE',13),
	 (1302801,'MARAA',13),
	 (1302900,'MAUES',13),
	 (1303007,'NHAMUNDA',13),
	 (1303106,'NOVA OLINDA DO NORTE',13),
	 (1303205,'NOVO AIRAO',13),
	 (1303304,'NOVO ARIPUANA',13),
	 (1303403,'PARINTINS',13),
	 (1303502,'PAUINI',13);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1303536,'PRESIDENTE FIGUEIREDO',13),
	 (1303569,'RIO PRETO DA EVA',13),
	 (1303601,'SANTA ISABEL DO RIO NEGRO',13),
	 (1303700,'SANTO ANTONIO DO ICA',13),
	 (1303809,'SAO GABRIEL DA CACHOEIRA',13),
	 (1303908,'SAO PAULO DE OLIVENCA',13),
	 (1303957,'SAO SEBASTIAO DO UATUMA',13),
	 (1304005,'SILVES',13),
	 (1304062,'TABATINGA',13),
	 (1304104,'TAPAUA',13);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1304203,'TEFE',13),
	 (1304237,'TONANTINS',13),
	 (1304260,'UARINI',13),
	 (1304302,'URUCARA',13),
	 (1304401,'URUCURITUBA',13),
	 (1400027,'AMAJARI',14),
	 (1400050,'ALTO ALEGRE',14),
	 (1400100,'BOA VISTA',14),
	 (1400159,'BONFIM',14),
	 (1400175,'CANTA',14);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1400209,'CARACARAI',14),
	 (1400233,'CAROEBE',14),
	 (1400282,'IRACEMA',14),
	 (1400308,'MUCAJAI',14),
	 (1400407,'NORMANDIA',14),
	 (1400456,'PACARAIMA',14),
	 (1400472,'RORAINOPOLIS',14),
	 (1400506,'SAO JOAO DA BALIZA',14),
	 (1400605,'SAO LUIZ',14),
	 (1400704,'UIRAMUTA',14);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1500107,'ABAETETUBA',15),
	 (1500131,'ABEL FIGUEIREDO',15),
	 (1500206,'ACARA',15),
	 (1500305,'AFUA',15),
	 (1500347,'AGUA AZUL DO NORTE',15),
	 (1500404,'ALENQUER',15),
	 (1500503,'ALMEIRIM',15),
	 (1500602,'ALTAMIRA',15),
	 (1500701,'ANAJAS',15),
	 (1500800,'ANANINDEUA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1500859,'ANAPU',15),
	 (1500909,'AUGUSTO CORREA',15),
	 (1500958,'AURORA DO PARA',15),
	 (1501006,'AVEIRO',15),
	 (1501105,'BAGRE',15),
	 (1501204,'BAIAO',15),
	 (1501253,'BANNACH',15),
	 (1501303,'BARCARENA',15),
	 (1501402,'BELEM',15),
	 (1501451,'BELTERRA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1501501,'BENEVIDES',15),
	 (1501576,'BOM JESUS DO TOCANTINS',15),
	 (1501600,'BONITO',15),
	 (1501709,'BRAGANCA',15),
	 (1501725,'BRASIL NOVO',15),
	 (1501758,'BREJO GRANDE DO ARAGUAIA',15),
	 (1501782,'BREU BRANCO',15),
	 (1501808,'BREVES',15),
	 (1501907,'BUJARU',15),
	 (1501956,'CACHOEIRA DO PIRIA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1502004,'CACHOEIRA DO ARARI',15),
	 (1502103,'CAMETA',15),
	 (1502152,'CANAA DOS CARAJAS',15),
	 (1502202,'CAPANEMA',15),
	 (1502301,'CAPITAO POCO',15),
	 (1502400,'CASTANHAL',15),
	 (1502509,'CHAVES',15),
	 (1502608,'COLARES',15),
	 (1502707,'CONCEICAO DO ARAGUAIA',15),
	 (1502756,'CONCORDIA DO PARA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1502764,'CUMARU DO NORTE',15),
	 (1502772,'CURIONOPOLIS',15),
	 (1502806,'CURRALINHO',15),
	 (1502855,'CURUA',15),
	 (1502905,'CURUCA',15),
	 (1502939,'DOM ELISEU',15),
	 (1502954,'ELDORADO DOS CARAJAS',15),
	 (1503002,'FARO',15),
	 (1503044,'FLORESTA DO ARAGUAIA',15),
	 (1503077,'GARRAFAO DO NORTE',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1503093,'GOIANESIA DO PARA',15),
	 (1503101,'GURUPA',15),
	 (1503200,'IGARAPE-ACU',15),
	 (1503309,'IGARAPE-MIRI',15),
	 (1503408,'INHANGAPI',15),
	 (1503457,'IPIXUNA DO PARA',15),
	 (1503507,'IRITUIA',15),
	 (1503606,'ITAITUBA',15),
	 (1503705,'ITUPIRANGA',15),
	 (1503754,'JACAREACANGA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1503804,'JACUNDA',15),
	 (1503903,'JURUTI',15),
	 (1504000,'LIMOEIRO DO AJURU',15),
	 (1504059,'MAE DO RIO',15),
	 (1504109,'MAGALHAES BARATA',15),
	 (1504208,'MARABA',15),
	 (1504307,'MARACANA',15),
	 (1504406,'MARAPANIM',15),
	 (1504422,'MARITUBA',15),
	 (1504455,'MEDICILANDIA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1504505,'MELGACO',15),
	 (1504604,'MOCAJUBA',15),
	 (1504703,'MOJU',15),
	 (1504802,'MONTE ALEGRE',15),
	 (1504901,'MUANA',15),
	 (1504950,'NOVA ESPERANCA DO PIRIA',15),
	 (1504976,'NOVA IPIXUNA',15),
	 (1505007,'NOVA TIMBOTEUA',15),
	 (1505031,'NOVO PROGRESSO',15),
	 (1505064,'NOVO REPARTIMENTO',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1505106,'OBIDOS',15),
	 (1505205,'OEIRAS DO PARA',15),
	 (1505304,'ORIXIMINA',15),
	 (1505403,'OUREM',15),
	 (1505437,'OURILANDIA DO NORTE',15),
	 (1505486,'PACAJA',15),
	 (1505494,'PALESTINA DO PARA',15),
	 (1505502,'PARAGOMINAS',15),
	 (1505536,'PARAUAPEBAS',15),
	 (1505551,'PAU D ARCO',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1505601,'PEIXE-BOI',15),
	 (1505635,'PICARRA',15),
	 (1505650,'PLACAS',15),
	 (1505700,'PONTA DE PEDRAS',15),
	 (1505809,'PORTEL',15),
	 (1505908,'PORTO DE MOZ',15),
	 (1506005,'PRAINHA',15),
	 (1506104,'PRIMAVERA',15),
	 (1506112,'QUATIPURU',15),
	 (1506138,'REDENCAO',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1506161,'RIO MARIA',15),
	 (1506187,'RONDON DO PARA',15),
	 (1506195,'RUROPOLIS',15),
	 (1506203,'SALINOPOLIS',15),
	 (1506302,'SALVATERRA',15),
	 (1506351,'SANTA BARBARA DO PARA',15),
	 (1506401,'SANTA CRUZ DO ARARI',15),
	 (1506500,'SANTA ISABEL DO PARA',15),
	 (1506559,'SANTA LUZIA DO PARA',15),
	 (1506583,'SANTA MARIA DAS BARREIRAS',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1506609,'SANTA MARIA DO PARA',15),
	 (1506708,'SANTANA DO ARAGUAIA',15),
	 (1506807,'SANTAREM',15),
	 (1506906,'SANTAREM NOVO',15),
	 (1507003,'SANTO ANTONIO DO TAUA',15),
	 (1507102,'SAO CAETANO DE ODIVELAS',15),
	 (1507151,'SAO DOMINGOS DO ARAGUAIA',15),
	 (1507201,'SAO DOMINGOS DO CAPIM',15),
	 (1507300,'SAO FELIX DO XINGU',15),
	 (1507409,'SAO FRANCISCO DO PARA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1507458,'SAO GERALDO DO ARAGUAIA',15),
	 (1507466,'SAO JOAO DA PONTA',15),
	 (1507474,'SAO JOAO DE PIRABAS',15),
	 (1507508,'SAO JOAO DO ARAGUAIA',15),
	 (1507607,'SAO MIGUEL DO GUAMA',15),
	 (1507706,'SAO SEBASTIAO DA BOA VISTA',15),
	 (1507755,'SAPUCAIA',15),
	 (1507805,'SENADOR JOSE PORFIRIO',15),
	 (1507904,'SOURE',15),
	 (1507953,'TAILANDIA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1507961,'TERRA ALTA',15),
	 (1507979,'TERRA SANTA',15),
	 (1508001,'TOME-ACU',15),
	 (1508035,'TRACUATEUA',15),
	 (1508050,'TRAIRAO',15),
	 (1508084,'TUCUMA',15),
	 (1508100,'TUCURUI',15),
	 (1508126,'ULIANOPOLIS',15),
	 (1508159,'URUARA',15),
	 (1508209,'VIGIA',15);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1508308,'VISEU',15),
	 (1508357,'VITORIA DO XINGU',15),
	 (1508407,'XINGUARA',15),
	 (1600055,'SERRA DO NAVIO',16),
	 (1600105,'AMAPA',16),
	 (1600154,'PEDRA BRANCA DO AMAPARI',16),
	 (1600204,'CALCOENE',16),
	 (1600212,'CUTIAS',16),
	 (1600238,'FERREIRA GOMES',16),
	 (1600253,'ITAUBAL',16);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1600279,'LARANJAL DO JARI',16),
	 (1600303,'MACAPA',16),
	 (1600402,'MAZAGAO',16),
	 (1600501,'OIAPOQUE',16),
	 (1600535,'PORTO GRANDE',16),
	 (1600550,'PRACUUBA',16),
	 (1600600,'SANTANA',16),
	 (1600709,'TARTARUGALZINHO',16),
	 (1600808,'VITORIA DO JARI',16),
	 (1700251,'ABREULANDIA',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1700301,'AGUIARNOPOLIS',17),
	 (1700350,'ALIANCA DO TOCANTINS',17),
	 (1700400,'ALMAS',17),
	 (1700707,'ALVORADA',17),
	 (1701002,'ANANAS',17),
	 (1701051,'ANGICO',17),
	 (1701101,'APARECIDA DO RIO NEGRO',17),
	 (1701309,'ARAGOMINAS',17),
	 (1701903,'ARAGUACEMA',17),
	 (1702000,'ARAGUACU',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1702109,'ARAGUAINA',17),
	 (1702158,'ARAGUANA',17),
	 (1702208,'ARAGUATINS',17),
	 (1702307,'ARAPOEMA',17),
	 (1702406,'ARRAIAS',17),
	 (1702554,'AUGUSTINOPOLIS',17),
	 (1702703,'AURORA DO TOCANTINS',17),
	 (1702901,'AXIXA DO TOCANTINS',17),
	 (1703008,'BABACULANDIA',17),
	 (1703073,'BARRA DO OURO',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1703107,'BARROLANDIA',17),
	 (1703206,'BERNARDO SAYAO',17),
	 (1703305,'BOM JESUS DO TOCANTINS',17),
	 (1703602,'BRASILANDIA DO TOCANTINS',17),
	 (1703701,'BREJINHO DE NAZARE',17),
	 (1703800,'BURITI DO TOCANTINS',17),
	 (1703826,'CACHOEIRINHA',17),
	 (1703842,'CAMPOS LINDOS',17),
	 (1703867,'CARIRI DO TOCANTINS',17),
	 (1703883,'CARMOLANDIA',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1703891,'CARRASCO BONITO',17),
	 (1703909,'CASEARA',17),
	 (1704105,'CENTENARIO',17),
	 (1704600,'CHAPADA DE AREIA',17),
	 (1705102,'CHAPADA DA NATIVIDADE',17),
	 (1705508,'COLINAS DO TOCANTINS',17),
	 (1705557,'COMBINADO',17),
	 (1705607,'CONCEICAO DO TOCANTINS',17),
	 (1706001,'COUTO DE MAGALHAES',17),
	 (1706100,'CRISTALANDIA',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1706258,'CRIXAS DO TOCANTINS',17),
	 (1706506,'DARCINOPOLIS',17),
	 (1707009,'DIANOPOLIS',17),
	 (1707108,'DIVINOPOLIS DO TOCANTINS',17),
	 (1707207,'DOIS IRMAOS DO TOCANTINS',17),
	 (1707306,'DUERE',17),
	 (1707405,'ESPERANTINA',17),
	 (1707553,'FATIMA',17),
	 (1707652,'FIGUEIROPOLIS',17),
	 (1707702,'FILADELFIA',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1708205,'FORMOSO DO ARAGUAIA',17),
	 (1708254,'FORTALEZA DO TABOCAO',17),
	 (1708304,'GOIANORTE',17),
	 (1709005,'GOIATINS',17),
	 (1709302,'GUARAI',17),
	 (1709500,'GURUPI',17),
	 (1709807,'IPUEIRAS',17),
	 (1710508,'ITACAJA',17),
	 (1710706,'ITAGUATINS',17),
	 (1710904,'ITAPIRATINS',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1711100,'ITAPORA DO TOCANTINS',17),
	 (1711506,'JAU DO TOCANTINS',17),
	 (1711803,'JUARINA',17),
	 (1711902,'LAGOA DA CONFUSAO',17),
	 (1711951,'LAGOA DO TOCANTINS',17),
	 (1712009,'LAJEADO',17),
	 (1712157,'LAVANDEIRA',17),
	 (1712405,'LIZARDA',17),
	 (1712454,'LUZINOPOLIS',17),
	 (1712504,'MARIANOPOLIS DO TOCANTINS',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1712702,'MATEIROS',17),
	 (1712801,'MAURILANDIA DO TOCANTINS',17),
	 (1713205,'MIRACEMA DO TOCANTINS',17),
	 (1713304,'MIRANORTE',17),
	 (1713601,'MONTE DO CARMO',17),
	 (1713700,'MONTE SANTO DO TOCANTINS',17),
	 (1713809,'PALMEIRAS DO TOCANTINS',17),
	 (1713957,'MURICILANDIA',17),
	 (1714203,'NATIVIDADE',17),
	 (1714302,'NAZARE',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1714880,'NOVA OLINDA',17),
	 (1715002,'NOVA ROSALANDIA',17),
	 (1715101,'NOVO ACORDO',17),
	 (1715150,'NOVO ALEGRE',17),
	 (1715259,'NOVO JARDIM',17),
	 (1715507,'OLIVEIRA DE FATIMA',17),
	 (1715705,'PALMEIRANTE',17),
	 (1715754,'PALMEIROPOLIS',17),
	 (1716109,'PARAISO DO TOCANTINS',17),
	 (1716208,'PARANA',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1716307,'PAU D ARCO',17),
	 (1716505,'PEDRO AFONSO',17),
	 (1716604,'PEIXE',17),
	 (1716653,'PEQUIZEIRO',17),
	 (1716703,'COLMEIA',17),
	 (1717008,'PINDORAMA DO TOCANTINS',17),
	 (1717206,'PIRAQUE',17),
	 (1717503,'PIUM',17),
	 (1717800,'PONTE ALTA DO BOM JESUS',17),
	 (1717909,'PONTE ALTA DO TOCANTINS',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1718006,'PORTO ALEGRE DO TOCANTINS',17),
	 (1718204,'PORTO NACIONAL',17),
	 (1718303,'PRAIA NORTE',17),
	 (1718402,'PRESIDENTE KENNEDY',17),
	 (1718451,'PUGMIL',17),
	 (1718501,'RECURSOLANDIA',17),
	 (1718550,'RIACHINHO',17),
	 (1718659,'RIO DA CONCEICAO',17),
	 (1718709,'RIO DOS BOIS',17),
	 (1718758,'RIO SONO',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1718808,'SAMPAIO',17),
	 (1718840,'SANDOLANDIA',17),
	 (1718865,'SANTA FE DO ARAGUAIA',17),
	 (1718881,'SANTA MARIA DO TOCANTINS',17),
	 (1718899,'SANTA RITA DO TOCANTINS',17),
	 (1718907,'SANTA ROSA DO TOCANTINS',17),
	 (1719004,'SANTA TEREZA DO TOCANTINS',17),
	 (1720002,'SANTA TEREZINHA DO TOCANTINS',17),
	 (1720101,'SAO BENTO DO TOCANTINS',17),
	 (1720150,'SAO FELIX DO TOCANTINS',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1720200,'SAO MIGUEL DO TOCANTINS',17),
	 (1720259,'SAO SALVADOR DO TOCANTINS',17),
	 (1720309,'SAO SEBASTIAO DO TOCANTINS',17),
	 (1720499,'SAO VALERIO DA NATIVIDADE',17),
	 (1720655,'SILVANOPOLIS',17),
	 (1720804,'SITIO NOVO DO TOCANTINS',17),
	 (1720853,'SUCUPIRA',17),
	 (1720903,'TAGUATINGA',17),
	 (1720937,'TAIPAS DO TOCANTINS',17),
	 (1720978,'TALISMA',17);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1721000,'PALMAS',17),
	 (1721109,'TOCANTINIA',17),
	 (1721208,'TOCANTINOPOLIS',17),
	 (1721257,'TUPIRAMA',17),
	 (1721307,'TUPIRATINS',17),
	 (1722081,'WANDERLANDIA',17),
	 (1722107,'XAMBIOA',17),
	 (2100055,'ACAILANDIA',21),
	 (2100105,'AFONSO CUNHA',21),
	 (2100154,'AGUA DOCE DO MARANHAO',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2100204,'ALCANTARA',21),
	 (2100303,'ALDEIAS ALTAS',21),
	 (2100402,'ALTAMIRA DO MARANHAO',21),
	 (2100436,'ALTO ALEGRE DO MARANHAO',21),
	 (2100477,'ALTO ALEGRE DO PINDARE',21),
	 (2100501,'ALTO PARNAIBA',21),
	 (2100550,'AMAPA DO MARANHAO',21),
	 (2100600,'AMARANTE DO MARANHAO',21),
	 (2100709,'ANAJATUBA',21),
	 (2100808,'ANAPURUS',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2100832,'APICUM-ACU',21),
	 (2100873,'ARAGUANA',21),
	 (2100907,'ARAIOSES',21),
	 (2100956,'ARAME',21),
	 (2101004,'ARARI',21),
	 (2101103,'AXIXA',21),
	 (2101202,'BACABAL',21),
	 (2101251,'BACABEIRA',21),
	 (2101301,'BACURI',21),
	 (2101350,'BACURITUBA',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2101400,'BALSAS',21),
	 (2101509,'BARAO DE GRAJAU',21),
	 (2101608,'BARRA DO CORDA',21),
	 (2101707,'BARREIRINHAS',21),
	 (2101731,'BELAGUA',21),
	 (2101772,'BELA VISTA DO MARANHAO',21),
	 (2101806,'BENEDITO LEITE',21),
	 (2101905,'BEQUIMAO',21),
	 (2101939,'BERNARDO DO MEARIM',21),
	 (2101970,'BOA VISTA DO GURUPI',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2102002,'BOM JARDIM',21),
	 (2102036,'BOM JESUS DAS SELVAS',21),
	 (2102077,'BOM LUGAR',21),
	 (2102101,'BREJO',21),
	 (2102150,'BREJO DE AREIA',21),
	 (2102200,'BURITI',21),
	 (2102309,'BURITI BRAVO',21),
	 (2102325,'BURITICUPU',21),
	 (2102358,'BURITIRANA',21),
	 (2102374,'CACHOEIRA GRANDE',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2102408,'CAJAPIO',21),
	 (2102507,'CAJARI',21),
	 (2102556,'CAMPESTRE DO MARANHAO',21),
	 (2102606,'CANDIDO MENDES',21),
	 (2102705,'CANTANHEDE',21),
	 (2102754,'CAPINZAL DO NORTE',21),
	 (2102804,'CAROLINA',21),
	 (2102903,'CARUTAPERA',21),
	 (2103000,'CAXIAS',21),
	 (2103109,'CEDRAL',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2103125,'CENTRAL DO MARANHAO',21),
	 (2103158,'CENTRO DO GUILHERME',21),
	 (2103174,'CENTRO NOVO DO MARANHAO',21),
	 (2103208,'CHAPADINHA',21),
	 (2103257,'CIDELANDIA',21),
	 (2103307,'CODO',21),
	 (2103406,'COELHO NETO',21),
	 (2103505,'COLINAS',21),
	 (2103554,'CONCEICAO DO LAGO-ACU',21),
	 (2103604,'COROATA',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2103703,'CURURUPU',21),
	 (2103752,'DAVINOPOLIS',21),
	 (2103802,'DOM PEDRO',21),
	 (2103901,'DUQUE BACELAR',21),
	 (2104008,'ESPERANTINOPOLIS',21),
	 (2104057,'ESTREITO',21),
	 (2104073,'FEIRA NOVA DO MARANHAO',21),
	 (2104081,'FERNANDO FALCAO',21),
	 (2104099,'FORMOSA DA SERRA NEGRA',21),
	 (2104107,'FORTALEZA DOS NOGUEIRAS',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2104206,'FORTUNA',21),
	 (2104305,'GODOFREDO VIANA',21),
	 (2104404,'GONCALVES DIAS',21),
	 (2104503,'GOVERNADOR ARCHER',21),
	 (2104552,'GOVERNADOR EDISON LOBAO',21),
	 (2104602,'GOVERNADOR EUGENIO BARROS',21),
	 (2104628,'GOVERNADOR LUIZ ROCHA',21),
	 (2104651,'GOVERNADOR NEWTON BELLO',21),
	 (2104677,'GOVERNADOR NUNES FREIRE',21),
	 (2104701,'GRACA ARANHA',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2104800,'GRAJAU',21),
	 (2104909,'GUIMARAES',21),
	 (2105005,'HUMBERTO DE CAMPOS',21),
	 (2105104,'ICATU',21),
	 (2105153,'IGARAPE DO MEIO',21),
	 (2105203,'IGARAPE GRANDE',21),
	 (2105302,'IMPERATRIZ',21),
	 (2105351,'ITAIPAVA DO GRAJAU',21),
	 (2105401,'ITAPECURU MIRIM',21),
	 (2105427,'ITINGA DO MARANHAO',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2105450,'JATOBA',21),
	 (2105476,'JENIPAPO DOS VIEIRAS',21),
	 (2105500,'JOAO LISBOA',21),
	 (2105609,'JOSELANDIA',21),
	 (2105658,'JUNCO DO MARANHAO',21),
	 (2105708,'LAGO DA PEDRA',21),
	 (2105807,'LAGO DO JUNCO',21),
	 (2105906,'LAGO VERDE',21),
	 (2105922,'LAGOA DO MATO',21),
	 (2105948,'LAGO DOS RODRIGUES',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2105963,'LAGOA GRANDE DO MARANHAO',21),
	 (2105989,'LAJEADO NOVO',21),
	 (2106003,'LIMA CAMPOS',21),
	 (2106102,'LORETO',21),
	 (2106201,'LUIS DOMINGUES',21),
	 (2106300,'MAGALHAES DE ALMEIDA',21),
	 (2106326,'MARACACUME',21),
	 (2106359,'MARAJA DO SENA',21),
	 (2106375,'MARANHAOZINHO',21),
	 (2106409,'MATA ROMA',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2106508,'MATINHA',21),
	 (2106607,'MATOES',21),
	 (2106631,'MATOES DO NORTE',21),
	 (2106672,'MILAGRES DO MARANHAO',21),
	 (2106706,'MIRADOR',21),
	 (2106755,'MIRANDA DO NORTE',21),
	 (2106805,'MIRINZAL',21),
	 (2106904,'MONCAO',21),
	 (2107001,'MONTES ALTOS',21),
	 (2107100,'MORROS',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2107209,'NINA RODRIGUES',21),
	 (2107258,'NOVA COLINAS',21),
	 (2107308,'NOVA IORQUE',21),
	 (2107357,'NOVA OLINDA DO MARANHAO',21),
	 (2107407,'OLHO D AGUA DAS CUNHAS',21),
	 (2107456,'OLINDA NOVA DO MARANHAO',21),
	 (2107506,'PACO DO LUMIAR',21),
	 (2107605,'PALMEIRANDIA',21),
	 (2107704,'PARAIBANO',21),
	 (2107803,'PARNARAMA',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2107902,'PASSAGEM FRANCA',21),
	 (2108009,'PASTOS BONS',21),
	 (2108058,'PAULINO NEVES',21),
	 (2108108,'PAULO RAMOS',21),
	 (2108207,'PEDREIRAS',21),
	 (2108256,'PEDRO DO ROSARIO',21),
	 (2108306,'PENALVA',21),
	 (2108405,'PERI MIRIM',21),
	 (2108454,'PERITORO',21),
	 (2108504,'PINDARE-MIRIM',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2108603,'PINHEIRO',21),
	 (2108702,'PIO XII',21),
	 (2108801,'PIRAPEMAS',21),
	 (2108900,'POCAO DE PEDRAS',21),
	 (2109007,'PORTO FRANCO',21),
	 (2109056,'PORTO RICO DO MARANHAO',21),
	 (2109106,'PRESIDENTE DUTRA',21),
	 (2109205,'PRESIDENTE JUSCELINO',21),
	 (2109239,'PRESIDENTE MEDICI',21),
	 (2109270,'PRESIDENTE SARNEY',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2109304,'PRESIDENTE VARGAS',21),
	 (2109403,'PRIMEIRA CRUZ',21),
	 (2109452,'RAPOSA',21),
	 (2109502,'RIACHAO',21),
	 (2109551,'RIBAMAR FIQUENE',21),
	 (2109601,'ROSARIO',21),
	 (2109700,'SAMBAIBA',21),
	 (2109759,'SANTA FILOMENA DO MARANHAO',21),
	 (2109809,'SANTA HELENA',21),
	 (2109908,'SANTA INES',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2110005,'SANTA LUZIA',21),
	 (2110039,'SANTA LUZIA DO PARUA',21),
	 (2110104,'SANTA QUITERIA DO MARANHAO',21),
	 (2110203,'SANTA RITA',21),
	 (2110237,'SANTANA DO MARANHAO',21),
	 (2110278,'SANTO AMARO DO MARANHAO',21),
	 (2110302,'SANTO ANTONIO DOS LOPES',21),
	 (2110401,'SAO BENEDITO DO RIO PRETO',21),
	 (2110500,'SAO BENTO',21),
	 (2110609,'SAO BERNARDO',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2110658,'SAO DOMINGOS DO AZEITAO',21),
	 (2110708,'SAO DOMINGOS DO MARANHAO',21),
	 (2110807,'SAO FELIX DE BALSAS',21),
	 (2110856,'SAO FRANCISCO DO BREJAO',21),
	 (2110906,'SAO FRANCISCO DO MARANHAO',21),
	 (2111003,'SAO JOAO BATISTA',21),
	 (2111029,'SAO JOAO DO CARU',21),
	 (2111052,'SAO JOAO DO PARAISO',21),
	 (2111078,'SAO JOAO DO SOTER',21),
	 (2111102,'SAO JOAO DOS PATOS',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2111201,'SAO JOSE DE RIBAMAR',21),
	 (2111250,'SAO JOSE DOS BASILIOS',21),
	 (2111300,'SAO LUIS',21),
	 (2111409,'SAO LUIS GONZAGA DO MARANHAO',21),
	 (2111508,'SAO MATEUS DO MARANHAO',21),
	 (2111532,'SAO PEDRO DA AGUA BRANCA',21),
	 (2111573,'SAO PEDRO DOS CRENTES',21),
	 (2111607,'SAO RAIMUNDO DAS MANGABEIRAS',21),
	 (2111631,'SAO RAIMUNDO DO DOCA BEZERRA',21),
	 (2111672,'SAO ROBERTO',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2111706,'SAO VICENTE FERRER',21),
	 (2111722,'SATUBINHA',21),
	 (2111748,'SENADOR ALEXANDRE COSTA',21),
	 (2111763,'SENADOR LA ROCQUE',21),
	 (2111789,'SERRANO DO MARANHAO',21),
	 (2111805,'SITIO NOVO',21),
	 (2111904,'SUCUPIRA DO NORTE',21),
	 (2111953,'SUCUPIRA DO RIACHAO',21),
	 (2112001,'TASSO FRAGOSO',21),
	 (2112100,'TIMBIRAS',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2112209,'TIMON',21),
	 (2112233,'TRIZIDELA DO VALE',21),
	 (2112274,'TUFILANDIA',21),
	 (2112308,'TUNTUM',21),
	 (2112407,'TURIACU',21),
	 (2112456,'TURILANDIA',21),
	 (2112506,'TUTOIA',21),
	 (2112605,'URBANO SANTOS',21),
	 (2112704,'VARGEM GRANDE',21),
	 (2112803,'VIANA',21);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2112852,'VILA NOVA DOS MARTIRIOS',21),
	 (2112902,'VITORIA DO MEARIM',21),
	 (2113009,'VITORINO FREIRE',21),
	 (2114007,'ZE DOCA',21),
	 (2200053,'ACAUA',22),
	 (2200103,'AGRICOLANDIA',22),
	 (2200202,'AGUA BRANCA',22),
	 (2200251,'ALAGOINHA DO PIAUI',22),
	 (2200277,'ALEGRETE DO PIAUI',22),
	 (2200301,'ALTO LONGA',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2200400,'ALTOS',22),
	 (2200459,'ALVORADA DO GURGUEIA',22),
	 (2200509,'AMARANTE',22),
	 (2200608,'ANGICAL DO PIAUI',22),
	 (2200707,'ANISIO DE ABREU',22),
	 (2200806,'ANTONIO ALMEIDA',22),
	 (2200905,'AROAZES',22),
	 (2200954,'AROEIRAS DO ITAIM',22),
	 (2201002,'ARRAIAL',22),
	 (2201051,'ASSUNCAO DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2201101,'AVELINO LOPES',22),
	 (2201150,'BAIXA GRANDE DO RIBEIRO',22),
	 (2201176,'BARRA D ALCANTARA',22),
	 (2201200,'BARRAS',22),
	 (2201309,'BARREIRAS DO PIAUI',22),
	 (2201408,'BARRO DURO',22),
	 (2201507,'BATALHA',22),
	 (2201556,'BELA VISTA DO PIAUI',22),
	 (2201572,'BELEM DO PIAUI',22),
	 (2201606,'BENEDITINOS',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2201705,'BERTOLINIA',22),
	 (2201739,'BETANIA DO PIAUI',22),
	 (2201770,'BOA HORA',22),
	 (2201804,'BOCAINA',22),
	 (2201903,'BOM JESUS',22),
	 (2201919,'BOM PRINCIPIO DO PIAUI',22),
	 (2201929,'BONFIM DO PIAUI',22),
	 (2201945,'BOQUEIRAO DO PIAUI',22),
	 (2201960,'BRASILEIRA',22),
	 (2201988,'BREJO DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2202000,'BURITI DOS LOPES',22),
	 (2202026,'BURITI DOS MONTES',22),
	 (2202059,'CABECEIRAS DO PIAUI',22),
	 (2202075,'CAJAZEIRAS DO PIAUI',22),
	 (2202083,'CAJUEIRO DA PRAIA',22),
	 (2202091,'CALDEIRAO GRANDE DO PIAUI',22),
	 (2202109,'CAMPINAS DO PIAUI',22),
	 (2202117,'CAMPO ALEGRE DO FIDALGO',22),
	 (2202133,'CAMPO GRANDE DO PIAUI',22),
	 (2202174,'CAMPO LARGO DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2202208,'CAMPO MAIOR',22),
	 (2202251,'CANAVIEIRA',22),
	 (2202307,'CANTO DO BURITI',22),
	 (2202406,'CAPITAO DE CAMPOS',22),
	 (2202455,'CAPITAO GERVASIO OLIVEIRA',22),
	 (2202505,'CARACOL',22),
	 (2202539,'CARAUBAS DO PIAUI',22),
	 (2202554,'CARIDADE DO PIAUI',22),
	 (2202604,'CASTELO DO PIAUI',22),
	 (2202653,'CAXINGO',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2202703,'COCAL',22),
	 (2202711,'COCAL DE TELHA',22),
	 (2202729,'COCAL DOS ALVES',22),
	 (2202737,'COIVARAS',22),
	 (2202752,'COLONIA DO GURGUEIA',22),
	 (2202778,'COLONIA DO PIAUI',22),
	 (2202802,'CONCEICAO DO CANINDE',22),
	 (2202851,'CORONEL JOSE DIAS',22),
	 (2202901,'CORRENTE',22),
	 (2203008,'CRISTALANDIA DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2203107,'CRISTINO CASTRO',22),
	 (2203206,'CURIMATA',22),
	 (2203230,'CURRAIS',22),
	 (2203255,'CURRALINHOS',22),
	 (2203271,'CURRAL NOVO DO PIAUI',22),
	 (2203305,'DEMERVAL LOBAO',22),
	 (2203354,'DIRCEU ARCOVERDE',22),
	 (2203404,'DOM EXPEDITO LOPES',22),
	 (2203420,'DOMINGOS MOURAO',22),
	 (2203453,'DOM INOCENCIO',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2203503,'ELESBAO VELOSO',22),
	 (2203602,'ELISEU MARTINS',22),
	 (2203701,'ESPERANTINA',22),
	 (2203750,'FARTURA DO PIAUI',22),
	 (2203800,'FLORES DO PIAUI',22),
	 (2203859,'FLORESTA DO PIAUI',22),
	 (2203909,'FLORIANO',22),
	 (2204006,'FRANCINOPOLIS',22),
	 (2204105,'FRANCISCO AYRES',22),
	 (2204154,'FRANCISCO MACEDO',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2204204,'FRANCISCO SANTOS',22),
	 (2204303,'FRONTEIRAS',22),
	 (2204352,'GEMINIANO',22),
	 (2204402,'GILBUES',22),
	 (2204501,'GUADALUPE',22),
	 (2204550,'GUARIBAS',22),
	 (2204600,'HUGO NAPOLEAO',22),
	 (2204659,'ILHA GRANDE',22),
	 (2204709,'INHUMA',22),
	 (2204808,'IPIRANGA DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2204907,'ISAIAS COELHO',22),
	 (2205003,'ITAINOPOLIS',22),
	 (2205102,'ITAUEIRA',22),
	 (2205151,'JACOBINA DO PIAUI',22),
	 (2205201,'JAICOS',22),
	 (2205250,'JARDIM DO MULATO',22),
	 (2205276,'JATOBA DO PIAUI',22),
	 (2205300,'JERUMENHA',22),
	 (2205359,'JOAO COSTA',22),
	 (2205409,'JOAQUIM PIRES',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2205458,'JOCA MARQUES',22),
	 (2205508,'JOSE DE FREITAS',22),
	 (2205516,'JUAZEIRO DO PIAUI',22),
	 (2205524,'JULIO BORGES',22),
	 (2205532,'JUREMA',22),
	 (2205540,'LAGOINHA DO PIAUI',22),
	 (2205557,'LAGOA ALEGRE',22),
	 (2205565,'LAGOA DO BARRO DO PIAUI',22),
	 (2205573,'LAGOA DE SAO FRANCISCO',22),
	 (2205581,'LAGOA DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2205599,'LAGOA DO SITIO',22),
	 (2205607,'LANDRI SALES',22),
	 (2205706,'LUIS CORREIA',22),
	 (2205805,'LUZILANDIA',22),
	 (2205854,'MADEIRO',22),
	 (2205904,'MANOEL EMIDIO',22),
	 (2205953,'MARCOLANDIA',22),
	 (2206001,'MARCOS PARENTE',22),
	 (2206050,'MASSAPE DO PIAUI',22),
	 (2206100,'MATIAS OLIMPIO',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2206209,'MIGUEL ALVES',22),
	 (2206308,'MIGUEL LEAO',22),
	 (2206357,'MILTON BRANDAO',22),
	 (2206407,'MONSENHOR GIL',22),
	 (2206506,'MONSENHOR HIPOLITO',22),
	 (2206605,'MONTE ALEGRE DO PIAUI',22),
	 (2206654,'MORRO CABECA NO TEMPO',22),
	 (2206670,'MORRO DO CHAPEU DO PIAUI',22),
	 (2206696,'MURICI DOS PORTELAS',22),
	 (2206704,'NAZARE DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2206753,'NOSSA SENHORA DE NAZARE',22),
	 (2206803,'NOSSA SENHORA DOS REMEDIOS',22),
	 (2206902,'NOVO ORIENTE DO PIAUI',22),
	 (2206951,'NOVO SANTO ANTONIO',22),
	 (2207009,'OEIRAS',22),
	 (2207108,'OLHO D AGUA DO PIAUI',22),
	 (2207207,'PADRE MARCOS',22),
	 (2207306,'PAES LANDIM',22),
	 (2207355,'PAJEU DO PIAUI',22),
	 (2207405,'PALMEIRA DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2207504,'PALMEIRAIS',22),
	 (2207553,'PAQUETA',22),
	 (2207603,'PARNAGUA',22),
	 (2207702,'PARNAIBA',22),
	 (2207751,'PASSAGEM FRANCA DO PIAUI',22),
	 (2207777,'PATOS DO PIAUI',22),
	 (2207793,'PAU D ARCO DO PIAUI',22),
	 (2207801,'PAULISTANA',22),
	 (2207850,'PAVUSSU',22),
	 (2207900,'PEDRO II',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2207934,'PEDRO LAURENTINO',22),
	 (2207959,'NOVA SANTA RITA',22),
	 (2208007,'PICOS',22),
	 (2208106,'PIMENTEIRAS',22),
	 (2208205,'PIO IX',22),
	 (2208304,'PIRACURUCA',22),
	 (2208403,'PIRIPIRI',22),
	 (2208502,'PORTO',22),
	 (2208551,'PORTO ALEGRE DO PIAUI',22),
	 (2208601,'PRATA DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2208650,'QUEIMADA NOVA',22),
	 (2208700,'REDENCAO DO GURGUEIA',22),
	 (2208809,'REGENERACAO',22),
	 (2208858,'RIACHO FRIO',22),
	 (2208874,'RIBEIRA DO PIAUI',22),
	 (2208908,'RIBEIRO GONCALVES',22),
	 (2209005,'RIO GRANDE DO PIAUI',22),
	 (2209104,'SANTA CRUZ DO PIAUI',22),
	 (2209153,'SANTA CRUZ DOS MILAGRES',22),
	 (2209203,'SANTA FILOMENA',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2209302,'SANTA LUZ',22),
	 (2209351,'SANTANA DO PIAUI',22),
	 (2209377,'SANTA ROSA DO PIAUI',22),
	 (2209401,'SANTO ANTONIO DE LISBOA',22),
	 (2209450,'SANTO ANTONIO DOS MILAGRES',22),
	 (2209500,'SANTO INACIO DO PIAUI',22),
	 (2209559,'SAO BRAZ DO PIAUI',22),
	 (2209609,'SAO FELIX DO PIAUI',22),
	 (2209658,'SAO FRANCISCO DE ASSIS DO PIAUI',22),
	 (2209708,'SAO FRANCISCO DO PIAUI',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2209757,'SAO GONCALO DO GURGUEIA',22),
	 (2209807,'SAO GONCALO DO PIAUI',22),
	 (2209856,'SAO JOAO DA CANABRAVA',22),
	 (2209872,'SAO JOAO DA FRONTEIRA',22),
	 (2209906,'SAO JOAO DA SERRA',22),
	 (2209955,'SAO JOAO DA VARJOTA',22),
	 (2209971,'SAO JOAO DO ARRAIAL',22),
	 (2210003,'SAO JOAO DO PIAUI',22),
	 (2210052,'SAO JOSE DO DIVINO',22),
	 (2210102,'SAO JOSE DO PEIXE',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2210201,'SAO JOSE DO PIAUI',22),
	 (2210300,'SAO JULIAO',22),
	 (2210359,'SAO LOURENCO DO PIAUI',22),
	 (2210375,'SAO LUIS DO PIAUI',22),
	 (2210383,'SAO MIGUEL DA BAIXA GRANDE',22),
	 (2210391,'SAO MIGUEL DO FIDALGO',22),
	 (2210409,'SAO MIGUEL DO TAPUIO',22),
	 (2210508,'SAO PEDRO DO PIAUI',22),
	 (2210607,'SAO RAIMUNDO NONATO',22),
	 (2210623,'SEBASTIAO BARROS',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2210631,'SEBASTIAO LEAL',22),
	 (2210656,'SIGEFREDO PACHECO',22),
	 (2210706,'SIMOES',22),
	 (2210805,'SIMPLICIO MENDES',22),
	 (2210904,'SOCORRO DO PIAUI',22),
	 (2210938,'SUSSUAPARA',22),
	 (2210953,'TAMBORIL DO PIAUI',22),
	 (2210979,'TANQUE DO PIAUI',22),
	 (2211001,'TERESINA',22),
	 (2211100,'UNIAO',22);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2211209,'URUCUI',22),
	 (2211308,'VALENCA DO PIAUI',22),
	 (2211357,'VARZEA BRANCA',22),
	 (2211407,'VARZEA GRANDE',22),
	 (2211506,'VERA MENDES',22),
	 (2211605,'VILA NOVA DO PIAUI',22),
	 (2211704,'WALL FERRAZ',22),
	 (2300101,'ABAIARA',23),
	 (2300150,'ACARAPE',23),
	 (2300200,'ACARAU',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2300309,'ACOPIARA',23),
	 (2300408,'AIUABA',23),
	 (2300507,'ALCANTARAS',23),
	 (2300606,'ALTANEIRA',23),
	 (2300705,'ALTO SANTO',23),
	 (2300754,'AMONTADA',23),
	 (2300804,'ANTONINA DO NORTE',23),
	 (2300903,'APUIARES',23),
	 (2301000,'AQUIRAZ',23),
	 (2301109,'ARACATI',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2301208,'ARACOIABA',23),
	 (2301257,'ARARENDA',23),
	 (2301307,'ARARIPE',23),
	 (2301406,'ARATUBA',23),
	 (2301505,'ARNEIROZ',23),
	 (2301604,'ASSARE',23),
	 (2301703,'AURORA',23),
	 (2301802,'BAIXIO',23),
	 (2301851,'BANABUIU',23),
	 (2301901,'BARBALHA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2301950,'BARREIRA',23),
	 (2302008,'BARRO',23),
	 (2302057,'BARROQUINHA',23),
	 (2302107,'BATURITE',23),
	 (2302206,'BEBERIBE',23),
	 (2302305,'BELA CRUZ',23),
	 (2302404,'BOA VIAGEM',23),
	 (2302503,'BREJO SANTO',23),
	 (2302602,'CAMOCIM',23),
	 (2302701,'CAMPOS SALES',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2302800,'CANINDE',23),
	 (2302909,'CAPISTRANO',23),
	 (2303006,'CARIDADE',23),
	 (2303105,'CARIRE',23),
	 (2303204,'CARIRIACU',23),
	 (2303303,'CARIUS',23),
	 (2303402,'CARNAUBAL',23),
	 (2303501,'CASCAVEL',23),
	 (2303600,'CATARINA',23),
	 (2303659,'CATUNDA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2303709,'CAUCAIA',23),
	 (2303808,'CEDRO',23),
	 (2303907,'CHAVAL',23),
	 (2303931,'CHORO',23),
	 (2303956,'CHOROZINHO',23),
	 (2304004,'COREAU',23),
	 (2304103,'CRATEUS',23),
	 (2304202,'CRATO',23),
	 (2304236,'CROATA',23),
	 (2304251,'CRUZ',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2304269,'DEPUTADO IRAPUAN PINHEIRO',23),
	 (2304277,'ERERE',23),
	 (2304285,'EUSEBIO',23),
	 (2304301,'FARIAS BRITO',23),
	 (2304350,'FORQUILHA',23),
	 (2304400,'FORTALEZA',23),
	 (2304459,'FORTIM',23),
	 (2304509,'FRECHEIRINHA',23),
	 (2304608,'GENERAL SAMPAIO',23),
	 (2304657,'GRACA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2304707,'GRANJA',23),
	 (2304806,'GRANJEIRO',23),
	 (2304905,'GROAIRAS',23),
	 (2304954,'GUAIUBA',23),
	 (2305001,'GUARACIABA DO NORTE',23),
	 (2305100,'GUARAMIRANGA',23),
	 (2305209,'HIDROLANDIA',23),
	 (2305233,'HORIZONTE',23),
	 (2305266,'IBARETAMA',23),
	 (2305308,'IBIAPINA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2305332,'IBICUITINGA',23),
	 (2305357,'ICAPUI',23),
	 (2305407,'ICO',23),
	 (2305506,'IGUATU',23),
	 (2305605,'INDEPENDENCIA',23),
	 (2305654,'IPAPORANGA',23),
	 (2305704,'IPAUMIRIM',23),
	 (2305803,'IPU',23),
	 (2305902,'IPUEIRAS',23),
	 (2306009,'IRACEMA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2306108,'IRAUCUBA',23),
	 (2306207,'ITAICABA',23),
	 (2306256,'ITAITINGA',23),
	 (2306306,'ITAPAGE',23),
	 (2306405,'ITAPIPOCA',23),
	 (2306504,'ITAPIUNA',23),
	 (2306553,'ITAREMA',23),
	 (2306603,'ITATIRA',23),
	 (2306702,'JAGUARETAMA',23),
	 (2306801,'JAGUARIBARA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2306900,'JAGUARIBE',23),
	 (2307007,'JAGUARUANA',23),
	 (2307106,'JARDIM',23),
	 (2307205,'JATI',23),
	 (2307254,'JIJOCA DE JERICOACOARA',23),
	 (2307304,'JUAZEIRO DO NORTE',23),
	 (2307403,'JUCAS',23),
	 (2307502,'LAVRAS DA MANGABEIRA',23),
	 (2307601,'LIMOEIRO DO NORTE',23),
	 (2307635,'MADALENA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2307650,'MARACANAU',23),
	 (2307700,'MARANGUAPE',23),
	 (2307809,'MARCO',23),
	 (2307908,'MARTINOPOLE',23),
	 (2308005,'MASSAPE',23),
	 (2308104,'MAURITI',23),
	 (2308203,'MERUOCA',23),
	 (2308302,'MILAGRES',23),
	 (2308351,'MILHA',23),
	 (2308377,'MIRAIMA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2308401,'MISSAO VELHA',23),
	 (2308500,'MOMBACA',23),
	 (2308609,'MONSENHOR TABOSA',23),
	 (2308708,'MORADA NOVA',23),
	 (2308807,'MORAUJO',23),
	 (2308906,'MORRINHOS',23),
	 (2309003,'MUCAMBO',23),
	 (2309102,'MULUNGU',23),
	 (2309201,'NOVA OLINDA',23),
	 (2309300,'NOVA RUSSAS',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2309409,'NOVO ORIENTE',23),
	 (2309458,'OCARA',23),
	 (2309508,'OROS',23),
	 (2309607,'PACAJUS',23),
	 (2309706,'PACATUBA',23),
	 (2309805,'PACOTI',23),
	 (2309904,'PACUJA',23),
	 (2310001,'PALHANO',23),
	 (2310100,'PALMACIA',23),
	 (2310209,'PARACURU',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2310258,'PARAIPABA',23),
	 (2310308,'PARAMBU',23),
	 (2310407,'PARAMOTI',23),
	 (2310506,'PEDRA BRANCA',23),
	 (2310605,'PENAFORTE',23),
	 (2310704,'PENTECOSTE',23),
	 (2310803,'PEREIRO',23),
	 (2310852,'PINDORETAMA',23),
	 (2310902,'PIQUET CARNEIRO',23),
	 (2310951,'PIRES FERREIRA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2311009,'PORANGA',23),
	 (2311108,'PORTEIRAS',23),
	 (2311207,'POTENGI',23),
	 (2311231,'POTIRETAMA',23),
	 (2311264,'QUITERIANOPOLIS',23),
	 (2311306,'QUIXADA',23),
	 (2311355,'QUIXELO',23),
	 (2311405,'QUIXERAMOBIM',23),
	 (2311504,'QUIXERE',23),
	 (2311603,'REDENCAO',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2311702,'RERIUTABA',23),
	 (2311801,'RUSSAS',23),
	 (2311900,'SABOEIRO',23),
	 (2311959,'SALITRE',23),
	 (2312007,'SANTANA DO ACARAU',23),
	 (2312106,'SANTANA DO CARIRI',23),
	 (2312205,'SANTA QUITERIA',23),
	 (2312304,'SAO BENEDITO',23),
	 (2312403,'SAO GONCALO DO AMARANTE',23),
	 (2312502,'SAO JOAO DO JAGUARIBE',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2312601,'SAO LUIS DO CURU',23),
	 (2312700,'SENADOR POMPEU',23),
	 (2312809,'SENADOR SA',23),
	 (2312908,'SOBRAL',23),
	 (2313005,'SOLONOPOLE',23),
	 (2313104,'TABULEIRO DO NORTE',23),
	 (2313203,'TAMBORIL',23),
	 (2313252,'TARRAFAS',23),
	 (2313302,'TAUA',23),
	 (2313351,'TEJUCUOCA',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2313401,'TIANGUA',23),
	 (2313500,'TRAIRI',23),
	 (2313559,'TURURU',23),
	 (2313609,'UBAJARA',23),
	 (2313708,'UMARI',23),
	 (2313757,'UMIRIM',23),
	 (2313807,'URUBURETAMA',23),
	 (2313906,'URUOCA',23),
	 (2313955,'VARJOTA',23),
	 (2314003,'VARZEA ALEGRE',23);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2314102,'VICOSA DO CEARA',23),
	 (2400109,'ACARI',24),
	 (2400208,'ACU',24),
	 (2400307,'AFONSO BEZERRA',24),
	 (2400406,'AGUA NOVA',24),
	 (2400505,'ALEXANDRIA',24),
	 (2400604,'ALMINO AFONSO',24),
	 (2400703,'ALTO DO RODRIGUES',24),
	 (2400802,'ANGICOS',24),
	 (2400901,'ANTONIO MARTINS',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2401008,'APODI',24),
	 (2401107,'AREIA BRANCA',24),
	 (2401206,'ARES',24),
	 (2401305,'AUGUSTO SEVERO',24),
	 (2401404,'BAIA FORMOSA',24),
	 (2401453,'BARAUNA',24),
	 (2401503,'BARCELONA',24),
	 (2401602,'BENTO FERNANDES',24),
	 (2401651,'BODO',24),
	 (2401701,'BOM JESUS',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2401800,'BREJINHO',24),
	 (2401859,'CAICARA DO NORTE',24),
	 (2401909,'CAICARA DO RIO DO VENTO',24),
	 (2402006,'CAICO',24),
	 (2402105,'CAMPO REDONDO',24),
	 (2402204,'CANGUARETAMA',24),
	 (2402303,'CARAUBAS',24),
	 (2402402,'CARNAUBA DOS DANTAS',24),
	 (2402501,'CARNAUBAIS',24),
	 (2402600,'CEARA-MIRIM',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2402709,'CERRO CORA',24),
	 (2402808,'CORONEL EZEQUIEL',24),
	 (2402907,'CORONEL JOAO PESSOA',24),
	 (2403004,'CRUZETA',24),
	 (2403103,'CURRAIS NOVOS',24),
	 (2403202,'DOUTOR SEVERIANO',24),
	 (2403251,'PARNAMIRIM',24),
	 (2403301,'ENCANTO',24),
	 (2403400,'EQUADOR',24),
	 (2403509,'ESPIRITO SANTO',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2403608,'EXTREMOZ',24),
	 (2403707,'FELIPE GUERRA',24),
	 (2403756,'FERNANDO PEDROZA',24),
	 (2403806,'FLORANIA',24),
	 (2403905,'FRANCISCO DANTAS',24),
	 (2404002,'FRUTUOSO GOMES',24),
	 (2404101,'GALINHOS',24),
	 (2404200,'GOIANINHA',24),
	 (2404309,'GOVERNADOR DIX-SEPT ROSADO',24),
	 (2404408,'GROSSOS',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2404507,'GUAMARE',24),
	 (2404606,'IELMO MARINHO',24),
	 (2404705,'IPANGUACU',24),
	 (2404804,'IPUEIRA',24),
	 (2404853,'ITAJA',24),
	 (2404903,'ITAU',24),
	 (2405009,'JACANA',24),
	 (2405108,'JANDAIRA',24),
	 (2405207,'JANDUIS',24),
	 (2405306,'JANUARIO CICCO',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2405405,'JAPI',24),
	 (2405504,'JARDIM DE ANGICOS',24),
	 (2405603,'JARDIM DE PIRANHAS',24),
	 (2405702,'JARDIM DO SERIDO',24),
	 (2405801,'JOAO CAMARA',24),
	 (2405900,'JOAO DIAS',24),
	 (2406007,'JOSE DA PENHA',24),
	 (2406106,'JUCURUTU',24),
	 (2406155,'JUNDIA',24),
	 (2406205,'LAGOA D ANTA',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2406304,'LAGOA DE PEDRAS',24),
	 (2406403,'LAGOA DE VELHOS',24),
	 (2406502,'LAGOA NOVA',24),
	 (2406601,'LAGOA SALGADA',24),
	 (2406700,'LAJES',24),
	 (2406809,'LAJES PINTADAS',24),
	 (2406908,'LUCRECIA',24),
	 (2407005,'LUIS GOMES',24),
	 (2407104,'MACAIBA',24),
	 (2407203,'MACAU',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2407252,'MAJOR SALES',24),
	 (2407302,'MARCELINO VIEIRA',24),
	 (2407401,'MARTINS',24),
	 (2407500,'MAXARANGUAPE',24),
	 (2407609,'MESSIAS TARGINO',24),
	 (2407708,'MONTANHAS',24),
	 (2407807,'MONTE ALEGRE',24),
	 (2407906,'MONTE DAS GAMELEIRAS',24),
	 (2408003,'MOSSORO',24),
	 (2408102,'NATAL',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2408201,'NISIA FLORESTA',24),
	 (2408300,'NOVA CRUZ',24),
	 (2408409,'OLHO-D AGUA DO BORGES',24),
	 (2408508,'OURO BRANCO',24),
	 (2408607,'PARANA',24),
	 (2408706,'PARAU',24),
	 (2408805,'PARAZINHO',24),
	 (2408904,'PARELHAS',24),
	 (2408953,'RIO DO FOGO',24),
	 (2409100,'PASSA E FICA',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2409209,'PASSAGEM',24),
	 (2409308,'PATU',24),
	 (2409332,'SANTA MARIA',24),
	 (2409407,'PAU DOS FERROS',24),
	 (2409506,'PEDRA GRANDE',24),
	 (2409605,'PEDRA PRETA',24),
	 (2409704,'PEDRO AVELINO',24),
	 (2409803,'PEDRO VELHO',24),
	 (2409902,'PENDENCIAS',24),
	 (2410009,'PILOES',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2410108,'POCO BRANCO',24),
	 (2410207,'PORTALEGRE',24),
	 (2410256,'PORTO DO MANGUE',24),
	 (2410306,'PRESIDENTE JUSCELINO',24),
	 (2410405,'PUREZA',24),
	 (2410504,'RAFAEL FERNANDES',24),
	 (2410603,'RAFAEL GODEIRO',24),
	 (2410702,'RIACHO DA CRUZ',24),
	 (2410801,'RIACHO DE SANTANA',24),
	 (2410900,'RIACHUELO',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2411007,'RODOLFO FERNANDES',24),
	 (2411056,'TIBAU',24),
	 (2411106,'RUY BARBOSA',24),
	 (2411205,'SANTA CRUZ',24),
	 (2411403,'SANTANA DO MATOS',24),
	 (2411429,'SANTANA DO SERIDO',24),
	 (2411502,'SANTO ANTONIO',24),
	 (2411601,'SAO BENTO DO NORTE',24),
	 (2411700,'SAO BENTO DO TRAIRI',24),
	 (2411809,'SAO FERNANDO',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2411908,'SAO FRANCISCO DO OESTE',24),
	 (2412005,'SAO GONCALO DO AMARANTE',24),
	 (2412104,'SAO JOAO DO SABUGI',24),
	 (2412203,'SAO JOSE DE MIPIBU',24),
	 (2412302,'SAO JOSE DO CAMPESTRE',24),
	 (2412401,'SAO JOSE DO SERIDO',24),
	 (2412500,'SAO MIGUEL',24),
	 (2412559,'SAO MIGUEL DO GOSTOSO',24),
	 (2412609,'SAO PAULO DO POTENGI',24),
	 (2412708,'SAO PEDRO',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2412807,'SAO RAFAEL',24),
	 (2412906,'SAO TOME',24),
	 (2413003,'SAO VICENTE',24),
	 (2413102,'SENADOR ELOI DE SOUZA',24),
	 (2413201,'SENADOR GEORGINO AVELINO',24),
	 (2413300,'SERRA DE SAO BENTO',24),
	 (2413359,'SERRA DO MEL',24),
	 (2413409,'SERRA NEGRA DO NORTE',24),
	 (2413508,'SERRINHA',24),
	 (2413557,'SERRINHA DOS PINTOS',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2413607,'SEVERIANO MELO',24),
	 (2413706,'SITIO NOVO',24),
	 (2413805,'TABOLEIRO GRANDE',24),
	 (2413904,'TAIPU',24),
	 (2414001,'TANGARA',24),
	 (2414100,'TENENTE ANANIAS',24),
	 (2414159,'TENENTE LAURENTINO CRUZ',24),
	 (2414209,'TIBAU DO SUL',24),
	 (2414308,'TIMBAUBA DOS BATISTAS',24),
	 (2414407,'TOUROS',24);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2414456,'TRIUNFO POTIGUAR',24),
	 (2414506,'UMARIZAL',24),
	 (2414605,'UPANEMA',24),
	 (2414704,'VARZEA',24),
	 (2414753,'VENHA-VER',24),
	 (2414803,'VERA CRUZ',24),
	 (2414902,'VICOSA',24),
	 (2415008,'VILA FLOR',24),
	 (2500106,'AGUA BRANCA',25),
	 (2500205,'AGUIAR',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2500304,'ALAGOA GRANDE',25),
	 (2500403,'ALAGOA NOVA',25),
	 (2500502,'ALAGOINHA',25),
	 (2500536,'ALCANTIL',25),
	 (2500577,'ALGODAO DE JANDAIRA',25),
	 (2500601,'ALHANDRA',25),
	 (2500700,'SAO JOAO DO RIO DO PEIXE',25),
	 (2500734,'AMPARO',25),
	 (2500775,'APARECIDA',25),
	 (2500809,'ARACAGI',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2500908,'ARARA',25),
	 (2501005,'ARARUNA',25),
	 (2501104,'AREIA',25),
	 (2501153,'AREIA DE BARAUNAS',25),
	 (2501203,'AREIAL',25),
	 (2501302,'AROEIRAS',25),
	 (2501351,'ASSUNCAO',25),
	 (2501401,'BAIA DA TRAICAO',25),
	 (2501500,'BANANEIRAS',25),
	 (2501534,'BARAUNA',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2501575,'BARRA DE SANTANA',25),
	 (2501609,'BARRA DE SANTA ROSA',25),
	 (2501708,'BARRA DE SAO MIGUEL',25),
	 (2501807,'BAYEUX',25),
	 (2501906,'BELEM',25),
	 (2502003,'BELEM DO BREJO DO CRUZ',25),
	 (2502052,'BERNARDINO BATISTA',25),
	 (2502102,'BOA VENTURA',25),
	 (2502151,'BOA VISTA',25),
	 (2502201,'BOM JESUS',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2502300,'BOM SUCESSO',25),
	 (2502409,'BONITO DE SANTA FE',25),
	 (2502508,'BOQUEIRAO',25),
	 (2502607,'IGARACY',25),
	 (2502706,'BORBOREMA',25),
	 (2502805,'BREJO DO CRUZ',25),
	 (2502904,'BREJO DOS SANTOS',25),
	 (2503001,'CAAPORA',25),
	 (2503100,'CABACEIRAS',25),
	 (2503209,'CABEDELO',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2503308,'CACHOEIRA DOS INDIOS',25),
	 (2503407,'CACIMBA DE AREIA',25),
	 (2503506,'CACIMBA DE DENTRO',25),
	 (2503555,'CACIMBAS',25),
	 (2503605,'CAICARA',25),
	 (2503704,'CAJAZEIRAS',25),
	 (2503753,'CAJAZEIRINHAS',25),
	 (2503803,'CALDAS BRANDAO',25),
	 (2503902,'CAMALAU',25),
	 (2504009,'CAMPINA GRANDE',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2504033,'CAPIM',25),
	 (2504074,'CARAUBAS',25),
	 (2504108,'CARRAPATEIRA',25),
	 (2504157,'CASSERENGUE',25),
	 (2504207,'CATINGUEIRA',25),
	 (2504306,'CATOLE DO ROCHA',25),
	 (2504355,'CATURITE',25),
	 (2504405,'CONCEICAO',25),
	 (2504504,'CONDADO',25),
	 (2504603,'CONDE',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2504702,'CONGO',25),
	 (2504801,'COREMAS',25),
	 (2504850,'COXIXOLA',25),
	 (2504900,'CRUZ DO ESPIRITO SANTO',25),
	 (2505006,'CUBATI',25),
	 (2505105,'CUITE',25),
	 (2505204,'CUITEGI',25),
	 (2505238,'CUITE DE MAMANGUAPE',25),
	 (2505279,'CURRAL DE CIMA',25),
	 (2505303,'CURRAL VELHO',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2505352,'DAMIAO',25),
	 (2505402,'DESTERRO',25),
	 (2505501,'VISTA SERRANA',25),
	 (2505600,'DIAMANTE',25),
	 (2505709,'DONA INES',25),
	 (2505808,'DUAS ESTRADAS',25),
	 (2505907,'EMAS',25),
	 (2506004,'ESPERANCA',25),
	 (2506103,'FAGUNDES',25),
	 (2506202,'FREI MARTINHO',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2506251,'GADO BRAVO',25),
	 (2506301,'GUARABIRA',25),
	 (2506400,'GURINHEM',25),
	 (2506509,'GURJAO',25),
	 (2506608,'IBIARA',25),
	 (2506707,'IMACULADA',25),
	 (2506806,'INGA',25),
	 (2506905,'ITABAIANA',25),
	 (2507002,'ITAPORANGA',25),
	 (2507101,'ITAPOROROCA',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2507200,'ITATUBA',25),
	 (2507309,'JACARAU',25),
	 (2507408,'JERICO',25),
	 (2507507,'JOAO PESSOA',25),
	 (2507606,'JUAREZ TAVORA',25),
	 (2507705,'JUAZEIRINHO',25),
	 (2507804,'JUNCO DO SERIDO',25),
	 (2507903,'JURIPIRANGA',25),
	 (2508000,'JURU',25),
	 (2508109,'LAGOA',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2508208,'LAGOA DE DENTRO',25),
	 (2508307,'LAGOA SECA',25),
	 (2508406,'LASTRO',25),
	 (2508505,'LIVRAMENTO',25),
	 (2508554,'LOGRADOURO',25),
	 (2508604,'LUCENA',25),
	 (2508703,'MAE D AGUA',25),
	 (2508802,'MALTA',25),
	 (2508901,'MAMANGUAPE',25),
	 (2509008,'MANAIRA',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2509057,'MARCACAO',25),
	 (2509107,'MARI',25),
	 (2509156,'MARIZOPOLIS',25),
	 (2509206,'MASSARANDUBA',25),
	 (2509305,'MATARACA',25),
	 (2509339,'MATINHAS',25),
	 (2509370,'MATO GROSSO',25),
	 (2509396,'MATUREIA',25),
	 (2509404,'MOGEIRO',25),
	 (2509503,'MONTADAS',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2509602,'MONTE HOREBE',25),
	 (2509701,'MONTEIRO',25),
	 (2509800,'MULUNGU',25),
	 (2509909,'NATUBA',25),
	 (2510006,'NAZAREZINHO',25),
	 (2510105,'NOVA FLORESTA',25),
	 (2510204,'NOVA OLINDA',25),
	 (2510303,'NOVA PALMEIRA',25),
	 (2510402,'OLHO D AGUA',25),
	 (2510501,'OLIVEDOS',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2510600,'OURO VELHO',25),
	 (2510659,'PARARI',25),
	 (2510709,'PASSAGEM',25),
	 (2510808,'PATOS',25),
	 (2510907,'PAULISTA',25),
	 (2511004,'PEDRA BRANCA',25),
	 (2511103,'PEDRA LAVRADA',25),
	 (2511202,'PEDRAS DE FOGO',25),
	 (2511301,'PIANCO',25),
	 (2511400,'PICUI',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2511509,'PILAR',25),
	 (2511608,'PILOES',25),
	 (2511707,'PILOEZINHOS',25),
	 (2511806,'PIRPIRITUBA',25),
	 (2511905,'PITIMBU',25),
	 (2512002,'POCINHOS',25),
	 (2512036,'POCO DANTAS',25),
	 (2512077,'POCO DE JOSE DE MOURA',25),
	 (2512101,'POMBAL',25),
	 (2512200,'PRATA',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2512309,'PRINCESA ISABEL',25),
	 (2512408,'PUXINANA',25),
	 (2512507,'QUEIMADAS',25),
	 (2512606,'QUIXABA',25),
	 (2512705,'REMIGIO',25),
	 (2512721,'PEDRO REGIS',25),
	 (2512747,'RIACHAO',25),
	 (2512754,'RIACHAO DO BACAMARTE',25),
	 (2512762,'RIACHAO DO POCO',25),
	 (2512788,'RIACHO DE SANTO ANTONIO',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2512804,'RIACHO DOS CAVALOS',25),
	 (2512903,'RIO TINTO',25),
	 (2513000,'SALGADINHO',25),
	 (2513109,'SALGADO DE SAO FELIX',25),
	 (2513158,'SANTA CECILIA',25),
	 (2513208,'SANTA CRUZ',25),
	 (2513307,'SANTA HELENA',25),
	 (2513356,'SANTA INES',25),
	 (2513406,'SANTA LUZIA',25),
	 (2513505,'SANTANA DE MANGUEIRA',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2513604,'SANTANA DOS GARROTES',25),
	 (2513653,'SANTAREM',25),
	 (2513703,'SANTA RITA',25),
	 (2513802,'SANTA TERESINHA',25),
	 (2513851,'SANTO ANDRE',25),
	 (2513901,'SAO BENTO',25),
	 (2513927,'SAO BENTINHO',25),
	 (2513943,'SAO DOMINGOS DO CARIRI',25),
	 (2513968,'SAO DOMINGOS DE POMBAL',25),
	 (2513984,'SAO FRANCISCO',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2514008,'SAO JOAO DO CARIRI',25),
	 (2514107,'SAO JOAO DO TIGRE',25),
	 (2514206,'SAO JOSE DA LAGOA TAPADA',25),
	 (2514305,'SAO JOSE DE CAIANA',25),
	 (2514404,'SAO JOSE DE ESPINHARAS',25),
	 (2514453,'SAO JOSE DOS RAMOS',25),
	 (2514503,'SAO JOSE DE PIRANHAS',25),
	 (2514552,'SAO JOSE DE PRINCESA',25),
	 (2514602,'SAO JOSE DO BONFIM',25),
	 (2514651,'SAO JOSE DO BREJO DO CRUZ',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2514701,'SAO JOSE DO SABUGI',25),
	 (2514800,'SAO JOSE DOS CORDEIROS',25),
	 (2514909,'SAO MAMEDE',25),
	 (2515005,'SAO MIGUEL DE TAIPU',25),
	 (2515104,'SAO SEBASTIAO DE LAGOA DE ROCA',25),
	 (2515203,'SAO SEBASTIAO DO UMBUZEIRO',25),
	 (2515302,'SAPE',25),
	 (2515401,'SERIDO',25),
	 (2515500,'SERRA BRANCA',25),
	 (2515609,'SERRA DA RAIZ',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2515708,'SERRA GRANDE',25),
	 (2515807,'SERRA REDONDA',25),
	 (2515906,'SERRARIA',25),
	 (2515930,'SERTAOZINHO',25),
	 (2515971,'SOBRADO',25),
	 (2516003,'SOLANEA',25),
	 (2516102,'SOLEDADE',25),
	 (2516151,'SOSSEGO',25),
	 (2516201,'SOUSA',25),
	 (2516300,'SUME',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2516409,'CAMPO DE SANTANA',25),
	 (2516508,'TAPEROA',25),
	 (2516607,'TAVARES',25),
	 (2516706,'TEIXEIRA',25),
	 (2516755,'TENORIO',25),
	 (2516805,'TRIUNFO',25),
	 (2516904,'UIRAUNA',25),
	 (2517001,'UMBUZEIRO',25),
	 (2517100,'VARZEA',25),
	 (2517209,'VIEIROPOLIS',25);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2517407,'ZABELE',25),
	 (2600054,'ABREU E LIMA',26),
	 (2600104,'AFOGADOS DA INGAZEIRA',26),
	 (2600203,'AFRANIO',26),
	 (2600302,'AGRESTINA',26),
	 (2600401,'AGUA PRETA',26),
	 (2600500,'AGUAS BELAS',26),
	 (2600609,'ALAGOINHA',26),
	 (2600708,'ALIANCA',26),
	 (2600807,'ALTINHO',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2600906,'AMARAJI',26),
	 (2601003,'ANGELIM',26),
	 (2601052,'ARACOIABA',26),
	 (2601102,'ARARIPINA',26),
	 (2601201,'ARCOVERDE',26),
	 (2601300,'BARRA DE GUABIRABA',26),
	 (2601409,'BARREIROS',26),
	 (2601508,'BELEM DE MARIA',26),
	 (2601607,'BELEM DE SAO FRANCISCO',26),
	 (2601706,'BELO JARDIM',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2601805,'BETANIA',26),
	 (2601904,'BEZERROS',26),
	 (2602001,'BODOCO',26),
	 (2602100,'BOM CONSELHO',26),
	 (2602209,'BOM JARDIM',26),
	 (2602308,'BONITO',26),
	 (2602407,'BREJAO',26),
	 (2602506,'BREJINHO',26),
	 (2602605,'BREJO DA MADRE DE DEUS',26),
	 (2602704,'BUENOS AIRES',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2602803,'BUIQUE',26),
	 (2602902,'CABO DE SANTO AGOSTINHO',26),
	 (2603009,'CABROBO',26),
	 (2603108,'CACHOEIRINHA',26),
	 (2603207,'CAETES',26),
	 (2603306,'CALCADO',26),
	 (2603405,'CALUMBI',26),
	 (2603454,'CAMARAGIBE',26),
	 (2603504,'CAMOCIM DE SAO FELIX',26),
	 (2603603,'CAMUTANGA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2603702,'CANHOTINHO',26),
	 (2603801,'CAPOEIRAS',26),
	 (2603900,'CARNAIBA',26),
	 (2603926,'CARNAUBEIRA DA PENHA',26),
	 (2604007,'CARPINA',26),
	 (2604106,'CARUARU',26),
	 (2604155,'CASINHAS',26),
	 (2604205,'CATENDE',26),
	 (2604304,'CEDRO',26),
	 (2604403,'CHA DE ALEGRIA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2604502,'CHA GRANDE',26),
	 (2604601,'CONDADO',26),
	 (2604700,'CORRENTES',26),
	 (2604809,'CORTES',26),
	 (2604908,'CUMARU',26),
	 (2605004,'CUPIRA',26),
	 (2605103,'CUSTODIA',26),
	 (2605152,'DORMENTES',26),
	 (2605202,'ESCADA',26),
	 (2605301,'EXU',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2605400,'FEIRA NOVA',26),
	 (2605459,'FERNANDO DE NORONHA',26),
	 (2605509,'FERREIROS',26),
	 (2605608,'FLORES',26),
	 (2605707,'FLORESTA',26),
	 (2605806,'FREI MIGUELINHO',26),
	 (2605905,'GAMELEIRA',26),
	 (2606002,'GARANHUNS',26),
	 (2606101,'GLORIA DO GOITA',26),
	 (2606200,'GOIANA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2606309,'GRANITO',26),
	 (2606408,'GRAVATA',26),
	 (2606507,'IATI',26),
	 (2606606,'IBIMIRIM',26),
	 (2606705,'IBIRAJUBA',26),
	 (2606804,'IGARASSU',26),
	 (2606903,'IGUARACI',26),
	 (2607000,'INAJA',26),
	 (2607109,'INGAZEIRA',26),
	 (2607208,'IPOJUCA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2607307,'IPUBI',26),
	 (2607406,'ITACURUBA',26),
	 (2607505,'ITAIBA',26),
	 (2607604,'ILHA DE ITAMARACA',26),
	 (2607653,'ITAMBE',26),
	 (2607703,'ITAPETIM',26),
	 (2607752,'ITAPISSUMA',26),
	 (2607802,'ITAQUITINGA',26),
	 (2607901,'JABOATAO DOS GUARARAPES',26),
	 (2607950,'JAQUEIRA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2608008,'JATAUBA',26),
	 (2608057,'JATOBA',26),
	 (2608107,'JOAO ALFREDO',26),
	 (2608206,'JOAQUIM NABUCO',26),
	 (2608255,'JUCATI',26),
	 (2608305,'JUPI',26),
	 (2608404,'JUREMA',26),
	 (2608453,'LAGOA DO CARRO',26),
	 (2608503,'LAGOA DO ITAENGA',26),
	 (2608602,'LAGOA DO OURO',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2608701,'LAGOA DOS GATOS',26),
	 (2608750,'LAGOA GRANDE',26),
	 (2608800,'LAJEDO',26),
	 (2608909,'LIMOEIRO',26),
	 (2609006,'MACAPARANA',26),
	 (2609105,'MACHADOS',26),
	 (2609154,'MANARI',26),
	 (2609204,'MARAIAL',26),
	 (2609303,'MIRANDIBA',26),
	 (2609402,'MORENO',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2609501,'NAZARE DA MATA',26),
	 (2609600,'OLINDA',26),
	 (2609709,'OROBO',26),
	 (2609808,'OROCO',26),
	 (2609907,'OURICURI',26),
	 (2610004,'PALMARES',26),
	 (2610103,'PALMEIRINA',26),
	 (2610202,'PANELAS',26),
	 (2610301,'PARANATAMA',26),
	 (2610400,'PARNAMIRIM',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2610509,'PASSIRA',26),
	 (2610608,'PAUDALHO',26),
	 (2610707,'PAULISTA',26),
	 (2610806,'PEDRA',26),
	 (2610905,'PESQUEIRA',26),
	 (2611002,'PETROLANDIA',26),
	 (2611101,'PETROLINA',26),
	 (2611200,'POCAO',26),
	 (2611309,'POMBOS',26),
	 (2611408,'PRIMAVERA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2611507,'QUIPAPA',26),
	 (2611533,'QUIXABA',26),
	 (2611606,'RECIFE',26),
	 (2611705,'RIACHO DAS ALMAS',26),
	 (2611804,'RIBEIRAO',26),
	 (2611903,'RIO FORMOSO',26),
	 (2612000,'SAIRE',26),
	 (2612109,'SALGADINHO',26),
	 (2612208,'SALGUEIRO',26),
	 (2612307,'SALOA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2612406,'SANHARO',26),
	 (2612455,'SANTA CRUZ',26),
	 (2612471,'SANTA CRUZ DA BAIXA VERDE',26),
	 (2612505,'SANTA CRUZ DO CAPIBARIBE',26),
	 (2612554,'SANTA FILOMENA',26),
	 (2612604,'SANTA MARIA DA BOA VISTA',26),
	 (2612703,'SANTA MARIA DO CAMBUCA',26),
	 (2612802,'SANTA TEREZINHA',26),
	 (2612901,'SAO BENEDITO DO SUL',26),
	 (2613008,'SAO BENTO DO UNA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2613107,'SAO CAITANO',26),
	 (2613206,'SAO JOAO',26),
	 (2613305,'SAO JOAQUIM DO MONTE',26),
	 (2613404,'SAO JOSE DA COROA GRANDE',26),
	 (2613503,'SAO JOSE DO BELMONTE',26),
	 (2613602,'SAO JOSE DO EGITO',26),
	 (2613701,'SAO LOURENCO DA MATA',26),
	 (2613800,'SAO VICENTE FERRER',26),
	 (2613909,'SERRA TALHADA',26),
	 (2614006,'SERRITA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2614105,'SERTANIA',26),
	 (2614204,'SIRINHAEM',26),
	 (2614303,'MOREILANDIA',26),
	 (2614402,'SOLIDAO',26),
	 (2614501,'SURUBIM',26),
	 (2614600,'TABIRA',26),
	 (2614709,'TACAIMBO',26),
	 (2614808,'TACARATU',26),
	 (2614857,'TAMANDARE',26),
	 (2615003,'TAQUARITINGA DO NORTE',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2615102,'TEREZINHA',26),
	 (2615201,'TERRA NOVA',26),
	 (2615300,'TIMBAUBA',26),
	 (2615409,'TORITAMA',26),
	 (2615508,'TRACUNHAEM',26),
	 (2615607,'TRINDADE',26),
	 (2615706,'TRIUNFO',26),
	 (2615805,'TUPANATINGA',26),
	 (2615904,'TUPARETAMA',26),
	 (2616001,'VENTUROSA',26);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2616100,'VERDEJANTE',26),
	 (2616183,'VERTENTE DO LERIO',26),
	 (2616209,'VERTENTES',26),
	 (2616308,'VICENCIA',26),
	 (2616407,'VITORIA DE SANTO ANTAO',26),
	 (2616506,'XEXEU',26),
	 (2700102,'AGUA BRANCA',27),
	 (2700201,'ANADIA',27),
	 (2700300,'ARAPIRACA',27),
	 (2700409,'ATALAIA',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2700508,'BARRA DE SANTO ANTONIO',27),
	 (2700607,'BARRA DE SAO MIGUEL',27),
	 (2700706,'BATALHA',27),
	 (2700805,'BELEM',27),
	 (2700904,'BELO MONTE',27),
	 (2701001,'BOCA DA MATA',27),
	 (2701100,'BRANQUINHA',27),
	 (2701209,'CACIMBINHAS',27),
	 (2701308,'CAJUEIRO',27),
	 (2701357,'CAMPESTRE',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2701407,'CAMPO ALEGRE',27),
	 (2701506,'CAMPO GRANDE',27),
	 (2701605,'CANAPI',27),
	 (2701704,'CAPELA',27),
	 (2701803,'CARNEIROS',27),
	 (2701902,'CHA PRETA',27),
	 (2702009,'COITE DO NOIA',27),
	 (2702108,'COLONIA LEOPOLDINA',27),
	 (2702207,'COQUEIRO SECO',27),
	 (2702306,'CORURIPE',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2702355,'CRAIBAS',27),
	 (2702405,'DELMIRO GOUVEIA',27),
	 (2702504,'DOIS RIACHOS',27),
	 (2702553,'ESTRELA DE ALAGOAS',27),
	 (2702603,'FEIRA GRANDE',27),
	 (2702702,'FELIZ DESERTO',27),
	 (2702801,'FLEXEIRAS',27),
	 (2702900,'GIRAU DO PONCIANO',27),
	 (2703007,'IBATEGUARA',27),
	 (2703106,'IGACI',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2703205,'IGREJA NOVA',27),
	 (2703304,'INHAPI',27),
	 (2703403,'JACARE DOS HOMENS',27),
	 (2703502,'JACUIPE',27),
	 (2703601,'JAPARATINGA',27),
	 (2703700,'JARAMATAIA',27),
	 (2703759,'JEQUIA DA PRAIA',27),
	 (2703809,'JOAQUIM GOMES',27),
	 (2703908,'JUNDIA',27),
	 (2704005,'JUNQUEIRO',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2704104,'LAGOA DA CANOA',27),
	 (2704203,'LIMOEIRO DE ANADIA',27),
	 (2704302,'MACEIO',27),
	 (2704401,'MAJOR ISIDORO',27),
	 (2704500,'MARAGOGI',27),
	 (2704609,'MARAVILHA',27),
	 (2704708,'MARECHAL DEODORO',27),
	 (2704807,'MARIBONDO',27),
	 (2704906,'MAR VERMELHO',27),
	 (2705002,'MATA GRANDE',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2705101,'MATRIZ DE CAMARAGIBE',27),
	 (2705200,'MESSIAS',27),
	 (2705309,'MINADOR DO NEGRAO',27),
	 (2705408,'MONTEIROPOLIS',27),
	 (2705507,'MURICI',27),
	 (2705606,'NOVO LINO',27),
	 (2705705,'OLHO D AGUA DAS FLORES',27),
	 (2705804,'OLHO D AGUA DO CASADO',27),
	 (2705903,'OLHO D AGUA GRANDE',27),
	 (2706000,'OLIVENCA',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2706109,'OURO BRANCO',27),
	 (2706208,'PALESTINA',27),
	 (2706307,'PALMEIRA DOS INDIOS',27),
	 (2706406,'PAO DE ACUCAR',27),
	 (2706422,'PARICONHA',27),
	 (2706448,'PARIPUEIRA',27),
	 (2706505,'PASSO DE CAMARAGIBE',27),
	 (2706604,'PAULO JACINTO',27),
	 (2706703,'PENEDO',27),
	 (2706802,'PIACABUCU',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2706901,'PILAR',27),
	 (2707008,'PINDOBA',27),
	 (2707107,'PIRANHAS',27),
	 (2707206,'POCO DAS TRINCHEIRAS',27),
	 (2707305,'PORTO CALVO',27),
	 (2707404,'PORTO DE PEDRAS',27),
	 (2707503,'PORTO REAL DO COLEGIO',27),
	 (2707602,'QUEBRANGULO',27),
	 (2707701,'RIO LARGO',27),
	 (2707800,'ROTEIRO',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2707909,'SANTA LUZIA DO NORTE',27),
	 (2708006,'SANTANA DO IPANEMA',27),
	 (2708105,'SANTANA DO MUNDAU',27),
	 (2708204,'SAO BRAS',27),
	 (2708303,'SAO JOSE DA LAJE',27),
	 (2708402,'SAO JOSE DA TAPERA',27),
	 (2708501,'SAO LUIS DO QUITUNDE',27),
	 (2708600,'SAO MIGUEL DOS CAMPOS',27),
	 (2708709,'SAO MIGUEL DOS MILAGRES',27),
	 (2708808,'SAO SEBASTIAO',27);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2708907,'SATUBA',27),
	 (2708956,'SENADOR RUI PALMEIRA',27),
	 (2709004,'TANQUE D ARCA',27),
	 (2709103,'TAQUARANA',27),
	 (2709152,'TEOTONIO VILELA',27),
	 (2709202,'TRAIPU',27),
	 (2709301,'UNIAO DOS PALMARES',27),
	 (2709400,'VICOSA',27),
	 (2800100,'AMPARO DE SAO FRANCISCO',28),
	 (2800209,'AQUIDABA',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2800308,'ARACAJU',28),
	 (2800407,'ARAUA',28),
	 (2800506,'AREIA BRANCA',28),
	 (2800605,'BARRA DOS COQUEIROS',28),
	 (2800670,'BOQUIM',28),
	 (2800704,'BREJO GRANDE',28),
	 (2801009,'CAMPO DO BRITO',28),
	 (2801108,'CANHOBA',28),
	 (2801207,'CANINDE DE SAO FRANCISCO',28),
	 (2801306,'CAPELA',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2801405,'CARIRA',28),
	 (2801504,'CARMOPOLIS',28),
	 (2801603,'CEDRO DE SAO JOAO',28),
	 (2801702,'CRISTINAPOLIS',28),
	 (2801900,'CUMBE',28),
	 (2802007,'DIVINA PASTORA',28),
	 (2802106,'ESTANCIA',28),
	 (2802205,'FEIRA NOVA',28),
	 (2802304,'FREI PAULO',28),
	 (2802403,'GARARU',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2802502,'GENERAL MAYNARD',28),
	 (2802601,'GRACHO CARDOSO',28),
	 (2802700,'ILHA DAS FLORES',28),
	 (2802809,'INDIAROBA',28),
	 (2802908,'ITABAIANA',28),
	 (2803005,'ITABAIANINHA',28),
	 (2803104,'ITABI',28),
	 (2803203,'ITAPORANGA D AJUDA',28),
	 (2803302,'JAPARATUBA',28),
	 (2803401,'JAPOATA',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2803500,'LAGARTO',28),
	 (2803609,'LARANJEIRAS',28),
	 (2803708,'MACAMBIRA',28),
	 (2803807,'MALHADA DOS BOIS',28),
	 (2803906,'MALHADOR',28),
	 (2804003,'MARUIM',28),
	 (2804102,'MOITA BONITA',28),
	 (2804201,'MONTE ALEGRE DE SERGIPE',28),
	 (2804300,'MURIBECA',28),
	 (2804409,'NEOPOLIS',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2804458,'NOSSA SENHORA APARECIDA',28),
	 (2804508,'NOSSA SENHORA DA GLORIA',28),
	 (2804607,'NOSSA SENHORA DAS DORES',28),
	 (2804706,'NOSSA SENHORA DE LOURDES',28),
	 (2804805,'NOSSA SENHORA DO SOCORRO',28),
	 (2804904,'PACATUBA',28),
	 (2805000,'PEDRA MOLE',28),
	 (2805109,'PEDRINHAS',28),
	 (2805208,'PINHAO',28),
	 (2805307,'PIRAMBU',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2805406,'POCO REDONDO',28),
	 (2805505,'POCO VERDE',28),
	 (2805604,'PORTO DA FOLHA',28),
	 (2805703,'PROPRIA',28),
	 (2805802,'RIACHAO DO DANTAS',28),
	 (2805901,'RIACHUELO',28),
	 (2806008,'RIBEIROPOLIS',28),
	 (2806107,'ROSARIO DO CATETE',28),
	 (2806206,'SALGADO',28),
	 (2806305,'SANTA LUZIA DO ITANHY',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2806404,'SANTANA DO SAO FRANCISCO',28),
	 (2806503,'SANTA ROSA DE LIMA',28),
	 (2806602,'SANTO AMARO DAS BROTAS',28),
	 (2806701,'SAO CRISTOVAO',28),
	 (2806800,'SAO DOMINGOS',28),
	 (2806909,'SAO FRANCISCO',28),
	 (2807006,'SAO MIGUEL DO ALEIXO',28),
	 (2807105,'SIMAO DIAS',28),
	 (2807204,'SIRIRI',28),
	 (2807303,'TELHA',28);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2807402,'TOBIAS BARRETO',28),
	 (2807501,'TOMAR DO GERU',28),
	 (2807600,'UMBAUBA',28),
	 (2900108,'ABAIRA',29),
	 (2900207,'ABARE',29),
	 (2900306,'ACAJUTIBA',29),
	 (2900355,'ADUSTINA',29),
	 (2900405,'AGUA FRIA',29),
	 (2900504,'ERICO CARDOSO',29),
	 (2900603,'AIQUARA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2900702,'ALAGOINHAS',29),
	 (2900801,'ALCOBACA',29),
	 (2900900,'ALMADINA',29),
	 (2901007,'AMARGOSA',29),
	 (2901106,'AMELIA RODRIGUES',29),
	 (2901155,'AMERICA DOURADA',29),
	 (2901205,'ANAGE',29),
	 (2901304,'ANDARAI',29),
	 (2901353,'ANDORINHA',29),
	 (2901403,'ANGICAL',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2901502,'ANGUERA',29),
	 (2901601,'ANTAS',29),
	 (2901700,'ANTONIO CARDOSO',29),
	 (2901809,'ANTONIO GONCALVES',29),
	 (2901908,'APORA',29),
	 (2901957,'APUAREMA',29),
	 (2902005,'ARACATU',29),
	 (2902054,'ARACAS',29),
	 (2902104,'ARACI',29),
	 (2902203,'ARAMARI',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2902252,'ARATACA',29),
	 (2902302,'ARATUIPE',29),
	 (2902401,'AURELINO LEAL',29),
	 (2902500,'BAIANOPOLIS',29),
	 (2902609,'BAIXA GRANDE',29),
	 (2902658,'BANZAE',29),
	 (2902708,'BARRA',29),
	 (2902807,'BARRA DA ESTIVA',29),
	 (2902906,'BARRA DO CHOCA',29),
	 (2903003,'BARRA DO MENDES',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2903102,'BARRA DO ROCHA',29),
	 (2903201,'BARREIRAS',29),
	 (2903235,'BARRO ALTO',29),
	 (2903276,'BARROCAS',29),
	 (2903300,'BARRO PRETO',29),
	 (2903409,'BELMONTE',29),
	 (2903508,'BELO CAMPO',29),
	 (2903607,'BIRITINGA',29),
	 (2903706,'BOA NOVA',29),
	 (2903805,'BOA VISTA DO TUPIM',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2903904,'BOM JESUS DA LAPA',29),
	 (2903953,'BOM JESUS DA SERRA',29),
	 (2904001,'BONINAL',29),
	 (2904050,'BONITO',29),
	 (2904100,'BOQUIRA',29),
	 (2904209,'BOTUPORA',29),
	 (2904308,'BREJOES',29),
	 (2904407,'BREJOLANDIA',29),
	 (2904506,'BROTAS DE MACAUBAS',29),
	 (2904605,'BRUMADO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2904704,'BUERAREMA',29),
	 (2904753,'BURITIRAMA',29),
	 (2904803,'CAATIBA',29),
	 (2904852,'CABACEIRAS DO PARAGUACU',29),
	 (2904902,'CACHOEIRA',29),
	 (2905008,'CACULE',29),
	 (2905107,'CAEM',29),
	 (2905156,'CAETANOS',29),
	 (2905206,'CAETITE',29),
	 (2905305,'CAFARNAUM',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2905404,'CAIRU',29),
	 (2905503,'CALDEIRAO GRANDE',29),
	 (2905602,'CAMACAN',29),
	 (2905701,'CAMACARI',29),
	 (2905800,'CAMAMU',29),
	 (2905909,'CAMPO ALEGRE DE LOURDES',29),
	 (2906006,'CAMPO FORMOSO',29),
	 (2906105,'CANAPOLIS',29),
	 (2906204,'CANARANA',29),
	 (2906303,'CANAVIEIRAS',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2906402,'CANDEAL',29),
	 (2906501,'CANDEIAS',29),
	 (2906600,'CANDIBA',29),
	 (2906709,'CANDIDO SALES',29),
	 (2906808,'CANSANCAO',29),
	 (2906824,'CANUDOS',29),
	 (2906857,'CAPELA DO ALTO ALEGRE',29),
	 (2906873,'CAPIM GROSSO',29),
	 (2906899,'CARAIBAS',29),
	 (2906907,'CARAVELAS',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2907004,'CARDEAL DA SILVA',29),
	 (2907103,'CARINHANHA',29),
	 (2907202,'CASA NOVA',29),
	 (2907301,'CASTRO ALVES',29),
	 (2907400,'CATOLANDIA',29),
	 (2907509,'CATU',29),
	 (2907558,'CATURAMA',29),
	 (2907608,'CENTRAL',29),
	 (2907707,'CHORROCHO',29),
	 (2907806,'CICERO DANTAS',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2907905,'CIPO',29),
	 (2908002,'COARACI',29),
	 (2908101,'COCOS',29),
	 (2908200,'CONCEICAO DA FEIRA',29),
	 (2908309,'CONCEICAO DO ALMEIDA',29),
	 (2908408,'CONCEICAO DO COITE',29),
	 (2908507,'CONCEICAO DO JACUIPE',29),
	 (2908606,'CONDE',29),
	 (2908705,'CONDEUBA',29),
	 (2908804,'CONTENDAS DO SINCORA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2908903,'CORACAO DE MARIA',29),
	 (2909000,'CORDEIROS',29),
	 (2909109,'CORIBE',29),
	 (2909208,'CORONEL JOAO SA',29),
	 (2909307,'CORRENTINA',29),
	 (2909406,'COTEGIPE',29),
	 (2909505,'CRAVOLANDIA',29),
	 (2909604,'CRISOPOLIS',29),
	 (2909703,'CRISTOPOLIS',29),
	 (2909802,'CRUZ DAS ALMAS',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2909901,'CURACA',29),
	 (2910008,'DARIO MEIRA',29),
	 (2910057,'DIAS D AVILA',29),
	 (2910107,'DOM BASILIO',29),
	 (2910206,'DOM MACEDO COSTA',29),
	 (2910305,'ELISIO MEDRADO',29),
	 (2910404,'ENCRUZILHADA',29),
	 (2910503,'ENTRE RIOS',29),
	 (2910602,'ESPLANADA',29),
	 (2910701,'EUCLIDES DA CUNHA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2910727,'EUNAPOLIS',29),
	 (2910750,'FATIMA',29),
	 (2910776,'FEIRA DA MATA',29),
	 (2910800,'FEIRA DE SANTANA',29),
	 (2910859,'FILADELFIA',29),
	 (2910909,'FIRMINO ALVES',29),
	 (2911006,'FLORESTA AZUL',29),
	 (2911105,'FORMOSA DO RIO PRETO',29),
	 (2911204,'GANDU',29),
	 (2911253,'GAVIAO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2911303,'GENTIO DO OURO',29),
	 (2911402,'GLORIA',29),
	 (2911501,'GONGOGI',29),
	 (2911600,'GOVERNADOR MANGABEIRA',29),
	 (2911659,'GUAJERU',29),
	 (2911709,'GUANAMBI',29),
	 (2911808,'GUARATINGA',29),
	 (2911857,'HELIOPOLIS',29),
	 (2911907,'IACU',29),
	 (2912004,'IBIASSUCE',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2912103,'IBICARAI',29),
	 (2912202,'IBICOARA',29),
	 (2912301,'IBICUI',29),
	 (2912400,'IBIPEBA',29),
	 (2912509,'IBIPITANGA',29),
	 (2912608,'IBIQUERA',29),
	 (2912707,'IBIRAPITANGA',29),
	 (2912806,'IBIRAPUA',29),
	 (2912905,'IBIRATAIA',29),
	 (2913002,'IBITIARA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2913101,'IBITITA',29),
	 (2913200,'IBOTIRAMA',29),
	 (2913309,'ICHU',29),
	 (2913408,'IGAPORA',29),
	 (2913457,'IGRAPIUNA',29),
	 (2913507,'IGUAI',29),
	 (2913606,'ILHEUS',29),
	 (2913705,'INHAMBUPE',29),
	 (2913804,'IPECAETA',29),
	 (2913903,'IPIAU',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2914000,'IPIRA',29),
	 (2914109,'IPUPIARA',29),
	 (2914208,'IRAJUBA',29),
	 (2914307,'IRAMAIA',29),
	 (2914406,'IRAQUARA',29),
	 (2914505,'IRARA',29),
	 (2914604,'IRECE',29),
	 (2914653,'ITABELA',29),
	 (2914703,'ITABERABA',29),
	 (2914802,'ITABUNA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2914901,'ITACARE',29),
	 (2915007,'ITAETE',29),
	 (2915106,'ITAGI',29),
	 (2915205,'ITAGIBA',29),
	 (2915304,'ITAGIMIRIM',29),
	 (2915353,'ITAGUACU DA BAHIA',29),
	 (2915403,'ITAJU DO COLONIA',29),
	 (2915502,'ITAJUIPE',29),
	 (2915601,'ITAMARAJU',29),
	 (2915700,'ITAMARI',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2915809,'ITAMBE',29),
	 (2915908,'ITANAGRA',29),
	 (2916005,'ITANHEM',29),
	 (2916104,'ITAPARICA',29),
	 (2916203,'ITAPE',29),
	 (2916302,'ITAPEBI',29),
	 (2916401,'ITAPETINGA',29),
	 (2916500,'ITAPICURU',29),
	 (2916609,'ITAPITANGA',29),
	 (2916708,'ITAQUARA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2916807,'ITARANTIM',29),
	 (2916856,'ITATIM',29),
	 (2916906,'ITIRUCU',29),
	 (2917003,'ITIUBA',29),
	 (2917102,'ITORORO',29),
	 (2917201,'ITUACU',29),
	 (2917300,'ITUBERA',29),
	 (2917334,'IUIU',29),
	 (2917359,'JABORANDI',29),
	 (2917409,'JACARACI',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2917508,'JACOBINA',29),
	 (2917607,'JAGUAQUARA',29),
	 (2917706,'JAGUARARI',29),
	 (2917805,'JAGUARIPE',29),
	 (2917904,'JANDAIRA',29),
	 (2918001,'JEQUIE',29),
	 (2918100,'JEREMOABO',29),
	 (2918209,'JIQUIRICA',29),
	 (2918308,'JITAUNA',29),
	 (2918357,'JOAO DOURADO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2918407,'JUAZEIRO',29),
	 (2918456,'JUCURUCU',29),
	 (2918506,'JUSSARA',29),
	 (2918555,'JUSSARI',29),
	 (2918605,'JUSSIAPE',29),
	 (2918704,'LAFAIETE COUTINHO',29),
	 (2918753,'LAGOA REAL',29),
	 (2918803,'LAJE',29),
	 (2918902,'LAJEDAO',29),
	 (2919009,'LAJEDINHO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2919058,'LAJEDO DO TABOCAL',29),
	 (2919108,'LAMARAO',29),
	 (2919157,'LAPAO',29),
	 (2919207,'LAURO DE FREITAS',29),
	 (2919306,'LENCOIS',29),
	 (2919405,'LICINIO DE ALMEIDA',29),
	 (2919504,'LIVRAMENTO DE NOSSA SENHORA',29),
	 (2919553,'LUIS EDUARDO MAGALHAES',29),
	 (2919603,'MACAJUBA',29),
	 (2919702,'MACARANI',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2919801,'MACAUBAS',29),
	 (2919900,'MACURURE',29),
	 (2919926,'MADRE DE DEUS',29),
	 (2919959,'MAETINGA',29),
	 (2920007,'MAIQUINIQUE',29),
	 (2920106,'MAIRI',29),
	 (2920205,'MALHADA',29),
	 (2920304,'MALHADA DE PEDRAS',29),
	 (2920403,'MANOEL VITORINO',29),
	 (2920452,'MANSIDAO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2920502,'MARACAS',29),
	 (2920601,'MARAGOGIPE',29),
	 (2920700,'MARAU',29),
	 (2920809,'MARCIONILIO SOUZA',29),
	 (2920908,'MASCOTE',29),
	 (2921005,'MATA DE SAO JOAO',29),
	 (2921054,'MATINA',29),
	 (2921104,'MEDEIROS NETO',29),
	 (2921203,'MIGUEL CALMON',29),
	 (2921302,'MILAGRES',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2921401,'MIRANGABA',29),
	 (2921450,'MIRANTE',29),
	 (2921500,'MONTE SANTO',29),
	 (2921609,'MORPARA',29),
	 (2921708,'MORRO DO CHAPEU',29),
	 (2921807,'MORTUGABA',29),
	 (2921906,'MUCUGE',29),
	 (2922003,'MUCURI',29),
	 (2922052,'MULUNGU DO MORRO',29),
	 (2922102,'MUNDO NOVO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2922201,'MUNIZ FERREIRA',29),
	 (2922250,'MUQUEM DE SAO FRANCISCO',29),
	 (2922300,'MURITIBA',29),
	 (2922409,'MUTUIPE',29),
	 (2922508,'NAZARE',29),
	 (2922607,'NILO PECANHA',29),
	 (2922656,'NORDESTINA',29),
	 (2922706,'NOVA CANAA',29),
	 (2922730,'NOVA FATIMA',29),
	 (2922755,'NOVA IBIA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2922805,'NOVA ITARANA',29),
	 (2922854,'NOVA REDENCAO',29),
	 (2922904,'NOVA SOURE',29),
	 (2923001,'NOVA VICOSA',29),
	 (2923035,'NOVO HORIZONTE',29),
	 (2923050,'NOVO TRIUNFO',29),
	 (2923100,'OLINDINA',29),
	 (2923209,'OLIVEIRA DOS BREJINHOS',29),
	 (2923308,'OURICANGAS',29),
	 (2923357,'OUROLANDIA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2923407,'PALMAS DE MONTE ALTO',29),
	 (2923506,'PALMEIRAS',29),
	 (2923605,'PARAMIRIM',29),
	 (2923704,'PARATINGA',29),
	 (2923803,'PARIPIRANGA',29),
	 (2923902,'PAU BRASIL',29),
	 (2924009,'PAULO AFONSO',29),
	 (2924058,'PE DE SERRA',29),
	 (2924108,'PEDRAO',29),
	 (2924207,'PEDRO ALEXANDRE',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2924306,'PIATA',29),
	 (2924405,'PILAO ARCADO',29),
	 (2924504,'PINDAI',29),
	 (2924603,'PINDOBACU',29),
	 (2924652,'PINTADAS',29),
	 (2924678,'PIRAI DO NORTE',29),
	 (2924702,'PIRIPA',29),
	 (2924801,'PIRITIBA',29),
	 (2924900,'PLANALTINO',29),
	 (2925006,'PLANALTO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2925105,'POCOES',29),
	 (2925204,'POJUCA',29),
	 (2925253,'PONTO NOVO',29),
	 (2925303,'PORTO SEGURO',29),
	 (2925402,'POTIRAGUA',29),
	 (2925501,'PRADO',29),
	 (2925600,'PRESIDENTE DUTRA',29),
	 (2925709,'PRESIDENTE JANIO QUADROS',29),
	 (2925758,'PRESIDENTE TANCREDO NEVES',29),
	 (2925808,'QUEIMADAS',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2925907,'QUIJINGUE',29),
	 (2925931,'QUIXABEIRA',29),
	 (2925956,'RAFAEL JAMBEIRO',29),
	 (2926004,'REMANSO',29),
	 (2926103,'RETIROLANDIA',29),
	 (2926202,'RIACHAO DAS NEVES',29),
	 (2926301,'RIACHAO DO JACUIPE',29),
	 (2926400,'RIACHO DE SANTANA',29),
	 (2926509,'RIBEIRA DO AMPARO',29),
	 (2926608,'RIBEIRA DO POMBAL',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2926657,'RIBEIRAO DO LARGO',29),
	 (2926707,'RIO DE CONTAS',29),
	 (2926806,'RIO DO ANTONIO',29),
	 (2926905,'RIO DO PIRES',29),
	 (2927002,'RIO REAL',29),
	 (2927101,'RODELAS',29),
	 (2927200,'RUY BARBOSA',29),
	 (2927309,'SALINAS DA MARGARIDA',29),
	 (2927408,'SALVADOR',29),
	 (2927507,'SANTA BARBARA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2927606,'SANTA BRIGIDA',29),
	 (2927705,'SANTA CRUZ CABRALIA',29),
	 (2927804,'SANTA CRUZ DA VITORIA',29),
	 (2927903,'SANTA INES',29),
	 (2928000,'SANTALUZ',29),
	 (2928059,'SANTA LUZIA',29),
	 (2928109,'SANTA MARIA DA VITORIA',29),
	 (2928208,'SANTANA',29),
	 (2928307,'SANTANOPOLIS',29),
	 (2928406,'SANTA RITA DE CASSIA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2928505,'SANTA TERESINHA',29),
	 (2928604,'SANTO AMARO',29),
	 (2928703,'SANTO ANTONIO DE JESUS',29),
	 (2928802,'SANTO ESTEVAO',29),
	 (2928901,'SAO DESIDERIO',29),
	 (2928950,'SAO DOMINGOS',29),
	 (2929008,'SAO FELIX',29),
	 (2929057,'SAO FELIX DO CORIBE',29),
	 (2929107,'SAO FELIPE',29),
	 (2929206,'SAO FRANCISCO DO CONDE',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2929255,'SAO GABRIEL',29),
	 (2929305,'SAO GONCALO DOS CAMPOS',29),
	 (2929354,'SAO JOSE DA VITORIA',29),
	 (2929370,'SAO JOSE DO JACUIPE',29),
	 (2929404,'SAO MIGUEL DAS MATAS',29),
	 (2929503,'SAO SEBASTIAO DO PASSE',29),
	 (2929602,'SAPEACU',29),
	 (2929701,'SATIRO DIAS',29),
	 (2929750,'SAUBARA',29),
	 (2929800,'SAUDE',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2929909,'SEABRA',29),
	 (2930006,'SEBASTIAO LARANJEIRAS',29),
	 (2930105,'SENHOR DO BONFIM',29),
	 (2930154,'SERRA DO RAMALHO',29),
	 (2930204,'SENTO SE',29),
	 (2930303,'SERRA DOURADA',29),
	 (2930402,'SERRA PRETA',29),
	 (2930501,'SERRINHA',29),
	 (2930600,'SERROLANDIA',29),
	 (2930709,'SIMOES FILHO',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2930758,'SITIO DO MATO',29),
	 (2930766,'SITIO DO QUINTO',29),
	 (2930774,'SOBRADINHO',29),
	 (2930808,'SOUTO SOARES',29),
	 (2930907,'TABOCAS DO BREJO VELHO',29),
	 (2931004,'TANHACU',29),
	 (2931053,'TANQUE NOVO',29),
	 (2931103,'TANQUINHO',29),
	 (2931202,'TAPEROA',29),
	 (2931301,'TAPIRAMUTA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2931350,'TEIXEIRA DE FREITAS',29),
	 (2931400,'TEODORO SAMPAIO',29),
	 (2931509,'TEOFILANDIA',29),
	 (2931608,'TEOLANDIA',29),
	 (2931707,'TERRA NOVA',29),
	 (2931806,'TREMEDAL',29),
	 (2931905,'TUCANO',29),
	 (2932002,'UAUA',29),
	 (2932101,'UBAIRA',29),
	 (2932200,'UBAITABA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2932309,'UBATA',29),
	 (2932408,'UIBAI',29),
	 (2932457,'UMBURANAS',29),
	 (2932507,'UNA',29),
	 (2932606,'URANDI',29),
	 (2932705,'URUCUCA',29),
	 (2932804,'UTINGA',29),
	 (2932903,'VALENCA',29),
	 (2933000,'VALENTE',29),
	 (2933059,'VARZEA DA ROCA',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (2933109,'VARZEA DO POCO',29),
	 (2933158,'VARZEA NOVA',29),
	 (2933174,'VARZEDO',29),
	 (2933208,'VERA CRUZ',29),
	 (2933257,'VEREDA',29),
	 (2933307,'VITORIA DA CONQUISTA',29),
	 (2933406,'WAGNER',29),
	 (2933455,'WANDERLEY',29),
	 (2933505,'WENCESLAU GUIMARAES',29),
	 (2933604,'XIQUE-XIQUE',29);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3100104,'ABADIA DOS DOURADOS',31),
	 (3100203,'ABAETE',31),
	 (3100302,'ABRE CAMPO',31),
	 (3100401,'ACAIACA',31),
	 (3100500,'ACUCENA',31),
	 (3100609,'AGUA BOA',31),
	 (3100708,'AGUA COMPRIDA',31),
	 (3100807,'AGUANIL',31),
	 (3100906,'AGUAS FORMOSAS',31),
	 (3101003,'AGUAS VERMELHAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3101102,'AIMORES',31),
	 (3101201,'AIURUOCA',31),
	 (3101300,'ALAGOA',31),
	 (3101409,'ALBERTINA',31),
	 (3101508,'ALEM PARAIBA',31),
	 (3101607,'ALFENAS',31),
	 (3101631,'ALFREDO VASCONCELOS',31),
	 (3101706,'ALMENARA',31),
	 (3101805,'ALPERCATA',31),
	 (3101904,'ALPINOPOLIS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3102001,'ALTEROSA',31),
	 (3102050,'ALTO CAPARAO',31),
	 (3102100,'ALTO RIO DOCE',31),
	 (3102209,'ALVARENGA',31),
	 (3102308,'ALVINOPOLIS',31),
	 (3102407,'ALVORADA DE MINAS',31),
	 (3102506,'AMPARO DO SERRA',31),
	 (3102605,'ANDRADAS',31),
	 (3102704,'CACHOEIRA DE PAJEU',31),
	 (3102803,'ANDRELANDIA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3102852,'ANGELANDIA',31),
	 (3102902,'ANTONIO CARLOS',31),
	 (3103009,'ANTONIO DIAS',31),
	 (3103108,'ANTONIO PRADO DE MINAS',31),
	 (3103207,'ARACAI',31),
	 (3103306,'ARACITABA',31),
	 (3103405,'ARACUAI',31),
	 (3103504,'ARAGUARI',31),
	 (3103603,'ARANTINA',31),
	 (3103702,'ARAPONGA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3103751,'ARAPORA',31),
	 (3103801,'ARAPUA',31),
	 (3103900,'ARAUJOS',31),
	 (3104007,'ARAXA',31),
	 (3104106,'ARCEBURGO',31),
	 (3104205,'ARCOS',31),
	 (3104304,'AREADO',31),
	 (3104403,'ARGIRITA',31),
	 (3104452,'ARICANDUVA',31),
	 (3104502,'ARINOS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3104601,'ASTOLFO DUTRA',31),
	 (3104700,'ATALEIA',31),
	 (3104809,'AUGUSTO DE LIMA',31),
	 (3104908,'BAEPENDI',31),
	 (3105004,'BALDIM',31),
	 (3105103,'BAMBUI',31),
	 (3105202,'BANDEIRA',31),
	 (3105301,'BANDEIRA DO SUL',31),
	 (3105400,'BARAO DE COCAIS',31),
	 (3105509,'BARAO DE MONTE ALTO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3105608,'BARBACENA',31),
	 (3105707,'BARRA LONGA',31),
	 (3105905,'BARROSO',31),
	 (3106002,'BELA VISTA DE MINAS',31),
	 (3106101,'BELMIRO BRAGA',31),
	 (3106200,'BELO HORIZONTE',31),
	 (3106309,'BELO ORIENTE',31),
	 (3106408,'BELO VALE',31),
	 (3106507,'BERILO',31),
	 (3106606,'BERTOPOLIS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3106655,'BERIZAL',31),
	 (3106705,'BETIM',31),
	 (3106804,'BIAS FORTES',31),
	 (3106903,'BICAS',31),
	 (3107000,'BIQUINHAS',31),
	 (3107109,'BOA ESPERANCA',31),
	 (3107208,'BOCAINA DE MINAS',31),
	 (3107307,'BOCAIUVA',31),
	 (3107406,'BOM DESPACHO',31),
	 (3107505,'BOM JARDIM DE MINAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3107604,'BOM JESUS DA PENHA',31),
	 (3107703,'BOM JESUS DO AMPARO',31),
	 (3107802,'BOM JESUS DO GALHO',31),
	 (3107901,'BOM REPOUSO',31),
	 (3108008,'BOM SUCESSO',31),
	 (3108107,'BONFIM',31),
	 (3108206,'BONFINOPOLIS DE MINAS',31),
	 (3108255,'BONITO DE MINAS',31),
	 (3108305,'BORDA DA MATA',31),
	 (3108404,'BOTELHOS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3108503,'BOTUMIRIM',31),
	 (3108552,'BRASILANDIA DE MINAS',31),
	 (3108602,'BRASILIA DE MINAS',31),
	 (3108701,'BRAS PIRES',31),
	 (3108800,'BRAUNAS',31),
	 (3108909,'BRASOPOLIS',31),
	 (3109006,'BRUMADINHO',31),
	 (3109105,'BUENO BRANDAO',31),
	 (3109204,'BUENOPOLIS',31),
	 (3109253,'BUGRE',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3109303,'BURITIS',31),
	 (3109402,'BURITIZEIRO',31),
	 (3109451,'CABECEIRA GRANDE',31),
	 (3109501,'CABO VERDE',31),
	 (3109600,'CACHOEIRA DA PRATA',31),
	 (3109709,'CACHOEIRA DE MINAS',31),
	 (3109808,'CACHOEIRA DOURADA',31),
	 (3109907,'CAETANOPOLIS',31),
	 (3110004,'CAETE',31),
	 (3110103,'CAIANA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3110202,'CAJURI',31),
	 (3110301,'CALDAS',31),
	 (3110400,'CAMACHO',31),
	 (3110509,'CAMANDUCAIA',31),
	 (3110608,'CAMBUI',31),
	 (3110707,'CAMBUQUIRA',31),
	 (3110806,'CAMPANARIO',31),
	 (3110905,'CAMPANHA',31),
	 (3111002,'CAMPESTRE',31),
	 (3111101,'CAMPINA VERDE',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3111150,'CAMPO AZUL',31),
	 (3111200,'CAMPO BELO',31),
	 (3111309,'CAMPO DO MEIO',31),
	 (3111408,'CAMPO FLORIDO',31),
	 (3111507,'CAMPOS ALTOS',31),
	 (3111606,'CAMPOS GERAIS',31),
	 (3111705,'CANAA',31),
	 (3111804,'CANAPOLIS',31),
	 (3111903,'CANA VERDE',31),
	 (3112000,'CANDEIAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3112059,'CANTAGALO',31),
	 (3112109,'CAPARAO',31),
	 (3112208,'CAPELA NOVA',31),
	 (3112307,'CAPELINHA',31),
	 (3112406,'CAPETINGA',31),
	 (3112505,'CAPIM BRANCO',31),
	 (3112604,'CAPINOPOLIS',31),
	 (3112653,'CAPITAO ANDRADE',31),
	 (3112703,'CAPITAO ENEAS',31),
	 (3112802,'CAPITOLIO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3112901,'CAPUTIRA',31),
	 (3113008,'CARAI',31),
	 (3113107,'CARANAIBA',31),
	 (3113206,'CARANDAI',31),
	 (3113305,'CARANGOLA',31),
	 (3113404,'CARATINGA',31),
	 (3113503,'CARBONITA',31),
	 (3113602,'CAREACU',31),
	 (3113701,'CARLOS CHAGAS',31),
	 (3113800,'CARMESIA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3113909,'CARMO DA CACHOEIRA',31),
	 (3114006,'CARMO DA MATA',31),
	 (3114105,'CARMO DE MINAS',31),
	 (3114204,'CARMO DO CAJURU',31),
	 (3114303,'CARMO DO PARANAIBA',31),
	 (3114402,'CARMO DO RIO CLARO',31),
	 (3114501,'CARMOPOLIS DE MINAS',31),
	 (3114550,'CARNEIRINHO',31),
	 (3114600,'CARRANCAS',31),
	 (3114709,'CARVALHOPOLIS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3114808,'CARVALHOS',31),
	 (3114907,'CASA GRANDE',31),
	 (3115003,'CASCALHO RICO',31),
	 (3115102,'CASSIA',31),
	 (3115201,'CONCEICAO DA BARRA DE MINAS',31),
	 (3115300,'CATAGUASES',31),
	 (3115359,'CATAS ALTAS',31),
	 (3115409,'CATAS ALTAS DA NORUEGA',31),
	 (3115458,'CATUJI',31),
	 (3115474,'CATUTI',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3115508,'CAXAMBU',31),
	 (3115607,'CEDRO DO ABAETE',31),
	 (3115706,'CENTRAL DE MINAS',31),
	 (3115805,'CENTRALINA',31),
	 (3115904,'CHACARA',31),
	 (3116001,'CHALE',31),
	 (3116100,'CHAPADA DO NORTE',31),
	 (3116159,'CHAPADA GAUCHA',31),
	 (3116209,'CHIADOR',31),
	 (3116308,'CIPOTANEA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3116407,'CLARAVAL',31),
	 (3116506,'CLARO DOS POCOES',31),
	 (3116605,'CLAUDIO',31),
	 (3116704,'COIMBRA',31),
	 (3116803,'COLUNA',31),
	 (3116902,'COMENDADOR GOMES',31),
	 (3117009,'COMERCINHO',31),
	 (3117108,'CONCEICAO DA APARECIDA',31),
	 (3117207,'CONCEICAO DAS PEDRAS',31),
	 (3117306,'CONCEICAO DAS ALAGOAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3117405,'CONCEICAO DE IPANEMA',31),
	 (3117504,'CONCEICAO DO MATO DENTRO',31),
	 (3117603,'CONCEICAO DO PARA',31),
	 (3117702,'CONCEICAO DO RIO VERDE',31),
	 (3117801,'CONCEICAO DOS OUROS',31),
	 (3117836,'CONEGO MARINHO',31),
	 (3117876,'CONFINS',31),
	 (3117900,'CONGONHAL',31),
	 (3118007,'CONGONHAS',31),
	 (3118106,'CONGONHAS DO NORTE',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3118205,'CONQUISTA',31),
	 (3118304,'CONSELHEIRO LAFAIETE',31),
	 (3118403,'CONSELHEIRO PENA',31),
	 (3118502,'CONSOLACAO',31),
	 (3118601,'CONTAGEM',31),
	 (3118700,'COQUEIRAL',31),
	 (3118809,'CORACAO DE JESUS',31),
	 (3118908,'CORDISBURGO',31),
	 (3119005,'CORDISLANDIA',31),
	 (3119104,'CORINTO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3119203,'COROACI',31),
	 (3119302,'COROMANDEL',31),
	 (3119401,'CORONEL FABRICIANO',31),
	 (3119500,'CORONEL MURTA',31),
	 (3119609,'CORONEL PACHECO',31),
	 (3119708,'CORONEL XAVIER CHAVES',31),
	 (3119807,'CORREGO DANTA',31),
	 (3119906,'CORREGO DO BOM JESUS',31),
	 (3119955,'CORREGO FUNDO',31),
	 (3120003,'CORREGO NOVO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3120102,'COUTO DE MAGALHAES DE MINAS',31),
	 (3120151,'CRISOLITA',31),
	 (3120201,'CRISTAIS',31),
	 (3120300,'CRISTALIA',31),
	 (3120409,'CRISTIANO OTONI',31),
	 (3120508,'CRISTINA',31),
	 (3120607,'CRUCILANDIA',31),
	 (3120706,'CRUZEIRO DA FORTALEZA',31),
	 (3120805,'CRUZILIA',31),
	 (3120839,'CUPARAQUE',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3120870,'CURRAL DE DENTRO',31),
	 (3120904,'CURVELO',31),
	 (3121001,'DATAS',31),
	 (3121100,'DELFIM MOREIRA',31),
	 (3121209,'DELFINOPOLIS',31),
	 (3121258,'DELTA',31),
	 (3121308,'DESCOBERTO',31),
	 (3121407,'DESTERRO DE ENTRE RIOS',31),
	 (3121506,'DESTERRO DO MELO',31),
	 (3121605,'DIAMANTINA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3121704,'DIOGO DE VASCONCELOS',31),
	 (3121803,'DIONISIO',31),
	 (3121902,'DIVINESIA',31),
	 (3122009,'DIVINO',31),
	 (3122108,'DIVINO DAS LARANJEIRAS',31),
	 (3122207,'DIVINOLANDIA DE MINAS',31),
	 (3122306,'DIVINOPOLIS',31),
	 (3122355,'DIVISA ALEGRE',31),
	 (3122405,'DIVISA NOVA',31),
	 (3122454,'DIVISOPOLIS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3122470,'DOM BOSCO',31),
	 (3122504,'DOM CAVATI',31),
	 (3122603,'DOM JOAQUIM',31),
	 (3122702,'DOM SILVERIO',31),
	 (3122801,'DOM VICOSO',31),
	 (3122900,'DONA EUSEBIA',31),
	 (3123007,'DORES DE CAMPOS',31),
	 (3123106,'DORES DE GUANHAES',31),
	 (3123205,'DORES DO INDAIA',31),
	 (3123304,'DORES DO TURVO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3123403,'DORESOPOLIS',31),
	 (3123502,'DOURADOQUARA',31),
	 (3123528,'DURANDE',31),
	 (3123601,'ELOI MENDES',31),
	 (3123700,'ENGENHEIRO CALDAS',31),
	 (3123809,'ENGENHEIRO NAVARRO',31),
	 (3123858,'ENTRE FOLHAS',31),
	 (3123908,'ENTRE RIOS DE MINAS',31),
	 (3124005,'ERVALIA',31),
	 (3124104,'ESMERALDAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3124203,'ESPERA FELIZ',31),
	 (3124302,'ESPINOSA',31),
	 (3124401,'ESPIRITO SANTO DO DOURADO',31),
	 (3124500,'ESTIVA',31),
	 (3124609,'ESTRELA DALVA',31),
	 (3124708,'ESTRELA DO INDAIA',31),
	 (3124807,'ESTRELA DO SUL',31),
	 (3124906,'EUGENOPOLIS',31),
	 (3125002,'EWBANK DA CAMARA',31),
	 (3125101,'EXTREMA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3125200,'FAMA',31),
	 (3125309,'FARIA LEMOS',31),
	 (3125408,'FELICIO DOS SANTOS',31),
	 (3125507,'SAO GONCALO DO RIO PRETO',31),
	 (3125606,'FELISBURGO',31),
	 (3125705,'FELIXLANDIA',31),
	 (3125804,'FERNANDES TOURINHO',31),
	 (3125903,'FERROS',31),
	 (3125952,'FERVEDOURO',31),
	 (3126000,'FLORESTAL',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3126109,'FORMIGA',31),
	 (3126208,'FORMOSO',31),
	 (3126307,'FORTALEZA DE MINAS',31),
	 (3126406,'FORTUNA DE MINAS',31),
	 (3126505,'FRANCISCO BADARO',31),
	 (3126604,'FRANCISCO DUMONT',31),
	 (3126703,'FRANCISCO SA',31),
	 (3126752,'FRANCISCOPOLIS',31),
	 (3126802,'FREI GASPAR',31),
	 (3126901,'FREI INOCENCIO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3126950,'FREI LAGONEGRO',31),
	 (3127008,'FRONTEIRA',31),
	 (3127057,'FRONTEIRA DOS VALES',31),
	 (3127073,'FRUTA DE LEITE',31),
	 (3127107,'FRUTAL',31),
	 (3127206,'FUNILANDIA',31),
	 (3127305,'GALILEIA',31),
	 (3127339,'GAMELEIRAS',31),
	 (3127354,'GLAUCILANDIA',31),
	 (3127370,'GOIABEIRA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3127388,'GOIANA',31),
	 (3127404,'GONCALVES',31),
	 (3127503,'GONZAGA',31),
	 (3127602,'GOUVEIA',31),
	 (3127701,'GOVERNADOR VALADARES',31),
	 (3127800,'GRAO MOGOL',31),
	 (3127909,'GRUPIARA',31),
	 (3128006,'GUANHAES',31),
	 (3128105,'GUAPE',31),
	 (3128204,'GUARACIABA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3128253,'GUARACIAMA',31),
	 (3128303,'GUARANESIA',31),
	 (3128402,'GUARANI',31),
	 (3128501,'GUARARA',31),
	 (3128600,'GUARDA-MOR',31),
	 (3128709,'GUAXUPE',31),
	 (3128808,'GUIDOVAL',31),
	 (3128907,'GUIMARANIA',31),
	 (3129004,'GUIRICEMA',31),
	 (3129103,'GURINHATA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3129202,'HELIODORA',31),
	 (3129301,'IAPU',31),
	 (3129400,'IBERTIOGA',31),
	 (3129509,'IBIA',31),
	 (3129608,'IBIAI',31),
	 (3129657,'IBIRACATU',31),
	 (3129707,'IBIRACI',31),
	 (3129806,'IBIRITE',31),
	 (3129905,'IBITIURA DE MINAS',31),
	 (3130002,'IBITURUNA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3130051,'ICARAI DE MINAS',31),
	 (3130101,'IGARAPE',31),
	 (3130200,'IGARATINGA',31),
	 (3130309,'IGUATAMA',31),
	 (3130408,'IJACI',31),
	 (3130507,'ILICINEA',31),
	 (3130556,'IMBE DE MINAS',31),
	 (3130606,'INCONFIDENTES',31),
	 (3130655,'INDAIABIRA',31),
	 (3130705,'INDIANOPOLIS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3130804,'INGAI',31),
	 (3130903,'INHAPIM',31),
	 (3131000,'INHAUMA',31),
	 (3131109,'INIMUTABA',31),
	 (3131158,'IPABA',31),
	 (3131208,'IPANEMA',31),
	 (3131307,'IPATINGA',31),
	 (3131406,'IPIACU',31),
	 (3131505,'IPUIUNA',31),
	 (3131604,'IRAI DE MINAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3131703,'ITABIRA',31),
	 (3131802,'ITABIRINHA',31),
	 (3131901,'ITABIRITO',31),
	 (3132008,'ITACAMBIRA',31),
	 (3132107,'ITACARAMBI',31),
	 (3132206,'ITAGUARA',31),
	 (3132305,'ITAIPE',31),
	 (3132404,'ITAJUBA',31),
	 (3132503,'ITAMARANDIBA',31),
	 (3132602,'ITAMARATI DE MINAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3132701,'ITAMBACURI',31),
	 (3132800,'ITAMBE DO MATO DENTRO',31),
	 (3132909,'ITAMOGI',31),
	 (3133006,'ITAMONTE',31),
	 (3133105,'ITANHANDU',31),
	 (3133204,'ITANHOMI',31),
	 (3133303,'ITAOBIM',31),
	 (3133402,'ITAPAGIPE',31),
	 (3133501,'ITAPECERICA',31),
	 (3133600,'ITAPEVA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3133709,'ITATIAIUCU',31),
	 (3133758,'ITAU DE MINAS',31),
	 (3133808,'ITAUNA',31),
	 (3133907,'ITAVERAVA',31),
	 (3134004,'ITINGA',31),
	 (3134103,'ITUETA',31),
	 (3134202,'ITUIUTABA',31),
	 (3134301,'ITUMIRIM',31),
	 (3134400,'ITURAMA',31),
	 (3134509,'ITUTINGA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3134608,'JABOTICATUBAS',31),
	 (3134707,'JACINTO',31),
	 (3134806,'JACUI',31),
	 (3134905,'JACUTINGA',31),
	 (3135001,'JAGUARACU',31),
	 (3135050,'JAIBA',31),
	 (3135076,'JAMPRUCA',31),
	 (3135100,'JANAUBA',31),
	 (3135209,'JANUARIA',31),
	 (3135308,'JAPARAIBA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3135357,'JAPONVAR',31),
	 (3135407,'JECEABA',31),
	 (3135456,'JENIPAPO DE MINAS',31),
	 (3135506,'JEQUERI',31),
	 (3135605,'JEQUITAI',31),
	 (3135704,'JEQUITIBA',31),
	 (3135803,'JEQUITINHONHA',31),
	 (3135902,'JESUANIA',31),
	 (3136009,'JOAIMA',31),
	 (3136108,'JOANESIA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3136207,'JOAO MONLEVADE',31),
	 (3136306,'JOAO PINHEIRO',31),
	 (3136405,'JOAQUIM FELICIO',31),
	 (3136504,'JORDANIA',31),
	 (3136520,'JOSE GONCALVES DE MINAS',31),
	 (3136553,'JOSE RAYDAN',31),
	 (3136579,'JOSENOPOLIS',31),
	 (3136603,'NOVA UNIAO',31),
	 (3136652,'JUATUBA',31),
	 (3136702,'JUIZ DE FORA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3136801,'JURAMENTO',31),
	 (3136900,'JURUAIA',31),
	 (3136959,'JUVENILIA',31),
	 (3137007,'LADAINHA',31),
	 (3137106,'LAGAMAR',31),
	 (3137205,'LAGOA DA PRATA',31),
	 (3137304,'LAGOA DOS PATOS',31),
	 (3137403,'LAGOA DOURADA',31),
	 (3137502,'LAGOA FORMOSA',31),
	 (3137536,'LAGOA GRANDE',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3137601,'LAGOA SANTA',31),
	 (3137700,'LAJINHA',31),
	 (3137809,'LAMBARI',31),
	 (3137908,'LAMIM',31),
	 (3138005,'LARANJAL',31),
	 (3138104,'LASSANCE',31),
	 (3138203,'LAVRAS',31),
	 (3138302,'LEANDRO FERREIRA',31),
	 (3138351,'LEME DO PRADO',31),
	 (3138401,'LEOPOLDINA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3138500,'LIBERDADE',31),
	 (3138609,'LIMA DUARTE',31),
	 (3138625,'LIMEIRA DO OESTE',31),
	 (3138658,'LONTRA',31),
	 (3138674,'LUISBURGO',31),
	 (3138682,'LUISLANDIA',31),
	 (3138708,'LUMINARIAS',31),
	 (3138807,'LUZ',31),
	 (3138906,'MACHACALIS',31),
	 (3139003,'MACHADO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3139102,'MADRE DE DEUS DE MINAS',31),
	 (3139201,'MALACACHETA',31),
	 (3139250,'MAMONAS',31),
	 (3139300,'MANGA',31),
	 (3139409,'MANHUACU',31),
	 (3139508,'MANHUMIRIM',31),
	 (3139607,'MANTENA',31),
	 (3139706,'MARAVILHAS',31),
	 (3139805,'MAR DE ESPANHA',31),
	 (3139904,'MARIA DA FE',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3140001,'MARIANA',31),
	 (3140100,'MARILAC',31),
	 (3140159,'MARIO CAMPOS',31),
	 (3140209,'MARIPA DE MINAS',31),
	 (3140308,'MARLIERIA',31),
	 (3140407,'MARMELOPOLIS',31),
	 (3140506,'MARTINHO CAMPOS',31),
	 (3140530,'MARTINS SOARES',31),
	 (3140555,'MATA VERDE',31),
	 (3140605,'MATERLANDIA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3140704,'MATEUS LEME',31),
	 (3140803,'MATIAS BARBOSA',31),
	 (3140852,'MATIAS CARDOSO',31),
	 (3140902,'MATIPO',31),
	 (3141009,'MATO VERDE',31),
	 (3141108,'MATOZINHOS',31),
	 (3141207,'MATUTINA',31),
	 (3141306,'MEDEIROS',31),
	 (3141405,'MEDINA',31),
	 (3141504,'MENDES PIMENTEL',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3141603,'MERCES',31),
	 (3141702,'MESQUITA',31),
	 (3141801,'MINAS NOVAS',31),
	 (3141900,'MINDURI',31),
	 (3142007,'MIRABELA',31),
	 (3142106,'MIRADOURO',31),
	 (3142205,'MIRAI',31),
	 (3142254,'MIRAVANIA',31),
	 (3142304,'MOEDA',31),
	 (3142403,'MOEMA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3142502,'MONJOLOS',31),
	 (3142601,'MONSENHOR PAULO',31),
	 (3142700,'MONTALVANIA',31),
	 (3142809,'MONTE ALEGRE DE MINAS',31),
	 (3142908,'MONTE AZUL',31),
	 (3143005,'MONTE BELO',31),
	 (3143104,'MONTE CARMELO',31),
	 (3143153,'MONTE FORMOSO',31),
	 (3143203,'MONTE SANTO DE MINAS',31),
	 (3143302,'MONTES CLAROS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3143401,'MONTE SIAO',31),
	 (3143450,'MONTEZUMA',31),
	 (3143500,'MORADA NOVA DE MINAS',31),
	 (3143609,'MORRO DA GARCA',31),
	 (3143708,'MORRO DO PILAR',31),
	 (3143807,'MUNHOZ',31),
	 (3143906,'MURIAE',31),
	 (3144003,'MUTUM',31),
	 (3144102,'MUZAMBINHO',31),
	 (3144201,'NACIP RAYDAN',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3144300,'NANUQUE',31),
	 (3144359,'NAQUE',31),
	 (3144375,'NATALANDIA',31),
	 (3144409,'NATERCIA',31),
	 (3144508,'NAZARENO',31),
	 (3144607,'NEPOMUCENO',31),
	 (3144656,'NINHEIRA',31),
	 (3144672,'NOVA BELEM',31),
	 (3144706,'NOVA ERA',31),
	 (3144805,'NOVA LIMA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3144904,'NOVA MODICA',31),
	 (3145000,'NOVA PONTE',31),
	 (3145059,'NOVA PORTEIRINHA',31),
	 (3145109,'NOVA RESENDE',31),
	 (3145208,'NOVA SERRANA',31),
	 (3145307,'NOVO CRUZEIRO',31),
	 (3145356,'NOVO ORIENTE DE MINAS',31),
	 (3145372,'NOVORIZONTE',31),
	 (3145406,'OLARIA',31),
	 (3145455,'OLHOS-D AGUA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3145505,'OLIMPIO NORONHA',31),
	 (3145604,'OLIVEIRA',31),
	 (3145703,'OLIVEIRA FORTES',31),
	 (3145802,'ONCA DE PITANGUI',31),
	 (3145851,'ORATORIOS',31),
	 (3145877,'ORIZANIA',31),
	 (3145901,'OURO BRANCO',31),
	 (3146008,'OURO FINO',31),
	 (3146107,'OURO PRETO',31),
	 (3146206,'OURO VERDE DE MINAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3146255,'PADRE CARVALHO',31),
	 (3146305,'PADRE PARAISO',31),
	 (3146404,'PAINEIRAS',31),
	 (3146503,'PAINS',31),
	 (3146552,'PAI PEDRO',31),
	 (3146602,'PAIVA',31),
	 (3146701,'PALMA',31),
	 (3146750,'PALMOPOLIS',31),
	 (3146909,'PAPAGAIOS',31),
	 (3147006,'PARACATU',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3147105,'PARA DE MINAS',31),
	 (3147204,'PARAGUACU',31),
	 (3147303,'PARAISOPOLIS',31),
	 (3147402,'PARAOPEBA',31),
	 (3147501,'PASSABEM',31),
	 (3147600,'PASSA QUATRO',31),
	 (3147709,'PASSA TEMPO',31),
	 (3147808,'PASSA-VINTE',31),
	 (3147907,'PASSOS',31),
	 (3147956,'PATIS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3148004,'PATOS DE MINAS',31),
	 (3148103,'PATROCINIO',31),
	 (3148202,'PATROCINIO DO MURIAE',31),
	 (3148301,'PAULA CANDIDO',31),
	 (3148400,'PAULISTAS',31),
	 (3148509,'PAVAO',31),
	 (3148608,'PECANHA',31),
	 (3148707,'PEDRA AZUL',31),
	 (3148756,'PEDRA BONITA',31),
	 (3148806,'PEDRA DO ANTA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3148905,'PEDRA DO INDAIA',31),
	 (3149002,'PEDRA DOURADA',31),
	 (3149101,'PEDRALVA',31),
	 (3149150,'PEDRAS DE MARIA DA CRUZ',31),
	 (3149200,'PEDRINOPOLIS',31),
	 (3149309,'PEDRO LEOPOLDO',31),
	 (3149408,'PEDRO TEIXEIRA',31),
	 (3149507,'PEQUERI',31),
	 (3149606,'PEQUI',31),
	 (3149705,'PERDIGAO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3149804,'PERDIZES',31),
	 (3149903,'PERDOES',31),
	 (3149952,'PERIQUITO',31),
	 (3150000,'PESCADOR',31),
	 (3150109,'PIAU',31),
	 (3150158,'PIEDADE DE CARATINGA',31),
	 (3150208,'PIEDADE DE PONTE NOVA',31),
	 (3150307,'PIEDADE DO RIO GRANDE',31),
	 (3150406,'PIEDADE DOS GERAIS',31),
	 (3150505,'PIMENTA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3150539,'PINGO-D AGUA',31),
	 (3150570,'PINTOPOLIS',31),
	 (3150604,'PIRACEMA',31),
	 (3150703,'PIRAJUBA',31),
	 (3150802,'PIRANGA',31),
	 (3150901,'PIRANGUCU',31),
	 (3151008,'PIRANGUINHO',31),
	 (3151107,'PIRAPETINGA',31),
	 (3151206,'PIRAPORA',31),
	 (3151305,'PIRAUBA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3151404,'PITANGUI',31),
	 (3151503,'PIUMHI',31),
	 (3151602,'PLANURA',31),
	 (3151701,'POCO FUNDO',31),
	 (3151800,'POCOS DE CALDAS',31),
	 (3151909,'POCRANE',31),
	 (3152006,'POMPEU',31),
	 (3152105,'PONTE NOVA',31),
	 (3152131,'PONTO CHIQUE',31),
	 (3152170,'PONTO DOS VOLANTES',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3152204,'PORTEIRINHA',31),
	 (3152303,'PORTO FIRME',31),
	 (3152402,'POTE',31),
	 (3152501,'POUSO ALEGRE',31),
	 (3152600,'POUSO ALTO',31),
	 (3152709,'PRADOS',31),
	 (3152808,'PRATA',31),
	 (3152907,'PRATAPOLIS',31),
	 (3153004,'PRATINHA',31),
	 (3153103,'PRESIDENTE BERNARDES',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3153202,'PRESIDENTE JUSCELINO',31),
	 (3153301,'PRESIDENTE KUBITSCHEK',31),
	 (3153400,'PRESIDENTE OLEGARIO',31),
	 (3153509,'ALTO JEQUITIBA',31),
	 (3153608,'PRUDENTE DE MORAIS',31),
	 (3153707,'QUARTEL GERAL',31),
	 (3153806,'QUELUZITO',31),
	 (3153905,'RAPOSOS',31),
	 (3154002,'RAUL SOARES',31),
	 (3154101,'RECREIO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3154150,'REDUTO',31),
	 (3154200,'RESENDE COSTA',31),
	 (3154309,'RESPLENDOR',31),
	 (3154408,'RESSAQUINHA',31),
	 (3154457,'RIACHINHO',31),
	 (3154507,'RIACHO DOS MACHADOS',31),
	 (3154606,'RIBEIRAO DAS NEVES',31),
	 (3154705,'RIBEIRAO VERMELHO',31),
	 (3154804,'RIO ACIMA',31),
	 (3154903,'RIO CASCA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3155009,'RIO DOCE',31),
	 (3155108,'RIO DO PRADO',31),
	 (3155207,'RIO ESPERA',31),
	 (3155306,'RIO MANSO',31),
	 (3155405,'RIO NOVO',31),
	 (3155504,'RIO PARANAIBA',31),
	 (3155603,'RIO PARDO DE MINAS',31),
	 (3155702,'RIO PIRACICABA',31),
	 (3155801,'RIO POMBA',31),
	 (3155900,'RIO PRETO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3156007,'RIO VERMELHO',31),
	 (3156106,'RITAPOLIS',31),
	 (3156205,'ROCHEDO DE MINAS',31),
	 (3156304,'RODEIRO',31),
	 (3156403,'ROMARIA',31),
	 (3156452,'ROSARIO DA LIMEIRA',31),
	 (3156502,'RUBELITA',31),
	 (3156601,'RUBIM',31),
	 (3156700,'SABARA',31),
	 (3156809,'SABINOPOLIS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3156908,'SACRAMENTO',31),
	 (3157005,'SALINAS',31),
	 (3157104,'SALTO DA DIVISA',31),
	 (3157203,'SANTA BARBARA',31),
	 (3157252,'SANTA BARBARA DO LESTE',31),
	 (3157278,'SANTA BARBARA DO MONTE VERDE',31),
	 (3157302,'SANTA BARBARA DO TUGURIO',31),
	 (3157336,'SANTA CRUZ DE MINAS',31),
	 (3157377,'SANTA CRUZ DE SALINAS',31),
	 (3157401,'SANTA CRUZ DO ESCALVADO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3157500,'SANTA EFIGENIA DE MINAS',31),
	 (3157609,'SANTA FE DE MINAS',31),
	 (3157658,'SANTA HELENA DE MINAS',31),
	 (3157708,'SANTA JULIANA',31),
	 (3157807,'SANTA LUZIA',31),
	 (3157906,'SANTA MARGARIDA',31),
	 (3158003,'SANTA MARIA DE ITABIRA',31),
	 (3158102,'SANTA MARIA DO SALTO',31),
	 (3158201,'SANTA MARIA DO SUACUI',31),
	 (3158300,'SANTANA DA VARGEM',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3158409,'SANTANA DE CATAGUASES',31),
	 (3158508,'SANTANA DE PIRAPAMA',31),
	 (3158607,'SANTANA DO DESERTO',31),
	 (3158706,'SANTANA DO GARAMBEU',31),
	 (3158805,'SANTANA DO JACARE',31),
	 (3158904,'SANTANA DO MANHUACU',31),
	 (3158953,'SANTANA DO PARAISO',31),
	 (3159001,'SANTANA DO RIACHO',31),
	 (3159100,'SANTANA DOS MONTES',31),
	 (3159209,'SANTA RITA DE CALDAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3159308,'SANTA RITA DE JACUTINGA',31),
	 (3159357,'SANTA RITA DE MINAS',31),
	 (3159407,'SANTA RITA DE IBITIPOCA',31),
	 (3159506,'SANTA RITA DO ITUETO',31),
	 (3159605,'SANTA RITA DO SAPUCAI',31),
	 (3159704,'SANTA ROSA DA SERRA',31),
	 (3159803,'SANTA VITORIA',31),
	 (3159902,'SANTO ANTONIO DO AMPARO',31),
	 (3160009,'SANTO ANTONIO DO AVENTUREIRO',31),
	 (3160108,'SANTO ANTONIO DO GRAMA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3160207,'SANTO ANTONIO DO ITAMBE',31),
	 (3160306,'SANTO ANTONIO DO JACINTO',31),
	 (3160405,'SANTO ANTONIO DO MONTE',31),
	 (3160454,'SANTO ANTONIO DO RETIRO',31),
	 (3160504,'SANTO ANTONIO DO RIO ABAIXO',31),
	 (3160603,'SANTO HIPOLITO',31),
	 (3160702,'SANTOS DUMONT',31),
	 (3160801,'SAO BENTO ABADE',31),
	 (3160900,'SAO BRAS DO SUACUI',31),
	 (3160959,'SAO DOMINGOS DAS DORES',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3161007,'SAO DOMINGOS DO PRATA',31),
	 (3161056,'SAO FELIX DE MINAS',31),
	 (3161106,'SAO FRANCISCO',31),
	 (3161205,'SAO FRANCISCO DE PAULA',31),
	 (3161304,'SAO FRANCISCO DE SALES',31),
	 (3161403,'SAO FRANCISCO DO GLORIA',31),
	 (3161502,'SAO GERALDO',31),
	 (3161601,'SAO GERALDO DA PIEDADE',31),
	 (3161650,'SAO GERALDO DO BAIXIO',31),
	 (3161700,'SAO GONCALO DO ABAETE',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3161809,'SAO GONCALO DO PARA',31),
	 (3161908,'SAO GONCALO DO RIO ABAIXO',31),
	 (3162005,'SAO GONCALO DO SAPUCAI',31),
	 (3162104,'SAO GOTARDO',31),
	 (3162203,'SAO JOAO BATISTA DO GLORIA',31),
	 (3162252,'SAO JOAO DA LAGOA',31),
	 (3162302,'SAO JOAO DA MATA',31),
	 (3162401,'SAO JOAO DA PONTE',31),
	 (3162450,'SAO JOAO DAS MISSOES',31),
	 (3162500,'SAO JOAO DEL REI',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3162559,'SAO JOAO DO MANHUACU',31),
	 (3162575,'SAO JOAO DO MANTENINHA',31),
	 (3162609,'SAO JOAO DO ORIENTE',31),
	 (3162658,'SAO JOAO DO PACUI',31),
	 (3162708,'SAO JOAO DO PARAISO',31),
	 (3162807,'SAO JOAO EVANGELISTA',31),
	 (3162906,'SAO JOAO NEPOMUCENO',31),
	 (3162922,'SAO JOAQUIM DE BICAS',31),
	 (3162948,'SAO JOSE DA BARRA',31),
	 (3162955,'SAO JOSE DA LAPA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3163003,'SAO JOSE DA SAFIRA',31),
	 (3163102,'SAO JOSE DA VARGINHA',31),
	 (3163201,'SAO JOSE DO ALEGRE',31),
	 (3163300,'SAO JOSE DO DIVINO',31),
	 (3163409,'SAO JOSE DO GOIABAL',31),
	 (3163508,'SAO JOSE DO JACURI',31),
	 (3163607,'SAO JOSE DO MANTIMENTO',31),
	 (3163706,'SAO LOURENCO',31),
	 (3163805,'SAO MIGUEL DO ANTA',31),
	 (3163904,'SAO PEDRO DA UNIAO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3164001,'SAO PEDRO DOS FERROS',31),
	 (3164100,'SAO PEDRO DO SUACUI',31),
	 (3164209,'SAO ROMAO',31),
	 (3164308,'SAO ROQUE DE MINAS',31),
	 (3164407,'SAO SEBASTIAO DA BELA VISTA',31),
	 (3164431,'SAO SEBASTIAO DA VARGEM ALEGRE',31),
	 (3164472,'SAO SEBASTIAO DO ANTA',31),
	 (3164506,'SAO SEBASTIAO DO MARANHAO',31),
	 (3164605,'SAO SEBASTIAO DO OESTE',31),
	 (3164704,'SAO SEBASTIAO DO PARAISO',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3164803,'SAO SEBASTIAO DO RIO PRETO',31),
	 (3164902,'SAO SEBASTIAO DO RIO VERDE',31),
	 (3165008,'SAO TIAGO',31),
	 (3165107,'SAO TOMAS DE AQUINO',31),
	 (3165206,'SAO THOME DAS LETRAS',31),
	 (3165305,'SAO VICENTE DE MINAS',31),
	 (3165404,'SAPUCAI-MIRIM',31),
	 (3165503,'SARDOA',31),
	 (3165537,'SARZEDO',31),
	 (3165552,'SETUBINHA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3165560,'SEM-PEIXE',31),
	 (3165578,'SENADOR AMARAL',31),
	 (3165602,'SENADOR CORTES',31),
	 (3165701,'SENADOR FIRMINO',31),
	 (3165800,'SENADOR JOSE BENTO',31),
	 (3165909,'SENADOR MODESTINO GONCALVES',31),
	 (3166006,'SENHORA DE OLIVEIRA',31),
	 (3166105,'SENHORA DO PORTO',31),
	 (3166204,'SENHORA DOS REMEDIOS',31),
	 (3166303,'SERICITA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3166402,'SERITINGA',31),
	 (3166501,'SERRA AZUL DE MINAS',31),
	 (3166600,'SERRA DA SAUDADE',31),
	 (3166709,'SERRA DOS AIMORES',31),
	 (3166808,'SERRA DO SALITRE',31),
	 (3166907,'SERRANIA',31),
	 (3166956,'SERRANOPOLIS DE MINAS',31),
	 (3167004,'SERRANOS',31),
	 (3167103,'SERRO',31),
	 (3167202,'SETE LAGOAS',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3167301,'SILVEIRANIA',31),
	 (3167400,'SILVIANOPOLIS',31),
	 (3167509,'SIMAO PEREIRA',31),
	 (3167608,'SIMONESIA',31),
	 (3167707,'SOBRALIA',31),
	 (3167806,'SOLEDADE DE MINAS',31),
	 (3167905,'TABULEIRO',31),
	 (3168002,'TAIOBEIRAS',31),
	 (3168051,'TAPARUBA',31),
	 (3168101,'TAPIRA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3168200,'TAPIRAI',31),
	 (3168309,'TAQUARACU DE MINAS',31),
	 (3168408,'TARUMIRIM',31),
	 (3168507,'TEIXEIRAS',31),
	 (3168606,'TEOFILO OTONI',31),
	 (3168705,'TIMOTEO',31),
	 (3168804,'TIRADENTES',31),
	 (3168903,'TIROS',31),
	 (3169000,'TOCANTINS',31),
	 (3169059,'TOCOS DO MOJI',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3169109,'TOLEDO',31),
	 (3169208,'TOMBOS',31),
	 (3169307,'TRES CORACOES',31),
	 (3169356,'TRES MARIAS',31),
	 (3169406,'TRES PONTAS',31),
	 (3169505,'TUMIRITINGA',31),
	 (3169604,'TUPACIGUARA',31),
	 (3169703,'TURMALINA',31),
	 (3169802,'TURVOLANDIA',31),
	 (3169901,'UBA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3170008,'UBAI',31),
	 (3170057,'UBAPORANGA',31),
	 (3170107,'UBERABA',31),
	 (3170206,'UBERLANDIA',31),
	 (3170305,'UMBURATIBA',31),
	 (3170404,'UNAI',31),
	 (3170438,'UNIAO DE MINAS',31),
	 (3170479,'URUANA DE MINAS',31),
	 (3170503,'URUCANIA',31),
	 (3170529,'URUCUIA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3170578,'VARGEM ALEGRE',31),
	 (3170602,'VARGEM BONITA',31),
	 (3170651,'VARGEM GRANDE DO RIO PARDO',31),
	 (3170701,'VARGINHA',31),
	 (3170750,'VARJAO DE MINAS',31),
	 (3170800,'VARZEA DA PALMA',31),
	 (3170909,'VARZELANDIA',31),
	 (3171006,'VAZANTE',31),
	 (3171030,'VERDELANDIA',31),
	 (3171071,'VEREDINHA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3171105,'VERISSIMO',31),
	 (3171154,'VERMELHO NOVO',31),
	 (3171204,'VESPASIANO',31),
	 (3171303,'VICOSA',31),
	 (3171402,'VIEIRAS',31),
	 (3171501,'MATHIAS LOBATO',31),
	 (3171600,'VIRGEM DA LAPA',31),
	 (3171709,'VIRGINIA',31),
	 (3171808,'VIRGINOPOLIS',31),
	 (3171907,'VIRGOLANDIA',31);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3172004,'VISCONDE DO RIO BRANCO',31),
	 (3172103,'VOLTA GRANDE',31),
	 (3172202,'WENCESLAU BRAZ',31),
	 (3200102,'AFONSO CLAUDIO',32),
	 (3200136,'AGUIA BRANCA',32),
	 (3200169,'AGUA DOCE DO NORTE',32),
	 (3200201,'ALEGRE',32),
	 (3200300,'ALFREDO CHAVES',32),
	 (3200359,'ALTO RIO NOVO',32),
	 (3200409,'ANCHIETA',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3200508,'APIACA',32),
	 (3200607,'ARACRUZ',32),
	 (3200706,'ATILIO VIVACQUA',32),
	 (3200805,'BAIXO GUANDU',32),
	 (3200904,'BARRA DE SAO FRANCISCO',32),
	 (3201001,'BOA ESPERANCA',32),
	 (3201100,'BOM JESUS DO NORTE',32),
	 (3201159,'BREJETUBA',32),
	 (3201209,'CACHOEIRO DE ITAPEMIRIM',32),
	 (3201308,'CARIACICA',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3201407,'CASTELO',32),
	 (3201506,'COLATINA',32),
	 (3201605,'CONCEICAO DA BARRA',32),
	 (3201704,'CONCEICAO DO CASTELO',32),
	 (3201803,'DIVINO DE SAO LOURENCO',32),
	 (3201902,'DOMINGOS MARTINS',32),
	 (3202009,'DORES DO RIO PRETO',32),
	 (3202108,'ECOPORANGA',32),
	 (3202207,'FUNDAO',32),
	 (3202256,'GOVERNADOR LINDENBERG',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3202306,'GUACUI',32),
	 (3202405,'GUARAPARI',32),
	 (3202454,'IBATIBA',32),
	 (3202504,'IBIRACU',32),
	 (3202553,'IBITIRAMA',32),
	 (3202603,'ICONHA',32),
	 (3202652,'IRUPI',32),
	 (3202702,'ITAGUACU',32),
	 (3202801,'ITAPEMIRIM',32),
	 (3202900,'ITARANA',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3203007,'IUNA',32),
	 (3203056,'JAGUARE',32),
	 (3203106,'JERONIMO MONTEIRO',32),
	 (3203130,'JOAO NEIVA',32),
	 (3203163,'LARANJA DA TERRA',32),
	 (3203205,'LINHARES',32),
	 (3203304,'MANTENOPOLIS',32),
	 (3203320,'MARATAIZES',32),
	 (3203346,'MARECHAL FLORIANO',32),
	 (3203353,'MARILANDIA',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3203403,'MIMOSO DO SUL',32),
	 (3203502,'MONTANHA',32),
	 (3203601,'MUCURICI',32),
	 (3203700,'MUNIZ FREIRE',32),
	 (3203809,'MUQUI',32),
	 (3203908,'NOVA VENECIA',32),
	 (3204005,'PANCAS',32),
	 (3204054,'PEDRO CANARIO',32),
	 (3204104,'PINHEIROS',32),
	 (3204203,'PIUMA',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3204252,'PONTO BELO',32),
	 (3204302,'PRESIDENTE KENNEDY',32),
	 (3204351,'RIO BANANAL',32),
	 (3204401,'RIO NOVO DO SUL',32),
	 (3204500,'SANTA LEOPOLDINA',32),
	 (3204559,'SANTA MARIA DE JETIBA',32),
	 (3204609,'SANTA TERESA',32),
	 (3204658,'SAO DOMINGOS DO NORTE',32),
	 (3204708,'SAO GABRIEL DA PALHA',32),
	 (3204807,'SAO JOSE DO CALCADO',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3204906,'SAO MATEUS',32),
	 (3204955,'SAO ROQUE DO CANAA',32),
	 (3205002,'SERRA',32),
	 (3205010,'SOORETAMA',32),
	 (3205036,'VARGEM ALTA',32),
	 (3205069,'VENDA NOVA DO IMIGRANTE',32),
	 (3205101,'VIANA',32),
	 (3205150,'VILA PAVAO',32),
	 (3205176,'VILA VALERIO',32),
	 (3205200,'VILA VELHA',32);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3205309,'VITORIA',32),
	 (3300100,'ANGRA DOS REIS',33),
	 (3300159,'APERIBE',33),
	 (3300209,'ARARUAMA',33),
	 (3300225,'AREAL',33),
	 (3300233,'ARMACAO DOS BUZIOS',33),
	 (3300258,'ARRAIAL DO CABO',33),
	 (3300308,'BARRA DO PIRAI',33),
	 (3300407,'BARRA MANSA',33),
	 (3300456,'BELFORD ROXO',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3300506,'BOM JARDIM',33),
	 (3300605,'BOM JESUS DO ITABAPOANA',33),
	 (3300704,'CABO FRIO',33),
	 (3300803,'CACHOEIRAS DE MACACU',33),
	 (3300902,'CAMBUCI',33),
	 (3300936,'CARAPEBUS',33),
	 (3300951,'COMENDADOR LEVY GASPARIAN',33),
	 (3301009,'CAMPOS DOS GOYTACAZES',33),
	 (3301108,'CANTAGALO',33),
	 (3301157,'CARDOSO MOREIRA',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3301207,'CARMO',33),
	 (3301306,'CASIMIRO DE ABREU',33),
	 (3301405,'CONCEICAO DE MACABU',33),
	 (3301504,'CORDEIRO',33),
	 (3301603,'DUAS BARRAS',33),
	 (3301702,'DUQUE DE CAXIAS',33),
	 (3301801,'ENGENHEIRO PAULO DE FRONTIN',33),
	 (3301850,'GUAPIMIRIM',33),
	 (3301876,'IGUABA GRANDE',33),
	 (3301900,'ITABORAI',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3302007,'ITAGUAI',33),
	 (3302056,'ITALVA',33),
	 (3302106,'ITAOCARA',33),
	 (3302205,'ITAPERUNA',33),
	 (3302254,'ITATIAIA',33),
	 (3302270,'JAPERI',33),
	 (3302304,'LAJE DO MURIAE',33),
	 (3302403,'MACAE',33),
	 (3302452,'MACUCO',33),
	 (3302502,'MAGE',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3302601,'MANGARATIBA',33),
	 (3302700,'MARICA',33),
	 (3302809,'MENDES',33),
	 (3302858,'MESQUITA',33),
	 (3302908,'MIGUEL PEREIRA',33),
	 (3303005,'MIRACEMA',33),
	 (3303104,'NATIVIDADE',33),
	 (3303203,'NILOPOLIS',33),
	 (3303302,'NITEROI',33),
	 (3303401,'NOVA FRIBURGO',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3303500,'NOVA IGUACU',33),
	 (3303609,'PARACAMBI',33),
	 (3303708,'PARAIBA DO SUL',33),
	 (3303807,'PARATI',33),
	 (3303856,'PATY DO ALFERES',33),
	 (3303906,'PETROPOLIS',33),
	 (3303955,'PINHEIRAL',33),
	 (3304003,'PIRAI',33),
	 (3304102,'PORCIUNCULA',33),
	 (3304110,'PORTO REAL',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3304128,'QUATIS',33),
	 (3304144,'QUEIMADOS',33),
	 (3304151,'QUISSAMA',33),
	 (3304201,'RESENDE',33),
	 (3304300,'RIO BONITO',33),
	 (3304409,'RIO CLARO',33),
	 (3304508,'RIO DAS FLORES',33),
	 (3304524,'RIO DAS OSTRAS',33),
	 (3304557,'RIO DE JANEIRO',33),
	 (3304607,'SANTA MARIA MADALENA',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3304706,'SANTO ANTONIO DE PADUA',33),
	 (3304755,'SAO FRANCISCO DE ITABAPOANA',33),
	 (3304805,'SAO FIDELIS',33),
	 (3304904,'SAO GONCALO',33),
	 (3305000,'SAO JOAO DA BARRA',33),
	 (3305109,'SAO JOAO DE MERITI',33),
	 (3305133,'SAO JOSE DE UBA',33),
	 (3305158,'SAO JOSE DO VALE DO RIO PRETO',33),
	 (3305208,'SAO PEDRO DA ALDEIA',33),
	 (3305307,'SAO SEBASTIAO DO ALTO',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3305406,'SAPUCAIA',33),
	 (3305505,'SAQUAREMA',33),
	 (3305554,'SEROPEDICA',33),
	 (3305604,'SILVA JARDIM',33),
	 (3305703,'SUMIDOURO',33),
	 (3305752,'TANGUA',33),
	 (3305802,'TERESOPOLIS',33),
	 (3305901,'TRAJANO DE MORAIS',33),
	 (3306008,'TRES RIOS',33),
	 (3306107,'VALENCA',33);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3306156,'VARRE-SAI',33),
	 (3306206,'VASSOURAS',33),
	 (3306305,'VOLTA REDONDA',33),
	 (3500105,'ADAMANTINA',35),
	 (3500204,'ADOLFO',35),
	 (3500303,'AGUAI',35),
	 (3500402,'AGUAS DA PRATA',35),
	 (3500501,'AGUAS DE LINDOIA',35),
	 (3500550,'AGUAS DE SANTA BARBARA',35),
	 (3500600,'AGUAS DE SAO PEDRO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3500709,'AGUDOS',35),
	 (3500758,'ALAMBARI',35),
	 (3500808,'ALFREDO MARCONDES',35),
	 (3500907,'ALTAIR',35),
	 (3501004,'ALTINOPOLIS',35),
	 (3501103,'ALTO ALEGRE',35),
	 (3501152,'ALUMINIO',35),
	 (3501202,'ALVARES FLORENCE',35),
	 (3501301,'ALVARES MACHADO',35),
	 (3501400,'ALVARO DE CARVALHO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3501509,'ALVINLANDIA',35),
	 (3501608,'AMERICANA',35),
	 (3501707,'AMERICO BRASILIENSE',35),
	 (3501806,'AMERICO DE CAMPOS',35),
	 (3501905,'AMPARO',35),
	 (3502002,'ANALANDIA',35),
	 (3502101,'ANDRADINA',35),
	 (3502200,'ANGATUBA',35),
	 (3502309,'ANHEMBI',35),
	 (3502408,'ANHUMAS',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3502507,'APARECIDA',35),
	 (3502606,'APARECIDA D OESTE',35),
	 (3502705,'APIAI',35),
	 (3502754,'ARACARIGUAMA',35),
	 (3502804,'ARACATUBA',35),
	 (3502903,'ARACOIABA DA SERRA',35),
	 (3503000,'ARAMINA',35),
	 (3503109,'ARANDU',35),
	 (3503158,'ARAPEI',35),
	 (3503208,'ARARAQUARA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3503307,'ARARAS',35),
	 (3503356,'ARCO-IRIS',35),
	 (3503406,'AREALVA',35),
	 (3503505,'AREIAS',35),
	 (3503604,'AREIOPOLIS',35),
	 (3503703,'ARIRANHA',35),
	 (3503802,'ARTUR NOGUEIRA',35),
	 (3503901,'ARUJA',35),
	 (3503950,'ASPASIA',35),
	 (3504008,'ASSIS',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3504107,'ATIBAIA',35),
	 (3504206,'AURIFLAMA',35),
	 (3504305,'AVAI',35),
	 (3504404,'AVANHANDAVA',35),
	 (3504503,'AVARE',35),
	 (3504602,'BADY BASSITT',35),
	 (3504701,'BALBINOS',35),
	 (3504800,'BALSAMO',35),
	 (3504909,'BANANAL',35),
	 (3505005,'BARAO DE ANTONINA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3505104,'BARBOSA',35),
	 (3505203,'BARIRI',35),
	 (3505302,'BARRA BONITA',35),
	 (3505351,'BARRA DO CHAPEU',35),
	 (3505401,'BARRA DO TURVO',35),
	 (3505500,'BARRETOS',35),
	 (3505609,'BARRINHA',35),
	 (3505708,'BARUERI',35),
	 (3505807,'BASTOS',35),
	 (3505906,'BATATAIS',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3506003,'BAURU',35),
	 (3506102,'BEBEDOURO',35),
	 (3506201,'BENTO DE ABREU',35),
	 (3506300,'BERNARDINO DE CAMPOS',35),
	 (3506359,'BERTIOGA',35),
	 (3506409,'BILAC',35),
	 (3506508,'BIRIGUI',35),
	 (3506607,'BIRITIBA-MIRIM',35),
	 (3506706,'BOA ESPERANCA DO SUL',35),
	 (3506805,'BOCAINA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3506904,'BOFETE',35),
	 (3507001,'BOITUVA',35),
	 (3507100,'BOM JESUS DOS PERDOES',35),
	 (3507159,'BOM SUCESSO DE ITARARE',35),
	 (3507209,'BORA',35),
	 (3507308,'BORACEIA',35),
	 (3507407,'BORBOREMA',35),
	 (3507456,'BOREBI',35),
	 (3507506,'BOTUCATU',35),
	 (3507605,'BRAGANCA PAULISTA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3507704,'BRAUNA',35),
	 (3507753,'BREJO ALEGRE',35),
	 (3507803,'BRODOWSKI',35),
	 (3507902,'BROTAS',35),
	 (3508009,'BURI',35),
	 (3508108,'BURITAMA',35),
	 (3508207,'BURITIZAL',35),
	 (3508306,'CABRALIA PAULISTA',35),
	 (3508405,'CABREUVA',35),
	 (3508504,'CACAPAVA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3508603,'CACHOEIRA PAULISTA',35),
	 (3508702,'CACONDE',35),
	 (3508801,'CAFELANDIA',35),
	 (3508900,'CAIABU',35),
	 (3509007,'CAIEIRAS',35),
	 (3509106,'CAIUA',35),
	 (3509205,'CAJAMAR',35),
	 (3509254,'CAJATI',35),
	 (3509304,'CAJOBI',35),
	 (3509403,'CAJURU',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3509452,'CAMPINA DO MONTE ALEGRE',35),
	 (3509502,'CAMPINAS',35),
	 (3509601,'CAMPO LIMPO PAULISTA',35),
	 (3509700,'CAMPOS DO JORDAO',35),
	 (3509809,'CAMPOS NOVOS PAULISTA',35),
	 (3509908,'CANANEIA',35),
	 (3509957,'CANAS',35),
	 (3510005,'CANDIDO MOTA',35),
	 (3510104,'CANDIDO RODRIGUES',35),
	 (3510153,'CANITAR',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3510203,'CAPAO BONITO',35),
	 (3510302,'CAPELA DO ALTO',35),
	 (3510401,'CAPIVARI',35),
	 (3510500,'CARAGUATATUBA',35),
	 (3510609,'CARAPICUIBA',35),
	 (3510708,'CARDOSO',35),
	 (3510807,'CASA BRANCA',35),
	 (3510906,'CASSIA DOS COQUEIROS',35),
	 (3511003,'CASTILHO',35),
	 (3511102,'CATANDUVA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3511201,'CATIGUA',35),
	 (3511300,'CEDRAL',35),
	 (3511409,'CERQUEIRA CESAR',35),
	 (3511508,'CERQUILHO',35),
	 (3511607,'CESARIO LANGE',35),
	 (3511706,'CHARQUEADA',35),
	 (3511904,'CLEMENTINA',35),
	 (3512001,'COLINA',35),
	 (3512100,'COLOMBIA',35),
	 (3512209,'CONCHAL',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3512308,'CONCHAS',35),
	 (3512407,'CORDEIROPOLIS',35),
	 (3512506,'COROADOS',35),
	 (3512605,'CORONEL MACEDO',35),
	 (3512704,'CORUMBATAI',35),
	 (3512803,'COSMOPOLIS',35),
	 (3512902,'COSMORAMA',35),
	 (3513009,'COTIA',35),
	 (3513108,'CRAVINHOS',35),
	 (3513207,'CRISTAIS PAULISTA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3513306,'CRUZALIA',35),
	 (3513405,'CRUZEIRO',35),
	 (3513504,'CUBATAO',35),
	 (3513603,'CUNHA',35),
	 (3513702,'DESCALVADO',35),
	 (3513801,'DIADEMA',35),
	 (3513850,'DIRCE REIS',35),
	 (3513900,'DIVINOLANDIA',35),
	 (3514007,'DOBRADA',35),
	 (3514106,'DOIS CORREGOS',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3514205,'DOLCINOPOLIS',35),
	 (3514304,'DOURADO',35),
	 (3514403,'DRACENA',35),
	 (3514502,'DUARTINA',35),
	 (3514601,'DUMONT',35),
	 (3514700,'ECHAPORA',35),
	 (3514809,'ELDORADO',35),
	 (3514908,'ELIAS FAUSTO',35),
	 (3514924,'ELISIARIO',35),
	 (3514957,'EMBAUBA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3515004,'EMBU',35),
	 (3515103,'EMBU-GUACU',35),
	 (3515129,'EMILIANOPOLIS',35),
	 (3515152,'ENGENHEIRO COELHO',35),
	 (3515186,'ESPIRITO SANTO DO PINHAL',35),
	 (3515194,'ESPIRITO SANTO DO TURVO',35),
	 (3515202,'ESTRELA D OESTE',35),
	 (3515301,'ESTRELA DO NORTE',35),
	 (3515350,'EUCLIDES DA CUNHA PAULISTA',35),
	 (3515400,'FARTURA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3515509,'FERNANDOPOLIS',35),
	 (3515608,'FERNANDO PRESTES',35),
	 (3515657,'FERNAO',35),
	 (3515707,'FERRAZ DE VASCONCELOS',35),
	 (3515806,'FLORA RICA',35),
	 (3515905,'FLOREAL',35),
	 (3516002,'FLORIDA PAULISTA',35),
	 (3516101,'FLORINIA',35),
	 (3516200,'FRANCA',35),
	 (3516309,'FRANCISCO MORATO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3516408,'FRANCO DA ROCHA',35),
	 (3516507,'GABRIEL MONTEIRO',35),
	 (3516606,'GALIA',35),
	 (3516705,'GARCA',35),
	 (3516804,'GASTAO VIDIGAL',35),
	 (3516853,'GAVIAO PEIXOTO',35),
	 (3516903,'GENERAL SALGADO',35),
	 (3517000,'GETULINA',35),
	 (3517109,'GLICERIO',35),
	 (3517208,'GUAICARA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3517307,'GUAIMBE',35),
	 (3517406,'GUAIRA',35),
	 (3517505,'GUAPIACU',35),
	 (3517604,'GUAPIARA',35),
	 (3517703,'GUARA',35),
	 (3517802,'GUARACAI',35),
	 (3517901,'GUARACI',35),
	 (3518008,'GUARANI D OESTE',35),
	 (3518107,'GUARANTA',35),
	 (3518206,'GUARARAPES',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3518305,'GUARAREMA',35),
	 (3518404,'GUARATINGUETA',35),
	 (3518503,'GUAREI',35),
	 (3518602,'GUARIBA',35),
	 (3518701,'GUARUJA',35),
	 (3518800,'GUARULHOS',35),
	 (3518859,'GUATAPARA',35),
	 (3518909,'GUZOLANDIA',35),
	 (3519006,'HERCULANDIA',35),
	 (3519055,'HOLAMBRA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3519071,'HORTOLANDIA',35),
	 (3519105,'IACANGA',35),
	 (3519204,'IACRI',35),
	 (3519253,'IARAS',35),
	 (3519303,'IBATE',35),
	 (3519402,'IBIRA',35),
	 (3519501,'IBIRAREMA',35),
	 (3519600,'IBITINGA',35),
	 (3519709,'IBIUNA',35),
	 (3519808,'ICEM',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3519907,'IEPE',35),
	 (3520004,'IGARACU DO TIETE',35),
	 (3520103,'IGARAPAVA',35),
	 (3520202,'IGARATA',35),
	 (3520301,'IGUAPE',35),
	 (3520400,'ILHABELA',35),
	 (3520426,'ILHA COMPRIDA',35),
	 (3520442,'ILHA SOLTEIRA',35),
	 (3520509,'INDAIATUBA',35),
	 (3520608,'INDIANA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3520707,'INDIAPORA',35),
	 (3520806,'INUBIA PAULISTA',35),
	 (3520905,'IPAUSSU',35),
	 (3521002,'IPERO',35),
	 (3521101,'IPEUNA',35),
	 (3521150,'IPIGUA',35),
	 (3521200,'IPORANGA',35),
	 (3521309,'IPUA',35),
	 (3521408,'IRACEMAPOLIS',35),
	 (3521507,'IRAPUA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3521606,'IRAPURU',35),
	 (3521705,'ITABERA',35),
	 (3521804,'ITAI',35),
	 (3521903,'ITAJOBI',35),
	 (3522000,'ITAJU',35),
	 (3522109,'ITANHAEM',35),
	 (3522158,'ITAOCA',35),
	 (3522208,'ITAPECERICA DA SERRA',35),
	 (3522307,'ITAPETININGA',35),
	 (3522406,'ITAPEVA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3522505,'ITAPEVI',35),
	 (3522604,'ITAPIRA',35),
	 (3522653,'ITAPIRAPUA PAULISTA',35),
	 (3522703,'ITAPOLIS',35),
	 (3522802,'ITAPORANGA',35),
	 (3522901,'ITAPUI',35),
	 (3523008,'ITAPURA',35),
	 (3523107,'ITAQUAQUECETUBA',35),
	 (3523206,'ITARARE',35),
	 (3523305,'ITARIRI',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3523404,'ITATIBA',35),
	 (3523503,'ITATINGA',35),
	 (3523602,'ITIRAPINA',35),
	 (3523701,'ITIRAPUA',35),
	 (3523800,'ITOBI',35),
	 (3523909,'ITU',35),
	 (3524006,'ITUPEVA',35),
	 (3524105,'ITUVERAVA',35),
	 (3524204,'JABORANDI',35),
	 (3524303,'JABOTICABAL',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3524402,'JACAREI',35),
	 (3524501,'JACI',35),
	 (3524600,'JACUPIRANGA',35),
	 (3524709,'JAGUARIUNA',35),
	 (3524808,'JALES',35),
	 (3524907,'JAMBEIRO',35),
	 (3525003,'JANDIRA',35),
	 (3525102,'JARDINOPOLIS',35),
	 (3525201,'JARINU',35),
	 (3525300,'JAU',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3525409,'JERIQUARA',35),
	 (3525508,'JOANOPOLIS',35),
	 (3525607,'JOAO RAMALHO',35),
	 (3525706,'JOSE BONIFACIO',35),
	 (3525805,'JULIO MESQUITA',35),
	 (3525854,'JUMIRIM',35),
	 (3525904,'JUNDIAI',35),
	 (3526001,'JUNQUEIROPOLIS',35),
	 (3526100,'JUQUIA',35),
	 (3526209,'JUQUITIBA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3526308,'LAGOINHA',35),
	 (3526407,'LARANJAL PAULISTA',35),
	 (3526506,'LAVINIA',35),
	 (3526605,'LAVRINHAS',35),
	 (3526704,'LEME',35),
	 (3526803,'LENCOIS PAULISTA',35),
	 (3526902,'LIMEIRA',35),
	 (3527009,'LINDOIA',35),
	 (3527108,'LINS',35),
	 (3527207,'LORENA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3527256,'LOURDES',35),
	 (3527306,'LOUVEIRA',35),
	 (3527405,'LUCELIA',35),
	 (3527504,'LUCIANOPOLIS',35),
	 (3527603,'LUIS ANTONIO',35),
	 (3527702,'LUIZIANIA',35),
	 (3527801,'LUPERCIO',35),
	 (3527900,'LUTECIA',35),
	 (3528007,'MACATUBA',35),
	 (3528106,'MACAUBAL',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3528205,'MACEDONIA',35),
	 (3528304,'MAGDA',35),
	 (3528403,'MAIRINQUE',35),
	 (3528502,'MAIRIPORA',35),
	 (3528601,'MANDURI',35),
	 (3528700,'MARABA PAULISTA',35),
	 (3528809,'MARACAI',35),
	 (3528858,'MARAPOAMA',35),
	 (3528908,'MARIAPOLIS',35),
	 (3529005,'MARILIA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3529104,'MARINOPOLIS',35),
	 (3529203,'MARTINOPOLIS',35),
	 (3529302,'MATAO',35),
	 (3529401,'MAUA',35),
	 (3529500,'MENDONCA',35),
	 (3529609,'MERIDIANO',35),
	 (3529658,'MESOPOLIS',35),
	 (3529708,'MIGUELOPOLIS',35),
	 (3529807,'MINEIROS DO TIETE',35),
	 (3529906,'MIRACATU',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3530003,'MIRA ESTRELA',35),
	 (3530102,'MIRANDOPOLIS',35),
	 (3530201,'MIRANTE DO PARANAPANEMA',35),
	 (3530300,'MIRASSOL',35),
	 (3530409,'MIRASSOLANDIA',35),
	 (3530508,'MOCOCA',35),
	 (3530607,'MOGI DAS CRUZES',35),
	 (3530706,'MOGI GUACU',35),
	 (3530805,'MOGI MIRIM',35),
	 (3530904,'MOMBUCA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3531001,'MONCOES',35),
	 (3531100,'MONGAGUA',35),
	 (3531209,'MONTE ALEGRE DO SUL',35),
	 (3531308,'MONTE ALTO',35),
	 (3531407,'MONTE APRAZIVEL',35),
	 (3531506,'MONTE AZUL PAULISTA',35),
	 (3531605,'MONTE CASTELO',35),
	 (3531704,'MONTEIRO LOBATO',35),
	 (3531803,'MONTE MOR',35),
	 (3531902,'MORRO AGUDO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3532009,'MORUNGABA',35),
	 (3532058,'MOTUCA',35),
	 (3532108,'MURUTINGA DO SUL',35),
	 (3532157,'NANTES',35),
	 (3532207,'NARANDIBA',35),
	 (3532306,'NATIVIDADE DA SERRA',35),
	 (3532405,'NAZARE PAULISTA',35),
	 (3532504,'NEVES PAULISTA',35),
	 (3532603,'NHANDEARA',35),
	 (3532702,'NIPOA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3532801,'NOVA ALIANCA',35),
	 (3532827,'NOVA CAMPINA',35),
	 (3532843,'NOVA CANAA PAULISTA',35),
	 (3532868,'NOVA CASTILHO',35),
	 (3532900,'NOVA EUROPA',35),
	 (3533007,'NOVA GRANADA',35),
	 (3533106,'NOVA GUATAPORANGA',35),
	 (3533205,'NOVA INDEPENDENCIA',35),
	 (3533254,'NOVAIS',35),
	 (3533304,'NOVA LUZITANIA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3533403,'NOVA ODESSA',35),
	 (3533502,'NOVO HORIZONTE',35),
	 (3533601,'NUPORANGA',35),
	 (3533700,'OCAUCU',35),
	 (3533809,'OLEO',35),
	 (3533908,'OLIMPIA',35),
	 (3534005,'ONDA VERDE',35),
	 (3534104,'ORIENTE',35),
	 (3534203,'ORINDIUVA',35),
	 (3534302,'ORLANDIA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3534401,'OSASCO',35),
	 (3534500,'OSCAR BRESSANE',35),
	 (3534609,'OSVALDO CRUZ',35),
	 (3534708,'OURINHOS',35),
	 (3534757,'OUROESTE',35),
	 (3534807,'OURO VERDE',35),
	 (3534906,'PACAEMBU',35),
	 (3535002,'PALESTINA',35),
	 (3535101,'PALMARES PAULISTA',35),
	 (3535200,'PALMEIRA D OESTE',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3535309,'PALMITAL',35),
	 (3535408,'PANORAMA',35),
	 (3535507,'PARAGUACU PAULISTA',35),
	 (3535606,'PARAIBUNA',35),
	 (3535705,'PARAISO',35),
	 (3535804,'PARANAPANEMA',35),
	 (3535903,'PARANAPUA',35),
	 (3536000,'PARAPUA',35),
	 (3536109,'PARDINHO',35),
	 (3536208,'PARIQUERA-ACU',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3536257,'PARISI',35),
	 (3536307,'PATROCINIO PAULISTA',35),
	 (3536406,'PAULICEIA',35),
	 (3536505,'PAULINIA',35),
	 (3536570,'PAULISTANIA',35),
	 (3536604,'PAULO DE FARIA',35),
	 (3536703,'PEDERNEIRAS',35),
	 (3536802,'PEDRA BELA',35),
	 (3536901,'PEDRANOPOLIS',35),
	 (3537008,'PEDREGULHO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3537107,'PEDREIRA',35),
	 (3537156,'PEDRINHAS PAULISTA',35),
	 (3537206,'PEDRO DE TOLEDO',35),
	 (3537305,'PENAPOLIS',35),
	 (3537404,'PEREIRA BARRETO',35),
	 (3537503,'PEREIRAS',35),
	 (3537602,'PERUIBE',35),
	 (3537701,'PIACATU',35),
	 (3537800,'PIEDADE',35),
	 (3537909,'PILAR DO SUL',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3538006,'PINDAMONHANGABA',35),
	 (3538105,'PINDORAMA',35),
	 (3538204,'PINHALZINHO',35),
	 (3538303,'PIQUEROBI',35),
	 (3538501,'PIQUETE',35),
	 (3538600,'PIRACAIA',35),
	 (3538709,'PIRACICABA',35),
	 (3538808,'PIRAJU',35),
	 (3538907,'PIRAJUI',35),
	 (3539004,'PIRANGI',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3539103,'PIRAPORA DO BOM JESUS',35),
	 (3539202,'PIRAPOZINHO',35),
	 (3539301,'PIRASSUNUNGA',35),
	 (3539400,'PIRATININGA',35),
	 (3539509,'PITANGUEIRAS',35),
	 (3539608,'PLANALTO',35),
	 (3539707,'PLATINA',35),
	 (3539806,'POA',35),
	 (3539905,'POLONI',35),
	 (3540002,'POMPEIA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3540101,'PONGAI',35),
	 (3540200,'PONTAL',35),
	 (3540259,'PONTALINDA',35),
	 (3540309,'PONTES GESTAL',35),
	 (3540408,'POPULINA',35),
	 (3540507,'PORANGABA',35),
	 (3540606,'PORTO FELIZ',35),
	 (3540705,'PORTO FERREIRA',35),
	 (3540754,'POTIM',35),
	 (3540804,'POTIRENDABA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3540853,'PRACINHA',35),
	 (3540903,'PRADOPOLIS',35),
	 (3541000,'PRAIA GRANDE',35),
	 (3541059,'PRATANIA',35),
	 (3541109,'PRESIDENTE ALVES',35),
	 (3541208,'PRESIDENTE BERNARDES',35),
	 (3541307,'PRESIDENTE EPITACIO',35),
	 (3541406,'PRESIDENTE PRUDENTE',35),
	 (3541505,'PRESIDENTE VENCESLAU',35),
	 (3541604,'PROMISSAO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3541653,'QUADRA',35),
	 (3541703,'QUATA',35),
	 (3541802,'QUEIROZ',35),
	 (3541901,'QUELUZ',35),
	 (3542008,'QUINTANA',35),
	 (3542107,'RAFARD',35),
	 (3542206,'RANCHARIA',35),
	 (3542305,'REDENCAO DA SERRA',35),
	 (3542404,'REGENTE FEIJO',35),
	 (3542503,'REGINOPOLIS',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3542602,'REGISTRO',35),
	 (3542701,'RESTINGA',35),
	 (3542800,'RIBEIRA',35),
	 (3542909,'RIBEIRAO BONITO',35),
	 (3543006,'RIBEIRAO BRANCO',35),
	 (3543105,'RIBEIRAO CORRENTE',35),
	 (3543204,'RIBEIRAO DO SUL',35),
	 (3543238,'RIBEIRAO DOS INDIOS',35),
	 (3543253,'RIBEIRAO GRANDE',35),
	 (3543303,'RIBEIRAO PIRES',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3543402,'RIBEIRAO PRETO',35),
	 (3543501,'RIVERSUL',35),
	 (3543600,'RIFAINA',35),
	 (3543709,'RINCAO',35),
	 (3543808,'RINOPOLIS',35),
	 (3543907,'RIO CLARO',35),
	 (3544004,'RIO DAS PEDRAS',35),
	 (3544103,'RIO GRANDE DA SERRA',35),
	 (3544202,'RIOLANDIA',35),
	 (3544251,'ROSANA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3544301,'ROSEIRA',35),
	 (3544400,'RUBIACEA',35),
	 (3544509,'RUBINEIA',35),
	 (3544608,'SABINO',35),
	 (3544707,'SAGRES',35),
	 (3544806,'SALES',35),
	 (3544905,'SALES OLIVEIRA',35),
	 (3545001,'SALESOPOLIS',35),
	 (3545100,'SALMOURAO',35),
	 (3545159,'SALTINHO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3545209,'SALTO',35),
	 (3545308,'SALTO DE PIRAPORA',35),
	 (3545407,'SALTO GRANDE',35),
	 (3545506,'SANDOVALINA',35),
	 (3545605,'SANTA ADELIA',35),
	 (3545704,'SANTA ALBERTINA',35),
	 (3545803,'SANTA BARBARA D OESTE',35),
	 (3546009,'SANTA BRANCA',35),
	 (3546108,'SANTA CLARA D OESTE',35),
	 (3546207,'SANTA CRUZ DA CONCEICAO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3546256,'SANTA CRUZ DA ESPERANCA',35),
	 (3546306,'SANTA CRUZ DAS PALMEIRAS',35),
	 (3546405,'SANTA CRUZ DO RIO PARDO',35),
	 (3546504,'SANTA ERNESTINA',35),
	 (3546603,'SANTA FE DO SUL',35),
	 (3546702,'SANTA GERTRUDES',35),
	 (3546801,'SANTA ISABEL',35),
	 (3546900,'SANTA LUCIA',35),
	 (3547007,'SANTA MARIA DA SERRA',35),
	 (3547106,'SANTA MERCEDES',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3547205,'SANTANA DA PONTE PENSA',35),
	 (3547304,'SANTANA DE PARNAIBA',35),
	 (3547403,'SANTA RITA D OESTE',35),
	 (3547502,'SANTA RITA DO PASSA QUATRO',35),
	 (3547601,'SANTA ROSA DE VITERBO',35),
	 (3547650,'SANTA SALETE',35),
	 (3547700,'SANTO ANASTACIO',35),
	 (3547809,'SANTO ANDRE',35),
	 (3547908,'SANTO ANTONIO DA ALEGRIA',35),
	 (3548005,'SANTO ANTONIO DE POSSE',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3548054,'SANTO ANTONIO DO ARACANGUA',35),
	 (3548104,'SANTO ANTONIO DO JARDIM',35),
	 (3548203,'SANTO ANTONIO DO PINHAL',35),
	 (3548302,'SANTO EXPEDITO',35),
	 (3548401,'SANTOPOLIS DO AGUAPEI',35),
	 (3548500,'SANTOS',35),
	 (3548609,'SAO BENTO DO SAPUCAI',35),
	 (3548708,'SAO BERNARDO DO CAMPO',35),
	 (3548807,'SAO CAETANO DO SUL',35),
	 (3548906,'SAO CARLOS',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3549003,'SAO FRANCISCO',35),
	 (3549102,'SAO JOAO DA BOA VISTA',35),
	 (3549201,'SAO JOAO DAS DUAS PONTES',35),
	 (3549250,'SAO JOAO DE IRACEMA',35),
	 (3549300,'SAO JOAO DO PAU D ALHO',35),
	 (3549409,'SAO JOAQUIM DA BARRA',35),
	 (3549508,'SAO JOSE DA BELA VISTA',35),
	 (3549607,'SAO JOSE DO BARREIRO',35),
	 (3549706,'SAO JOSE DO RIO PARDO',35),
	 (3549805,'SAO JOSE DO RIO PRETO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3549904,'SAO JOSE DOS CAMPOS',35),
	 (3549953,'SAO LOURENCO DA SERRA',35),
	 (3550001,'SAO LUIS DO PARAITINGA',35),
	 (3550100,'SAO MANUEL',35),
	 (3550209,'SAO MIGUEL ARCANJO',35),
	 (3550308,'SAO PAULO',35),
	 (3550407,'SAO PEDRO',35),
	 (3550506,'SAO PEDRO DO TURVO',35),
	 (3550605,'SAO ROQUE',35),
	 (3550704,'SAO SEBASTIAO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3550803,'SAO SEBASTIAO DA GRAMA',35),
	 (3550902,'SAO SIMAO',35),
	 (3551009,'SAO VICENTE',35),
	 (3551108,'SARAPUI',35),
	 (3551207,'SARUTAIA',35),
	 (3551306,'SEBASTIANOPOLIS DO SUL',35),
	 (3551405,'SERRA AZUL',35),
	 (3551504,'SERRANA',35),
	 (3551603,'SERRA NEGRA',35),
	 (3551702,'SERTAOZINHO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3551801,'SETE BARRAS',35),
	 (3551900,'SEVERINIA',35),
	 (3552007,'SILVEIRAS',35),
	 (3552106,'SOCORRO',35),
	 (3552205,'SOROCABA',35),
	 (3552304,'SUD MENNUCCI',35),
	 (3552403,'SUMARE',35),
	 (3552502,'SUZANO',35),
	 (3552551,'SUZANAPOLIS',35),
	 (3552601,'TABAPUA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3552700,'TABATINGA',35),
	 (3552809,'TABOAO DA SERRA',35),
	 (3552908,'TACIBA',35),
	 (3553005,'TAGUAI',35),
	 (3553104,'TAIACU',35),
	 (3553203,'TAIUVA',35),
	 (3553302,'TAMBAU',35),
	 (3553401,'TANABI',35),
	 (3553500,'TAPIRAI',35),
	 (3553609,'TAPIRATIBA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3553658,'TAQUARAL',35),
	 (3553708,'TAQUARITINGA',35),
	 (3553807,'TAQUARITUBA',35),
	 (3553856,'TAQUARIVAI',35),
	 (3553906,'TARABAI',35),
	 (3553955,'TARUMA',35),
	 (3554003,'TATUI',35),
	 (3554102,'TAUBATE',35),
	 (3554201,'TEJUPA',35),
	 (3554300,'TEODORO SAMPAIO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3554409,'TERRA ROXA',35),
	 (3554508,'TIETE',35),
	 (3554607,'TIMBURI',35),
	 (3554656,'TORRE DE PEDRA',35),
	 (3554706,'TORRINHA',35),
	 (3554755,'TRABIJU',35),
	 (3554805,'TREMEMBE',35),
	 (3554904,'TRES FRONTEIRAS',35),
	 (3554953,'TUIUTI',35),
	 (3555000,'TUPA',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3555109,'TUPI PAULISTA',35),
	 (3555208,'TURIUBA',35),
	 (3555307,'TURMALINA',35),
	 (3555356,'UBARANA',35),
	 (3555406,'UBATUBA',35),
	 (3555505,'UBIRAJARA',35),
	 (3555604,'UCHOA',35),
	 (3555703,'UNIAO PAULISTA',35),
	 (3555802,'URANIA',35),
	 (3555901,'URU',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3556008,'URUPES',35),
	 (3556107,'VALENTIM GENTIL',35),
	 (3556206,'VALINHOS',35),
	 (3556305,'VALPARAISO',35),
	 (3556354,'VARGEM',35),
	 (3556404,'VARGEM GRANDE DO SUL',35),
	 (3556453,'VARGEM GRANDE PAULISTA',35),
	 (3556503,'VARZEA PAULISTA',35),
	 (3556602,'VERA CRUZ',35),
	 (3556701,'VINHEDO',35);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (3556800,'VIRADOURO',35),
	 (3556909,'VISTA ALEGRE DO ALTO',35),
	 (3556958,'VITORIA BRASIL',35),
	 (3557006,'VOTORANTIM',35),
	 (3557105,'VOTUPORANGA',35),
	 (3557154,'ZACARIAS',35),
	 (3557204,'CHAVANTES',35),
	 (3557303,'ESTIVA GERBI',35),
	 (4100103,'ABATIA',41),
	 (4100202,'ADRIANOPOLIS',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4100301,'AGUDOS DO SUL',41),
	 (4100400,'ALMIRANTE TAMANDARE',41),
	 (4100459,'ALTAMIRA DO PARANA',41),
	 (4100509,'ALTONIA',41),
	 (4100608,'ALTO PARANA',41),
	 (4100707,'ALTO PIQUIRI',41),
	 (4100806,'ALVORADA DO SUL',41),
	 (4100905,'AMAPORA',41),
	 (4101002,'AMPERE',41),
	 (4101051,'ANAHY',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4101101,'ANDIRA',41),
	 (4101150,'ANGULO',41),
	 (4101200,'ANTONINA',41),
	 (4101309,'ANTONIO OLINTO',41),
	 (4101408,'APUCARANA',41),
	 (4101507,'ARAPONGAS',41),
	 (4101606,'ARAPOTI',41),
	 (4101655,'ARAPUA',41),
	 (4101705,'ARARUNA',41),
	 (4101804,'ARAUCARIA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4101853,'ARIRANHA DO IVAI',41),
	 (4101903,'ASSAI',41),
	 (4102000,'ASSIS CHATEAUBRIAND',41),
	 (4102109,'ASTORGA',41),
	 (4102208,'ATALAIA',41),
	 (4102307,'BALSA NOVA',41),
	 (4102505,'BARBOSA FERRAZ',41),
	 (4102604,'BARRACAO',41),
	 (4102703,'BARRA DO JACARE',41),
	 (4102752,'BELA VISTA DA CAROBA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4102802,'BELA VISTA DO PARAISO',41),
	 (4102901,'BITURUNA',41),
	 (4103008,'BOA ESPERANCA',41),
	 (4103024,'BOA ESPERANCA DO IGUACU',41),
	 (4103040,'BOA VENTURA DE SAO ROQUE',41),
	 (4103057,'BOA VISTA DA APARECIDA',41),
	 (4103107,'BOCAIUVA DO SUL',41),
	 (4103156,'BOM JESUS DO SUL',41),
	 (4103206,'BOM SUCESSO',41),
	 (4103222,'BOM SUCESSO DO SUL',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4103305,'BORRAZOPOLIS',41),
	 (4103354,'BRAGANEY',41),
	 (4103370,'BRASILANDIA DO SUL',41),
	 (4103404,'CAFEARA',41),
	 (4103453,'CAFELANDIA',41),
	 (4103479,'CAFEZAL DO SUL',41),
	 (4103503,'CALIFORNIA',41),
	 (4103602,'CAMBARA',41),
	 (4103701,'CAMBE',41),
	 (4103800,'CAMBIRA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4103909,'CAMPINA DA LAGOA',41),
	 (4103958,'CAMPINA DO SIMAO',41),
	 (4104006,'CAMPINA GRANDE DO SUL',41),
	 (4104055,'CAMPO BONITO',41),
	 (4104105,'CAMPO DO TENENTE',41),
	 (4104204,'CAMPO LARGO',41),
	 (4104253,'CAMPO MAGRO',41),
	 (4104303,'CAMPO MOURAO',41),
	 (4104402,'CANDIDO DE ABREU',41),
	 (4104428,'CANDOI',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4104451,'CANTAGALO',41),
	 (4104501,'CAPANEMA',41),
	 (4104600,'CAPITAO LEONIDAS MARQUES',41),
	 (4104659,'CARAMBEI',41),
	 (4104709,'CARLOPOLIS',41),
	 (4104808,'CASCAVEL',41),
	 (4104907,'CASTRO',41),
	 (4105003,'CATANDUVAS',41),
	 (4105102,'CENTENARIO DO SUL',41),
	 (4105201,'CERRO AZUL',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4105300,'CEU AZUL',41),
	 (4105409,'CHOPINZINHO',41),
	 (4105508,'CIANORTE',41),
	 (4105607,'CIDADE GAUCHA',41),
	 (4105706,'CLEVELANDIA',41),
	 (4105805,'COLOMBO',41),
	 (4105904,'COLORADO',41),
	 (4106001,'CONGONHINHAS',41),
	 (4106100,'CONSELHEIRO MAIRINCK',41),
	 (4106209,'CONTENDA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4106308,'CORBELIA',41),
	 (4106407,'CORNELIO PROCOPIO',41),
	 (4106456,'CORONEL DOMINGOS SOARES',41),
	 (4106506,'CORONEL VIVIDA',41),
	 (4106555,'CORUMBATAI DO SUL',41),
	 (4106571,'CRUZEIRO DO IGUACU',41),
	 (4106605,'CRUZEIRO DO OESTE',41),
	 (4106704,'CRUZEIRO DO SUL',41),
	 (4106803,'CRUZ MACHADO',41),
	 (4106852,'CRUZMALTINA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4106902,'CURITIBA',41),
	 (4107009,'CURIUVA',41),
	 (4107108,'DIAMANTE DO NORTE',41),
	 (4107124,'DIAMANTE DO SUL',41),
	 (4107157,'DIAMANTE D OESTE',41),
	 (4107207,'DOIS VIZINHOS',41),
	 (4107256,'DOURADINA',41),
	 (4107306,'DOUTOR CAMARGO',41),
	 (4107405,'ENEAS MARQUES',41),
	 (4107504,'ENGENHEIRO BELTRAO',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4107520,'ESPERANCA NOVA',41),
	 (4107538,'ENTRE RIOS DO OESTE',41),
	 (4107546,'ESPIGAO ALTO DO IGUACU',41),
	 (4107553,'FAROL',41),
	 (4107603,'FAXINAL',41),
	 (4107652,'FAZENDA RIO GRANDE',41),
	 (4107702,'FENIX',41),
	 (4107736,'FERNANDES PINHEIRO',41),
	 (4107751,'FIGUEIRA',41),
	 (4107801,'FLORAI',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4107850,'FLOR DA SERRA DO SUL',41),
	 (4107900,'FLORESTA',41),
	 (4108007,'FLORESTOPOLIS',41),
	 (4108106,'FLORIDA',41),
	 (4108205,'FORMOSA DO OESTE',41),
	 (4108304,'FOZ DO IGUACU',41),
	 (4108320,'FRANCISCO ALVES',41),
	 (4108403,'FRANCISCO BELTRAO',41),
	 (4108452,'FOZ DO JORDAO',41),
	 (4108502,'GENERAL CARNEIRO',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4108551,'GODOY MOREIRA',41),
	 (4108601,'GOIOERE',41),
	 (4108650,'GOIOXIM',41),
	 (4108700,'GRANDES RIOS',41),
	 (4108809,'GUAIRA',41),
	 (4108908,'GUAIRACA',41),
	 (4108957,'GUAMIRANGA',41),
	 (4109005,'GUAPIRAMA',41),
	 (4109104,'GUAPOREMA',41),
	 (4109203,'GUARACI',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4109302,'GUARANIACU',41),
	 (4109401,'GUARAPUAVA',41),
	 (4109500,'GUARAQUECABA',41),
	 (4109609,'GUARATUBA',41),
	 (4109658,'HONORIO SERPA',41),
	 (4109708,'IBAITI',41),
	 (4109757,'IBEMA',41),
	 (4109807,'IBIPORA',41),
	 (4109906,'ICARAIMA',41),
	 (4110003,'IGUARACU',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4110052,'IGUATU',41),
	 (4110078,'IMBAU',41),
	 (4110102,'IMBITUVA',41),
	 (4110201,'INACIO MARTINS',41),
	 (4110300,'INAJA',41),
	 (4110409,'INDIANOPOLIS',41),
	 (4110508,'IPIRANGA',41),
	 (4110607,'IPORA',41),
	 (4110656,'IRACEMA DO OESTE',41),
	 (4110706,'IRATI',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4110805,'IRETAMA',41),
	 (4110904,'ITAGUAJE',41),
	 (4110953,'ITAIPULANDIA',41),
	 (4111001,'ITAMBARACA',41),
	 (4111100,'ITAMBE',41),
	 (4111209,'ITAPEJARA D OESTE',41),
	 (4111258,'ITAPERUCU',41),
	 (4111308,'ITAUNA DO SUL',41),
	 (4111407,'IVAI',41),
	 (4111506,'IVAIPORA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4111555,'IVATE',41),
	 (4111605,'IVATUBA',41),
	 (4111704,'JABOTI',41),
	 (4111803,'JACAREZINHO',41),
	 (4111902,'JAGUAPITA',41),
	 (4112009,'JAGUARIAIVA',41),
	 (4112108,'JANDAIA DO SUL',41),
	 (4112207,'JANIOPOLIS',41),
	 (4112306,'JAPIRA',41),
	 (4112405,'JAPURA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4112504,'JARDIM ALEGRE',41),
	 (4112603,'JARDIM OLINDA',41),
	 (4112702,'JATAIZINHO',41),
	 (4112751,'JESUITAS',41),
	 (4112801,'JOAQUIM TAVORA',41),
	 (4112900,'JUNDIAI DO SUL',41),
	 (4112959,'JURANDA',41),
	 (4113007,'JUSSARA',41),
	 (4113106,'KALORE',41),
	 (4113205,'LAPA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4113254,'LARANJAL',41),
	 (4113304,'LARANJEIRAS DO SUL',41),
	 (4113403,'LEOPOLIS',41),
	 (4113429,'LIDIANOPOLIS',41),
	 (4113452,'LINDOESTE',41),
	 (4113502,'LOANDA',41),
	 (4113601,'LOBATO',41),
	 (4113700,'LONDRINA',41),
	 (4113734,'LUIZIANA',41),
	 (4113759,'LUNARDELLI',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4113809,'LUPIONOPOLIS',41),
	 (4113908,'MALLET',41),
	 (4114005,'MAMBORE',41),
	 (4114104,'MANDAGUACU',41),
	 (4114203,'MANDAGUARI',41),
	 (4114302,'MANDIRITUBA',41),
	 (4114351,'MANFRINOPOLIS',41),
	 (4114401,'MANGUEIRINHA',41),
	 (4114500,'MANOEL RIBAS',41),
	 (4114609,'MARECHAL CANDIDO RONDON',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4114708,'MARIA HELENA',41),
	 (4114807,'MARIALVA',41),
	 (4114906,'MARILANDIA DO SUL',41),
	 (4115002,'MARILENA',41),
	 (4115101,'MARILUZ',41),
	 (4115200,'MARINGA',41),
	 (4115309,'MARIOPOLIS',41),
	 (4115358,'MARIPA',41),
	 (4115408,'MARMELEIRO',41),
	 (4115457,'MARQUINHO',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4115507,'MARUMBI',41),
	 (4115606,'MATELANDIA',41),
	 (4115705,'MATINHOS',41),
	 (4115739,'MATO RICO',41),
	 (4115754,'MAUA DA SERRA',41),
	 (4115804,'MEDIANEIRA',41),
	 (4115853,'MERCEDES',41),
	 (4115903,'MIRADOR',41),
	 (4116000,'MIRASELVA',41),
	 (4116059,'MISSAL',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4116109,'MOREIRA SALES',41),
	 (4116208,'MORRETES',41),
	 (4116307,'MUNHOZ DE MELO',41),
	 (4116406,'NOSSA SENHORA DAS GRACAS',41),
	 (4116505,'NOVA ALIANCA DO IVAI',41),
	 (4116604,'NOVA AMERICA DA COLINA',41),
	 (4116703,'NOVA AURORA',41),
	 (4116802,'NOVA CANTU',41),
	 (4116901,'NOVA ESPERANCA',41),
	 (4116950,'NOVA ESPERANCA DO SUDOESTE',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4117008,'NOVA FATIMA',41),
	 (4117057,'NOVA LARANJEIRAS',41),
	 (4117107,'NOVA LONDRINA',41),
	 (4117206,'NOVA OLIMPIA',41),
	 (4117214,'NOVA SANTA BARBARA',41),
	 (4117222,'NOVA SANTA ROSA',41),
	 (4117255,'NOVA PRATA DO IGUACU',41),
	 (4117271,'NOVA TEBAS',41),
	 (4117297,'NOVO ITACOLOMI',41),
	 (4117305,'ORTIGUEIRA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4117404,'OURIZONA',41),
	 (4117453,'OURO VERDE DO OESTE',41),
	 (4117503,'PAICANDU',41),
	 (4117602,'PALMAS',41),
	 (4117701,'PALMEIRA',41),
	 (4117800,'PALMITAL',41),
	 (4117909,'PALOTINA',41),
	 (4118006,'PARAISO DO NORTE',41),
	 (4118105,'PARANACITY',41),
	 (4118204,'PARANAGUA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4118303,'PARANAPOEMA',41),
	 (4118402,'PARANAVAI',41),
	 (4118451,'PATO BRAGADO',41),
	 (4118501,'PATO BRANCO',41),
	 (4118600,'PAULA FREITAS',41),
	 (4118709,'PAULO FRONTIN',41),
	 (4118808,'PEABIRU',41),
	 (4118857,'PEROBAL',41),
	 (4118907,'PEROLA',41),
	 (4119004,'PEROLA D OESTE',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4119103,'PIEN',41),
	 (4119152,'PINHAIS',41),
	 (4119202,'PINHALAO',41),
	 (4119251,'PINHAL DE SAO BENTO',41),
	 (4119301,'PINHAO',41),
	 (4119400,'PIRAI DO SUL',41),
	 (4119509,'PIRAQUARA',41),
	 (4119608,'PITANGA',41),
	 (4119657,'PITANGUEIRAS',41),
	 (4119707,'PLANALTINA DO PARANA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4119806,'PLANALTO',41),
	 (4119905,'PONTA GROSSA',41),
	 (4119954,'PONTAL DO PARANA',41),
	 (4120002,'PORECATU',41),
	 (4120101,'PORTO AMAZONAS',41),
	 (4120150,'PORTO BARREIRO',41),
	 (4120200,'PORTO RICO',41),
	 (4120309,'PORTO VITORIA',41),
	 (4120333,'PRADO FERREIRA',41),
	 (4120358,'PRANCHITA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4120408,'PRESIDENTE CASTELO BRANCO',41),
	 (4120507,'PRIMEIRO DE MAIO',41),
	 (4120606,'PRUDENTOPOLIS',41),
	 (4120655,'QUARTO CENTENARIO',41),
	 (4120705,'QUATIGUA',41),
	 (4120804,'QUATRO BARRAS',41),
	 (4120853,'QUATRO PONTES',41),
	 (4120903,'QUEDAS DO IGUACU',41),
	 (4121000,'QUERENCIA DO NORTE',41),
	 (4121109,'QUINTA DO SOL',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4121208,'QUITANDINHA',41),
	 (4121257,'RAMILANDIA',41),
	 (4121307,'RANCHO ALEGRE',41),
	 (4121356,'RANCHO ALEGRE D OESTE',41),
	 (4121406,'REALEZA',41),
	 (4121505,'REBOUCAS',41),
	 (4121604,'RENASCENCA',41),
	 (4121703,'RESERVA',41),
	 (4121752,'RESERVA DO IGUACU',41),
	 (4121802,'RIBEIRAO CLARO',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4121901,'RIBEIRAO DO PINHAL',41),
	 (4122008,'RIO AZUL',41),
	 (4122107,'RIO BOM',41),
	 (4122156,'RIO BONITO DO IGUACU',41),
	 (4122172,'RIO BRANCO DO IVAI',41),
	 (4122206,'RIO BRANCO DO SUL',41),
	 (4122305,'RIO NEGRO',41),
	 (4122404,'ROLANDIA',41),
	 (4122503,'RONCADOR',41),
	 (4122602,'RONDON',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4122651,'ROSARIO DO IVAI',41),
	 (4122701,'SABAUDIA',41),
	 (4122800,'SALGADO FILHO',41),
	 (4122909,'SALTO DO ITARARE',41),
	 (4123006,'SALTO DO LONTRA',41),
	 (4123105,'SANTA AMELIA',41),
	 (4123204,'SANTA CECILIA DO PAVAO',41),
	 (4123303,'SANTA CRUZ DE MONTE CASTELO',41),
	 (4123402,'SANTA FE',41),
	 (4123501,'SANTA HELENA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4123600,'SANTA INES',41),
	 (4123709,'SANTA ISABEL DO IVAI',41),
	 (4123808,'SANTA IZABEL DO OESTE',41),
	 (4123824,'SANTA LUCIA',41),
	 (4123857,'SANTA MARIA DO OESTE',41),
	 (4123907,'SANTA MARIANA',41),
	 (4123956,'SANTA MONICA',41),
	 (4124004,'SANTANA DO ITARARE',41),
	 (4124020,'SANTA TEREZA DO OESTE',41),
	 (4124053,'SANTA TEREZINHA DE ITAIPU',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4124103,'SANTO ANTONIO DA PLATINA',41),
	 (4124202,'SANTO ANTONIO DO CAIUA',41),
	 (4124301,'SANTO ANTONIO DO PARAISO',41),
	 (4124400,'SANTO ANTONIO DO SUDOESTE',41),
	 (4124509,'SANTO INACIO',41),
	 (4124608,'SAO CARLOS DO IVAI',41),
	 (4124707,'SAO JERONIMO DA SERRA',41),
	 (4124806,'SAO JOAO',41),
	 (4124905,'SAO JOAO DO CAIUA',41),
	 (4125001,'SAO JOAO DO IVAI',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4125100,'SAO JOAO DO TRIUNFO',41),
	 (4125209,'SAO JORGE D OESTE',41),
	 (4125308,'SAO JORGE DO IVAI',41),
	 (4125357,'SAO JORGE DO PATROCINIO',41),
	 (4125407,'SAO JOSE DA BOA VISTA',41),
	 (4125456,'SAO JOSE DAS PALMEIRAS',41),
	 (4125506,'SAO JOSE DOS PINHAIS',41),
	 (4125555,'SAO MANOEL DO PARANA',41),
	 (4125605,'SAO MATEUS DO SUL',41),
	 (4125704,'SAO MIGUEL DO IGUACU',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4125753,'SAO PEDRO DO IGUACU',41),
	 (4125803,'SAO PEDRO DO IVAI',41),
	 (4125902,'SAO PEDRO DO PARANA',41),
	 (4126009,'SAO SEBASTIAO DA AMOREIRA',41),
	 (4126108,'SAO TOME',41),
	 (4126207,'SAPOPEMA',41),
	 (4126256,'SARANDI',41),
	 (4126272,'SAUDADE DO IGUACU',41),
	 (4126306,'SENGES',41),
	 (4126355,'SERRANOPOLIS DO IGUACU',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4126405,'SERTANEJA',41),
	 (4126504,'SERTANOPOLIS',41),
	 (4126603,'SIQUEIRA CAMPOS',41),
	 (4126652,'SULINA',41),
	 (4126678,'TAMARANA',41),
	 (4126702,'TAMBOARA',41),
	 (4126801,'TAPEJARA',41),
	 (4126900,'TAPIRA',41),
	 (4127007,'TEIXEIRA SOARES',41),
	 (4127106,'TELEMACO BORBA',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4127205,'TERRA BOA',41),
	 (4127304,'TERRA RICA',41),
	 (4127403,'TERRA ROXA',41),
	 (4127502,'TIBAGI',41),
	 (4127601,'TIJUCAS DO SUL',41),
	 (4127700,'TOLEDO',41),
	 (4127809,'TOMAZINA',41),
	 (4127858,'TRES BARRAS DO PARANA',41),
	 (4127882,'TUNAS DO PARANA',41),
	 (4127908,'TUNEIRAS DO OESTE',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4127957,'TUPASSI',41),
	 (4127965,'TURVO',41),
	 (4128005,'UBIRATA',41),
	 (4128104,'UMUARAMA',41),
	 (4128203,'UNIAO DA VITORIA',41),
	 (4128302,'UNIFLOR',41),
	 (4128401,'URAI',41),
	 (4128500,'WENCESLAU BRAZ',41),
	 (4128534,'VENTANIA',41),
	 (4128559,'VERA CRUZ DO OESTE',41);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4128609,'VERE',41),
	 (4128625,'ALTO PARAISO',41),
	 (4128633,'DOUTOR ULYSSES',41),
	 (4128658,'VIRMOND',41),
	 (4128708,'VITORINO',41),
	 (4128807,'XAMBRE',41),
	 (4200051,'ABDON BATISTA',42),
	 (4200101,'ABELARDO LUZ',42),
	 (4200200,'AGROLANDIA',42),
	 (4200309,'AGRONOMICA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4200408,'AGUA DOCE',42),
	 (4200507,'AGUAS DE CHAPECO',42),
	 (4200556,'AGUAS FRIAS',42),
	 (4200606,'AGUAS MORNAS',42),
	 (4200705,'ALFREDO WAGNER',42),
	 (4200754,'ALTO BELA VISTA',42),
	 (4200804,'ANCHIETA',42),
	 (4200903,'ANGELINA',42),
	 (4201000,'ANITA GARIBALDI',42),
	 (4201109,'ANITAPOLIS',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4201208,'ANTONIO CARLOS',42),
	 (4201257,'APIUNA',42),
	 (4201273,'ARABUTA',42),
	 (4201307,'ARAQUARI',42),
	 (4201406,'ARARANGUA',42),
	 (4201505,'ARMAZEM',42),
	 (4201604,'ARROIO TRINTA',42),
	 (4201653,'ARVOREDO',42),
	 (4201703,'ASCURRA',42),
	 (4201802,'ATALANTA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4201901,'AURORA',42),
	 (4201950,'BALNEARIO ARROIO DO SILVA',42),
	 (4202008,'BALNEARIO CAMBORIU',42),
	 (4202057,'BALNEARIO BARRA DO SUL',42),
	 (4202073,'BALNEARIO GAIVOTA',42),
	 (4202099,'BARRA BONITA',42),
	 (4202107,'BARRA VELHA',42),
	 (4202131,'BELA VISTA DO TOLDO',42),
	 (4202156,'BELMONTE',42),
	 (4202206,'BENEDITO NOVO',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4202305,'BIGUACU',42),
	 (4202404,'BLUMENAU',42),
	 (4202438,'BOCAINA DO SUL',42),
	 (4202453,'BOMBINHAS',42),
	 (4202503,'BOM JARDIM DA SERRA',42),
	 (4202537,'BOM JESUS',42),
	 (4202578,'BOM JESUS DO OESTE',42),
	 (4202602,'BOM RETIRO',42),
	 (4202701,'BOTUVERA',42),
	 (4202800,'BRACO DO NORTE',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4202859,'BRACO DO TROMBUDO',42),
	 (4202875,'BRUNOPOLIS',42),
	 (4202909,'BRUSQUE',42),
	 (4203006,'CACADOR',42),
	 (4203105,'CAIBI',42),
	 (4203154,'CALMON',42),
	 (4203204,'CAMBORIU',42),
	 (4203253,'CAPAO ALTO',42),
	 (4203303,'CAMPO ALEGRE',42),
	 (4203402,'CAMPO BELO DO SUL',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4203501,'CAMPO ERE',42),
	 (4203600,'CAMPOS NOVOS',42),
	 (4203709,'CANELINHA',42),
	 (4203808,'CANOINHAS',42),
	 (4203907,'CAPINZAL',42),
	 (4203956,'CAPIVARI DE BAIXO',42),
	 (4204004,'CATANDUVAS',42),
	 (4204103,'CAXAMBU DO SUL',42),
	 (4204152,'CELSO RAMOS',42),
	 (4204178,'CERRO NEGRO',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4204194,'CHAPADAO DO LAGEADO',42),
	 (4204202,'CHAPECO',42),
	 (4204251,'COCAL DO SUL',42),
	 (4204301,'CONCORDIA',42),
	 (4204350,'CORDILHEIRA ALTA',42),
	 (4204400,'CORONEL FREITAS',42),
	 (4204459,'CORONEL MARTINS',42),
	 (4204509,'CORUPA',42),
	 (4204558,'CORREIA PINTO',42),
	 (4204608,'CRICIUMA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4204707,'CUNHA PORA',42),
	 (4204756,'CUNHATAI',42),
	 (4204806,'CURITIBANOS',42),
	 (4204905,'DESCANSO',42),
	 (4205001,'DIONISIO CERQUEIRA',42),
	 (4205100,'DONA EMMA',42),
	 (4205159,'DOUTOR PEDRINHO',42),
	 (4205175,'ENTRE RIOS',42),
	 (4205191,'ERMO',42),
	 (4205209,'ERVAL VELHO',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4205308,'FAXINAL DOS GUEDES',42),
	 (4205357,'FLOR DO SERTAO',42),
	 (4205407,'FLORIANOPOLIS',42),
	 (4205431,'FORMOSA DO SUL',42),
	 (4205456,'FORQUILHINHA',42),
	 (4205506,'FRAIBURGO',42),
	 (4205555,'FREI ROGERIO',42),
	 (4205605,'GALVAO',42),
	 (4205704,'GAROPABA',42),
	 (4205803,'GARUVA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4205902,'GASPAR',42),
	 (4206009,'GOVERNADOR CELSO RAMOS',42),
	 (4206108,'GRAO PARA',42),
	 (4206207,'GRAVATAL',42),
	 (4206306,'GUABIRUBA',42),
	 (4206405,'GUARACIABA',42),
	 (4206504,'GUARAMIRIM',42),
	 (4206603,'GUARUJA DO SUL',42),
	 (4206652,'GUATAMBU',42),
	 (4206702,'HERVAL D OESTE',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4206751,'IBIAM',42),
	 (4206801,'IBICARE',42),
	 (4206900,'IBIRAMA',42),
	 (4207007,'ICARA',42),
	 (4207106,'ILHOTA',42),
	 (4207205,'IMARUI',42),
	 (4207304,'IMBITUBA',42),
	 (4207403,'IMBUIA',42),
	 (4207502,'INDAIAL',42),
	 (4207577,'IOMERE',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4207601,'IPIRA',42),
	 (4207650,'IPORA DO OESTE',42),
	 (4207684,'IPUACU',42),
	 (4207700,'IPUMIRIM',42),
	 (4207759,'IRACEMINHA',42),
	 (4207809,'IRANI',42),
	 (4207858,'IRATI',42),
	 (4207908,'IRINEOPOLIS',42),
	 (4208005,'ITA',42),
	 (4208104,'ITAIOPOLIS',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4208203,'ITAJAI',42),
	 (4208302,'ITAPEMA',42),
	 (4208401,'ITAPIRANGA',42),
	 (4208450,'ITAPOA',42),
	 (4208500,'ITUPORANGA',42),
	 (4208609,'JABORA',42),
	 (4208708,'JACINTO MACHADO',42),
	 (4208807,'JAGUARUNA',42),
	 (4208906,'JARAGUA DO SUL',42),
	 (4208955,'JARDINOPOLIS',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4209003,'JOACABA',42),
	 (4209102,'JOINVILLE',42),
	 (4209151,'JOSE BOITEUX',42),
	 (4209177,'JUPIA',42),
	 (4209201,'LACERDOPOLIS',42),
	 (4209300,'LAGES',42),
	 (4209409,'LAGUNA',42),
	 (4209458,'LAJEADO GRANDE',42),
	 (4209508,'LAURENTINO',42),
	 (4209607,'LAURO MULLER',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4209706,'LEBON REGIS',42),
	 (4209805,'LEOBERTO LEAL',42),
	 (4209854,'LINDOIA DO SUL',42),
	 (4209904,'LONTRAS',42),
	 (4210001,'LUIZ ALVES',42),
	 (4210035,'LUZERNA',42),
	 (4210050,'MACIEIRA',42),
	 (4210100,'MAFRA',42),
	 (4210209,'MAJOR GERCINO',42),
	 (4210308,'MAJOR VIEIRA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4210407,'MARACAJA',42),
	 (4210506,'MARAVILHA',42),
	 (4210555,'MAREMA',42),
	 (4210605,'MASSARANDUBA',42),
	 (4210704,'MATOS COSTA',42),
	 (4210803,'MELEIRO',42),
	 (4210852,'MIRIM DOCE',42),
	 (4210902,'MODELO',42),
	 (4211009,'MONDAI',42),
	 (4211058,'MONTE CARLO',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4211108,'MONTE CASTELO',42),
	 (4211207,'MORRO DA FUMACA',42),
	 (4211256,'MORRO GRANDE',42),
	 (4211306,'NAVEGANTES',42),
	 (4211405,'NOVA ERECHIM',42),
	 (4211454,'NOVA ITABERABA',42),
	 (4211504,'NOVA TRENTO',42),
	 (4211603,'NOVA VENEZA',42),
	 (4211652,'NOVO HORIZONTE',42),
	 (4211702,'ORLEANS',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4211751,'OTACILIO COSTA',42),
	 (4211801,'OURO',42),
	 (4211850,'OURO VERDE',42),
	 (4211876,'PAIAL',42),
	 (4211892,'PAINEL',42),
	 (4211900,'PALHOCA',42),
	 (4212007,'PALMA SOLA',42),
	 (4212056,'PALMEIRA',42),
	 (4212106,'PALMITOS',42),
	 (4212205,'PAPANDUVA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4212239,'PARAISO',42),
	 (4212254,'PASSO DE TORRES',42),
	 (4212270,'PASSOS MAIA',42),
	 (4212304,'PAULO LOPES',42),
	 (4212403,'PEDRAS GRANDES',42),
	 (4212502,'PENHA',42),
	 (4212601,'PERITIBA',42),
	 (4212700,'PETROLANDIA',42),
	 (4212809,'BALNEARIO PICARRAS',42),
	 (4212908,'PINHALZINHO',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4213005,'PINHEIRO PRETO',42),
	 (4213104,'PIRATUBA',42),
	 (4213153,'PLANALTO ALEGRE',42),
	 (4213203,'POMERODE',42),
	 (4213302,'PONTE ALTA',42),
	 (4213351,'PONTE ALTA DO NORTE',42),
	 (4213401,'PONTE SERRADA',42),
	 (4213500,'PORTO BELO',42),
	 (4213609,'PORTO UNIAO',42),
	 (4213708,'POUSO REDONDO',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4213807,'PRAIA GRANDE',42),
	 (4213906,'PRESIDENTE CASTELLO BRANCO',42),
	 (4214003,'PRESIDENTE GETULIO',42),
	 (4214102,'PRESIDENTE NEREU',42),
	 (4214151,'PRINCESA',42),
	 (4214201,'QUILOMBO',42),
	 (4214300,'RANCHO QUEIMADO',42),
	 (4214409,'RIO DAS ANTAS',42),
	 (4214508,'RIO DO CAMPO',42),
	 (4214607,'RIO DO OESTE',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4214706,'RIO DOS CEDROS',42),
	 (4214805,'RIO DO SUL',42),
	 (4214904,'RIO FORTUNA',42),
	 (4215000,'RIO NEGRINHO',42),
	 (4215059,'RIO RUFINO',42),
	 (4215075,'RIQUEZA',42),
	 (4215109,'RODEIO',42),
	 (4215208,'ROMELANDIA',42),
	 (4215307,'SALETE',42),
	 (4215356,'SALTINHO',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4215406,'SALTO VELOSO',42),
	 (4215455,'SANGAO',42),
	 (4215505,'SANTA CECILIA',42),
	 (4215554,'SANTA HELENA',42),
	 (4215604,'SANTA ROSA DE LIMA',42),
	 (4215653,'SANTA ROSA DO SUL',42),
	 (4215679,'SANTA TEREZINHA',42),
	 (4215687,'SANTA TEREZINHA DO PROGRESSO',42),
	 (4215695,'SANTIAGO DO SUL',42),
	 (4215703,'SANTO AMARO DA IMPERATRIZ',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4215752,'SAO BERNARDINO',42),
	 (4215802,'SAO BENTO DO SUL',42),
	 (4215901,'SAO BONIFACIO',42),
	 (4216008,'SAO CARLOS',42),
	 (4216057,'SAO CRISTOVAO DO SUL',42),
	 (4216107,'SAO DOMINGOS',42),
	 (4216206,'SAO FRANCISCO DO SUL',42),
	 (4216255,'SAO JOAO DO OESTE',42),
	 (4216305,'SAO JOAO BATISTA',42),
	 (4216354,'SAO JOAO DO ITAPERIU',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4216404,'SAO JOAO DO SUL',42),
	 (4216503,'SAO JOAQUIM',42),
	 (4216602,'SAO JOSE',42),
	 (4216701,'SAO JOSE DO CEDRO',42),
	 (4216800,'SAO JOSE DO CERRITO',42),
	 (4216909,'SAO LOURENCO DO OESTE',42),
	 (4217006,'SAO LUDGERO',42),
	 (4217105,'SAO MARTINHO',42),
	 (4217154,'SAO MIGUEL DA BOA VISTA',42),
	 (4217204,'SAO MIGUEL DO OESTE',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4217253,'SAO PEDRO DE ALCANTARA',42),
	 (4217303,'SAUDADES',42),
	 (4217402,'SCHROEDER',42),
	 (4217501,'SEARA',42),
	 (4217550,'SERRA ALTA',42),
	 (4217600,'SIDEROPOLIS',42),
	 (4217709,'SOMBRIO',42),
	 (4217758,'SUL BRASIL',42),
	 (4217808,'TAIO',42),
	 (4217907,'TANGARA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4217956,'TIGRINHOS',42),
	 (4218004,'TIJUCAS',42),
	 (4218103,'TIMBE DO SUL',42),
	 (4218202,'TIMBO',42),
	 (4218251,'TIMBO GRANDE',42),
	 (4218301,'TRES BARRAS',42),
	 (4218350,'TREVISO',42),
	 (4218400,'TREZE DE MAIO',42),
	 (4218509,'TREZE TILIAS',42),
	 (4218608,'TROMBUDO CENTRAL',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4218707,'TUBARAO',42),
	 (4218756,'TUNAPOLIS',42),
	 (4218806,'TURVO',42),
	 (4218855,'UNIAO DO OESTE',42),
	 (4218905,'URUBICI',42),
	 (4218954,'URUPEMA',42),
	 (4219002,'URUSSANGA',42),
	 (4219101,'VARGEAO',42),
	 (4219150,'VARGEM',42),
	 (4219176,'VARGEM BONITA',42);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4219200,'VIDAL RAMOS',42),
	 (4219309,'VIDEIRA',42),
	 (4219358,'VITOR MEIRELES',42),
	 (4219408,'WITMARSUM',42),
	 (4219507,'XANXERE',42),
	 (4219606,'XAVANTINA',42),
	 (4219705,'XAXIM',42),
	 (4219853,'ZORTEA',42),
	 (4300034,'ACEGUA',43),
	 (4300059,'AGUA SANTA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4300109,'AGUDO',43),
	 (4300208,'AJURICABA',43),
	 (4300307,'ALECRIM',43),
	 (4300406,'ALEGRETE',43),
	 (4300455,'ALEGRIA',43),
	 (4300471,'ALMIRANTE TAMANDARE DO SUL',43),
	 (4300505,'ALPESTRE',43),
	 (4300554,'ALTO ALEGRE',43),
	 (4300570,'ALTO FELIZ',43),
	 (4300604,'ALVORADA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4300638,'AMARAL FERRADOR',43),
	 (4300646,'AMETISTA DO SUL',43),
	 (4300661,'ANDRE DA ROCHA',43),
	 (4300703,'ANTA GORDA',43),
	 (4300802,'ANTONIO PRADO',43),
	 (4300851,'ARAMBARE',43),
	 (4300877,'ARARICA',43),
	 (4300901,'ARATIBA',43),
	 (4301008,'ARROIO DO MEIO',43),
	 (4301057,'ARROIO DO SAL',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4301073,'ARROIO DO PADRE',43),
	 (4301107,'ARROIO DOS RATOS',43),
	 (4301206,'ARROIO DO TIGRE',43),
	 (4301305,'ARROIO GRANDE',43),
	 (4301404,'ARVOREZINHA',43),
	 (4301503,'AUGUSTO PESTANA',43),
	 (4301552,'AUREA',43),
	 (4301602,'BAGE',43),
	 (4301636,'BALNEARIO PINHAL',43),
	 (4301651,'BARAO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4301701,'BARAO DE COTEGIPE',43),
	 (4301750,'BARAO DO TRIUNFO',43),
	 (4301800,'BARRACAO',43),
	 (4301859,'BARRA DO GUARITA',43),
	 (4301875,'BARRA DO QUARAI',43),
	 (4301909,'BARRA DO RIBEIRO',43),
	 (4301925,'BARRA DO RIO AZUL',43),
	 (4301958,'BARRA FUNDA',43),
	 (4302006,'BARROS CASSAL',43),
	 (4302055,'BENJAMIN CONSTANT DO SUL',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4302105,'BENTO GONCALVES',43),
	 (4302154,'BOA VISTA DAS MISSOES',43),
	 (4302204,'BOA VISTA DO BURICA',43),
	 (4302220,'BOA VISTA DO CADEADO',43),
	 (4302238,'BOA VISTA DO INCRA',43),
	 (4302253,'BOA VISTA DO SUL',43),
	 (4302303,'BOM JESUS',43),
	 (4302352,'BOM PRINCIPIO',43),
	 (4302378,'BOM PROGRESSO',43),
	 (4302402,'BOM RETIRO DO SUL',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4302451,'BOQUEIRAO DO LEAO',43),
	 (4302501,'BOSSOROCA',43),
	 (4302584,'BOZANO',43),
	 (4302600,'BRAGA',43),
	 (4302659,'BROCHIER',43),
	 (4302709,'BUTIA',43),
	 (4302808,'CACAPAVA DO SUL',43),
	 (4302907,'CACEQUI',43),
	 (4303004,'CACHOEIRA DO SUL',43),
	 (4303103,'CACHOEIRINHA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4303202,'CACIQUE DOBLE',43),
	 (4303301,'CAIBATE',43),
	 (4303400,'CAICARA',43),
	 (4303509,'CAMAQUA',43),
	 (4303558,'CAMARGO',43),
	 (4303608,'CAMBARA DO SUL',43),
	 (4303673,'CAMPESTRE DA SERRA',43),
	 (4303707,'CAMPINA DAS MISSOES',43),
	 (4303806,'CAMPINAS DO SUL',43),
	 (4303905,'CAMPO BOM',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4304002,'CAMPO NOVO',43),
	 (4304101,'CAMPOS BORGES',43),
	 (4304200,'CANDELARIA',43),
	 (4304309,'CANDIDO GODOI',43),
	 (4304358,'CANDIOTA',43),
	 (4304408,'CANELA',43),
	 (4304507,'CANGUCU',43),
	 (4304606,'CANOAS',43),
	 (4304614,'CANUDOS DO VALE',43),
	 (4304622,'CAPAO BONITO DO SUL',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4304630,'CAPAO DA CANOA',43),
	 (4304655,'CAPAO DO CIPO',43),
	 (4304663,'CAPAO DO LEAO',43),
	 (4304671,'CAPIVARI DO SUL',43),
	 (4304689,'CAPELA DE SANTANA',43),
	 (4304697,'CAPITAO',43),
	 (4304705,'CARAZINHO',43),
	 (4304713,'CARAA',43),
	 (4304804,'CARLOS BARBOSA',43),
	 (4304853,'CARLOS GOMES',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4304903,'CASCA',43),
	 (4304952,'CASEIROS',43),
	 (4305009,'CATUIPE',43),
	 (4305108,'CAXIAS DO SUL',43),
	 (4305116,'CENTENARIO',43),
	 (4305124,'CERRITO',43),
	 (4305132,'CERRO BRANCO',43),
	 (4305157,'CERRO GRANDE',43),
	 (4305173,'CERRO GRANDE DO SUL',43),
	 (4305207,'CERRO LARGO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4305306,'CHAPADA',43),
	 (4305355,'CHARQUEADAS',43),
	 (4305371,'CHARRUA',43),
	 (4305405,'CHIAPETTA',43),
	 (4305439,'CHUI',43),
	 (4305447,'CHUVISCA',43),
	 (4305454,'CIDREIRA',43),
	 (4305504,'CIRIACO',43),
	 (4305587,'COLINAS',43),
	 (4305603,'COLORADO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4305702,'CONDOR',43),
	 (4305801,'CONSTANTINA',43),
	 (4305835,'COQUEIRO BAIXO',43),
	 (4305850,'COQUEIROS DO SUL',43),
	 (4305871,'CORONEL BARROS',43),
	 (4305900,'CORONEL BICACO',43),
	 (4305934,'CORONEL PILAR',43),
	 (4305959,'COTIPORA',43),
	 (4305975,'COXILHA',43),
	 (4306007,'CRISSIUMAL',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4306056,'CRISTAL',43),
	 (4306072,'CRISTAL DO SUL',43),
	 (4306106,'CRUZ ALTA',43),
	 (4306130,'CRUZALTENSE',43),
	 (4306205,'CRUZEIRO DO SUL',43),
	 (4306304,'DAVID CANABARRO',43),
	 (4306320,'DERRUBADAS',43),
	 (4306353,'DEZESSEIS DE NOVEMBRO',43),
	 (4306379,'DILERMANDO DE AGUIAR',43),
	 (4306403,'DOIS IRMAOS',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4306429,'DOIS IRMAOS DAS MISSOES',43),
	 (4306452,'DOIS LAJEADOS',43),
	 (4306502,'DOM FELICIANO',43),
	 (4306551,'DOM PEDRO DE ALCANTARA',43),
	 (4306601,'DOM PEDRITO',43),
	 (4306700,'DONA FRANCISCA',43),
	 (4306734,'DOUTOR MAURICIO CARDOSO',43),
	 (4306759,'DOUTOR RICARDO',43),
	 (4306767,'ELDORADO DO SUL',43),
	 (4306809,'ENCANTADO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4306908,'ENCRUZILHADA DO SUL',43),
	 (4306924,'ENGENHO VELHO',43),
	 (4306932,'ENTRE-IJUIS',43),
	 (4306957,'ENTRE RIOS DO SUL',43),
	 (4306973,'EREBANGO',43),
	 (4307005,'ERECHIM',43),
	 (4307054,'ERNESTINA',43),
	 (4307104,'HERVAL',43),
	 (4307203,'ERVAL GRANDE',43),
	 (4307302,'ERVAL SECO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4307401,'ESMERALDA',43),
	 (4307450,'ESPERANCA DO SUL',43),
	 (4307500,'ESPUMOSO',43),
	 (4307559,'ESTACAO',43),
	 (4307609,'ESTANCIA VELHA',43),
	 (4307708,'ESTEIO',43),
	 (4307807,'ESTRELA',43),
	 (4307815,'ESTRELA VELHA',43),
	 (4307831,'EUGENIO DE CASTRO',43),
	 (4307864,'FAGUNDES VARELA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4307906,'FARROUPILHA',43),
	 (4308003,'FAXINAL DO SOTURNO',43),
	 (4308052,'FAXINALZINHO',43),
	 (4308078,'FAZENDA VILANOVA',43),
	 (4308102,'FELIZ',43),
	 (4308201,'FLORES DA CUNHA',43),
	 (4308250,'FLORIANO PEIXOTO',43),
	 (4308300,'FONTOURA XAVIER',43),
	 (4308409,'FORMIGUEIRO',43),
	 (4308433,'FORQUETINHA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4308458,'FORTALEZA DOS VALOS',43),
	 (4308508,'FREDERICO WESTPHALEN',43),
	 (4308607,'GARIBALDI',43),
	 (4308656,'GARRUCHOS',43),
	 (4308706,'GAURAMA',43),
	 (4308805,'GENERAL CAMARA',43),
	 (4308854,'GENTIL',43),
	 (4308904,'GETULIO VARGAS',43),
	 (4309001,'GIRUA',43),
	 (4309050,'GLORINHA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4309100,'GRAMADO',43),
	 (4309126,'GRAMADO DOS LOUREIROS',43),
	 (4309159,'GRAMADO XAVIER',43),
	 (4309209,'GRAVATAI',43),
	 (4309258,'GUABIJU',43),
	 (4309308,'GUAIBA',43),
	 (4309407,'GUAPORE',43),
	 (4309506,'GUARANI DAS MISSOES',43),
	 (4309555,'HARMONIA',43),
	 (4309571,'HERVEIRAS',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4309605,'HORIZONTINA',43),
	 (4309654,'HULHA NEGRA',43),
	 (4309704,'HUMAITA',43),
	 (4309753,'IBARAMA',43),
	 (4309803,'IBIACA',43),
	 (4309902,'IBIRAIARAS',43),
	 (4309951,'IBIRAPUITA',43),
	 (4310009,'IBIRUBA',43),
	 (4310108,'IGREJINHA',43),
	 (4310207,'IJUI',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4310306,'ILOPOLIS',43),
	 (4310330,'IMBE',43),
	 (4310363,'IMIGRANTE',43),
	 (4310405,'INDEPENDENCIA',43),
	 (4310413,'INHACORA',43),
	 (4310439,'IPE',43),
	 (4310462,'IPIRANGA DO SUL',43),
	 (4310504,'IRAI',43),
	 (4310538,'ITAARA',43),
	 (4310553,'ITACURUBI',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4310579,'ITAPUCA',43),
	 (4310603,'ITAQUI',43),
	 (4310652,'ITATI',43),
	 (4310702,'ITATIBA DO SUL',43),
	 (4310751,'IVORA',43),
	 (4310801,'IVOTI',43),
	 (4310850,'JABOTICABA',43),
	 (4310876,'JACUIZINHO',43),
	 (4310900,'JACUTINGA',43),
	 (4311007,'JAGUARAO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4311106,'JAGUARI',43),
	 (4311122,'JAQUIRANA',43),
	 (4311130,'JARI',43),
	 (4311155,'JOIA',43),
	 (4311205,'JULIO DE CASTILHOS',43),
	 (4311239,'LAGOA BONITA DO SUL',43),
	 (4311254,'LAGOAO',43),
	 (4311270,'LAGOA DOS TRES CANTOS',43),
	 (4311304,'LAGOA VERMELHA',43),
	 (4311403,'LAJEADO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4311429,'LAJEADO DO BUGRE',43),
	 (4311502,'LAVRAS DO SUL',43),
	 (4311601,'LIBERATO SALZANO',43),
	 (4311627,'LINDOLFO COLLOR',43),
	 (4311643,'LINHA NOVA',43),
	 (4311700,'MACHADINHO',43),
	 (4311718,'MACAMBARA',43),
	 (4311734,'MAMPITUBA',43),
	 (4311759,'MANOEL VIANA',43),
	 (4311775,'MAQUINE',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4311791,'MARATA',43),
	 (4311809,'MARAU',43),
	 (4311908,'MARCELINO RAMOS',43),
	 (4311981,'MARIANA PIMENTEL',43),
	 (4312005,'MARIANO MORO',43),
	 (4312054,'MARQUES DE SOUZA',43),
	 (4312104,'MATA',43),
	 (4312138,'MATO CASTELHANO',43),
	 (4312153,'MATO LEITAO',43),
	 (4312179,'MATO QUEIMADO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4312203,'MAXIMILIANO DE ALMEIDA',43),
	 (4312252,'MINAS DO LEAO',43),
	 (4312302,'MIRAGUAI',43),
	 (4312351,'MONTAURI',43),
	 (4312377,'MONTE ALEGRE DOS CAMPOS',43),
	 (4312385,'MONTE BELO DO SUL',43),
	 (4312401,'MONTENEGRO',43),
	 (4312427,'MORMACO',43),
	 (4312443,'MORRINHOS DO SUL',43),
	 (4312450,'MORRO REDONDO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4312476,'MORRO REUTER',43),
	 (4312500,'MOSTARDAS',43),
	 (4312609,'MUCUM',43),
	 (4312617,'MUITOS CAPOES',43),
	 (4312625,'MULITERNO',43),
	 (4312658,'NAO-ME-TOQUE',43),
	 (4312674,'NICOLAU VERGUEIRO',43),
	 (4312708,'NONOAI',43),
	 (4312757,'NOVA ALVORADA',43),
	 (4312807,'NOVA ARACA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4312906,'NOVA BASSANO',43),
	 (4312955,'NOVA BOA VISTA',43),
	 (4313003,'NOVA BRESCIA',43),
	 (4313011,'NOVA CANDELARIA',43),
	 (4313037,'NOVA ESPERANCA DO SUL',43),
	 (4313060,'NOVA HARTZ',43),
	 (4313086,'NOVA PADUA',43),
	 (4313102,'NOVA PALMA',43),
	 (4313201,'NOVA PETROPOLIS',43),
	 (4313300,'NOVA PRATA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4313334,'NOVA RAMADA',43),
	 (4313359,'NOVA ROMA DO SUL',43),
	 (4313375,'NOVA SANTA RITA',43),
	 (4313391,'NOVO CABRAIS',43),
	 (4313409,'NOVO HAMBURGO',43),
	 (4313425,'NOVO MACHADO',43),
	 (4313441,'NOVO TIRADENTES',43),
	 (4313466,'NOVO XINGU',43),
	 (4313490,'NOVO BARREIRO',43),
	 (4313508,'OSORIO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4313607,'PAIM FILHO',43),
	 (4313656,'PALMARES DO SUL',43),
	 (4313706,'PALMEIRA DAS MISSOES',43),
	 (4313805,'PALMITINHO',43),
	 (4313904,'PANAMBI',43),
	 (4313953,'PANTANO GRANDE',43),
	 (4314001,'PARAI',43),
	 (4314027,'PARAISO DO SUL',43),
	 (4314035,'PARECI NOVO',43),
	 (4314050,'PAROBE',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4314068,'PASSA SETE',43),
	 (4314076,'PASSO DO SOBRADO',43),
	 (4314100,'PASSO FUNDO',43),
	 (4314134,'PAULO BENTO',43),
	 (4314159,'PAVERAMA',43),
	 (4314175,'PEDRAS ALTAS',43),
	 (4314209,'PEDRO OSORIO',43),
	 (4314308,'PEJUCARA',43),
	 (4314407,'PELOTAS',43),
	 (4314423,'PICADA CAFE',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4314456,'PINHAL',43),
	 (4314464,'PINHAL DA SERRA',43),
	 (4314472,'PINHAL GRANDE',43),
	 (4314498,'PINHEIRINHO DO VALE',43),
	 (4314506,'PINHEIRO MACHADO',43),
	 (4314555,'PIRAPO',43),
	 (4314605,'PIRATINI',43),
	 (4314704,'PLANALTO',43),
	 (4314753,'POCO DAS ANTAS',43),
	 (4314779,'PONTAO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4314787,'PONTE PRETA',43),
	 (4314803,'PORTAO',43),
	 (4314902,'PORTO ALEGRE',43),
	 (4315008,'PORTO LUCENA',43),
	 (4315057,'PORTO MAUA',43),
	 (4315073,'PORTO VERA CRUZ',43),
	 (4315107,'PORTO XAVIER',43),
	 (4315131,'POUSO NOVO',43),
	 (4315149,'PRESIDENTE LUCENA',43),
	 (4315156,'PROGRESSO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4315172,'PROTASIO ALVES',43),
	 (4315206,'PUTINGA',43),
	 (4315305,'QUARAI',43),
	 (4315313,'QUATRO IRMAOS',43),
	 (4315321,'QUEVEDOS',43),
	 (4315354,'QUINZE DE NOVEMBRO',43),
	 (4315404,'REDENTORA',43),
	 (4315453,'RELVADO',43),
	 (4315503,'RESTINGA SECA',43),
	 (4315552,'RIO DOS INDIOS',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4315602,'RIO GRANDE',43),
	 (4315701,'RIO PARDO',43),
	 (4315750,'RIOZINHO',43),
	 (4315800,'ROCA SALES',43),
	 (4315909,'RODEIO BONITO',43),
	 (4315958,'ROLADOR',43),
	 (4316006,'ROLANTE',43),
	 (4316105,'RONDA ALTA',43),
	 (4316204,'RONDINHA',43),
	 (4316303,'ROQUE GONZALES',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4316402,'ROSARIO DO SUL',43),
	 (4316428,'SAGRADA FAMILIA',43),
	 (4316436,'SALDANHA MARINHO',43),
	 (4316451,'SALTO DO JACUI',43),
	 (4316477,'SALVADOR DAS MISSOES',43),
	 (4316501,'SALVADOR DO SUL',43),
	 (4316600,'SANANDUVA',43),
	 (4316709,'SANTA BARBARA DO SUL',43),
	 (4316733,'SANTA CECILIA DO SUL',43),
	 (4316758,'SANTA CLARA DO SUL',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4316808,'SANTA CRUZ DO SUL',43),
	 (4316907,'SANTA MARIA',43),
	 (4316956,'SANTA MARIA DO HERVAL',43),
	 (4316972,'SANTA MARGARIDA DO SUL',43),
	 (4317004,'SANTANA DA BOA VISTA',43),
	 (4317103,'SANTANA DO LIVRAMENTO',43),
	 (4317202,'SANTA ROSA',43),
	 (4317251,'SANTA TEREZA',43),
	 (4317301,'SANTA VITORIA DO PALMAR',43),
	 (4317400,'SANTIAGO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4317509,'SANTO ANGELO',43),
	 (4317558,'SANTO ANTONIO DO PALMA',43),
	 (4317608,'SANTO ANTONIO DA PATRULHA',43),
	 (4317707,'SANTO ANTONIO DAS MISSOES',43),
	 (4317756,'SANTO ANTONIO DO PLANALTO',43),
	 (4317806,'SANTO AUGUSTO',43),
	 (4317905,'SANTO CRISTO',43),
	 (4317954,'SANTO EXPEDITO DO SUL',43),
	 (4318002,'SAO BORJA',43),
	 (4318051,'SAO DOMINGOS DO SUL',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4318101,'SAO FRANCISCO DE ASSIS',43),
	 (4318200,'SAO FRANCISCO DE PAULA',43),
	 (4318309,'SAO GABRIEL',43),
	 (4318408,'SAO JERONIMO',43),
	 (4318424,'SAO JOAO DA URTIGA',43),
	 (4318432,'SAO JOAO DO POLESINE',43),
	 (4318440,'SAO JORGE',43),
	 (4318457,'SAO JOSE DAS MISSOES',43),
	 (4318465,'SAO JOSE DO HERVAL',43),
	 (4318481,'SAO JOSE DO HORTENCIO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4318499,'SAO JOSE DO INHACORA',43),
	 (4318507,'SAO JOSE DO NORTE',43),
	 (4318606,'SAO JOSE DO OURO',43),
	 (4318614,'SAO JOSE DO SUL',43),
	 (4318622,'SAO JOSE DOS AUSENTES',43),
	 (4318705,'SAO LEOPOLDO',43),
	 (4318804,'SAO LOURENCO DO SUL',43),
	 (4318903,'SAO LUIZ GONZAGA',43),
	 (4319000,'SAO MARCOS',43),
	 (4319109,'SAO MARTINHO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4319125,'SAO MARTINHO DA SERRA',43),
	 (4319158,'SAO MIGUEL DAS MISSOES',43),
	 (4319208,'SAO NICOLAU',43),
	 (4319307,'SAO PAULO DAS MISSOES',43),
	 (4319356,'SAO PEDRO DA SERRA',43),
	 (4319364,'SAO PEDRO DAS MISSOES',43),
	 (4319372,'SAO PEDRO DO BUTIA',43),
	 (4319406,'SAO PEDRO DO SUL',43),
	 (4319505,'SAO SEBASTIAO DO CAI',43),
	 (4319604,'SAO SEPE',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4319703,'SAO VALENTIM',43),
	 (4319711,'SAO VALENTIM DO SUL',43),
	 (4319737,'SAO VALERIO DO SUL',43),
	 (4319752,'SAO VENDELINO',43),
	 (4319802,'SAO VICENTE DO SUL',43),
	 (4319901,'SAPIRANGA',43),
	 (4320008,'SAPUCAIA DO SUL',43),
	 (4320107,'SARANDI',43),
	 (4320206,'SEBERI',43),
	 (4320230,'SEDE NOVA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4320263,'SEGREDO',43),
	 (4320305,'SELBACH',43),
	 (4320321,'SENADOR SALGADO FILHO',43),
	 (4320354,'SENTINELA DO SUL',43),
	 (4320404,'SERAFINA CORREA',43),
	 (4320453,'SERIO',43),
	 (4320503,'SERTAO',43),
	 (4320552,'SERTAO SANTANA',43),
	 (4320578,'SETE DE SETEMBRO',43),
	 (4320602,'SEVERIANO DE ALMEIDA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4320651,'SILVEIRA MARTINS',43),
	 (4320677,'SINIMBU',43),
	 (4320701,'SOBRADINHO',43),
	 (4320800,'SOLEDADE',43),
	 (4320859,'TABAI',43),
	 (4320909,'TAPEJARA',43),
	 (4321006,'TAPERA',43),
	 (4321105,'TAPES',43),
	 (4321204,'TAQUARA',43),
	 (4321303,'TAQUARI',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4321329,'TAQUARUCU DO SUL',43),
	 (4321352,'TAVARES',43),
	 (4321402,'TENENTE PORTELA',43),
	 (4321436,'TERRA DE AREIA',43),
	 (4321451,'TEUTONIA',43),
	 (4321469,'TIO HUGO',43),
	 (4321477,'TIRADENTES DO SUL',43),
	 (4321493,'TOROPI',43),
	 (4321501,'TORRES',43),
	 (4321600,'TRAMANDAI',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4321626,'TRAVESSEIRO',43),
	 (4321634,'TRES ARROIOS',43),
	 (4321667,'TRES CACHOEIRAS',43),
	 (4321709,'TRES COROAS',43),
	 (4321808,'TRES DE MAIO',43),
	 (4321832,'TRES FORQUILHAS',43),
	 (4321857,'TRES PALMEIRAS',43),
	 (4321907,'TRES PASSOS',43),
	 (4321956,'TRINDADE DO SUL',43),
	 (4322004,'TRIUNFO',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4322103,'TUCUNDUVA',43),
	 (4322152,'TUNAS',43),
	 (4322186,'TUPANCI DO SUL',43),
	 (4322202,'TUPANCIRETA',43),
	 (4322251,'TUPANDI',43),
	 (4322301,'TUPARENDI',43),
	 (4322327,'TURUCU',43),
	 (4322343,'UBIRETAMA',43),
	 (4322350,'UNIAO DA SERRA',43),
	 (4322376,'UNISTALDA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4322400,'URUGUAIANA',43),
	 (4322509,'VACARIA',43),
	 (4322525,'VALE VERDE',43),
	 (4322533,'VALE DO SOL',43),
	 (4322541,'VALE REAL',43),
	 (4322558,'VANINI',43),
	 (4322608,'VENANCIO AIRES',43),
	 (4322707,'VERA CRUZ',43),
	 (4322806,'VERANOPOLIS',43),
	 (4322855,'VESPASIANO CORREA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4322905,'VIADUTOS',43),
	 (4323002,'VIAMAO',43),
	 (4323101,'VICENTE DUTRA',43),
	 (4323200,'VICTOR GRAEFF',43),
	 (4323309,'VILA FLORES',43),
	 (4323358,'VILA LANGARO',43),
	 (4323408,'VILA MARIA',43),
	 (4323457,'VILA NOVA DO SUL',43),
	 (4323507,'VISTA ALEGRE',43),
	 (4323606,'VISTA ALEGRE DO PRATA',43);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (4323705,'VISTA GAUCHA',43),
	 (4323754,'VITORIA DAS MISSOES',43),
	 (4323770,'WESTFALIA',43),
	 (4323804,'XANGRI-LA',43),
	 (5000203,'AGUA CLARA',50),
	 (5000252,'ALCINOPOLIS',50),
	 (5000609,'AMAMBAI',50),
	 (5000708,'ANASTACIO',50),
	 (5000807,'ANAURILANDIA',50),
	 (5000856,'ANGELICA',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5000906,'ANTONIO JOAO',50),
	 (5001003,'APARECIDA DO TABOADO',50),
	 (5001102,'AQUIDAUANA',50),
	 (5001243,'ARAL MOREIRA',50),
	 (5001508,'BANDEIRANTES',50),
	 (5001904,'BATAGUASSU',50),
	 (5002001,'BATAYPORA',50),
	 (5002100,'BELA VISTA',50),
	 (5002159,'BODOQUENA',50),
	 (5002209,'BONITO',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5002308,'BRASILANDIA',50),
	 (5002407,'CAARAPO',50),
	 (5002605,'CAMAPUA',50),
	 (5002704,'CAMPO GRANDE',50),
	 (5002803,'CARACOL',50),
	 (5002902,'CASSILANDIA',50),
	 (5002951,'CHAPADAO DO SUL',50),
	 (5003108,'CORGUINHO',50),
	 (5003157,'CORONEL SAPUCAIA',50),
	 (5003207,'CORUMBA',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5003256,'COSTA RICA',50),
	 (5003306,'COXIM',50),
	 (5003454,'DEODAPOLIS',50),
	 (5003488,'DOIS IRMAOS DO BURITI',50),
	 (5003504,'DOURADINA',50),
	 (5003702,'DOURADOS',50),
	 (5003751,'ELDORADO',50),
	 (5003801,'FATIMA DO SUL',50),
	 (5003900,'FIGUEIRAO',50),
	 (5004007,'GLORIA DE DOURADOS',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5004106,'GUIA LOPES DA LAGUNA',50),
	 (5004304,'IGUATEMI',50),
	 (5004403,'INOCENCIA',50),
	 (5004502,'ITAPORA',50),
	 (5004601,'ITAQUIRAI',50),
	 (5004700,'IVINHEMA',50),
	 (5004809,'JAPORA',50),
	 (5004908,'JARAGUARI',50),
	 (5005004,'JARDIM',50),
	 (5005103,'JATEI',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5005152,'JUTI',50),
	 (5005202,'LADARIO',50),
	 (5005251,'LAGUNA CARAPA',50),
	 (5005400,'MARACAJU',50),
	 (5005608,'MIRANDA',50),
	 (5005681,'MUNDO NOVO',50),
	 (5005707,'NAVIRAI',50),
	 (5005806,'NIOAQUE',50),
	 (5006002,'NOVA ALVORADA DO SUL',50),
	 (5006200,'NOVA ANDRADINA',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5006259,'NOVO HORIZONTE DO SUL',50),
	 (5006309,'PARANAIBA',50),
	 (5006358,'PARANHOS',50),
	 (5006408,'PEDRO GOMES',50),
	 (5006606,'PONTA PORA',50),
	 (5006903,'PORTO MURTINHO',50),
	 (5007109,'RIBAS DO RIO PARDO',50),
	 (5007208,'RIO BRILHANTE',50),
	 (5007307,'RIO NEGRO',50),
	 (5007406,'RIO VERDE DE MATO GROSSO',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5007505,'ROCHEDO',50),
	 (5007554,'SANTA RITA DO PARDO',50),
	 (5007695,'SAO GABRIEL DO OESTE',50),
	 (5007703,'SETE QUEDAS',50),
	 (5007802,'SELVIRIA',50),
	 (5007901,'SIDROLANDIA',50),
	 (5007935,'SONORA',50),
	 (5007950,'TACURU',50),
	 (5007976,'TAQUARUSSU',50),
	 (5008008,'TERENOS',50);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5008305,'TRES LAGOAS',50),
	 (5008404,'VICENTINA',50),
	 (5100102,'ACORIZAL',51),
	 (5100201,'AGUA BOA',51),
	 (5100250,'ALTA FLORESTA',51),
	 (5100300,'ALTO ARAGUAIA',51),
	 (5100359,'ALTO BOA VISTA',51),
	 (5100409,'ALTO GARCAS',51),
	 (5100508,'ALTO PARAGUAI',51),
	 (5100607,'ALTO TAQUARI',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5100805,'APIACAS',51),
	 (5101001,'ARAGUAIANA',51),
	 (5101209,'ARAGUAINHA',51),
	 (5101258,'ARAPUTANGA',51),
	 (5101308,'ARENAPOLIS',51),
	 (5101407,'ARIPUANA',51),
	 (5101605,'BARAO DE MELGACO',51),
	 (5101704,'BARRA DO BUGRES',51),
	 (5101803,'BARRA DO GARCAS',51),
	 (5101852,'BOM JESUS DO ARAGUAIA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5101902,'BRASNORTE',51),
	 (5102504,'CACERES',51),
	 (5102603,'CAMPINAPOLIS',51),
	 (5102637,'CAMPO NOVO DO PARECIS',51),
	 (5102678,'CAMPO VERDE',51),
	 (5102686,'CAMPOS DE JULIO',51),
	 (5102694,'CANABRAVA DO NORTE',51),
	 (5102702,'CANARANA',51),
	 (5102793,'CARLINDA',51),
	 (5102850,'CASTANHEIRA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5103007,'CHAPADA DOS GUIMARAES',51),
	 (5103056,'CLAUDIA',51),
	 (5103106,'COCALINHO',51),
	 (5103205,'COLIDER',51),
	 (5103254,'COLNIZA',51),
	 (5103304,'COMODORO',51),
	 (5103353,'CONFRESA',51),
	 (5103361,'CONQUISTA D OESTE',51),
	 (5103379,'COTRIGUACU',51),
	 (5103403,'CUIABA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5103437,'CURVELANDIA',51),
	 (5103452,'DENISE',51),
	 (5103502,'DIAMANTINO',51),
	 (5103601,'DOM AQUINO',51),
	 (5103700,'FELIZ NATAL',51),
	 (5103809,'FIGUEIROPOLIS D OESTE',51),
	 (5103858,'GAUCHA DO NORTE',51),
	 (5103908,'GENERAL CARNEIRO',51),
	 (5103957,'GLORIA D OESTE',51),
	 (5104104,'GUARANTA DO NORTE',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5104203,'GUIRATINGA',51),
	 (5104500,'INDIAVAI',51),
	 (5104526,'IPIRANGA DO NORTE',51),
	 (5104542,'ITANHANGA',51),
	 (5104559,'ITAUBA',51),
	 (5104609,'ITIQUIRA',51),
	 (5104807,'JACIARA',51),
	 (5104906,'JANGADA',51),
	 (5105002,'JAURU',51),
	 (5105101,'JUARA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5105150,'JUINA',51),
	 (5105176,'JURUENA',51),
	 (5105200,'JUSCIMEIRA',51),
	 (5105234,'LAMBARI D OESTE',51),
	 (5105259,'LUCAS DO RIO VERDE',51),
	 (5105309,'LUCIARA',51),
	 (5105507,'VILA BELA DA SANTISSIMA TRINDADE',51),
	 (5105580,'MARCELANDIA',51),
	 (5105606,'MATUPA',51),
	 (5105622,'MIRASSOL D OESTE',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5105903,'NOBRES',51),
	 (5106000,'NORTELANDIA',51),
	 (5106109,'NOSSA SENHORA DO LIVRAMENTO',51),
	 (5106158,'NOVA BANDEIRANTES',51),
	 (5106174,'NOVA NAZARE',51),
	 (5106182,'NOVA LACERDA',51),
	 (5106190,'NOVA SANTA HELENA',51),
	 (5106208,'NOVA BRASILANDIA',51),
	 (5106216,'NOVA CANAA DO NORTE',51),
	 (5106224,'NOVA MUTUM',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5106232,'NOVA OLIMPIA',51),
	 (5106240,'NOVA UBIRATA',51),
	 (5106257,'NOVA XAVANTINA',51),
	 (5106265,'NOVO MUNDO',51),
	 (5106273,'NOVO HORIZONTE DO NORTE',51),
	 (5106281,'NOVO SAO JOAQUIM',51),
	 (5106299,'PARANAITA',51),
	 (5106307,'PARANATINGA',51),
	 (5106315,'NOVO SANTO ANTONIO',51),
	 (5106372,'PEDRA PRETA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5106422,'PEIXOTO DE AZEVEDO',51),
	 (5106455,'PLANALTO DA SERRA',51),
	 (5106505,'POCONE',51),
	 (5106653,'PONTAL DO ARAGUAIA',51),
	 (5106703,'PONTE BRANCA',51),
	 (5106752,'PONTES E LACERDA',51),
	 (5106778,'PORTO ALEGRE DO NORTE',51),
	 (5106802,'PORTO DOS GAUCHOS',51),
	 (5106828,'PORTO ESPERIDIAO',51),
	 (5106851,'PORTO ESTRELA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5107008,'POXOREO',51),
	 (5107040,'PRIMAVERA DO LESTE',51),
	 (5107065,'QUERENCIA',51),
	 (5107107,'SAO JOSE DOS QUATRO MARCOS',51),
	 (5107156,'RESERVA DO CABACAL',51),
	 (5107180,'RIBEIRAO CASCALHEIRA',51),
	 (5107198,'RIBEIRAOZINHO',51),
	 (5107206,'RIO BRANCO',51),
	 (5107248,'SANTA CARMEM',51),
	 (5107263,'SANTO AFONSO',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5107297,'SAO JOSE DO POVO',51),
	 (5107305,'SAO JOSE DO RIO CLARO',51),
	 (5107354,'SAO JOSE DO XINGU',51),
	 (5107404,'SAO PEDRO DA CIPA',51),
	 (5107578,'RONDOLANDIA',51),
	 (5107602,'RONDONOPOLIS',51),
	 (5107701,'ROSARIO OESTE',51),
	 (5107743,'SANTA CRUZ DO XINGU',51),
	 (5107750,'SALTO DO CEU',51),
	 (5107768,'SANTA RITA DO TRIVELATO',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5107776,'SANTA TEREZINHA',51),
	 (5107792,'SANTO ANTONIO DO LESTE',51),
	 (5107800,'SANTO ANTONIO DO LEVERGER',51),
	 (5107859,'SAO FELIX DO ARAGUAIA',51),
	 (5107875,'SAPEZAL',51),
	 (5107883,'SERRA NOVA DOURADA',51),
	 (5107909,'SINOP',51),
	 (5107925,'SORRISO',51),
	 (5107941,'TABAPORA',51),
	 (5107958,'TANGARA DA SERRA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5108006,'TAPURAH',51),
	 (5108055,'TERRA NOVA DO NORTE',51),
	 (5108105,'TESOURO',51),
	 (5108204,'TORIXOREU',51),
	 (5108303,'UNIAO DO SUL',51),
	 (5108352,'VALE DE SAO DOMINGOS',51),
	 (5108402,'VARZEA GRANDE',51),
	 (5108501,'VERA',51),
	 (5108600,'VILA RICA',51),
	 (5108808,'NOVA GUARITA',51);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5108857,'NOVA MARILANDIA',51),
	 (5108907,'NOVA MARINGA',51),
	 (5108956,'NOVA MONTE VERDE',51),
	 (5200050,'ABADIA DE GOIAS',52),
	 (5200100,'ABADIANIA',52),
	 (5200134,'ACREUNA',52),
	 (5200159,'ADELANDIA',52),
	 (5200175,'AGUA FRIA DE GOIAS',52),
	 (5200209,'AGUA LIMPA',52),
	 (5200258,'AGUAS LINDAS DE GOIAS',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5200308,'ALEXANIA',52),
	 (5200506,'ALOANDIA',52),
	 (5200555,'ALTO HORIZONTE',52),
	 (5200605,'ALTO PARAISO DE GOIAS',52),
	 (5200803,'ALVORADA DO NORTE',52),
	 (5200829,'AMARALINA',52),
	 (5200852,'AMERICANO DO BRASIL',52),
	 (5200902,'AMORINOPOLIS',52),
	 (5201108,'ANAPOLIS',52),
	 (5201207,'ANHANGUERA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5201306,'ANICUNS',52),
	 (5201405,'APARECIDA DE GOIANIA',52),
	 (5201454,'APARECIDA DO RIO DOCE',52),
	 (5201504,'APORE',52),
	 (5201603,'ARACU',52),
	 (5201702,'ARAGARCAS',52),
	 (5201801,'ARAGOIANIA',52),
	 (5202155,'ARAGUAPAZ',52),
	 (5202353,'ARENOPOLIS',52),
	 (5202502,'ARUANA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5202601,'AURILANDIA',52),
	 (5202809,'AVELINOPOLIS',52),
	 (5203104,'BALIZA',52),
	 (5203203,'BARRO ALTO',52),
	 (5203302,'BELA VISTA DE GOIAS',52),
	 (5203401,'BOM JARDIM DE GOIAS',52),
	 (5203500,'BOM JESUS DE GOIAS',52),
	 (5203559,'BONFINOPOLIS',52),
	 (5203575,'BONOPOLIS',52),
	 (5203609,'BRAZABRANTES',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5203807,'BRITANIA',52),
	 (5203906,'BURITI ALEGRE',52),
	 (5203939,'BURITI DE GOIAS',52),
	 (5203962,'BURITINOPOLIS',52),
	 (5204003,'CABECEIRAS',52),
	 (5204102,'CACHOEIRA ALTA',52),
	 (5204201,'CACHOEIRA DE GOIAS',52),
	 (5204250,'CACHOEIRA DOURADA',52),
	 (5204300,'CACU',52),
	 (5204409,'CAIAPONIA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5204508,'CALDAS NOVAS',52),
	 (5204557,'CALDAZINHA',52),
	 (5204607,'CAMPESTRE DE GOIAS',52),
	 (5204656,'CAMPINACU',52),
	 (5204706,'CAMPINORTE',52),
	 (5204805,'CAMPO ALEGRE DE GOIAS',52),
	 (5204854,'CAMPO LIMPO DE GOIAS',52),
	 (5204904,'CAMPOS BELOS',52),
	 (5204953,'CAMPOS VERDES',52),
	 (5205000,'CARMO DO RIO VERDE',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5205059,'CASTELANDIA',52),
	 (5205109,'CATALAO',52),
	 (5205208,'CATURAI',52),
	 (5205307,'CAVALCANTE',52),
	 (5205406,'CERES',52),
	 (5205455,'CEZARINA',52),
	 (5205471,'CHAPADAO DO CEU',52),
	 (5205497,'CIDADE OCIDENTAL',52),
	 (5205513,'COCALZINHO DE GOIAS',52),
	 (5205521,'COLINAS DO SUL',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5205703,'CORREGO DO OURO',52),
	 (5205802,'CORUMBA DE GOIAS',52),
	 (5205901,'CORUMBAIBA',52),
	 (5206206,'CRISTALINA',52),
	 (5206305,'CRISTIANOPOLIS',52),
	 (5206404,'CRIXAS',52),
	 (5206503,'CROMINIA',52),
	 (5206602,'CUMARI',52),
	 (5206701,'DAMIANOPOLIS',52),
	 (5206800,'DAMOLANDIA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5206909,'DAVINOPOLIS',52),
	 (5207105,'DIORAMA',52),
	 (5207253,'DOVERLANDIA',52),
	 (5207352,'EDEALINA',52),
	 (5207402,'EDEIA',52),
	 (5207501,'ESTRELA DO NORTE',52),
	 (5207535,'FAINA',52),
	 (5207600,'FAZENDA NOVA',52),
	 (5207808,'FIRMINOPOLIS',52),
	 (5207907,'FLORES DE GOIAS',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5208004,'FORMOSA',52),
	 (5208103,'FORMOSO',52),
	 (5208152,'GAMELEIRA DE GOIAS',52),
	 (5208301,'DIVINOPOLIS DE GOIAS',52),
	 (5208400,'GOIANAPOLIS',52),
	 (5208509,'GOIANDIRA',52),
	 (5208608,'GOIANESIA',52),
	 (5208707,'GOIANIA',52),
	 (5208806,'GOIANIRA',52),
	 (5208905,'GOIAS',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5209101,'GOIATUBA',52),
	 (5209150,'GOUVELANDIA',52),
	 (5209200,'GUAPO',52),
	 (5209291,'GUARAITA',52),
	 (5209408,'GUARANI DE GOIAS',52),
	 (5209457,'GUARINOS',52),
	 (5209606,'HEITORAI',52),
	 (5209705,'HIDROLANDIA',52),
	 (5209804,'HIDROLINA',52),
	 (5209903,'IACIARA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5209937,'INACIOLANDIA',52),
	 (5209952,'INDIARA',52),
	 (5210000,'INHUMAS',52),
	 (5210109,'IPAMERI',52),
	 (5210158,'IPIRANGA DE GOIAS',52),
	 (5210208,'IPORA',52),
	 (5210307,'ISRAELANDIA',52),
	 (5210406,'ITABERAI',52),
	 (5210562,'ITAGUARI',52),
	 (5210604,'ITAGUARU',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5210802,'ITAJA',52),
	 (5210901,'ITAPACI',52),
	 (5211008,'ITAPIRAPUA',52),
	 (5211206,'ITAPURANGA',52),
	 (5211305,'ITARUMA',52),
	 (5211404,'ITAUCU',52),
	 (5211503,'ITUMBIARA',52),
	 (5211602,'IVOLANDIA',52),
	 (5211701,'JANDAIA',52),
	 (5211800,'JARAGUA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5211909,'JATAI',52),
	 (5212006,'JAUPACI',52),
	 (5212055,'JESUPOLIS',52),
	 (5212105,'JOVIANIA',52),
	 (5212204,'JUSSARA',52),
	 (5212253,'LAGOA SANTA',52),
	 (5212303,'LEOPOLDO DE BULHOES',52),
	 (5212501,'LUZIANIA',52),
	 (5212600,'MAIRIPOTABA',52),
	 (5212709,'MAMBAI',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5212808,'MARA ROSA',52),
	 (5212907,'MARZAGAO',52),
	 (5212956,'MATRINCHA',52),
	 (5213004,'MAURILANDIA',52),
	 (5213053,'MIMOSO DE GOIAS',52),
	 (5213087,'MINACU',52),
	 (5213103,'MINEIROS',52),
	 (5213400,'MOIPORA',52),
	 (5213509,'MONTE ALEGRE DE GOIAS',52),
	 (5213707,'MONTES CLAROS DE GOIAS',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5213756,'MONTIVIDIU',52),
	 (5213772,'MONTIVIDIU DO NORTE',52),
	 (5213806,'MORRINHOS',52),
	 (5213855,'MORRO AGUDO DE GOIAS',52),
	 (5213905,'MOSSAMEDES',52),
	 (5214002,'MOZARLANDIA',52),
	 (5214051,'MUNDO NOVO',52),
	 (5214101,'MUTUNOPOLIS',52),
	 (5214408,'NAZARIO',52),
	 (5214507,'NEROPOLIS',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5214606,'NIQUELANDIA',52),
	 (5214705,'NOVA AMERICA',52),
	 (5214804,'NOVA AURORA',52),
	 (5214838,'NOVA CRIXAS',52),
	 (5214861,'NOVA GLORIA',52),
	 (5214879,'NOVA IGUACU DE GOIAS',52),
	 (5214903,'NOVA ROMA',52),
	 (5215009,'NOVA VENEZA',52),
	 (5215207,'NOVO BRASIL',52),
	 (5215231,'NOVO GAMA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5215256,'NOVO PLANALTO',52),
	 (5215306,'ORIZONA',52),
	 (5215405,'OURO VERDE DE GOIAS',52),
	 (5215504,'OUVIDOR',52),
	 (5215603,'PADRE BERNARDO',52),
	 (5215652,'PALESTINA DE GOIAS',52),
	 (5215702,'PALMEIRAS DE GOIAS',52),
	 (5215801,'PALMELO',52),
	 (5215900,'PALMINOPOLIS',52),
	 (5216007,'PANAMA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5216304,'PARANAIGUARA',52),
	 (5216403,'PARAUNA',52),
	 (5216452,'PEROLANDIA',52),
	 (5216809,'PETROLINA DE GOIAS',52),
	 (5216908,'PILAR DE GOIAS',52),
	 (5217104,'PIRACANJUBA',52),
	 (5217203,'PIRANHAS',52),
	 (5217302,'PIRENOPOLIS',52),
	 (5217401,'PIRES DO RIO',52),
	 (5217609,'PLANALTINA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5217708,'PONTALINA',52),
	 (5218003,'PORANGATU',52),
	 (5218052,'PORTEIRAO',52),
	 (5218102,'PORTELANDIA',52),
	 (5218300,'POSSE',52),
	 (5218391,'PROFESSOR JAMIL',52),
	 (5218508,'QUIRINOPOLIS',52),
	 (5218607,'RIALMA',52),
	 (5218706,'RIANAPOLIS',52),
	 (5218789,'RIO QUENTE',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5218904,'RUBIATABA',52),
	 (5219001,'SANCLERLANDIA',52),
	 (5219100,'SANTA BARBARA DE GOIAS',52),
	 (5219209,'SANTA CRUZ DE GOIAS',52),
	 (5219258,'SANTA FE DE GOIAS',52),
	 (5219308,'SANTA HELENA DE GOIAS',52),
	 (5219357,'SANTA ISABEL',52),
	 (5219407,'SANTA RITA DO ARAGUAIA',52),
	 (5219456,'SANTA RITA DO NOVO DESTINO',52),
	 (5219506,'SANTA ROSA DE GOIAS',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5219605,'SANTA TEREZA DE GOIAS',52),
	 (5219704,'SANTA TEREZINHA DE GOIAS',52),
	 (5219712,'SANTO ANTONIO DA BARRA',52),
	 (5219738,'SANTO ANTONIO DE GOIAS',52),
	 (5219753,'SANTO ANTONIO DO DESCOBERTO',52),
	 (5219803,'SAO DOMINGOS',52),
	 (5219902,'SAO FRANCISCO DE GOIAS',52),
	 (5220009,'SAO JOAO D ALIANCA',52),
	 (5220058,'SAO JOAO DA PARAUNA',52),
	 (5220108,'SAO LUIS DE MONTES BELOS',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5220157,'SAO LUIZ DO NORTE',52),
	 (5220207,'SAO MIGUEL DO ARAGUAIA',52),
	 (5220264,'SAO MIGUEL DO PASSA QUATRO',52),
	 (5220280,'SAO PATRICIO',52),
	 (5220405,'SAO SIMAO',52),
	 (5220454,'SENADOR CANEDO',52),
	 (5220504,'SERRANOPOLIS',52),
	 (5220603,'SILVANIA',52),
	 (5220686,'SIMOLANDIA',52),
	 (5220702,'SITIO D ABADIA',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5221007,'TAQUARAL DE GOIAS',52),
	 (5221080,'TERESINA DE GOIAS',52),
	 (5221197,'TEREZOPOLIS DE GOIAS',52),
	 (5221304,'TRES RANCHOS',52),
	 (5221403,'TRINDADE',52),
	 (5221452,'TROMBAS',52),
	 (5221502,'TURVANIA',52),
	 (5221551,'TURVELANDIA',52),
	 (5221577,'UIRAPURU',52),
	 (5221601,'URUACU',52);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (5221700,'URUANA',52),
	 (5221809,'URUTAI',52),
	 (5221858,'VALPARAISO DE GOIAS',52),
	 (5221908,'VARJAO',52),
	 (5222005,'VIANOPOLIS',52),
	 (5222054,'VICENTINOPOLIS',52),
	 (5222203,'VILA BOA',52),
	 (5222302,'VILA PROPICIO',52),
	 (5300108,'BRASILIA',53),
	 (9999999,'EXTERIOR',99);
INSERT INTO public.tab_municipio (mun_codigo,mun_descricao,est_codigo) VALUES
	 (1100064,'COLORADO DO OESTE',11);
