--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-10-30 19:50:26

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5037 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 249 (class 1255 OID 16757)
-- Name: adicionar_acabamento_para_madeira_macica(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.adicionar_acabamento_para_madeira_macica() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tipo_madeira INTEGER;
    acabamento_id INTEGER;
BEGIN
    SELECT Tipo_Material_Cod INTO tipo_madeira FROM Material WHERE Material_ID = NEW.FK_Material_ID;
    SELECT Processo_ID INTO acabamento_id FROM Processo_Producao WHERE Etapa_Cod = 3 LIMIT 1;

    IF tipo_madeira = 2 THEN -- Código 2: Madeira Maciça
        -- Status_Cod = 0 significa "Aguardando Início" ou similar
        INSERT INTO Peca_Processo (FK_Peca_ID, FK_Processo_ID, Status_Cod, Tempo_Real_Data)
        VALUES (NEW.Peca_ID, acabamento_id, 0, NULL);
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.adicionar_acabamento_para_madeira_macica() OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16751)
-- Name: atualizar_status_produto_apos_montagem(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.atualizar_status_produto_apos_montagem() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.Aprovado_QC = TRUE THEN
        UPDATE Produto
        SET Status_Producao = 'Montado'
        WHERE Produto_ID = NEW.FK_Produto_ID;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.atualizar_status_produto_apos_montagem() OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 16765)
