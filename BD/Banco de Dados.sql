PGDMP                      |            DeMaria    16.3    16.3 M    %           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            &           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            '           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            (           1262    16397    DeMaria    DATABASE        CREATE DATABASE "DeMaria" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Portuguese_Brazil.936';
    DROP DATABASE "DeMaria";
                postgres    false            ^           1247    16399    uf    TYPE     :  CREATE TYPE public.uf AS ENUM (
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
    'EX'
);
    DROP TYPE public.uf;
       public          postgres    false            )           0    0    TYPE uf    COMMENT     C   COMMENT ON TYPE public.uf IS 'Estados do Brasil ou EX = Exterior';
          public          postgres    false    862            �            1255    16515    funccalculaprecototal()    FUNCTION     C  CREATE FUNCTION public.funccalculaprecototal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 .   DROP FUNCTION public.funccalculaprecototal();
       public          postgres    false            �            1255    16502    funccompraestoque()    FUNCTION     �   CREATE FUNCTION public.funccompraestoque() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	update tab_estoque 
	set    quantidade = quantidade + new.quantidade
	where  id_produto = new.id_produto ;
	return new;
end;
$$;
 *   DROP FUNCTION public.funccompraestoque();
       public          postgres    false            �            1255    16493    funccriaestoque()    FUNCTION     �   CREATE FUNCTION public.funccriaestoque() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into tab_estoque(id_produto,quantidade) 
	values(new.id_produto, 0);