-- Name: buscar_pedidos_cliente(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.buscar_pedidos_cliente(p_nome_cliente character varying) RETURNS TABLE(pedido_id integer, data_pedido date, tipo_pedido numeric, produto_nome character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.Pedido_ID,
        p.Data_Pedido,
        p.Tipo_Pedido_Numerico,
        pr.Nome
    FROM Pedido p
    JOIN Cliente c ON p.FK_Cliente_ID = c.Cliente_ID
    JOIN Produto pr ON p.FK_Produto_ID = pr.Produto_ID
    WHERE c.Nome ILIKE '%' || p_nome_cliente || '%';
END;
$$;


ALTER FUNCTION public.buscar_pedidos_cliente(p_nome_cliente character varying) OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 16766)
-- Name: custo_total_materiais_produto(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.custo_total_materiais_produto(p_produto_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    total DECIMAL(10,2);
BEGIN
    SELECT SUM(m.Custo_Unitario)
    INTO total
    FROM Peca p
    JOIN Material m ON p.FK_Material_ID = m.Material_ID
    WHERE p.FK_Produto_ID = p_produto_id;

    RETURN COALESCE(total, 0);
END;
$$;


ALTER FUNCTION public.custo_total_materiais_produto(p_produto_id integer) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 16755)
-- Name: definir_data_pedido_default(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.definir_data_pedido_default() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.Data_Pedido IS NULL THEN
        NEW.Data_Pedido := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.definir_data_pedido_default() OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16761)
-- Name: fn_auditar_pedido(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_auditar_pedido() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Auditoria_Pedido (Pedido_ID, Acao)
    VALUES (NEW.Pedido_ID, 'INSERIDO');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_auditar_pedido() OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 16763)
-- Name: fn_verificar_fim_producao(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_verificar_fim_producao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_produto_id INTEGER;
    processos_restantes INTEGER;
BEGIN
    -- 1. Obtém o Produto ligado à peça
    SELECT FK_Produto_ID INTO v_produto_id
    FROM Peca
    WHERE Peca_ID = NEW.FK_Peca_ID;

    -- 2. Conta quantos processos AINDA NÃO estão finalizados (Status_Cod != 2)
    -- Se processos_restantes = 0, significa que TODOS os processos foram concluídos.
    SELECT COUNT(*) INTO processos_restantes
    FROM Peca_Processo pp
    JOIN Peca p ON pp.FK_Peca_ID = p.Peca_ID
    WHERE p.FK_Produto_ID = v_produto_id AND pp.Status_Cod IS DISTINCT FROM 2;

    -- 3. Se não há processos restantes (0), atualiza o status do produto
    IF processos_restantes = 0 THEN
        UPDATE Produto
        SET Status_Producao = 'Produzido'
        WHERE Produto_ID = v_produto_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_verificar_fim_producao() OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 16768)
-- Name: listar_produtos_por_status(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.listar_produtos_por_status(p_status character varying) RETURNS TABLE(produto_id integer, nome character varying, tipo_produto character varying, status_producao character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    -- Correção: Adicionado o alias 'p' para a tabela Produto e usado para qualificar as colunas.
    SELECT 
        p.Produto_ID, 
        p.Nome, 
        p.Tipo_Produto, 
        p.Status_Producao
    FROM Produto p
    WHERE p.Status_Producao ILIKE '%' || p_status || '%';
END;
$$;


ALTER FUNCTION public.listar_produtos_por_status(p_status character varying) OWNER TO postgres;

--
-- TOC entry 256 (class 1255 OID 16769)
-- Name: produto_foi_entregue(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.produto_foi_entregue(p_produto_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM Entrega WHERE FK_Produto_ID = p_produto_id
    ) INTO existe;

    RETURN existe;
END;
$$;


ALTER FUNCTION public.produto_foi_entregue(p_produto_id integer) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 16767)
-- Name: tempo_estimado_total_producao(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tempo_estimado_total_producao(p_produto_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    tempo_total INTEGER;
BEGIN
    SELECT SUM(pp.Tempo_Estimado_min)
    INTO tempo_total
    FROM Peca p
    JOIN Peca_Processo px ON px.FK_Peca_ID = p.Peca_ID
    JOIN Processo_Producao pp ON pp.Processo_ID = px.FK_Processo_ID
    WHERE p.FK_Produto_ID = p_produto_id;

    RETURN COALESCE(tempo_total, 0);
END;
$$;


ALTER FUNCTION public.tempo_estimado_total_producao(p_produto_id integer) OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 16753)
-- Name: validar_cpf_cnpj_cliente(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validar_cpf_cnpj_cliente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Cliente WHERE CPF_CNPJ = NEW.CPF_CNPJ AND Cliente_ID != NEW.Cliente_ID
    ) THEN
        RAISE EXCEPTION 'CPF/CNPJ "% já está cadastrado.', NEW.CPF_CNPJ;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.validar_cpf_cnpj_cliente() OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16759)
-- Name: verificar_entrega_atrasada(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verificar_entrega_atrasada() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    data_montagem DATE;
    dias_atraso INTEGER;
BEGIN
    SELECT Data_Montagem INTO data_montagem FROM Montagem WHERE FK_Produto_ID = NEW.FK_Produto_ID;

    -- Atraso é verificado se a data de envio for MAIOR que a data de montagem + 7 dias
    IF data_montagem IS NOT NULL AND NEW.Data_Envio > (data_montagem + INTERVAL '7 days') THEN
        dias_atraso := NEW.Data_Envio - data_montagem;
        INSERT INTO Log_Entregas_Atrasadas (Produto_ID, Data_Entrega, Dias_Atraso, Observacao)
        VALUES (NEW.FK_Produto_ID, NEW.Data_Envio, dias_atraso, 'Entrega após prazo de 7 dias.');
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.verificar_entrega_atrasada() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 232 (class 1259 OID 16661)
-- Name: auditoria_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditoria_pedido (
    auditoria_id integer NOT NULL,
    pedido_id integer,
    data_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    acao character varying(20)
);


ALTER TABLE public.auditoria_pedido OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16660)
-- Name: auditoria_pedido_auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auditoria_pedido_auditoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auditoria_pedido_auditoria_id_seq OWNER TO postgres;

--
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 231
-- Name: auditoria_pedido_auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auditoria_pedido_auditoria_id_seq OWNED BY public.auditoria_pedido.auditoria_id;


--
-- TOC entry 219 (class 1259 OID 16586)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    cliente_id integer NOT NULL,
    nome character varying(100),
    cpf_cnpj character varying(18),
    endereco character varying(255),
    email character varying(100),
    telefone character varying(20)
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16612)
-- Name: embalagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.embalagem (
    embalagem_id integer NOT NULL,
    tipo_embalagem character varying(50),
    protecao_termica boolean,
    etiqueta_rastreamento character varying(50)
);


ALTER TABLE public.embalagem OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16605)
-- Name: entrega; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entrega (
    entrega_id integer NOT NULL,
    data_envio date,
    destino character varying(255),
    status_entrega_cod numeric,
    fk_produto_id integer
);


ALTER TABLE public.entrega OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16651)
-- Name: log_entregas_atrasadas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_entregas_atrasadas (
    log_id integer NOT NULL,
    produto_id integer,
    data_entrega date,
    dias_atraso integer,
    observacao text,
    data_log timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.log_entregas_atrasadas OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16650)
-- Name: log_entregas_atrasadas_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_entregas_atrasadas_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_entregas_atrasadas_log_id_seq OWNER TO postgres;

--
-- TOC entry 5039 (class 0 OID 0)
-- Dependencies: 229
-- Name: log_entregas_atrasadas_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_entregas_atrasadas_log_id_seq OWNED BY public.log_entregas_atrasadas.log_id;


--
-- TOC entry 225 (class 1259 OID 16624)
-- Name: material; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material (
    material_id integer NOT NULL,
    nome character varying(100),
    fornecedor character varying(100),
    tipo_material_cod numeric,
    custo_unitario numeric(10,2)
);


ALTER TABLE public.material OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16600)
-- Name: montagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.montagem (
    montagem_id integer NOT NULL,
    responsavel character varying(100),
    data_montagem date,
    aprovado_qc boolean,
    fk_produto_id integer
);


ALTER TABLE public.montagem OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16617)
-- Name: peca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.peca (
    peca_id integer NOT NULL,
    nome character varying(100),
    tipo_processo_cod numeric,
    medidas character varying(50),
    fk_produto_id integer,
    fk_material_id integer
);


ALTER TABLE public.peca OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16638)
-- Name: peca_processo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.peca_processo (
    fk_peca_id integer NOT NULL,
    fk_processo_id integer NOT NULL,
    status_cod numeric,
    tempo_real_data date
);


ALTER TABLE public.peca_processo OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16593)
-- Name: pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedido (
    pedido_id integer NOT NULL,
    data_pedido date,
    tipo_pedido_numerico numeric,
    fk_cliente_id integer,
    fk_produto_id integer
);


ALTER TABLE public.pedido OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16631)
-- Name: processo_producao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processo_producao (
    processo_id integer NOT NULL,
    etapa_cod numeric,
    ordem character varying(10),
    descricao character varying(255),
    tempo_estimado_min integer
);


ALTER TABLE public.processo_producao OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16576)
-- Name: produto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produto (
    produto_id integer NOT NULL,
    nome character varying(100),
    status_producao character varying(50),
    tipo_produto character varying(20),
    data_criacao date,
    dimensoes_m2 numeric(10,2),
    fk_embalagem_id integer
);


ALTER TABLE public.produto OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16645)
-- Name: produto_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produto_pedido (
    fk_produto_id integer NOT NULL,
    fk_pedido_id integer NOT NULL
);


ALTER TABLE public.produto_pedido OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16581)
-- Name: projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projeto (
    projeto_id integer NOT NULL,
    descricao character varying(255),
    designer character varying(100),
    software_utilizado character varying(50),
    data_conclusao date,
    data_inicio date,
    fk_produto_id integer,
    fk_material_id integer
);


ALTER TABLE public.projeto OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16775)
-- Name: vw_producao_em_andamento; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_producao_em_andamento AS
 SELECT pr.produto_id,
    pr.nome AS produto,
    pc.peca_id,
    pc.nome AS peca,
    pp.processo_id,
    pp.descricao AS processo,
    ppx.status_cod,
    ppx.tempo_real_data
   FROM (((public.produto pr
     JOIN public.peca pc ON ((pc.fk_produto_id = pr.produto_id)))
     JOIN public.peca_processo ppx ON ((ppx.fk_peca_id = pc.peca_id)))
     JOIN public.processo_producao pp ON ((pp.processo_id = ppx.fk_processo_id)))
  WHERE (ppx.status_cod IS DISTINCT FROM (2)::numeric);