return new;
end;
$$;
 (   DROP FUNCTION public.funccriaestoque();
       public          postgres    false            �            1255    16550    funcvendaestoque()    FUNCTION     O	  CREATE FUNCTION public.funcvendaestoque() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 )   DROP FUNCTION public.funcvendaestoque();
       public          postgres    false            �            1259    16456    tab_cliente    TABLE     /  CREATE TABLE public.tab_cliente (
    id_cliente integer NOT NULL,
    nome_cliente character varying(100) NOT NULL,
    telefone character varying(20),
    endereco character varying(100) NOT NULL,
    cidade character varying(35) NOT NULL,
    cep character varying(20) NOT NULL,
    ativo boolean
);
    DROP TABLE public.tab_cliente;
       public         heap    postgres    false            �            1259    16455    tab_cliente_id_cliente_seq    SEQUENCE     �   ALTER TABLE public.tab_cliente ALTER COLUMN id_cliente ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_cliente_id_cliente_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    216            �            1259    16504 
   tab_compra    TABLE     �   CREATE TABLE public.tab_compra (
    id_compra integer NOT NULL,
    id_fornecedor integer NOT NULL,
    data_compra date NOT NULL,
    valor_total money
);
    DROP TABLE public.tab_compra;
       public         heap    postgres    false            �            1259    16503    tab_compra_id_compra_seq    SEQUENCE     �   ALTER TABLE public.tab_compra ALTER COLUMN id_compra ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_compra_id_compra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    224            �            1259    16516    tab_compra_produto    TABLE     �   CREATE TABLE public.tab_compra_produto (
    id_compra integer NOT NULL,
    id_produto integer NOT NULL,
    quantidade integer NOT NULL
);
 &   DROP TABLE public.tab_compra_produto;
       public         heap    postgres    false            �            1259    16462 
   tab_estado    TABLE     �  CREATE TABLE public.tab_estado (
    est_codigo numeric(2,0) NOT NULL,
    est_sigla public.uf NOT NULL,
    est_nome character varying(20),
    est_aliq_fcp numeric(10,2) DEFAULT 0,
    est_excecao_fcp boolean DEFAULT false,
    est_link_consulta_nfce text,
    est_modo_envio_nfe character varying(1),
    est_modo_envio_nfce character varying(1)
)
WITH (autovacuum_enabled='true');
    DROP TABLE public.tab_estado;
       public         heap    postgres    false    862            �            1259    16532    tab_estoque    TABLE     �   CREATE TABLE public.tab_estoque (
    id_registro integer NOT NULL,
    id_produto integer NOT NULL,
    quantidade integer NOT NULL
);
    DROP TABLE public.tab_estoque;
       public         heap    postgres    false            �            1259    16531    tab_estoque_id_registro_seq    SEQUENCE     �   ALTER TABLE public.tab_estoque ALTER COLUMN id_registro ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_estoque_id_registro_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    227            �            1259    16474    tab_fornecedor    TABLE     �  CREATE TABLE public.tab_fornecedor (
    id_fornecedor integer NOT NULL,
    nome_contato character varying(50) NOT NULL,
    razao_social character varying(50) NOT NULL,
    cnpj character varying(20) NOT NULL,
    telefone character varying(20),
    endereco character varying(100),
    cep character varying(10) NOT NULL,
    email character varying(40),
    ativo boolean DEFAULT true NOT NULL
);
 "   DROP TABLE public.tab_fornecedor;
       public         heap    postgres    false            �            1259    16473     tab_fornecedor_id_fornecedor_seq    SEQUENCE     �   ALTER TABLE public.tab_fornecedor ALTER COLUMN id_fornecedor ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_fornecedor_id_fornecedor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    219            �            1259    16483    tab_municipio    TABLE     �   CREATE TABLE public.tab_municipio (
    mun_codigo integer NOT NULL,
    mun_descricao character varying(40) NOT NULL,
    est_codigo numeric(2,0) NOT NULL
)
WITH (autovacuum_enabled='true');
 !   DROP TABLE public.tab_municipio;
       public         heap    postgres    false            �            1259    16545 
   tab_pedido    TABLE     b   CREATE TABLE public.tab_pedido (
    id_pedido integer NOT NULL,
    data_pedido date NOT NULL
);
    DROP TABLE public.tab_pedido;
       public         heap    postgres    false            �            1259    16544    tab_pedido_id_pedido_seq    SEQUENCE     �   ALTER TABLE public.tab_pedido ALTER COLUMN id_pedido ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_pedido_id_pedido_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    229            �            1259    16551    tab_pedido_item    TABLE     �   CREATE TABLE public.tab_pedido_item (
    id_produto integer NOT NULL,
    id_pedido integer NOT NULL,
    quantidade integer NOT NULL
);
 #   DROP TABLE public.tab_pedido_item;
       public         heap    postgres    false            �            1259    16495    tab_produto    TABLE     �   CREATE TABLE public.tab_produto (
    id_produto integer NOT NULL,
    nome_produto character varying(50) NOT NULL,
    descricao character varying(100),
    preco_venda money NOT NULL,
    preco_compra money NOT NULL,
    ativo boolean NOT NULL
);
    DROP TABLE public.tab_produto;
       public         heap    postgres    false            �            1259    16494    tab_produto_id_produto_seq    SEQUENCE     �   ALTER TABLE public.tab_produto ALTER COLUMN id_produto ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_produto_id_produto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    222            �            1259    16566 	   tab_venda    TABLE     �   CREATE TABLE public.tab_venda (
    id_venda integer NOT NULL,
    id_pedido integer NOT NULL,
    id_cliente integer NOT NULL,
    valor_total money NOT NULL
);
    DROP TABLE public.tab_venda;
       public         heap    postgres    false            �            1259    16565    tab_venda_id_venda_seq    SEQUENCE     �   ALTER TABLE public.tab_venda ALTER COLUMN id_venda ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tab_venda_id_venda_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public          postgres    false    232            �            1259    16583    vie_municipios    VIEW     �  CREATE VIEW public.vie_municipios AS
 SELECT tab_municipio.mun_codigo AS ibge,
    tab_municipio.mun_descricao AS descricao,
    tab_estado.est_codigo AS cod_uf,
    (tab_estado.est_sigla)::text AS desc_uf
   FROM (public.tab_municipio
     LEFT JOIN public.tab_estado ON ((tab_estado.est_codigo = tab_municipio.est_codigo)))
  ORDER BY (tab_estado.est_sigla)::text, tab_municipio.mun_descricao;
 !   DROP VIEW public.vie_municipios;
       public          postgres    false    217    220    220    220    217                      0    16456    tab_cliente 
   TABLE DATA           g   COPY public.tab_cliente (id_cliente, nome_cliente, telefone, endereco, cidade, cep, ativo) FROM stdin;
    public          postgres    false    216   m                 0    16504 
   tab_compra 
   TABLE DATA           X   COPY public.tab_compra (id_compra, id_fornecedor, data_compra, valor_total) FROM stdin;
    public          postgres    false    224   �m                 0    16516    tab_compra_produto 
   TABLE DATA           O   COPY public.tab_compra_produto (id_compra, id_produto, quantidade) FROM stdin;
    public          postgres    false    225   �m                 0    16462 
   tab_estado 
   TABLE DATA           �   COPY public.tab_estado (est_codigo, est_sigla, est_nome, est_aliq_fcp, est_excecao_fcp, est_link_consulta_nfce, est_modo_envio_nfe, est_modo_envio_nfce) FROM stdin;
    public          postgres    false    217   �m                 0    16532    tab_estoque 
   TABLE DATA           J   COPY public.tab_estoque (id_registro, id_produto, quantidade) FROM stdin;
    public          postgres    false    227   [p                 0    16474    tab_fornecedor 
   TABLE DATA           �   COPY public.tab_fornecedor (id_fornecedor, nome_contato, razao_social, cnpj, telefone, endereco, cep, email, ativo) FROM stdin;
    public          postgres    false    219   xp                 0    16483    tab_municipio 
   TABLE DATA           N   COPY public.tab_municipio (mun_codigo, mun_descricao, est_codigo) FROM stdin;
    public          postgres    false    220   �p                 0    16545 
   tab_pedido 
   TABLE DATA           <   COPY public.tab_pedido (id_pedido, data_pedido) FROM stdin;
    public          postgres    false    229   
%                 0    16551    tab_pedido_item 
   TABLE DATA           L   COPY public.tab_pedido_item (id_produto, id_pedido, quantidade) FROM stdin;
    public          postgres    false    230   '%                0    16495    tab_produto 
   TABLE DATA           l   COPY public.tab_produto (id_produto, nome_produto, descricao, preco_venda, preco_compra, ativo) FROM stdin;
    public          postgres    false    222   D%      "          0    16566 	   tab_venda 
   TABLE DATA           Q   COPY public.tab_venda (id_venda, id_pedido, id_cliente, valor_total) FROM stdin;
    public          postgres    false    232   a%      *           0    0    tab_cliente_id_cliente_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.tab_cliente_id_cliente_seq', 2, true);
          public          postgres    false    215            +           0    0    tab_compra_id_compra_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.tab_compra_id_compra_seq', 1, false);
          public          postgres    false    223            ,           0    0    tab_estoque_id_registro_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.tab_estoque_id_registro_seq', 1, false);
          public          postgres    false    226            -           0    0     tab_fornecedor_id_fornecedor_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.tab_fornecedor_id_fornecedor_seq', 1, false);
          public          postgres    false    218            .           0    0    tab_pedido_id_pedido_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.tab_pedido_id_pedido_seq', 1, false);
          public          postgres    false    228            /           0    0    tab_produto_id_produto_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.tab_produto_id_produto_seq', 1, false);
          public          postgres    false    221            0           0    0    tab_venda_id_venda_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.tab_venda_id_venda_seq', 1, false);
          public          postgres    false    231            Z           2606    16470    tab_estado pk_estados 
   CONSTRAINT     [   ALTER TABLE ONLY public.tab_estado
    ADD CONSTRAINT pk_estados PRIMARY KEY (est_codigo);
 ?   ALTER TABLE ONLY public.tab_estado DROP CONSTRAINT pk_estados;
       public            postgres    false    217            c           2606    16487    tab_municipio pk_municipios 
   CONSTRAINT     a   ALTER TABLE ONLY public.tab_municipio
    ADD CONSTRAINT pk_municipios PRIMARY KEY (mun_codigo);
 E   ALTER TABLE ONLY public.tab_municipio DROP CONSTRAINT pk_municipios;
       public            postgres    false    220            X           2606    16460    tab_cliente tab_cliente_pk 
   CONSTRAINT     `   ALTER TABLE ONLY public.tab_cliente
    ADD CONSTRAINT tab_cliente_pk PRIMARY KEY (id_cliente);
 D   ALTER TABLE ONLY public.tab_cliente DROP CONSTRAINT tab_cliente_pk;
       public            postgres    false    216            i           2606    16508    tab_compra tab_compra_pk 
   CONSTRAINT     ]   ALTER TABLE ONLY public.tab_compra
    ADD CONSTRAINT tab_compra_pk PRIMARY KEY (id_compra);
 B   ALTER TABLE ONLY public.tab_compra DROP CONSTRAINT tab_compra_pk;
       public            postgres    false    224            k           2606    16536    tab_estoque tab_estoque_pk 
   CONSTRAINT     a   ALTER TABLE ONLY public.tab_estoque
    ADD CONSTRAINT tab_estoque_pk PRIMARY KEY (id_registro);
 D   ALTER TABLE ONLY public.tab_estoque DROP CONSTRAINT tab_estoque_pk;
       public            postgres    false    227            m           2606    16538    tab_estoque tab_estoque_un 
   CONSTRAINT     [   ALTER TABLE ONLY public.tab_estoque
    ADD CONSTRAINT tab_estoque_un UNIQUE (id_produto);
 D   ALTER TABLE ONLY public.tab_estoque DROP CONSTRAINT tab_estoque_un;
       public            postgres    false    227            ^           2606    16479     tab_fornecedor tab_fornecedor_pk 
   CONSTRAINT     i   ALTER TABLE ONLY public.tab_fornecedor
    ADD CONSTRAINT tab_fornecedor_pk PRIMARY KEY (id_fornecedor);
 J   ALTER TABLE ONLY public.tab_fornecedor DROP CONSTRAINT tab_fornecedor_pk;
       public            postgres    false    219            a           2606    16481     tab_fornecedor tab_fornecedor_un 
   CONSTRAINT     [   ALTER TABLE ONLY public.tab_fornecedor
    ADD CONSTRAINT tab_fornecedor_un UNIQUE (cnpj);
 J   ALTER TABLE ONLY public.tab_fornecedor DROP CONSTRAINT tab_fornecedor_un;
       public            postgres    false    219            o           2606    16549    tab_pedido tab_pedido_pk 
   CONSTRAINT     ]   ALTER TABLE ONLY public.tab_pedido
    ADD CONSTRAINT tab_pedido_pk PRIMARY KEY (id_pedido);
 B   ALTER TABLE ONLY public.tab_pedido DROP CONSTRAINT tab_pedido_pk;
       public            postgres    false    229            f           2606    16499    tab_produto tab_produto_pk 
   CONSTRAINT     `   ALTER TABLE ONLY public.tab_produto
    ADD CONSTRAINT tab_produto_pk PRIMARY KEY (id_produto);
 D   ALTER TABLE ONLY public.tab_produto DROP CONSTRAINT tab_produto_pk;
       public            postgres    false    222            q           2606    16570    tab_venda tab_venda_pk 
   CONSTRAINT     Z   ALTER TABLE ONLY public.tab_venda
    ADD CONSTRAINT tab_venda_pk PRIMARY KEY (id_venda);
 @   ALTER TABLE ONLY public.tab_venda DROP CONSTRAINT tab_venda_pk;
       public            postgres    false    232            s           2606    16572    tab_venda tab_venda_un 
   CONSTRAINT     V   ALTER TABLE ONLY public.tab_venda
    ADD CONSTRAINT tab_venda_un UNIQUE (id_pedido);
 @   ALTER TABLE ONLY public.tab_venda DROP CONSTRAINT tab_venda_un;
       public            postgres    false    232            \           2606    16472    tab_estado uk_dupl_est_sigla 
   CONSTRAINT     \   ALTER TABLE ONLY public.tab_estado
    ADD CONSTRAINT uk_dupl_est_sigla UNIQUE (est_sigla);
 F   ALTER TABLE ONLY public.tab_estado DROP CONSTRAINT uk_dupl_est_sigla;
       public            postgres    false    217            V           1259    16461    tab_cliente_id_cliente_idx    INDEX     f   CREATE INDEX tab_cliente_id_cliente_idx ON public.tab_cliente USING btree (id_cliente, nome_cliente);
 .   DROP INDEX public.tab_cliente_id_cliente_idx;
       public            postgres    false    216    216            g           1259    16509    tab_compra_data_compra_idx    INDEX     X   CREATE INDEX tab_compra_data_compra_idx ON public.tab_compra USING btree (data_compra);
 .   DROP INDEX public.tab_compra_data_compra_idx;
       public            postgres    false    224            _           1259    16482    tab_fornecedor_razao_social_idx    INDEX     h   CREATE INDEX tab_fornecedor_razao_social_idx ON public.tab_fornecedor USING btree (razao_social, cnpj);
 3   DROP INDEX public.tab_fornecedor_razao_social_idx;
       public            postgres    false    219    219            d           1259    16500    tab_produto_nome_produto_idx    INDEX     g   CREATE INDEX tab_produto_nome_produto_idx ON public.tab_produto USING btree (nome_produto, descricao);
 0   DROP INDEX public.tab_produto_nome_produto_idx;
       public            postgres    false    222    222            ~           2620    16519 (   tab_compra_produto atualizaestoquecompra    TRIGGER     �   CREATE TRIGGER atualizaestoquecompra AFTER INSERT ON public.tab_compra_produto FOR EACH ROW EXECUTE FUNCTION public.funccompraestoque();
 A   DROP TRIGGER atualizaestoquecompra ON public.tab_compra_produto;
       public          postgres    false    225    235            �           2620    16554 $   tab_pedido_item atualizaestoquevenda    TRIGGER     �   CREATE TRIGGER atualizaestoquevenda AFTER INSERT ON public.tab_pedido_item FOR EACH ROW EXECUTE FUNCTION public.funcvendaestoque();
 =   DROP TRIGGER atualizaestoquevenda ON public.tab_pedido_item;
       public          postgres    false    237    230                       2620    16520 +   tab_compra_produto atualizavalortotalcompra    TRIGGER     �   CREATE TRIGGER atualizavalortotalcompra AFTER INSERT ON public.tab_compra_produto FOR EACH ROW EXECUTE FUNCTION public.funccalculaprecototal();
 D   DROP TRIGGER atualizavalortotalcompra ON public.tab_compra_produto;
       public          postgres    false    225    236            }           2620    16501    tab_produto criaestoque    TRIGGER     v   CREATE TRIGGER criaestoque AFTER INSERT ON public.tab_produto FOR EACH ROW EXECUTE FUNCTION public.funccriaestoque();
 0   DROP TRIGGER criaestoque ON public.tab_produto;
       public          postgres    false    222    234            t           2606    16488 !   tab_municipio fk_estado_municipio    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_municipio
    ADD CONSTRAINT fk_estado_municipio FOREIGN KEY (est_codigo) REFERENCES public.tab_estado(est_codigo);
 K   ALTER TABLE ONLY public.tab_municipio DROP CONSTRAINT fk_estado_municipio;
       public          postgres    false    4698    220    217            u           2606    16510    tab_compra tab_compra_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_compra
    ADD CONSTRAINT tab_compra_fk FOREIGN KEY (id_fornecedor) REFERENCES public.tab_fornecedor(id_fornecedor);
 B   ALTER TABLE ONLY public.tab_compra DROP CONSTRAINT tab_compra_fk;
       public          postgres    false    224    219    4702            v           2606    16521 (   tab_compra_produto tab_compra_produto_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_compra_produto
    ADD CONSTRAINT tab_compra_produto_fk FOREIGN KEY (id_compra) REFERENCES public.tab_compra(id_compra);
 R   ALTER TABLE ONLY public.tab_compra_produto DROP CONSTRAINT tab_compra_produto_fk;
       public          postgres    false    4713    224    225            w           2606    16526 *   tab_compra_produto tab_compra_produto_fk_1    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_compra_produto
    ADD CONSTRAINT tab_compra_produto_fk_1 FOREIGN KEY (id_produto) REFERENCES public.tab_produto(id_produto);
 T   ALTER TABLE ONLY public.tab_compra_produto DROP CONSTRAINT tab_compra_produto_fk_1;
       public          postgres    false    225    4710    222            x           2606    16539    tab_estoque tab_estoque_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_estoque
    ADD CONSTRAINT tab_estoque_fk FOREIGN KEY (id_produto) REFERENCES public.tab_produto(id_produto) ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.tab_estoque DROP CONSTRAINT tab_estoque_fk;
       public          postgres    false    4710    222    227            y           2606    16555 "   tab_pedido_item tab_pedido_item_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_pedido_item
    ADD CONSTRAINT tab_pedido_item_fk FOREIGN KEY (id_produto) REFERENCES public.tab_produto(id_produto);
 L   ALTER TABLE ONLY public.tab_pedido_item DROP CONSTRAINT tab_pedido_item_fk;
       public          postgres    false    4710    230    222            z           2606    16560 $   tab_pedido_item tab_pedido_item_fk_1    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_pedido_item
    ADD CONSTRAINT tab_pedido_item_fk_1 FOREIGN KEY (id_pedido) REFERENCES public.tab_pedido(id_pedido);
 N   ALTER TABLE ONLY public.tab_pedido_item DROP CONSTRAINT tab_pedido_item_fk_1;
       public          postgres    false    4719    230    229            {           2606    16573    tab_venda tab_venda_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_venda
    ADD CONSTRAINT tab_venda_fk FOREIGN KEY (id_pedido) REFERENCES public.tab_pedido(id_pedido);
 @   ALTER TABLE ONLY public.tab_venda DROP CONSTRAINT tab_venda_fk;
       public          postgres    false    229    232    4719            |           2606    16578    tab_venda tab_venda_fk_1    FK CONSTRAINT     �   ALTER TABLE ONLY public.tab_venda
    ADD CONSTRAINT tab_venda_fk_1 FOREIGN KEY (id_cliente) REFERENCES public.tab_cliente(id_cliente);
 B   ALTER TABLE ONLY public.tab_venda DROP CONSTRAINT tab_venda_fk_1;
       public          postgres    false    4696    216    232               �   x�u�=�0 �=�; �R��Y~򌴤��Ec8��'��s�����50���3-�4g>"�*[��;0�ɺ��Kj!����7؁�}A�4�б�5MD�8��)��k��8Lk �,
�֠�h�����.Wܾ�y޸���9��4�            x������ � �            x������ � �         Y  x�}����@���S���:��D�a"4��d��*�n\`f��M��m߈ۂ�a:�o�V�_��!Nr��_�F�� v�#��_�������CĒ���w�N��n�7q��� ^]Roh �$aU��3��6J��!�w�l XpR�� 5 �v:�'F�(�$����g�@�| �ڽ��*?+���s���o������hd,N��7�ӷ@��,�%�&ކ�{��A����o�����A��s��7?)�6�l��K���%b�E���������ڂ��[ڜk.����X)i��b0�̰>�$܄��a��?�g����le�fZ�x����G�%	���J��I,l���k*Ĉvb�M'�-,��օ�R�h�Ӿb��$�ŏ� K���"l�k�֛wf�ʢF ^ʌ)�t-[������*�x�(#v[�����o�� iB�j&�(hb������w�)W���I9�� I��8.%����.d'5����jNY+���d�'���/#~��1m�U3��1O@z �)�<\-��,��p�Ko덄 {�d�-'��x���)�����Ʀs������o$ߢ�Ec^Y����2?X            x������ � �            x������ � �            x�t�Yv�H�5��;
O �{�h��%Q)���g���MeUY�7Bl�� `�(v�]Ѽ�����q^��C���}���ފ��+Р������:]�G�U�v��9�z䰌�@���0ݧ�i���]�vX��e?��1�~'(�~�r��|�ߦ�m>��������_r�.�}�����]��|����I�kܱ�vo���9����k���u������y��S4�۲ޗ��}z��q?����t��گ�uqA�k�n�]~�=�?��or��|��L��8�w˶|����A��O��������Q~ �oW��cĭ��ߟ�^�����9���ʝ�by�̧u:�m�o�1�o*��x�ẕ�������t���>���}��>��+L�9�o���	����W���m���gj��J<������:�����a\��9��dt������Kgݗ�q�����z���~�2���]/R����X�������U��P��֯uCO�vZ���u<.����~�ޟ����F�|��9����ŊR��2_��Sƛ<�}���V�32Fv�����颵tɅ�u�o�\5�5W酄6���*궷a�W��du�ʰ�/����K��L�9�>��|�^�HQ�J��宇���+�|�N���e�oև�M�AZ����i�ߗK<G'q���4�۷�L�Q���E�K�|X�X-e��$��U**Sw|<�-��*2�ƅ̣�����a���?�>Z���_����UK��M�a^�ρq�1�_K e�&c�8&�jeٓ�^�e�H��k��������}#�#�s<�??��2>��)�{Y���(G�+̒{��t��9>�ǘ�j��G��u��jv�czȒ�]�D2Zu9�/Ύ�|�$n0@tj��Y>���2<W,[����M%%�yWY0� �#30}}|w�6E�l��k<d�X�{�=c@�,���@!_Hz�7@:^���5�s<�3_S�b��L�y���7ݳ�w؏��t^k�û���n�E��UV���~X�XΞ!��|?���`����e|���,�wY������@���⽬s�徏��ƶn�ԧ@���ʻD�`��#�)0L����!�u�	�Nq����]��ʽEI�G��{�_����-+L�6]���r��4o\6��yn�C��ɧL
���2ug���5A2e��5z�d(`/�s�.8Ȅ��/w��a8pg��bY��}a�Rʻ}������n�+��^�q�>+���L̩@�����Y�;W�̲��3^��c��w\2Ƹð���ƨ��y��yY�GoTA��$���c�WК�{��	>*(2��g�7��+��v���|��B����죁Tm�t}��b�cܠi.U����w�چ�J�cܫ҄���j#�h�=�)�"W�����$e�5FYD�˔c�m���\f����k�� [<��,��ț��������F�_�މN��-Gz(�T�-K�C��N��>������EƼgko��ѳ5�"O�4�k,�����D���vX7uG��=S�rkR�� ���-C��Kj�eA��{�Up��q���4=L��)����W�!��zc�7H?��ֹ�f<_]?Q�>��2rL����7~����:�uˌ�D�2�VzC�m?N�I{�QTVr�|,���ێ�A��N�ǚ��劲����s6UZ�3����yvw���~���R��'�eNw갭]uV��f&�H&������)�mu`�O7���!�A�[&iz��{]O3	�7QG�i(R`[9�(����|��N�Y?�yŽU6�k\����ޝ.4�9�ݤ���N߲�<�e^޿��J5��|i����:?�:l���4r�V6�TҚ	X�C��/YI�ѨV{�0�62��������?�N�:@WXՆ6Ƽ�K�p��~a�`[���Y�t��2=�}!����8�$ĐL#C61o��P����^���.���-38l0�?��>�:A8˗��W-�0�Z���Ye�7��>ϯC��ZyaY]���4);88d�[b�+�˨�.s��/�7И�Y*pH��PG8b?=�5P�E��v��K/B�|�c
`�}K.��[����$Z���ݑ�S�E����I?�Bv�B�"�����6������x�G��z�2�������*��-�����z�F>݌=$=}+�+�c�VB�y��P�m�¤����~G\U��Ц��Pؙ��lZ�*�֘"�Y��L�8Z쀞��
�ҋZ�7������,�fG�0ƒ#�fKLfD,�u]B��/\�2��m�f�����4Ƽ�[(}��|e?��-_�>=t;���+>@�[�d���6=nV�D=t�݅bL��&�9_��3�W�������XBҚ�w�dT<�!��e/֨O�����l5P��3�E �E�K ��N���h�^7��t���,m�1vUAe�-�i<$�P?7�p��"���Q�k|�z�~������7Y��6Դ��m��e��@c��6�I=v���h�S-_z��B��A���;���	`Q��+J�|K����Ct(�K`��0�ӯ{x�Jz��V��7�T7�k-���uC}�P���NU�e>bJ�ޢ�>���mL�����pLm��/�21�X4@.wsni�v7lm���$���ռ�ׂ�4��a���2(��&�s���;u�D��j��9��v���q}Z�<TW�~����O�U�]�
�@�>?��f)m\�Y�tu�f�I���ۦ���V��daWg�	+ؘ&cט���nw�Oz�0]gJf���5c�(�7��Ӆ�Tq����[�s�c:�SX�mVv��6�2�8ޡ���>��=�1���߽�oOٛdN�����&�Z��bD��5^��������z�b3c{�sЇ���޾�S�H��;Ӆ�
�\Q�m�䣦��F���¼D��u�_�o�dK	�fPe��Jՙu��VmRR�=��+��W~"�Ǥ��]V�)I�c��";�9 �(gW}�g=�H���9d�X�	�W��xX ���1����I-���M�RP���P��R�gm�*�*��A���i;��Q�9|,v������{|~�򟽫3I�P������O�����e���
��4cUZ�g�m�<7��j�S+
�Pg��	����ձ�~/k�5�Z	&j�bٛ�P��-�m�
b���y�g4��mW��璁�ړ%Ը����W)<�b���u6N�F�^��.�7�e�>�=���8���]ſ��������/m�X�٫�����#�A��ɠ�����/�Q���u�煏w8#�􃶃�HZ�~��.��K�=��&�g���������ŉP�%� o$���a�	)6퍧���ߧ�~��9d�t�s��A}�nh51�{nQ3a_�3��W��g-=��j
��8.�����m�m)3@�?�?K��Q�ݗ���~�vE�M��v�N��"��~����O~\�9��f�<��������)ٵ����j�>\�2t���#޾/y� C��C�Xf���Ϧ�:�G��G�a��W�ࠇ�s�zP|��͎@i���DQ�M�V����g�Զ�,O�p�H"�yb��U��*f������/�ߛ�$gY�9�e4~�G%&�y5���ǯ)�t!�o'�7��}�z$2˲qL�|���V�Q�=F���#��/���ƈ|�8.�}���=O�ӷ/xq�X�=.������$�>���:�,\���O�8O^��N�|.����:��0�s7Wn�1�\oK��dHG
��.��KBa��xH2kPB>ge���׾F_6p���m�nb �o��b��"E�y熻�p�@����X���፡A�,3���u��^lE���2~����3�p�>j:l���T���6��Y]o^������7�ț�ި����=��g#������+T^�@��Wa|��w�6;����:�)�#��2�e���N���MX2~d�>UqU�m�tO��\}�2�2�K��v���m{����8'��}|y������@�}�j����~p׀    h6�7������&|��D�?�m���֖y#(I��+̴�O�/5%E������5�g�F] t����Qe~��a�V����cC�u=+����V�鎾���~�~/S�!�-v�cq�j�)�8P�ۯ+���^�rs_�J�Er��m�,�B�/�h�u����V&�䳥�b�R,��\�x�v�{>�����QtƅJzK4�)ʂ(Mj.w�J��0\N�u;p*��-���<o�A�=~U��Q���=\Pg���]��ڗXğM��	�V�f���G+^�y��Յn�߮ݝ�M�ʱ��p��|���$qN�U���^�q���Iiؠ��<��5��������ԯi �h:��8�G�&�y' �P���.;^��p�-����h4�In'�`�{��1�O��e:�5�l��u�b:�+�x^��1��~��B�]E̲��4?�p��.|I�q�,�&���.�^��L�V1b���U]��js0,�1ɒ��K���i�;X�ݻ���o��&)�v+���b_�5*-�uk'�D�i��U���G�d5�e�d�ƥ��4���(_n����t,q���ܙ�|=�H.��q]�~N�P��N�����t��i;6�\����2�XFԞ��� �|��@J���z��'���آYi}�yW�:���z��j��iɬ�jD�,�UEC����� ���:=��iN���c��k*[Z*(�2��YD%TF�=����8��0qpM��A����h��<ț�����&�{s%�к7��9ާ�'ꃃ����N��u}`��&����d�W3|��iz��=k�o�%���x��5�j�&k���)~\>w#�@�0uM��z``��1���x.��J�fBY�D�|?/��2��M�ӄCz��&m��\$��!W��5�N�{ʍd�<�!F k�^�M>��خ�;���]?��16�{�ℵ�1�
"�ᔲ�>-�^8�2@� �d p�kD�.Ʊ�40P]�Y����y���q����`�<l�A�5`Y��m⢲�_�`��d�ؗ�����75.��|T5����I�?bO�y 6s�ie��Z����g���<����8~T v3~�R �8u�P���r��y�7�׈�퐶��,E$�>�Ї�F�$�1-�� h��DK<B�3E�;TL�o+F�z�6EXΡD�U�Z���SS����g��tM����_O?LP3��%Z7�xf�w�2�㹤GDԵ"��U�vH�8#f��Kǵp�AՕyP��M���zu.qotl`�5���ΝIԭ�ۻ���l5�Y�vEx��W���傼�k:�iȂ����5���U����h�� -��6�/����^���xu�����N��Π4�:�\���t{+��4���x��颧�.�w�=��!\7p�W���;z�/v*�p{�������D�)�I8�����_�M���t>������<߼��.~7�>�l�t1	*��)z����5��N���钞v���`'�z��a)��x�����
7 �'��g,r���k}��1ǧJ���۹���B�������&S�{����0�\���	�GB 9����K*�~�2��E�?�sy��2�ӻ�ʃƖ_��%:t{�1���t�m:}D�|N�������W����x�����\֐�a�9�;k�(�2oV�U�Ƿ��Q�{Ȋ�~Ů2�U����ޫN^+5����v�B�ܵ�`k>&7��M��	q�ޤ��l��콅����r2�1C۟�00����/M^nSh��E� � ��&��RȚr#�$9w�@���t}�΅H���(<D�a.H&Թbs"��*N���{� �J���QM��������f�������n����>[�MW�m�{�2��aB�Xa�`?� u�-�Ү*^��Q���_�y�N�Pkv�Í�烦� �$:�+��O
����y���=�g�δ�h":�79c�?�^.BQ�hI]mc
����]2?�ڂ�j#ܬ�L�|{���a.S)7�/��?K�,�-� �� j\��va���2�J��{���HM�)�kHf�3����\�KB�xh����œB���"�Dn���z�lJd"~ˍ\��@�?�r�����*f��l9朼��8�1�ɯ�,K���9��*��fj� X~�p��u)��p�>������sC5�=g@3d��t��f����X�Z:ZObW�ܖ�E��1�WqL.���7��,T��lJ��t��{
C��y1��+1�����X��ɟJC�����~f:]ғ,.YAU]�&�BQ��{�\W!=�Tq�R��=�O�R��VqM�h�}��
�i_����4�%�����9+o���3+�ݙ���7+*����yf?����	"��.A��L��AQ�d/��?��Pz�OQ�0��9���.2�Ӄ���g�Y4=6__���25�Bȴ��t��K�}��=���3��k��[Ԇ��M磾ay�+Ї*��� m�Eg����C&���Df���u����,K�Ϟ�G���8�h6�)���NG�R��	�����U�D�T&D6�	O��{���qވ�X8�s@�&(��_z�^ZY�q0�CH�����+#� ��k�F!8�BSvE� ^F�s����%��㻨��yF�{ҵ��|/+�,�}.�<'��7�A�C�o$��u:��7��B�S�2���y�����XB���D��i����v��5?Ҽ-��JpW��͍�>N��;qM"_�8��ʐs���cf����1U6﫺ܽ�1A��h-# ?��-�0� .gYp��,4T�Tg�f��.q�������9,�·�\�?�^_M:�)�)�G���p��c�Ԛ����9�9��)�N��x@6��p��d�������8O�+~K�X8w>������0!NT��z�lvț��8�\O��7��ՈK�e.���0�e�!���ϖ��ڋ5������<�����{ۑ�#E z�X5�����j�L�Xk_��q���n�nR�\����o��\f��t_/�5��XZ�f�(Z�^�4��d|�>r)�aֹ9	�9&Qv�1HV6�Ԕ��8H[O���_H�G�gz���Z�֪��o��T7%����;ЏpAe�|����o�!Ihu����_L�a4�`0�D�j+w�������B!��j�����IrLw�%q�>LXI����"�����ǆǰb8�eP����ia�Y�P�[�L�W<�c-<ϗ��C.:�C�N�'�s?A(3�f���$��1{b|����|�����ߩ��j�-W�hЙ���ৼ���"Ck��=a�^���F`��e'�At��;�c/oM``�4����hL�vp".Y���Ok�E`.l�o&e$��/����x���c�m�3Bǋ��r�t��p�����cT�����6a,����!z2����C�S��NAA�1{ss.���7z�~J@�!�?�t����$GI�������tF��㡪;�+��Z7hD�僙S�����l���O�`��.�����ܬ���W>߱����L�]�1�z���ĕ�=�3i�?%���.��� �s�B�E[���O'1<q>��3�A/�9���f��G�C�L��8�7!��o�ݤ��ܳP��ڊE��Co�|�~��*;�8�0��b��CսF�nĞ1�yۧ8��&�O&���칵2z"��N�ŀʢ��O�/Q�[�y�3��,�$n{m�^�m�馅q��W�m��Ϛl.�~|�F�!���t���4�����(���f#{�ky&qW��n����['zr<�����98.M>~�jl�	�.������׫쓟��z��-��\�?�}��+F�w�E��x�>�x 3��ⶐ��A�n����\C7F����;&�A@�D��O�b�̧I��n�0M��$ �UR��v�1�<�Ne�B|X~�8�7Ö2��Y��J3_D9�_�8�D�(��^E�yC0�#lH�R"J�ˑ**~Ƥ_���DEF&G�m    <���L���LC"a�����ӷ��n���|�Yʨ�&9���:�ĭ�B8���G��Jhu�������q^�bH��Vs�>�_��W]�W�Nr������	�����5?tQ!3\o�͝�~�8'^[!Ko=��� Kd=,sz��#�x����m����Zhj��@+�Џ�W\��wA���S��#=���?���eq]g��b`��}�~jÚ]��+w����LW�k���X�DW������8ƼW��58@���h�ǡ,:
/����/Z�$H�,�9Zv�Gbƪu��f5o�B�rz�,�D1����X���9���Tw��K�J�h���Z�|@Q���n`�G|pr��ZEscʟc�T?�4\�������qиR�� �S�� ���%k��c �E��i���&_՝�����>�7��J�e����K�>i]���q��OĶ!f��)z��V%ka�p]�͛�w���q���d ����b��`�9��Gb�`�h�g��a`u��g�q�j����\$Þ���p�D�Gp&F$E������|Ճi�i���NVX<^��ة���<T��|��s���-h�l�71��iGľ2�gč'�*��:���@�VC���S��Į2#�ǇR���mFɸ|ݼvAW��RP�D����]�Z�q�A���-4�����a̰Ƙ��7m+M���b�PM6-��C�m<	x�&L�,�ٳ��o|�U����z�5ڞE�ְa�'������h�cͯP��Wڥ:�X�t���5��4�q��j��GbW3K���5�Q��٘Er��iN��h�`�j�at)	����8�9v��g��=�`7(��E�{���y�*讳�-��2>���{�w�0pBg�N��r�ٓv|~<�|!5mJz٧u��͖�jHx�f�E���~W���NF���x?�7w��q�6�;EKu��e=���1�Ԍ��Q6���(���{��{��r9�Q4� X��aZz�p�P�Q���3��Q��,�@��a���U�����\��LA�S����h��,3�hXY�e�j>-�P�A
��d8�3�V�G�)Ko� ��e �tO��J�aΖX$��xC��5������;��I�����5��Ҙe&���>��i���I֨�)����<z1�KT�ERDB��!������MB�ʽ�J�@jýo
,���f�I����>W�U2����ݼ_�^*Z���w@Dˆ5,�G4��B��\XF���K�]�	�t�6�A��H�7ڤ����,��*6v}6��n�H�o��6����&y�s2�u��]A$U� �%_*�J������,����2�3��TX7I��7�ze�H�kQa���zJ��>�MkU�p�LY0�b��C���d����j�:���u3�+���=*���UD<�nG�)�

F��#x���H�<���G�	�:�٠�Լ��hT	MA�蒯 �AJ��9x���(L�y]��G��
{�C�ԓ�ِ�-��!�V����/R�xGd�*N~�{ܦ ��q?����OW�F?�n9h���X��5��X�eII ���jo�m�H��3P�&AR�hR��Hƚ�.0H�ڷ��f��"��N��MJ5 �+��#n�����jD^3�Oq�#�XnI�]|�b�)U<J�Cѳ�9��m��VҐ������<Um�<�o��X��-G��xThv$� ��T�̅\�X�04��d<'�����ه� �q�N�P�~�!��H0�K��r�Y�A�iL6��"�!M�
dǑ*I�ߐ��C0�x�yW����G��<|_�+8����$d
����#����
�5�%�?�<�ۓG1�j8�Ĳ�OW�����w�5����E�EӀ��|�@�U��i�Y�Aj�|0�9�9)�c~6Z�At�t���P"j���{������i��|�i�k\���]��I�c6M�R�ZZ��::у�-�Xpkvx�D�"��ܢ�ل�c������\�=�kU�\�r��$�4�C9x^���A����B�/T�G������s�^��
H3���F��G�ѐ@M8���ϻC �=�Fs��AO|*��q���s�)�*.�ع<�Pe��Ed;PG�i��Y��r�%	�!Q@Ns�)�NL��w��l��W�I�G�K���l�2�=�(̳����LO���ʞF�zp��rI�Q�SV���IG�f�h=���q�ܚYs�W�}ޫu�f��W�S4n���>��7ԒB
���>�5�������~�*?VU2c�k��Z�d��<$��(o�*jd2R\H�*2H}[6�
Ԯ�@��L#�}OvSV���L���t��6�'h;��&���1�Y�.��	yYҝ����'�]`S�oМ��.��r�i�X#�t�:��1�``!Q�+L5T�J� XPwj9�P���Ԋ����s���?2G�������a����=���ĕ�r�e����%y�n�R���Z�m�nJ����q��~;��2mڢ�YM�_�9mR��1'��z�[�e�&k$�e��{�Բz90^oP�oz��==��y=�=-�č�y����Ae	����Ot�� ��Q?�e�a��[��<7�TF��a��1#*�{5�iᲾ��0/w�`����������%���v��x>����=�b0?��4�l��Q\�\�Z�+BϟS���X���S�:_�`��$��aQk~���	N���+W���U�.XPE)�)�����%�g^�|ه�aɐqm�ya;J���^?8n�����:��c܂�^V�� ��B�2GdG��n���Wc��t߬,���!(��g��	6Z#u����j��ˎT4�3�h��L�R�!ݖ�H�-�cZ�,ߚ/��b�L���U��b���mQ$֦©�N�D��`�Ԙ�
zH�cmN 4�*Ȍ�H��F��ɸ��.,w&��fANO�
,K�r��4K p��Ds��z�i�:9�����;�����d4�\�%�-]E|Uq������#ϳQ�Hd�̭HYҁj-P�U��1#�X��F��{���pj|˭'C��5�.2��b0�"�i9�����='�A�d$�9��V9�}^�d����t`�O<"���J���!�m��WZ�l?��*�"�Yu���|�x\���V:`��ȿT��-�#i�B�t%
�b-�6�!M����Ɠ�ev���¦��~�3�Zx`�J\�uc5�7��.<���iu����!�
v��q,.�p0e�l�d�z�pɞzz%Y�+v�sђ�Ɗd"v�Gu(V�I��BlF o{�e�U�J�&:��E��KʓaP�J��?�9b �����:{آ��m��S������n b)lP���x_¼41��j22��M�n������2G�4p��I�c�5��i"�f��e�;�x�������R(��q�%Q�w�c��&�#�EU"����O�|�J:��ٜ��J-�s������<Za��Q[+�6B<|жY��_�#mk�w��I�j?v�^7=�׿=�n��
ζ��v��U��~_⵻R����Q��<W����jz&�HC�O��T���G�����;-l�jvz�ud�[NU�����Ж'2�#����bg9-�Fp�si뫝��<�肾&��#kא����i:�H�</'�+��-β�D��,���_��(g�Ɗ���:���ꯙ64 �~�1-,C�%����!o���O#.Y%�qVf���'��Q#w�'���W�j��/i#*��`�K{�P�8���B=D�IS���a�����;g��~��8�Wg�l��m�Zn��4�
�ҿ�O*(�8l:�W�b�������UY�ì��ޣo�$(S�T��!W���c�vM>#�z����:'e� 7���]���<�;CN�Hժ�S&�-��$g����Qhd�1��z��n�^u�"s?�k�{�{�瞔>�So3L*��,\S�kR����'#)f���p,��׀����5n�v�� �6&�O/��",q���|��.���    SE�9Z?�#�����i^*s��eo�wu�؝�e� ������:��e.g�K���[+si,�ބ� ��s�j��0��s�s�P����lB��T�%2�O��I�bl�}a(�Z�;����ܹ�o�ה��G!8ה�׮�*+� Si���-
�3]��d�{LDR��IN����G�oEԤ$���?)M3��e`޹C]���PkѾD��W6ث����:�C���)]�����9��%Hf�<l�n�OV��6ծy˝x�L)Hp�K��J�� �I�Df��ܩ�yq��,�orN�w��.o_��Vڥ�փ��	W��t�f4�J���H��·�<GD�	W��Ɲ���˥bw�f|��{�5I�+w�n�|��7��E���[ܞ��L�*H1�~���B�Q���T�~!��
r� ���z�W�?�����w}}��HCB\N<�?Y�a���S�I���'ee���t��e�AA��=�����凷� g'������V�:�S�	WTZ}H�����=Vc2n�С��x�� ���$ݦ��x�.��0��bg��ce�Z˭�#�[K�-Q
F��x�e�W�@Ї��o��X��T�k-��R�b@}�/3Va���I� ƒUxs�g��-�
a ��k6�lu���Nt	�)�:ߐ\����r������|~�1��S'��_�$q����O%*!yY��E�޳�Uc0JJ[�]I��;���=q=����u@��9��}�yE+:�X|�gTޢ�X��]8�D6��5����*���>*#��p�יq��h��08��nW�Ch_���+I�zs�gܱRG����D!:kƳL�9 �`p�k�(8�U�����*��SMT�ё]jټC������ �8�!n�1~I}{ZA9I�D�d�����t��G�0sN������1�k��-eF����3�o���ъr��+��[e..��w���7���+���K7�a�G1DC���8'���~�/��ҙ�%�0T�O\�90�(�`<�	�슮n�3mg{3H�JGAv�b���|6&�x<��XmQj]��z����:;M�,�q�6B�a|�̭C�V�~�:�t	�ߌ���e����������F@1=Y��a̇���(
�l���y�o��~Wi幘�]�	'"���uy���A�'/�|��9^̫aB�ӺĔ�:ԺM�x�<ULY�w����Ց�od�(<0e�4/5��H�|D2���fo���Œ�5]��+R�[m<3�q(�Np���C�0�ꐾh_��v��k�����J<0McTI��$��Sz��e���SA�K�30��1Wz�@m�-�*�!�dO�1l��}u=�Gт�+Y��q�� �̕NEJ-˧��
�H�zG���+S�w�k��R������1��"p�,ٶ4����g���0���Td�5� m���ba/H����П
�^j�h�����dᢊ6�i�aX���6��1t�����פX�1H�{3=�A]��RfRʴS����]H$I�o��?cA��T2�@�� /.AU�|0
a�1����2��Ktb�n����)����ip���*�<!iQ���'������OY�#�sLm�f$dh�-6����
�T�i�����-am�Il*	�HT��*�[����sH��U�(����I+��Lڌ���r�D�%��l�{%��}jU�G�g���A�GD�h��ʷ� ��,GE��2��Λk�z�Sl�E���DD��E��W�e�a^�՗���v���+�Ԏ�rX��O>�IU�Em�LK�҉�<��HK���	�v���V��oq��{��f��r8���h�+�Mt���(`�`�����i�������jV����jHz7��{�$gb}_�]�w�������1��2�����+�8�P(H[�kL��-z��<��%]Hcބ�J�Z��`9��©�3�o|R����L�Y�Mxe^������TZ���L��;�v�6Dd�v��c�D�b������"Q@��s�f����1M2�i��A.��HQ�@,��A
k�ė-Ն5�[a��Q$Z�5�"�:�qW��+�a��Ϥ���O4�me�,V|Xf-�%��,v�7�<��s�>�RZ�����_��!��We�0f"������Q@e�Z��t㆜��C9���K�w���f8B�)��ME8�Y[L#ٹ���ԫ ���y�c���0�Op��)���Fd�?'��L��m� `���|YQF0H|����X�ԧ���ӟ�j�<qXS7����T[3��0�4}*T��BRј�&��ψ,-�@0�=w��߀���bSg�����y�œ,�q���4��0��5� I
�c>.��土��wW�j���=�]w�u>ɸ�{�/����^s�d��x��sQ�qօf-���aM��u�r�nT}�!��y�*�x��Ԗ�yTU T����to�U��kI"�hh�/���Q���Tм�����3紈�
�&#Ba->}v7��Z:�SĘ�k�L��8��wAI�������kf�GZ��,f���}�i��j�?z樂�'��)���鍚�+�xj}�GK�����M��N�c�k=R~�C �I�C���p��3tu��ҐT�r�Z�h�� O��?TF��{��`|�BC��d��ݰ�QFǔ&�YX;K�=�X�E~0
�]�y�Yn۸��uXh{{����7�/����⬭�gc�[��A۷��A���W
���O��f)��������c����s�A9\;84CP��:^�$�i�`Y��6>�2Gt���u�aN�2���^�0�=6[�~Gr�V��p�g�/��4t��OK��je�Z�M�I�Y2��t�[�\�T���1�!`�q���U_���tb�8�J�//�q<q�.y�M�_oZ��^�$Ej'�
D��b���(]�J���V�P�t�+�����+݂Ȃ@�B� =�Kܖ����ܛ�hE��i��G�K�K�'T���!�E�����c�H?�J�K��3�WT���*��=�:���@�d7pPe����U�Ҽ������p;F��-���U	R�+�����c����<!���P�� �B�╪	4�5c�/X�� 2��� 
1��Ep�����\~��x� ��x�N�MX+r�/%&PM��i3 ��s~�,�@�4��&�B���&��^�`AM���u�p5��pLmzƽmɚߍ���uL�횝�UE�E�] 5�I�R��ϘeMe[.��}Ǎ<ũ  7G��m�hAp���P1},�T��6Q%���3�4�� ��o7�r�|z�<�Ş�ӟ�U_���%��G~���ԛ��_W��IFd��3y��)�Ok�1`~Ioغ��˚,>qa�3y�����$�μi)N���'�R�Fʷ��p��Z�Ay�*!
@cx.{���<&m�@�?����j�����O�Ra9�`#��-)�]�;�}Ť�����՚���9@�'jNK�
����jJ*��MG{&*e�Rl`���xL�g6)��ۿb��;g��K5^�g�8Z5�SE�Һ��M&i��6�!1	�I��+Xk���:/
5Jy�N�L%�	� ��@�v3G]��X�pP��t�����8����e�՛bQ��OPj��x4�j��g�4�㙾C��Vre.�1Pe�[��)z��Ī��IaM��y�o� ����)����0��	S����N���А8����"�FQI���^����*\ �	�
}-�{+�w�
�
3�%���Y����FK����*�YR�)Fߒ��z���Q)�}�ɥ6�-~�����8�)��)��s@ m��E40�t�iL�<E�����]_{HLr)�q1X�5��`IH*�����C!���S�ٝZLJ�+�N�1[�j0���0:�`]+O�6�H�	3�)�(g}���"s��A�:"�h��oX�H�9�~SQ!�`dJ���N>�������_.3�Z��8d��	����^�K\ts#ik���I��l�ߩ�p�l6�[�2cO1��_�Tن�-bp��0$    М�)k�-+��Q8�g��Fz���i`�GZ�KjG���*Q�����֠�t�H�0|��as���aC��۩Iu�Cf�|���F�+{H�F:�ގ����*��}r�I�@W+��v�t�N�|���t�4��T���=z��H�E���o���0�{RU�������7�y�>�]:D�%����C�D�+�㳊dQ�Q�5��yŲ%͞��W>��Y�-��i���&�5FT�k>!"�t	x��CZ���Ʌ,O��"R6�4*�c�,4*�.:Eʌ���(���2_i}��}� �0^f`5;��m>���t��n6ف���n`�ӳ�8�W	������Pѿ��_�C7lz��;\ӁcD4+�0�<�Z�+L��*���{�ꈼ�A�uG5��P�{Q�a �^�w8�/�v;��MYDm=����͍�!,;n�/�����ᒚu�y$�dL}����&C��t�q:́���|W�4�q�֦�l����V[S�:��ϔ	�~�o'����'�=����	#kI�E*a15��a-5�̞f�Z��9XN�k�\�_�=�c�t�@���3�L�Tҧ|�|�"`�t��"R�f�y�bmt��+�T�K)�^�,��ܦ}4��	h�xSE-y�ߤ�#p���������yܱ������`��g|���B��9�誘?�_r�!�b���X�Sf����Y�dl"(�`p���aŊ04Qf�e��r��M�ach"*5P3.�FD͸��z�ް.� �+�\�Rto|�蛚���13H� K ��S���B�S,D��"�'1W����c�A�wa�"�����3�B�%cN4�:�N�� ��V����'�.��F��M�����!�rM�F�+md���2L�;��4�8�l�"2S�X�q�ؚ�R��2_%O����+�bmeY�S�����)��m�����X�Vn;y�N0��m�߁�/�{�Oϐ�g���\tZpqNC��Z���v��3'%��*>�O���*�V���q�<��::XGZ�!0�A�B���Π��fב�P#]��=		I��d%tBb8��oo�Z�q�,��_��=�5�DK_��A�f�k���U�H���S��8ata�0K�i�1���]���Ө�;���3���"�Ma��0��gH�W\b`��t��N#�����Y-+�_�sS`�!�X�/XS򖀒���D�K��q��9K�fCͤ��le�6�-j��YJ���g^�h�.�I�t\�,���}�Ckl��;t}�I�?�<��m�bz�o���l��4�I��:B9q��v��%���Y���OlG�4X�5_�U.56뺄�d���߻$O�%wr��<�[<����8��,�0��G�
���eܠbg��۳1�1f:��%������[I2#�� �,Wl+(�,�<7�ǥQ�`z6e�����(����[Lβ0����������7�ѐ�ww���q���IAd�2z�5���޼ �w�<2Z��ߌ`�$x�U�oi^����G�$�e��%I����"<�� �8$;\��A��d_��#�o�����6s�A��8��:�;q�nj	o�7!�ѫ`pB��Ӳ$�Q?�6�j4p&��b�f����T������C��z.h�i>ɎĨ{�6���X�eU[X����P0$ْ<� .��h�G��D�mm���G�q�I�9��m]'��8s��(����1��tĕ(��S�@��{��F��>���ݔɻ0��`�S���d!i����.*��h0zú�'�s���BEYϸ=��Λ)AR#��gZCIddh`�$ƺC.#�(2eZ�W�<&O�6>�Sؙ%Y�X�Ay>l��ht�22�����AZ������������LmV�B}��;�
�ЌxB�A� �f%�2�*,"[�D�G�4�Ї����1.R��>�L��A���<"Ɏ�S؍7�$��/��*���Fu�>�qV�������Mi��(*�佫�YtY��7U2X�U�K[)��'=�$��}9&�iI���&�Ȃe��'Qsy��"���X|,?���J&�ϧ�*�6���9>���	$5��8�V����*��� kX��Es�����ޢ���}�~lN��>1| �_��z�<��d*�<;2w�SW6�g�&P[�q�.��XD{O\9r���$h^�؉��b��Z-�(;�;Z�qL��3\6���_�k����gY�=&��@;k�la��\Oy��vF�FS�2��=�fCC�PиBki4��ɐ�9]�c7��44�aMݠy3�T;M����y��6���ʘ@L��qv\x{�n�U��z����������|Q*�X~����N�Y���f٭H�5Z���;�r�kt�6	`�d��6�dZV$�z���lc,{9���|$6#�b���'?�� T��i��
���|� 4�d
U��e���Lh�>��+k� .�"������c�t*��ނ�1�$#E{����/�����at��"s�:��P�}j͢U*�Oy�eR��
��`/XE�`���
��ߗDT���HA�fΝ�Ttq�6�5�D+�=Y�\���D�5��^��/Kj��%NDe��wI֓���e|���2�bQ�W���E���,'��a �qLEB�����tD����L�~��s���&�E�>�3�����G�?��!΀�=�#���:�oUA1�O����P�-a(�M��$=h)Q�h�P���F6`��r��`r���B,�#s~x� N�F��*��a���1l��O�1L�a2�y?�itؐ�E�ߛ9;ޒ��c���l�����UqE�w�`�$�{\�g�'Y3P����Էٵ�I�"F��d<�Pv�����e�3��*���dJ�vvg򻁌�>�ސ���o-FH���$N� ��7���:*M�a�*���t�״��g��)V\�nJ�٠�"h+�0�TB���Sq����ېX�>�ّJ�3t�3����5�k4��~b�Z��f㈼)H?\R�W��ztd��� ːA�ׯxO����ې"�Ude=� !
��g�r|��3�as���<\�m��q���tp���L�x����&`P
h�'#?���P�-c�X�?R��a*C
Ǝ��mJ��]��X�`1�<�D���fA���A	Q�!1q��o�M��IRX;g��'Z��N�������#	���E��K���həd�J��R9N�k`Þ�`C���|�j��tn��ہ�ߠNY��#�$�q�Juc0v^�;@����ɪGC��s��$K�|���!k
ei$�8�rb�ܰ�8�0 �9�~\�}��S�!�ʤa�����s�*�I�i�O�e�/ON����`VMW���Lb��볓%q�oD���܏)2�Z_��5�ce��iU]=�t\e܁��(�E�Z{��S��ZlO+�7��(GHE�P�2d�
6u�N���H� C�P�<�0��pQH��F�q?�^�i�ރ��H��ǘ��>hP\���5�/��jZ�p0j�q�vJ�rH��r��!�:iG4d���R�0ѻY�S$4�:�38-[j�A��Ɨ�[L"�i⢃�@cr)�J�>7���H��g=\  ��!�����*�b�s��3�.S<�V,`�5�4����"��C��O�=v%Z��z��̿�U n^��*J��N^�8:��"��F�S����a0�� ϩ�I�r�����I˞5�դ���'p�і�}R�-^�1l&��SzF�A����I�����4V*ӽ�֤(<M*��<�����T0P�r�(�@�ͽ[&���{�[� ʅڈӶS�M���bL<b2T�+����{��Jk�5iZ|����5@ML�d�&�j���ß�Ω�.�%��αA)�I��qצ�9-CZh���$���Vװ�7v�|�Ժ|� @]���SyQ>��;��MPh�m�b��l�R�Z#���H��7%���� �gj�������}�b�4���~́���Sƭ#_�3���g��2M2;Y�V,������3Y�J�"C���2��R��    J�
k���:�/o�ӸbA ���s�� ҂̷�I�YIgⷫ}ʰ±���z
e2R����ӽ�a�̗}z	��/�5޴e�>h&�Z��*��"&p64�bo��Z�rsD�L�� �ܙ;����	��,���V�$5�X�]�6V�$�����Y�$Ĵ�7��ߎ}�o���⊯0�R%W�t�|�d�A��w��c���i'��}�=����K�sIXi_�t�&��Z�!䷰���n ��!��ި5��`�rk*	[��qkzطr�l�x����,_�5���>�i�A����������1�Z����8�P��6N�e�G��>=0W�X
�.F��Č;6��C�!�'��w��\7*�������]��P@�B@��\��3g`�E5�,c��2B�ϱŖdZb�{(M%��;�ѐ�2��Q8��.�Jk��q����9��%ٕX���*�'_��h�����G}��>����:���b?��.��$���5K�3��dJ�21���N:2��%��(��X�˦#x���Ď=,4�Ū��H+������ª�k��J�I�&Y�O���dI�#�s\	�6Y�FT����7#a�"\e�)kQ:���Y��I��E�&��^Xj�	�⤂���
o/#*�fD,�C<��=]X4·��lN@���Ꮅ�/L!���)���q@�b%f�i}L��:�81���cn��$s
|��*4!Vd.�]�KV|=e��C�䉒M_���|��x��R�W����:-W�`,���4]u���̒O��
"��UU/�_3���WX�� $���w�{�
jz\@2��N(�/�������{W�z��,�|{���FX�-�Ր����t`5��g"#T&�dIZ�i=m}%Y�������S��>����}@��?��7���-��K�2�@�c�b�I;��*ަ\k3W��ے�P�,�d�����(&�T��tPVڑ�iw�ZcА��r����#��5���P�i���^�)� ]8KR=�(��h��Z�D�
���`*'Y��́�_�TP�UKT6(�aE�AK�ĸ=�4(�6�/��/��$_c�M�@~�ofk�����>O��t%��(�N'є����R�0���/��YQuGey>��px�B�l������w
pC`��L|a��7<�%ɩ��Ϡ�9U�@%=�/���li����x߁��C���^�gRi�3����qx$(����Jr*��.KZ*E}k"��q;ļ0����\��+{������į����W�^���qcRH������Gi���q0�\�Ǝq|�X��y�����y�Du�4X�W���� ��b"����u�v��F�`�^�y��C@<��}���MA$�L�ԏ�L	;���!�����'���zƇE����W<-�d���0E��4�����L���;*m��as��lAXM�$I�}�05���!�9F6HSnp̾#�Ƴ�j?#he�����4����'�wN����.8��4HN��W(4���7(<�,�l�9dV�PK#�p�%�,��]����5�#;���R̒Z��%�P֚���}DΤ��V������b F����{��,q�W��\4��
U;}�K:$D8���11��R�]6�K��҇_�1 �ڲ��Sz�����[n-�l���'3o^�W�B��k?T�~�4�A?"i�5�O�qU3���N�@�z��q�ۺ�$��̫�kM3���ZsQz��;�� C��I�3���ɑP�=s�~jR����+6��!]�b����R�\n�5:�aN�xӸk�Q6^W&�Ƅ�q�" K1ܖ�+���c��j�M6]AF��K�7!�߰aߞ��4�3����@{i�6�0�H;Yb#D�_?�l����kIȨ?��s��j+�&��g�B\ ���gMv��/��f�!���p��9^��EB�����w��Zܶ^��<���f��*]�A�6�Ve~��͵jam~�^����JƎ�ɑ�%��5�@`�!aN����]��'�P�����l��ľKȰ���
kd��2磪��o��j��3o���#9���ӊ���L+��#����i�Hc�s���D�z�kO�`�7�a1�'��-)!�e�0�Y����Ū�I�1VJ�@�@�4H�V�H��c�^.�����\<!C��r}�i�����-&`_�U쪇uz^1x�szK����?�t�'i�J;Ȋ$1�,OK|���F8|�i��K��*�d�ؘ�ȁ�c��Vȡ�����U|h���q�,�����(x���h�-������Ȧ/�+�$4$��0y�9sj���j�5�MEt��X�k2�^p�x���D�^����Λ��a�.i,)2;h�ɍ*�tχEMT��1���ɟFq��y+&|R�|i&��z�њ4�T`�'!�*P+�kh�.����"k�'l:�5�2�V�:�a����E�Ɲ��2�^P�%��u�\\��`q��L��:t��,�H�$Ɂa̮��l��̰��[ d��Pgb��I�zY�c L�]B��I�*��k	GmM�NZ�\�&�,�n��>L�}a�e987xqQ�MU�qQ�KUу��4�	6N��d�Y&���I�J�C��CP��#�˺b�-пa�ԕf�2N�;��=,�VONdF6�&�VٷM���Uz��#�y+��R���\:�ɵG�d�g&�U���FQ�I�z.%jP<�E����U�V��C�Rz�5����\��P�תv�n�R��Sah��N�e$Ѧ0κ�D��r�&�VO�	�DG��)7�j��Z*�c
͠&1�f�"�8�?�Y�Z�B!h����$_ES�o�+k��.�S�(���+�nxCN��r����g��d����XG�{K��C(k��B��"���p;Bd�n��F���~�uox�l��6g�W����?�̦&9,�̻[��j�ߏ?:�E�۾��������O�؛蜙�&I,� �Vl��:�2�8\�5�a��@�#��5��rZ�1��`oc�P�� ��=I���4�y�.դ�e���db-��}L%��C�l�u�Y3$�E�E��,r �?�s���|��#��a�qq��l�)u�e���$�pT˰9����"�kM��̼�c��ս�e��jq���vϚl��oPgy�c���]cE������bm��-�f�����e�2���x���ߐb������U�z(�Az{BY�qH/^��_{�-{}y���&i���%]-_�ߘ�C�W��St� _���pKK�"�A�Lrm(9�[,�x~�u?�Q<;8��o$oϬ7��'��"���+zv�*��L��@�r�N45&�{�m�%� �؇
Wl*<���lV������?�h�L�I*�t5��N�I���w��,g�S�����7�����[6�p�y6GSp]DY��y�q�ģ^:r�|��O��5]���ų��>D�L9��6�倓�J.����7M�L/_�,�¸�s(#��A��ck�҈�7;zS&J��ŵ�� �暉���YSr�4<t�l)s�)�`&�ESr�����#Gv<a�u1��qNt�#��
�Q��Y�]�2��ߺ��1|��7���
(����ESaR�tЋ笩�x��c(0K6c���	p �9��.��)���e� �3b�@RL)�z�ؐMM6��p���v�@�5.W�@u4c�4��;h �kZmj���>F+b�0IFfi��ͮ�TL�z�&f5� J��jeL�F�%jiLJ��]��kc2`��fG�<y�i
�7,/��^��Ac���A�(���!E_��n���4�=؍lS�ݼi:�q��7������_�����|��/��R�o�y;uZ��ঢ়~>Lc��7-�YDх&-��MQ��D����}�#6������+���zR5�[s��-8lܥ��k��¡���g�ϠQE.*�F+\Д[��<w�����-Ԝ��!MW�~��s�qk<tU9��]l�����E��5��R�P���M��x�>��t���tmPb|��"l�u?�~�Q�t��e��yN����D	8�3    #Q��e���,������N�ʮ�l����$_��M�W�W���GpM��kqyl���bK� j�ɲGMM�M���M�m�_�xHv�o�_i?�[7���*ol5�E.�؅E�!X��l�=���L+Ë��dL�4�K�|���U�S�[$t7C�²��%kZ�6XV\�ok��6C�2Z�d�Ӛ���a��"&RYO>�&"�i����VMkf˲ ?ڝ�9e�2!?Zը5��#6M6Ǖ-k��h�� K����B���I�������Z�fm��|�X��St�s�MU��#�|2�
����B��E��aCb��,W�m��]��osj��@lY�dK�g��8j�а��ٸpe,3���ղ������&����w����a��N-�ha�>�ba��9.�Y�f�y�K[�Vk'k���b0������X(w?�|���-�����pE������9��R�ek�2��Ж�n+L[mY[��,�W��ͅ���x��ݖ�.��2.s:d6 ���eMn���*Nפ"�e��^a��ݖ��&�-�e�{fK~[�6(��ɵ��>�r�J�����[$�X�����E^�ݕ�Ikȸ�i6BVDQY�{���?bwo��f#v�ê2���=��d[U�-T��Vut�J��U[5�~#�ʂwڪ��|L�-�L�l��:�˩;�۴ȪU�����O:n"�zg�kRY��ڶ.�]�]1����z\����/,&�]���3��⹁�D����LU��7���ɯ��@�X�m0��3=tk��i����ug���ω������pj�a����w��S�I?�o�FC�0�mh��IҞ�ˬ�3��m�\h����X�m�ˌK�?�qy�(��,�c �D)��:=�}6�`�
x��Of�0p�)c�|���K�9G˂8.�"."��8�ټi���,�����f���E���	L�&�4#y
��m��d�wrd�	B�'�|�m�-Kk['CS����i�M��qͶh��q޵���èe]� q����-���Xl����kRp��8� �߼[X�>�<w�eM&���=Y�Kj˪8Zm�6e�4-K�.�jY��n����X��~޼
���z�ti�y����Z�}|#�~�d[��Q�6G��R��IV�1z��kc��8���*-���?Z�{�n�$��5qd�XD��Uȣ�C�[�y�����o�ˁ_	�㩞ah���ܲ,�=�aYY���p�?�V��ˤ�8U���E���C���7d����)�R9�U�9�mY+G�K�$ݲR���er�v��:��Ds{���(V���Q��P~��q��.9c;�Y��&u�{M��h@y��u�?H��9 �K���%�ˠ��s�[e�;&ȏ�P��p���ľ����x���}���EzR�9_^v�ڱ�E��c����*֔��ŗ�]��xٳ��R�XS�=���c�o�t=R2n�j;��mj�|fP���'B���~|��[�fGn�Ҏ5u �ӷcM���c���q۱��7,�����k��hnC#;��It�=�-��Ȩ����J*��Rَ����v��R��٠SD����s�M��hN?�
H�w=|��S�\z7�T�5�5�*D��' |�����5Z��"�I�H"�]qVWtֈ�-
-��a�R�N̘�� G�#N��`���,�|�M��k�J�2f����*�ɠ)�ȵ #D��k��a5��{%%x����j2��E25�Š�����B�ir���f:�J᜚��f���pH�Hr�v��Y�������'oPi�EjM����M�JN��P�U�4zޠ�Ҍ��)��� \X�vF2��f9X��b�'9�_���^0@!��j����x;L����F_̳F�Ą��͌jF��V����҇g0I�1�*-���=��ZYC���Y���E��k�	���[u�R��3��"mU��S3_X�P���,le%��E�0&q�7 S����t�����?�!Mm���RA����0�`iG�qAx��{��3����z��������eX�혍Qf����qJn��Z�� ��A��n���s�/W�{{�=۶��Bu��㉥L�����4�
X���J�����)�JDO_@}I`�&m�`ن�A
cQ���|Aݴk�����4�,�r��ddh�*���4&����������=X	��&S��p���]!���E��+V6$�<P�[�2:��~�KsҤ�-������֛e7�+M��>��	���l)�vџ$jK�Om��㸈� ]�Rˑ{�IDF\�W5�,�TNA$Һ�$֔�Шۉ/���8ǧ��wT)Q�L'�z<*��W�c�D�Z��Gߛ������픸���A���wlD��>7��""I�2������܈�q�c#Qh��zl�d�J\fMFMAZʒ��$9$T���շ�<P7^��ı]K�C�z��(=t�[0*Glj
?�yR9b�$�i���:�L+A�Q(�b"���������c�tL�D	hg4{����|� 1q#Nu�[E�J05ًo�vK`h��/a=��	"�B�s�'�H�&Y	`Q�i;���;l��o1��I��я�Rc	�~E�*�Z��F»dZ=���ޝB&��[<��"�Aѱ��H;^э�9Y���>��.�D��B	�F/:�#�!%��$����;��>(a���A�������{A�}~=ʓF����^d��m��q�w���״�J��ھ��a�"�TE��L_���<��%Wީ�5�\Q�sE[%����:P������;�zd}��'�c�V��n�7��B���p����%��υV,����E�ˢ�����?��ӓiG_
�b���P,7�A�U�Z[.�'=��+��~ʥ���i�lX�(�W#h���i~.uO67����
&(H��/��X��'Nj=���~����v]�G����ß��V�����nkγc�zf��'��
�<��>��!����-�s$��$s��Yv��`�v��zS �<G�pboH����Hq� ~*ܔ2�9[��~��vL'�ِl��H��E��ߴ"�xa�`��%} ��Uh	�T��S��"���,}D#1����r�6.vZ���{mX�)����y]��Z�9�&�"�
K3N�m�$02�ӕE���h�!�&h�|{�9ϗp�%A$��=B�v�x�ǥ'������'%_!X�L����@-�o�W��LcQ@��u��4	"_�l�����?Х]}/�A���F��?q}5��0J����Ѡ�
�#C�Q��8����V�6�dz��6�b�=�oR9�RD�1�@��"�+H'�K�j6=/fy�tX������'7�2$2R��L �B�b*ԢɁL��Es��O�-��V�t�[�,qfd��E�u�����Z��!�eO����t��W<��e8���Q�����t�ݶ��-��mzL�K�՗ҟf�$e'�����,�n�����*BU�!�e���CRA4�q @Of:��W��`�L��<C���g�C���t#��ĺϟ��T��?����5��R'i��O깦�v�C�5I��A�Qj�� (�.���Zڊ�DzN���.%�|�H��T��>{3�Kjuym�r���*�Y�FE7��$i|=���״�o��kQ���=��k|�dР &��Ʈ�i0�^v�{N�a����&b�+���@b��QE��cN||��������__�h��7�L^�F���TU��Oh�I�,��Os�$�o���!���tO�����{�H�$&l
Q�vz���f��,d��&���lYE0j�N�f?)'�UԘP(��^vCF��N��?����*��H�]0ީ�����7��Tg~�����MX����ط:)���ǏG�B`֐0&!� �DyT�ų�Wtb2<�C�fg�QE9v4z�j�a��DH�FT�U[PF�iE�}���U���ZU�+z51Y���%��,eH��@�i~ۢ���dT��,�B��~U�j��SU�ȁ��kF@*    �Ʒ�cs���,�3�j��CĂ�f�o-�ʏ$��Rzp����=aO��HXh"d���L���!��^/���8��8e��gK�%��v�]ɒH�`��eQ�N>��jYR}��ژ�c���]��S�E��y-�,2�OLn����~���-�	h��3U��}����'|�Z����`l����ͻߊ>I�<AP
�.�yN獼�yy�f��
J��LjV�V�W���[�\]�q�"�����˩��T����@�@TY}�5�@TXݦG���+�΂PEC��*�$���P�Bӝ	�I��-���=�Ʀ'��U�Ji�Z�]�H	�W�N����W���0���^�9}R���H�"��/~���/�d��NN.��O1*:e���ء�����tY ��r]�E�W��O��;�y�ʒ��QUHy<_s�AF1?mL�@���H*���a�zo%i�)��#ZD�Mɏ�?c7�i��7���J)�+�,F�W2��п5�C�ZQZ���~�M;(�� Ӻ�؞���Je��J��a�`������/�M�������t�F}̯-k]i�qYNsz������gx}���B�V֘��QP��%��t�,mכ"���q����瓊y*D�'��ܽ��|��?Y�>�����3�9	��:z9|�;�#��~��k�����'��]R?���$����@ݾ�֔�M������ɟG��*b��n�'�NB$���ɇ*4vZҴ���v_i��3�i���ѳ���`�h����;TO�o��w=VM#&*��J�ρjz2�P���k�2�T�C�"T�XA�Dx���B����!Sm-��zy��BM+'@H#��NN"
�ET�~����rێ?�5휖>����tsZ�rk UR�܏B���o5�'�F��{چ�����5�5-��D��@~V��Tg�,5->&����N�e�4h����hWB���(W�����fʴ0w٫�&M��W.�t5}�\,S�`+l_~R���==_�3)o��)ժ��ߵZER�{^�H�ݲu�
�w� �F�Q�٠Ct��W�Q��4S��HMy��Q��ג~���7X7���k�&�nD�xލ����ֈ�=�VP�쾶������ha>�4J�IѨ�������~KR\�[�w����͵$�)��F8}tO��Z/Fj�^��ӭi���AäOI	�ϗ�I�0���@�������: S�[P)�r_��i�7��=�4�ŏ���x�!���z��V5'��[�f��s���ձ[G���1?}�d{����}��(�)sW������m�.�Ԥw���z�O���O�����y�󞚶F^�N�nF�KM+�Iv�7�R\��-@�M�WEj�](b���)�e��C�QEh7n��KH[�4���/S�t!�l0!Nbu�^B�"D/�k�ůi%lK_�d���1U����AX P
��������{t���	�zЅ��	킮�X-B���Xr��v�(1.E�I� ����iD����8Hؓ%ވ��j]'o�h������.AX:%OAa.��P�T��Ζ$���	���.����_:�2�
vhЊ�QCR0��lES��ĿeJy"�\/�Q�S�l ؐ|]Oޫ6�C֚K�L��)�P6kmH&��6���<$�3ٿq~s�4�5}L>H���N(1ˆSM�-��❂��\p�����t]�ݛ��i�RT�z�X�Ӗr�%4��"���&5��0ɼ��E��.�nY��8�b�\^rB�M5~A�uKB���J��p�!�W�	���|^����P-�V��ԓ_s_�]���-]�P��k:��1�6����yʆ`�A�beۓL,O-5��
��T>k���O�8�^��#E�)��G���-B�'5�鹌�"��0ZQrR3�h��)�m��Ac?��?,�s��lWOr�ڏ��o��E[�����D��x��!�v}ٴ�s"i_���3�~�t󝢽\�_�c���{�:�2�"u�����I��Pң@L�|����)����(>~����"("�y��c�˺ˆ�<��r��x\���:3\�[:�^���7���K;M�Ž���}z�P%T4�f�&D��Sc�Bv��!��K�����������w��-��$3��T{sΤ�I��o�y~ܲ���N;�/��;�-��f:��-�4�!�ò��n!���ˤi�2��_Vv'!��ͷ�8n+*|{t��BA����虋e��ݰ��;{�۸�@T���m�����\��y�A���W�^7���������������A�"haC+�544��E�T��&�l�#оF�cU�d�k�o�(�*x_�+��͝#����撖6���}CS����m�䗍hes���(r��ml�k��P -�k(�g���=�}wA��Pڑ0*����K�C�����Z`c�޳$lK��2��Q?qZ����+��m�I�� �Nx�	�v�����'v-Mk(��})-}k�`�;Z�0��7-m��-������I��X��x�>Sjio��M���l�R��*�,�f�BQd�}"���g�}�����f2}��OQ�S��7xy
����c���4QX ��і�7�c!�f#��&8�e���˧�8�pb���t��|=|�^��YF����j�4��r~��wKߛ�"J	U� ���#�N��Z�j�<��m��D�&����>:�탿?��I�ԠC�Dq��A�[�87-ub�r����9�iKۜ�M��9F{6d�T*.h���#��N�c��*�������\�}�iv�#�D�h�#�}����H���:ϔ5k�C w`$�ʥ�0�A�O.W�ۮ���J�}D�[�6��E�ZI�U�"��`�!��Zz�!i�M甿iC��.�v��$�1��mg�b%��LCl���g& fb�Xf�J�$t�M��Y��4�|��/�ڭ�Z�h����e��׏�Z6�n�ί������ɆM�z���c��@}�2����g[m�1�w_A_%BI��u�çzQ��~�o�\����*�)�֯O�芧��D�+��e�ίV�fH�͏c� �e��H���v�rK��?�L����_�?��ԕ���p�)*���Q���8f�n��i��o�r���ML���$���)k���?(!�/{0=LFa�$����7��L�K���j�ĭ�RGZ�M=w��j/����"�����2Nv�AЎ&����K )`i���K�A��R�2���ה�iiƓW�xٓ��N��$m�%M�혴�T��KQ$^�e�
Q��^0�_iG�˲����p�� �bG+����b�M�ǵk ��ĵ�L7��l��r���m�ބ��ji�x7&���k�}�����X��	_�xWF�	S�bm��?D�,�e���%eW�Z���ꠗ��SK7�Hk�������&�Y�o��w?��2	&\��wթ8�����R�����[`y%��� S`v3$F|zX irF�%"�+��O�C>�ǚ楁�������v����2��v���������)~��U��9��rGֈm~���D�|5����?F�%�h��<Y���J��,�X���V4Ҥҷiyr����	�X�@�L������J��Y�(X�Y����-�Ս
�á�|q=(A!� ���%����&,i|a��_jV�����B3��ar�6�z����@�F���h��՗�*�8�M�@�f%� g���"����E��xq��>ؑ�"�:;�)�Z�Ujn���P��Ҳ�%��o�Bm�e��
���mΒ�+�2�&����{e��n�S̆7�s>=�Xѷ�~�`�+�J����w{��}`��@K��Ψ
�N/>�_��.��ii�%K�̛.E*5�P RhA0�!��Z�.�v�ݵ�G���!�<��>%��o@��"��)U4e&�8�e�e�4���0���֦i�.9_��O���D�\6�p�%�,�����9�ʖ��s0���p]�doXχmzk+",�;?�j��T0�W�:4 {�,�r�    |�=,�D�U�%�mQs]��`-&u喽�(b����g��K���3�">�2
D�Tl@f?�
Zt�0��5@k���#P�06��E��O���?����Y金jv=dTq=<>N��$U|-��K����igZݷ�Mp0��8jL���+��O��b�j�^sl��
�-�¿g|+?l�$`�͏H�k���D� 5h(3�%d]�t��y�b�T�=reu�r�������@á�'YQ� �[�F�U�Je���Y��:�I{�&�!��W2�mB��S�׼�S��XBub�_���P(uB�X��"Z��p]�e]ŏV��_w��Uj���o�61���S�ʙw��z�Y2��~��J���b���>��OFډ���R?t��:H��1}���yi��N[,yْ��%Fޚ��N�6A��4�xu03���q���K���	�y� _������aɐ)��NHq�*Z�f��y]�����(��H��x�A�c�m��6�o��M�B$P��8�R�9��Ѵ��FUY�KRw�5F�[��8��Mj��;�u�����J�V`,C���G(��Y��~���,��0$>bs��n
iv�K��//9vRZ�eU�z�
�:�I�}���BdS\*�n��"�B�:��ŵJ��äL�qd�R1�S��έ����QmiuI.K�fB���3a�/RD<BV�T>�.0�~�G�G�^�ܙY����.
�H��7Ņ�2)�gȂ�MJg#���~��]��?���myLgӃ^�B�E�%�꤯E�r-:�BJ'J�`_P\F���$���gF�`V���+}�=��S�u�}����ŉ�0�7����|L2����z�����o���ӟ�����>}S,��(f���m��@�Y�}���ݢ�uz_�_�A�j|ң��O�w���y�^H�T�h�ȋԒ��;P��M#;�}��q�(���Y���)T>�Ų�C-i� rV��[v�d#>�L�_�� �벦���2�?q��R�T(E�%$S��QKx0�r,�D�\jA��d}�T
VZ�#u�
�V�s�'J*��[J>�HMn���de�}��L)��20���Y��=�d$|=�}���D^c9.�Ā�L�3-�YEz��#ۙc�R{%���crF�j�j|�Й-�^]�S#��b��7m��d7�H�\����H��.Mvg���"��� й-*��(U�?�w�>,�-�+2:iz3�w��Z�(RK=�}��W�,S7�L�g�[��W$z�iLEv'��n�܀�C���/OEv��2����F6��H�d�K
�ԩ���U�bu+���&a3F�⁒��)%&�����2EO�.Vf������*��<c��f�Q���$byM~|4��l��-$�R�vWk�O$���_~nϧ��+R/�oB�l�S��o���	&ju�T�0?2y����w�ik�|*Z^ do��5?s4�J�U��e��G�[�Mkt����p�HQ�\�"e�ő��t��~��/EZ��_���Bq�g��=U+wA-�Q��oG�b��jJ�F�=�4Ъt�f����o�rb���w����$� ��m�u_��'��?r:��m�\I�d0��Nb۷A���ƏDN@ŵ�rI��5�;#r�/����%O��-�L���"a}�{M�'�X���L�+LW?r��|(�}�=�r�ʃ�8��l�nA���B�V��J F��(JF��ns�)LvoI�a�z\i�&��Ƅ!ys�����l�Ȋ,�ۊ�o7爟�Z}�u0B���˄SE��į^��*�EoD�i{����Qc�{�Kƨp�˴�vy�ƀ�RQ��ѻ?H�+�;�C��g�k �.�ҳ���KM7��uw�CA�%t�i��z�9}�}=��85SV�����P1��HrO�{M��Nn>_� z5�?Q L1���\Ӊ�G|~�A	�$]+&&�5M���<��\e��j0�x�^�jF�7V�(hF�X��qj�k�ӛ9 o��_��t����7���,K'v�i��T��B�x�H��፹9�6h�~7�H�����h��MJ��o�7��Ѱ{3��ZP1lށZ�J1�T�����lK3'E�f�(���$ɖ���2s>��ʽ��D�*P	�����j��,�"��i�v��Z�����z��]�c����#�dT����>���V/Pӱ�@�T�D��H�?6,^�%�U��׮��u�*��x�<`���}a��xS��R�͂�¨��MM>���l��B�E@	,ɉ���h�j���>gm��s�I^,�.KE�����vN��C"6�M�&1�7t-�1�2P~D59�P ��}g�|��y�V��:��i�^�&
����WY���b���B��H�i"�*J�$���ӝ���)�{u(t�:��Ǔ��j��}s-��"�LGk�,{��u-��xB;FA��Sj�g�FT�W�}�<��i���t��?&�i`4����?|��&'�c��~�HN�r=�)�Z���4����SiL��-��-��?u��Y��w?���|�\�f�<ɛQd����m"�X���_�f��Z�fip��,w?Kf:�љ���Hkμ�ˇ�:��@�����\��7X�JI��n/n[���a��m�6�߬E�N�h�kX�����۔�ƚj�H�9�w�%���)�z��N$�\�V�����U7���`�8fGƅ����`�����o�q�4X�Xܡ�`*,�M�>�lC�D�!'�e�"
��d�}`S��bT�u����㉁F٘��%�Ϣ��R��W�������1ޞ����W��"�[+m����L�+~_�>���.Ѿs���݉SOGB�9�����yϟ~`e�ʌK-D�ń ��i!�Yni��t�kq{z席S��X2oh��<7EH7��b٫&s<6���!;�>��#䣄6v\DJ�d��#G<c�)�lV�>���Z>1v(�:���P��8�Lw��B�c2����� ���Bdn7ϛ�u��>hfϧ�k����d���*	��#|���V��i7�%�;ư�bPK^�"�t���,��D�&�b��1��WE2��/�Ŀ��b��Ԯ]���v�����c���z�N�lP0Z��w����iɡ0� e�5�����:
��L^	N��G0	J�PDoq�~r�d!��3�d!���2f���IS�T"±��%��!Ձ���q�	����#�!��HN1R�hV}3�#~
������퓄� ��B��$i��{�h�S�ǐ�j���ϡRU�$9*�H�����F@��|5HT���.�vڑ7��>��
Fq��ic�-����~JUqM_)(�}�9��㑃��7�(?mtbbx�<�,��(60�E�d[|L���J;�R�[�ʍ�ė��ڑ�b��7�3����02���;�PdY�"f��v����5�I\�.��#t]�T! &�R)Li��g��~(�TږH���1��_��J��U����:��FhS��8.��t׆Rכw��R���=�#�I�P	�h9.P�����oM#\��2 MT#�-ުj�8��O�	.�<�_tI���̆KL���T���nk�a	��3��0�0�dZ��iR��p�$"A+^Z�<�i��|yRSkM?�%�Vᑼ��t�q�e��'��e�-/+1!�s��6����G�)��R�&�`�XK���s<��!�\tXW�%Hz�@nH uf	6�c���O@P�ìD�ZS{��x @!ڧ�'������
U�oO;'&�%�3O4d&mQLMb�9������:hUp�U}�h.����1�3d].l��\F-�G�?U4ze��> �(���'�V5[ƌ<�8g51B����\�!$)G�x�q8�AMU�;j�^�ҙ�w����w�)H�6�<8��6E8�ȼ?~�g|�z�É���^�=v��ܵ�C�F��%��DE	J�N)!���q^@i(�(�Y�oy�碉���w<�ʨ��EcT��89�Z����8X��g�;�B���, �#�As z���x�8u�S�`��O    �Š��`�W�wCK)N�+9o�H~?{�<�#{�8���a0�� #�=��\����1��H���*��-�����?mU��*���(`:��BE;R*��!�PB�H�8QPB�|�|t���O��)_�UH�z����\�Sz�Y��{���r�wB�׼�q����o>/��<��@�Ao� (>Hg?�a�S�Ƴ�H��"*#_���Qf+u�-��}�,ּ�q���R��s�WT����o��H�J,��6%w�{�X�	&�q�m�����ơ���Ӓ�~�^D�=Tz�>c��C������*�����t"YJ� Ԃ�k�!,�����b��uzJ�Ŀ�e�X����Ow*i:]@�@I>�7}^VD����/�J��,8��{��ðS��@M1��غ�o��憠u�ߑ�����Cj~mmI~�Ú�>t]Z�z�v��S���*�|�/�o�|'q��^�����'��{E1$���f�(K�����d�`��X���Xˍ�#��1�^�������X_J(�m�Z�������+M� ϟ��ł��_a	rR��]P7+�@�]|'��f]�{ںѬ��+n�	����by�}6V�`�/h-��*V�����a��Y��kG	�JU��j5�F*�wJ�c� ���̢b9�}����wSq��������bͫ�9�;���g$�D��2�.��M�<@�\�H���5[��Vbՙ�}�V���mf!��p�(
�ɴb5E�-;����i�2N�ӑ��g��8MA�NW�!H��W�c��4��i�U����X�
4�}_ޙU�k�%�읂e�����{�C�Q��[��}�;�
�8���7[m.��aH蒨�b�/~�"�\I��GBK�U@[R�<�;_64��rMQ_�z��1����i4CC�1�')���F9�e��=1�լ�$]ɂ����j�(Թ^F�L��ELi#�zԵ��G-��f����kb'��K�sCu�k]�\[��ա\�_d{�H�V,#.���>��IŢ�<�3̹��Y�;Wy���B�6�����Kt|<oa�Q��� Fyy�A��e;̾۾�G��J8_�*��d����Xq��\C�R3�?{Y��=k�ߏ:�r1|�~	�S��H�Aϵ��^>�4�e���f����g�v�2jEJ��FJн�! ,�T*���������mj.�&z@>�@م}m}e��x��J#���}ω�#�z$�B�����+�Fr|>BzJ���!\�v�s��u��@��t��|�|6h������bo��@	�8k����ٌ \iA�!}g�y�t6ٟ�K�� ee��l 76VY����㈕��-��u<7?b������Ad�"���
b�����?���o�Od�y�oq��U�F�0�Z�S	�̯� .�|n��T�K��Ĺ�@\���
OD1����A}���|{e+��\�Tw�V�l�pXd&����;����"R��4��Z���lU!;���9�#i��.�����P����]�05���+R��^�g��&�x��*�@�^}q�ʑ�F���m���e��t�cV�������a��������D�劔����K�_x�\��c��X�~�.��+&B:ӘX�N~�V]dO�k�X�+\��Db���J��baL�,k�O��:���.],4��	a�w9�!�]N�a���v�+��)G�L�Z�f}���|����E�Ad���������%������ �O�����b����n�2���k.�e��[7��1�,}q
�����]1�F�h�Ų�1@�>�餮���������798�vP�I�N��>|��Kk+���9�{ڹ��իe�I\Ww'%M����ަF��̏�ؼ�2���skjqi�T%��x�/��z�$�X
�b�*�g��`��!�%�Ra��R#5u���zY�c���zJ��9.��!�<w�I������끲�+he�O�i>|�m�ˍ-�eJQ��R ��PӺx �x����߶�DUpE/����@�:^�m���]EWӥ�Ȑ���j-�����m�wT|�+�n���w]�ٛ�v}2y�f�v��|I��I1��q�ł#x����p��K��9x[�뾌|�	�ߨQ�_��kGz�>�V���z�sy��D>��v�o9�\Ѻ}��BM�뭖3Q&�s��T/z��KT�/ه�����4�3WY��+���R/p{%��������߱i=�m����btX�Mǔ.5�z��Y�t�e$�4�R�̅A���-�ބ8wx3o_[#�����ww�\��%K�g�1[�ƚZ:�i=B�z����c�z������Y�����Q�2��6A}mPy�]�ζ:?T_/�n���w��w��n�;��}Gx��}n�jb�3�']��s�r=�7B�Ul
�8�L?�Ƿ�r�W��bZ��-~�:�B>b�[���P���i�;�r]� �mc狑8�M<;^�6C�-��[����mM�-�����u�E8Zt��M��=�0�s�t����-vo<��==voxtx{λί��.�2V[��@SE�qҾ�}�o!���,60q�w�}���G���I��vRDV�oY�6	nY�.��In���O}K7�+����J�+W��#�c�5���H��Ө�G��S ��(�K"�xc�mt�T�9NT7�-~=4�|�x�EH�T}4صo�XǄ�D���"m��ol�g��pH2#R����*�0�w$L��@�B�XE�4/jU��=��"�p�Wcȯ��qH!�8�Oc��u?����6��>`1���\$�YY��_|����[N��ś~�eD�w�v�F���:�N{���	�A �铲�5}�zUxQ$�u������K�G��~� �/s�Di䚾ᱪ;�x��_fËT۠��#��{�8�|��olT��'�c+���է�c0S���u��p����9�r�Ǫ�b�ؖ6S0v�N��� +
�
c)�w���lvD5�r��4t�]&oe���s�e�Р���w�x�
G ϐC�L�K���C��!��2����^��w��������Y�R��?t��%�~�ծWR�iX�o���CՋzS�W͑���"$��|�N�)��kŪ4MN����N�����
�)�Z�o1�J����=G����NQQ��:8UŚj��w&�P��Z��2(t���cY�`[�?�a^.�:@^���h��W"����R�� �.��'�_�D��z�PS����6��T�4�Z���<h5=?wS
���N��/)+ ͂^�*�w.$C��y#��W�X��&ġ�)U}5�,S�l@���W��*�m���k�K߃K��U��~�^��_je��ju	�Л��44������S*�#�ya�ú����ѷo�%�i�}۱kQy���At)d��w��X0��eNsPԲ��EZi��ȑ���ą��q�u^�~��<�2�)2(�iI�k�=!_]:��{H��M3m,��l�g���~�5I5W�٠�!���?����D���4�w�^��"/�q���	8�6n���@���|#(�-�xE�S�{L�)�i��u��KE�۷[<��&~���1�-nk�ɽiZ��z�B,���|U�8"+��f4Q�l��Uh$���@ܕ;��P�|�_E:.�A�*��~};:��Y��;�L!�LCkS!#&��`��k8�(����f@���?˦��ǒ�m��;�ǔ�������{�������x�;�7�#i_]'�8b���&	`�'��G���j�Պ*=�Ί���Ĝ�9��&(�*ks��l��t�����؝��2�&M%�*�>�Igӂy(b�Y��7�(�Ǵ�nx떧/�AK�3�f"ǔ�cGy[\4Hpc�-U�Png�D��k�]W.�v�@�T/��Y`D��-��A�&�e�~�֐�8M�Y������/�D�k]���Po� �{ߎ�����ʄ*�D]ℕ�i�Q��3��{��Ar�P    ��z*�K��7/m;��%�/h ��m8���n)ԤAq�x{���'8m��S�p!xU�A>��xS)�,{%C<�� V�ޕ�*K�x�kNJ�f��(N�o�jY�d��ȓO�����5�3,�T��A��}��W)Ù+������/9�<|[�E�L��4҉�Y��ҹɌ����|��T��\�J���c.ج�0P��ӫ�,u�c�BG�:��t#�H-�l���m3��S��6�D.R��A��j�~ߧ�p�4Ԑ�v�\;���J;,�����I��b�����	���Fo0�O��Y�q�$��������&�
��͂;
�����V�	��A_��:�e1Ȕ*~�`zS�P%���&׬��Mb�t���!��܄�HA =�mbj����%XV�����k-�:}�7_0�3li���z{���K���.�U���p���}`�ѽǄ��;��X���������`�
f��7�2�2�`�3������fWlA�.ۢQ��G�->�Z��P���8�� ��;k��BI�IH��!v�I?��P(f���v��V���P���t;-�Ǳ�`�����K��v�_���XUxz�뮅�Ǵ=�q��+OQ�<��%!��l���/Y��&���xp������20'D*^�D��i��P2&��e��щ������)���5������"����Nd$�@��3*Kwoz�3���X�s�2O፽�q��q��
|w���=���u����e��h�c�8��Lh�^^Rx
4,�|h�I"E�Zl��GBpOe��;�;X�}H��@�ϗc�:T��*�;�*� �����_�\+2*�;�����cd��}b�����*T	f�V�	P2:��rB��4�CYh��k�ܠ��r��Tj�1�2�8������IS��XPы���6�]ŘLu]����XB*z����G�Nk�e5��'�RQp2*����W ;��/��C55�@�˗�Prѩ�n��=�］��*�q���{�p�i��dڱ���z�S�X�ʇ���o���/.L���Q�
a�G׿i6W�N�U��ǚ`r��Y�ⱃs3�u�~� ���DH��ʠ������w���Gɻx���̆���Eǁ���M� w�$U["i�a<G��F��jo�*�`M�5'"E�m�����
�9���d�z��" 7�5Ф�M�p�Q��tJ#`�Ti�6[E��M#�Y�n+��@�����ġ�7@pw$����'�����LZ��?�e�R�d5F�_�t�|�|5��7fy���o/�g�P�O������n!}C������}�v/h�~���x6��h|a�2W�-E�y���Mݲ"���n`�2�ùΦ�No�"=_��%� C�<��J���*��I(���-��r��f��~��2��z��ٰ��Gp3�n�!,D���c��̀ju��
�͍�H�%�����b��<mx��[*�\��B�@=�y�8*>�/����(t���K*��H�e:F��I��1i������L�"��e�WӅg�?�A��'iϦP��O��P��7H��oU!Z�`�R���	^M	5��}�j���w����,V�s�}�_��2g��?G+@m;��y�_�����$�嗽b�v�5��=iK W�V_�!da�Ƚ�n����m�bq���л��:�t,)�UO��ϩ��(櫝|K���z��n������D���c�5����5�:R���W7C*�;�f������9�\D=�{iP�TV <-�-h��|T��W��F��uX�D�[r���?�M_ٕ���O�B��a�^��m������aܕ��~J�e��-�wTR�۟xG!eN}���0呩�=�n<Xn����P"=�Oa�`����h�5��@Hj�ѢZYwT�ՊZ�S�x
EP��m�:���)j�כ&��������LK㜷a ��s�5_��M5�Ӫ��5�70Y����C�L��f���x��鰛?���ܧ��9L�V���6А4v'�	q�*b�X��V�a�5I6xy�9h��|cK
�隥�4Ҫ	)D�P��pȍH�l��άHm�8V��uJ��G����HGE�O64��)�6�L��fOіF��I{��gS�t�s���V����d�Րnw��8�U�v���8�(%m$ =kPn��A�-?�/#δ���@��8�H�n c_���
ⵒ㡑Xu��D4ڋ���g6
c�.:��F�qW��׍�̿DS
�A�_hCb�E$�"}*a��X�� 
\
���7ߠ�V�W_;~�z{@/���,������$j?T�OQ�t���M��Ylw@4T�9�]|�� �c�7����G�'����FY)��-jwn��IC�H���GH7��iiDP찭L������V|�d�ҿ<��Ј��?�x3���V�&�(�O:�K im�Mw�8`���0�4:-S�D�(���Jz�|Nl����sK?
(��ܖ[�U���T���yZ�٫j�����]��vtJb�-҆�B�i_2���o���@�u�e�~�v8(1*��v�v��B �=�e�#)(����!�&��l�t��Y��=�Y���B4�+Q�6}����6�H@�C���$��͇��nh��?3�x����Ӹn���hS�f4��z��k���RųE:#��ah��e�V�ؠ��\*�b����94�^��������-Hy��W(@�Lf7�v�\��(X
�S�I:��vԯ�#5��Ev����p"Ã��<��������N\`�2	�ۂ����)8�����P�%���O%�ŗf"��Q/}L}�ɶ���\(z�Rv�.��V�H ͞����P#3�@-�%�]�j<����}iP�h��p��:޹���
mJ��r���I�Ē`�Ĩ�K�� ��]B�ҠI����i�v�GN����'k�5�=ɸy��mi@�;$�"p����Dl���{k��m~H�Xh���B��M������6=� ����-�(�~N�9���ahTDSt�#u�4�z"�� ��@�L|l+.<ȴO1���Ⱦt"�C�t�-O������9F�*El���C��+jpj�xl*$�+~L.��q�N|M���U�4�������K�8X�bU��[��L�,4�Pj���g�� �C�3��t�4��
y�P3�,���Rb u2�ݹ%s����
�w�Ӿ��_v]T[����s(��s8���3N�.���u5���!��|��Hw(���<�o��Q2�t��g�/�MVuE�FØe�)"%x�SBp��`5���i���P 0^�i���-'����kH7�*�EFWVrOv%��0��\0��sJ�G�ĖΈ�ӷ�����)�7=d�+H'��K��P�����F��c��߶%%�X*Rي�����O�rt�
�.��C6u�G������-@�b݁e��X�h�P�1g8�N��ju����4��'3v���S�.v��I��DA�H��HMy U(�֜R'�m�%�P@�_J�!�}_��Q��4J��=俁k�%h�����;�.� B:j�*	�'K��\3�Ǿ�`�E?��l���lP-@=�i�݄K���f)G���Jj�i��P����B�ʗT�.��Ԅ�(����#�R���e	24��k��$��Z��]��ǷPmʛB]Yi�w��Y!�x̢n'����sU��G��3�|1Q��iyy�$��Mb���.F��~)�vz���{N��veP������0L��Z<3*��&�ܘBn�e%�\!����]�� b>��EQv-bi���c)���G}h�����#	��%+Fq&ޗ�u��ʥ�?Z9j��`�AX�hu:�����x��N;/~�~ı�������F��x/H�4���oU��Έ�h��b1;?0�� �d�0�ɮ�W�eR��5���$�o<�N�U��E�X����U���	�l{�(R�;O���d��s�2Y,�PӫI}�{(�0f���1Ի>B��=�8�,[V\TE�3Q�P M��|L�ݫ�z�Jž .  ���jS�ֹu�c3l���O�٨*��"���
�sW�Z��� ���6"��خ�r��z���\���Qk�*nlE]-u�7h`)GB�\C|��S��sڲ��h��GPQ��s�����S��nPh��Sd�n�p]�-����:�������w\g\񱾦��=�!�� � ՐJ�Vp}o�:W�Ӏ�����x�u?�ó�O6�����byV%�C��SD�<]1.���;IѦ�q�����O��[(x�w�"6b�ŏ��u���zM^�� t�Y|H��GBuEr�:�`����u�]yq�Z����^A鼾�����(��l��["�{syN;.����05�r�o�7�$����p�;���ý��������'��OA
��
����'`n4��1�]�A���L�V��V���W�<E*�ncAe�B����꼾{��Qm"�ɻ]�jǭVp��`����h���#�D:��.�k�i{��R�A��>���_#���k@��'�˙w"D��}�7��8d��޶��
;��iS*�/�9cE����a8E�݈�P���CŊ�%jZ����UZ����pˏ�#q�����������z���Q$�C��2�p7K?��r��A���s�F���S���y+���R-��rwZ�*��X{��Y�a/z��ʏ�Wɂ��ܮv���W	Y>3�u/�-dq�_�=�1|+��.߹����6�]����-��~dO'�-��;�}������y�ffM�2���+iQ��>�1�����fM4aC�~z}0���&cs�
�i.2E}��(;:z�턧�ǉ��^�ZJye·Zx�R�᭕=,�)�B�w�88{D�M���>����+�v0��o�RN�jʍ<0��d�S#�Q��e�0T%m���i��g�������$؈A��.��V����bt�9�L�G~qU 5�QNeп�oG�6Ȯ�����ʉ�{B=��� m(ɗ�'Qk�e|M�Oh����ͫk
a����{�E��N�"�����kBMfc|�Z�����m��B-��m���¡k]�/Ѯ��?��������$6�            x������ � �             x������ � �            x������ � �      "      x������ � �     