ALTER VIEW public.vw_producao_em_andamento OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16770)
-- Name: vw_resumo_pedidos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_resumo_pedidos AS
 SELECT p.pedido_id,
    c.nome AS cliente,
    pr.nome AS produto,
        CASE p.tipo_pedido_numerico
            WHEN 1 THEN 'Série'::text
            WHEN 2 THEN 'Sob Medida'::text
            ELSE 'Outro'::text
        END AS tipo_pedido,
    p.data_pedido
   FROM ((public.pedido p
     JOIN public.cliente c ON ((p.fk_cliente_id = c.cliente_id)))
     JOIN public.produto pr ON ((p.fk_produto_id = pr.produto_id)));


ALTER VIEW public.vw_resumo_pedidos OWNER TO postgres;

--
-- TOC entry 4817 (class 2604 OID 16664)
-- Name: auditoria_pedido auditoria_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_pedido ALTER COLUMN auditoria_id SET DEFAULT nextval('public.auditoria_pedido_auditoria_id_seq'::regclass);


--
-- TOC entry 4815 (class 2604 OID 16654)
-- Name: log_entregas_atrasadas log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_entregas_atrasadas ALTER COLUMN log_id SET DEFAULT nextval('public.log_entregas_atrasadas_log_id_seq'::regclass);


--
-- TOC entry 5031 (class 0 OID 16661)
-- Dependencies: 232
-- Data for Name: auditoria_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5018 (class 0 OID 16586)
-- Dependencies: 219
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.cliente (cliente_id, nome, cpf_cnpj, endereco, email, telefone) VALUES (1, 'João Silva', '123.456.789-00', 'Rua A, 100', 'joao.silva@email.com', '(11) 98765-4321');
INSERT INTO public.cliente (cliente_id, nome, cpf_cnpj, endereco, email, telefone) VALUES (2, 'Móveis & Cia', '00.111.222/0001-33', 'Av. B, 500', 'contato@moveiscia.com.br', '(21) 3333-2222');


--
-- TOC entry 5022 (class 0 OID 16612)
-- Dependencies: 223
-- Data for Name: embalagem; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.embalagem (embalagem_id, tipo_embalagem, protecao_termica, etiqueta_rastreamento) VALUES (301, 'Caixa de Papelão Reforçada', true, 'BR123456789');
INSERT INTO public.embalagem (embalagem_id, tipo_embalagem, protecao_termica, etiqueta_rastreamento) VALUES (302, 'Pallet Encaixotado', false, 'BR987654321');


--
-- TOC entry 5021 (class 0 OID 16605)
-- Dependencies: 222
-- Data for Name: entrega; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.entrega (entrega_id, data_envio, destino, status_entrega_cod, fk_produto_id) VALUES (801, '2025-10-06', 'Rua A, 100 - Cliente 1', 1, 501);


--
-- TOC entry 5029 (class 0 OID 16651)
-- Dependencies: 230
-- Data for Name: log_entregas_atrasadas; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5024 (class 0 OID 16624)
-- Dependencies: 225
-- Data for Name: material; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.material (material_id, nome, fornecedor, tipo_material_cod, custo_unitario) VALUES (101, 'MDF Branco 15mm', 'Madeireira Delta', 1, 45.50);
INSERT INTO public.material (material_id, nome, fornecedor, tipo_material_cod, custo_unitario) VALUES (102, 'Vidro Temperado 6mm', 'Vidraçaria Gema', 3, 85.00);
INSERT INTO public.material (material_id, nome, fornecedor, tipo_material_cod, custo_unitario) VALUES (103, 'Madeira Maciça Carvalho', 'Floresta Viva', 2, 120.75);


--
-- TOC entry 5020 (class 0 OID 16600)
-- Dependencies: 221
-- Data for Name: montagem; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.montagem (montagem_id, responsavel, data_montagem, aprovado_qc, fk_produto_id) VALUES (701, 'Carlos Mendes', '2025-09-28', true, 501);


--
-- TOC entry 5023 (class 0 OID 16617)
-- Dependencies: 224
-- Data for Name: peca; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.peca (peca_id, nome, tipo_processo_cod, medidas, fk_produto_id, fk_material_id) VALUES (901, 'Tampo da Mesa', 1, '650x650x15', 501, 101);
INSERT INTO public.peca (peca_id, nome, tipo_processo_cod, medidas, fk_produto_id, fk_material_id) VALUES (902, 'Perna da Mesa (x4)', 2, '600x50x50', 501, 103);


--
-- TOC entry 5026 (class 0 OID 16638)
-- Dependencies: 227
-- Data for Name: peca_processo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.peca_processo (fk_peca_id, fk_processo_id, status_cod, tempo_real_data) VALUES (901, 201, 1, '2025-10-01');
INSERT INTO public.peca_processo (fk_peca_id, fk_processo_id, status_cod, tempo_real_data) VALUES (902, 201, 1, '2025-10-01');


--
-- TOC entry 5019 (class 0 OID 16593)
-- Dependencies: 220
-- Data for Name: pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pedido (pedido_id, data_pedido, tipo_pedido_numerico, fk_cliente_id, fk_produto_id) VALUES (401, '2025-09-15', 1, 1, 501);
INSERT INTO public.pedido (pedido_id, data_pedido, tipo_pedido_numerico, fk_cliente_id, fk_produto_id) VALUES (402, '2025-09-20', 2, 2, 502);


--
-- TOC entry 5025 (class 0 OID 16631)
-- Dependencies: 226
-- Data for Name: processo_producao; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.processo_producao (processo_id, etapa_cod, ordem, descricao, tempo_estimado_min) VALUES (201, 1, 'A1', 'Corte de chapas de MDF', 60);
INSERT INTO public.processo_producao (processo_id, etapa_cod, ordem, descricao, tempo_estimado_min) VALUES (202, 2, 'B1', 'Furação para dobradiças', 30);
INSERT INTO public.processo_producao (processo_id, etapa_cod, ordem, descricao, tempo_estimado_min) VALUES (203, 3, 'C1', 'Acabamento e polimento', 45);


--
-- TOC entry 5016 (class 0 OID 16576)
-- Dependencies: 217
-- Data for Name: produto; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.produto (produto_id, nome, status_producao, tipo_produto, data_criacao, dimensoes_m2, fk_embalagem_id) VALUES (501, 'Mesa Lateral Padrão', 'Em Produção', 'Serie', '2025-09-01', 0.65, 301);
INSERT INTO public.produto (produto_id, nome, status_producao, tipo_produto, data_criacao, dimensoes_m2, fk_embalagem_id) VALUES (502, 'Armário Sob Medida - Cliente 2', 'Aguardando Projeto', 'Sob Medida', '2025-09-22', 1.80, 302);


--
-- TOC entry 5027 (class 0 OID 16645)
-- Dependencies: 228
-- Data for Name: produto_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.produto_pedido (fk_produto_id, fk_pedido_id) VALUES (501, 401);
INSERT INTO public.produto_pedido (fk_produto_id, fk_pedido_id) VALUES (502, 402);


--
-- TOC entry 5017 (class 0 OID 16581)
-- Dependencies: 218
-- Data for Name: projeto; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.projeto (projeto_id, descricao, designer, software_utilizado, data_conclusao, data_inicio, fk_produto_id, fk_material_id) VALUES (601, 'Projeto detalhado para Armário Sob Medida.', 'Ana Souza', 'AutoCAD', '2025-09-25', '2025-09-21', 502, 101);


--
-- TOC entry 5040 (class 0 OID 0)
-- Dependencies: 231
-- Name: auditoria_pedido_auditoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auditoria_pedido_auditoria_id_seq', 1, false);


--
-- TOC entry 5041 (class 0 OID 0)
-- Dependencies: 229
-- Name: log_entregas_atrasadas_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_entregas_atrasadas_log_id_seq', 1, false);


--
-- TOC entry 4848 (class 2606 OID 16667)
-- Name: auditoria_pedido auditoria_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_pedido
    ADD CONSTRAINT auditoria_pedido_pkey PRIMARY KEY (auditoria_id);


--
-- TOC entry 4824 (class 2606 OID 16592)
-- Name: cliente cliente_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 4826 (class 2606 OID 16590)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (cliente_id);


--
-- TOC entry 4834 (class 2606 OID 16616)
-- Name: embalagem embalagem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.embalagem
    ADD CONSTRAINT embalagem_pkey PRIMARY KEY (embalagem_id);


--
-- TOC entry 4832 (class 2606 OID 16611)
-- Name: entrega entrega_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entrega
    ADD CONSTRAINT entrega_pkey PRIMARY KEY (entrega_id);


--
-- TOC entry 4846 (class 2606 OID 16659)
-- Name: log_entregas_atrasadas log_entregas_atrasadas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_entregas_atrasadas
    ADD CONSTRAINT log_entregas_atrasadas_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4838 (class 2606 OID 16630)
-- Name: material material_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material
    ADD CONSTRAINT material_pkey PRIMARY KEY (material_id);


--
-- TOC entry 4830 (class 2606 OID 16604)
-- Name: montagem montagem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montagem
    ADD CONSTRAINT montagem_pkey PRIMARY KEY (montagem_id);


--
-- TOC entry 4836 (class 2606 OID 16623)
-- Name: peca peca_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca
    ADD CONSTRAINT peca_pkey PRIMARY KEY (peca_id);


--
-- TOC entry 4842 (class 2606 OID 16644)
-- Name: peca_processo peca_processo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca_processo
    ADD CONSTRAINT peca_processo_pkey PRIMARY KEY (fk_peca_id, fk_processo_id);


--
-- TOC entry 4828 (class 2606 OID 16599)
-- Name: pedido pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_pkey PRIMARY KEY (pedido_id);


--
-- TOC entry 4840 (class 2606 OID 16637)
-- Name: processo_producao processo_producao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processo_producao
    ADD CONSTRAINT processo_producao_pkey PRIMARY KEY (processo_id);


--
-- TOC entry 4844 (class 2606 OID 16649)
-- Name: produto_pedido produto_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_pedido
    ADD CONSTRAINT produto_pedido_pkey PRIMARY KEY (fk_produto_id, fk_pedido_id);


--
-- TOC entry 4820 (class 2606 OID 16580)
-- Name: produto produto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto
    ADD CONSTRAINT produto_pkey PRIMARY KEY (produto_id);


--
-- TOC entry 4822 (class 2606 OID 16585)
-- Name: projeto projeto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT projeto_pkey PRIMARY KEY (projeto_id);


--
-- TOC entry 4867 (class 2620 OID 16758)
-- Name: peca trg_adicionar_acabamento_madeira; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_adicionar_acabamento_madeira AFTER INSERT ON public.peca FOR EACH ROW EXECUTE FUNCTION public.adicionar_acabamento_para_madeira_macica();


--
-- TOC entry 4865 (class 2620 OID 16752)
-- Name: montagem trg_atualizar_status_produto_montagem; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualizar_status_produto_montagem AFTER INSERT OR UPDATE ON public.montagem FOR EACH ROW EXECUTE FUNCTION public.atualizar_status_produto_apos_montagem();


--
-- TOC entry 4863 (class 2620 OID 16762)
-- Name: pedido trg_auditoria_pedido; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_pedido AFTER INSERT ON public.pedido FOR EACH ROW EXECUTE FUNCTION public.fn_auditar_pedido();


--
-- TOC entry 4864 (class 2620 OID 16756)
-- Name: pedido trg_definir_data_pedido; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_definir_data_pedido BEFORE INSERT ON public.pedido FOR EACH ROW EXECUTE FUNCTION public.definir_data_pedido_default();


--
-- TOC entry 4868 (class 2620 OID 16764)
-- Name: peca_processo trg_finaliza_producao; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_finaliza_producao AFTER INSERT OR UPDATE ON public.peca_processo FOR EACH ROW EXECUTE FUNCTION public.fn_verificar_fim_producao();


--
-- TOC entry 4862 (class 2620 OID 16754)
-- Name: cliente trg_validar_cpf_cnpj_cliente; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validar_cpf_cnpj_cliente BEFORE INSERT OR UPDATE ON public.cliente FOR EACH ROW EXECUTE FUNCTION public.validar_cpf_cnpj_cliente();


--
-- TOC entry 4866 (class 2620 OID 16760)
-- Name: entrega trg_verificar_entrega_atrasada; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_verificar_entrega_atrasada AFTER INSERT ON public.entrega FOR EACH ROW EXECUTE FUNCTION public.verificar_entrega_atrasada();


--
-- TOC entry 4855 (class 2606 OID 16698)
-- Name: entrega fk_entrega_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entrega
    ADD CONSTRAINT fk_entrega_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE SET NULL;


--
-- TOC entry 4854 (class 2606 OID 16693)
-- Name: montagem fk_montagem_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montagem
    ADD CONSTRAINT fk_montagem_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE SET NULL;


--
-- TOC entry 4856 (class 2606 OID 16708)
-- Name: peca fk_peca_material; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca
    ADD CONSTRAINT fk_peca_material FOREIGN KEY (fk_material_id) REFERENCES public.material(material_id) ON DELETE SET NULL;


--
-- TOC entry 4857 (class 2606 OID 16703)
-- Name: peca fk_peca_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca
    ADD CONSTRAINT fk_peca_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE SET NULL;


--
-- TOC entry 4852 (class 2606 OID 16683)
-- Name: pedido fk_pedido_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT fk_pedido_cliente FOREIGN KEY (fk_cliente_id) REFERENCES public.cliente(cliente_id) ON DELETE SET NULL;


--
-- TOC entry 4853 (class 2606 OID 16688)
-- Name: pedido fk_pedido_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT fk_pedido_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE SET NULL;


--
-- TOC entry 4858 (class 2606 OID 16713)
-- Name: peca_processo fk_pp_peca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca_processo
    ADD CONSTRAINT fk_pp_peca FOREIGN KEY (fk_peca_id) REFERENCES public.peca(peca_id);


--
-- TOC entry 4860 (class 2606 OID 16728)
-- Name: produto_pedido fk_pp_pedido; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_pedido
    ADD CONSTRAINT fk_pp_pedido FOREIGN KEY (fk_pedido_id) REFERENCES public.pedido(pedido_id) ON DELETE SET NULL;


--
-- TOC entry 4859 (class 2606 OID 16718)
-- Name: peca_processo fk_pp_processo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca_processo
    ADD CONSTRAINT fk_pp_processo FOREIGN KEY (fk_processo_id) REFERENCES public.processo_producao(processo_id);


--
-- TOC entry 4861 (class 2606 OID 16723)
-- Name: produto_pedido fk_pp_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_pedido
    ADD CONSTRAINT fk_pp_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE SET NULL;


--
-- TOC entry 4849 (class 2606 OID 16668)
-- Name: produto fk_produto_embalagem; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto
    ADD CONSTRAINT fk_produto_embalagem FOREIGN KEY (fk_embalagem_id) REFERENCES public.embalagem(embalagem_id) ON DELETE SET NULL;


--
-- TOC entry 4850 (class 2606 OID 16678)
-- Name: projeto fk_projeto_material; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT fk_projeto_material FOREIGN KEY (fk_material_id) REFERENCES public.material(material_id) ON DELETE SET NULL;


--
-- TOC entry 4851 (class 2606 OID 16673)
-- Name: projeto fk_projeto_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT fk_projeto_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE SET NULL;


-- Completed on 2025-10-30 19:50:26

--
-- PostgreSQL database dump complete
--

