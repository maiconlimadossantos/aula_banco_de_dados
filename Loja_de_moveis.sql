--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-11-27 21:04:43

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
-- TOC entry 5297 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 284 (class 1255 OID 17144)
-- Name: adicionar_acabamento_para_madeira_macica(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.adicionar_acabamento_para_madeira_macica() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tipo_material_cod INTEGER; -- Alterado de NUMERIC para INTEGER
    acabamento_id INTEGER;
BEGIN
    SELECT Tipo_Material_Cod INTO tipo_material_cod FROM Material WHERE Material_ID = NEW.FK_Material_ID;
    SELECT Processo_ID INTO acabamento_id FROM Processo_Producao WHERE Etapa_Cod = 3 LIMIT 1;

    IF tipo_material_cod = 2 THEN -- Código 2: Madeira Maciça
        INSERT INTO Peca_Processo (FK_Peca_ID, FK_Processo_ID, Status_Cod, Tempo_Real_Data)
        VALUES (NEW.Peca_ID, acabamento_id, 0, NULL); -- Status 0 = Pendente
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.adicionar_acabamento_para_madeira_macica() OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 17138)
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
-- TOC entry 288 (class 1255 OID 17152)
-- Name: buscar_pedidos_cliente(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.buscar_pedidos_cliente(p_nome_cliente character varying) RETURNS TABLE(pedido_id integer, data_pedido date, tipo_pedido integer, produto_nome character varying)
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
    JOIN Itens_Pedido ip ON p.Pedido_ID = ip.FK_Pedido_ID
    JOIN Produto pr ON ip.FK_Produto_ID = pr.Produto_ID
    WHERE c.Nome ILIKE '%' || p_nome_cliente || '%';
END;
$$;


ALTER FUNCTION public.buscar_pedidos_cliente(p_nome_cliente character varying) OWNER TO postgres;

--
-- TOC entry 307 (class 1255 OID 17160)
-- Name: calcular_preco_aluguel_total(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_preco_aluguel_total(p_produto_id integer, p_data_inicio date, p_data_fim date) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    preco_diario DECIMAL(10,2);
    dias_aluguel INTEGER;
    preco_total DECIMAL(10,2);
BEGIN
    SELECT Preco_Diario INTO preco_diario
    FROM ALUGUEL -- Corrigido o nome da tabela
    WHERE FK_Produto_ID = p_produto_id
      AND p_data_inicio >= Data_Inicio
      AND p_data_fim <= Data_Fim;

    IF preco_diario IS NULL THEN
        RETURN 0;
    END IF;

    dias_aluguel := (p_data_fim - p_data_inicio) + 1;
    preco_total := preco_diario * dias_aluguel;

    RETURN preco_total;
END;
$$;


ALTER FUNCTION public.calcular_preco_aluguel_total(p_produto_id integer, p_data_inicio date, p_data_fim date) OWNER TO postgres;

--
-- TOC entry 308 (class 1255 OID 17161)
-- Name: calcular_preco_venda_total(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_preco_venda_total(p_produto_id integer, p_quantidade integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    preco_unitario DECIMAL(10,2);
    preco_total DECIMAL(10,2);
BEGIN
    SELECT Preco_Total / Quantidade INTO preco_unitario
    FROM VENDA
    WHERE FK_Produto_ID = p_produto_id
    LIMIT 1; -- Adicionado LIMIT 1 para garantir que só pegue um registro caso haja duplicidade (Venda é 1:N com Produto, mas aqui busca o preço unitário da venda existente)

    IF preco_unitario IS NULL THEN
        RETURN 0;
    END IF;

    preco_total := preco_unitario * p_quantidade;

    RETURN preco_total;
END;
$$;


ALTER FUNCTION public.calcular_preco_venda_total(p_produto_id integer, p_quantidade integer) OWNER TO postgres;

--
-- TOC entry 289 (class 1255 OID 17153)
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
-- TOC entry 283 (class 1255 OID 17142)
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
-- TOC entry 286 (class 1255 OID 17148)
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
-- TOC entry 287 (class 1255 OID 17150)
-- Name: fn_verificar_fim_producao(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_verificar_fim_producao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_produto_id INTEGER;
    total_processos INTEGER;
    finalizados INTEGER;
BEGIN
    -- Obtém o Produto ligado à peça
    SELECT FK_Produto_ID INTO v_produto_id
    FROM Peca
    WHERE Peca_ID = NEW.FK_Peca_ID;

    -- Conta todos os processos para TODAS as peças do produto
    SELECT COUNT(pp.FK_Processo_ID) INTO total_processos
    FROM Peca_Processo pp
    JOIN Peca p ON pp.FK_Peca_ID = p.Peca_ID
    WHERE p.FK_Produto_ID = v_produto_id;

    -- Conta quantos estão finalizados (Status_Cod = 2)
    SELECT COUNT(pp.FK_Processo_ID) INTO finalizados
    FROM Peca_Processo pp
    JOIN Peca p ON pp.FK_Peca_ID = p.Peca_ID
    WHERE p.FK_Produto_ID = v_produto_id AND pp.Status_Cod = 2;

    -- Se todos finalizados, atualiza status
    IF total_processos > 0 AND total_processos = finalizados THEN
        UPDATE Produto
        SET Status_Producao = 'Produzido'
        WHERE Produto_ID = v_produto_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_verificar_fim_producao() OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 17157)
-- Name: foi_alugado(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foi_alugado(p_produto_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM ALUGUEL WHERE FK_Produto_ID = p_produto_id -- Corrigido o nome da tabela
    ) INTO existe;

    RETURN existe;
END;
$$;


ALTER FUNCTION public.foi_alugado(p_produto_id integer) OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 17158)
-- Name: foi_vendido(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.foi_vendido(p_produto_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM VENDA WHERE FK_Produto_ID = p_produto_id
    ) INTO existe;

    RETURN existe;
END;
$$;


ALTER FUNCTION public.foi_vendido(p_produto_id integer) OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 17155)
-- Name: listar_produtos_por_status(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.listar_produtos_por_status(p_status character varying) RETURNS TABLE(produto_id integer, nome character varying, tipo_produto character varying, status_producao character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT Produto_ID, Nome, Tipo_Produto, Status_Producao
    FROM Produto
    WHERE Status_Producao ILIKE '%' || p_status || '%';
END;
$$;


ALTER FUNCTION public.listar_produtos_por_status(p_status character varying) OWNER TO postgres;

--
-- TOC entry 292 (class 1255 OID 17156)
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
-- TOC entry 309 (class 1255 OID 17162)
-- Name: rotas_de_transporte_efetivas(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rotas_de_transporte_efetivas(p_transporte_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_rotas INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_rotas
    FROM Rota_Transporte
    WHERE FK_Transporte_ID = p_transporte_id; -- Corrigido o nome da coluna
    RETURN total_rotas;
END;
$$;


ALTER FUNCTION public.rotas_de_transporte_efetivas(p_transporte_id integer) OWNER TO postgres;

--
-- TOC entry 290 (class 1255 OID 17154)
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
-- TOC entry 282 (class 1255 OID 17140)
-- Name: validar_cpf_cnpj_cliente(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validar_cpf_cnpj_cliente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Cliente WHERE CPF_CNPJ = NEW.CPF_CNPJ AND Cliente_ID != NEW.Cliente_ID
    ) THEN
        RAISE EXCEPTION 'CPF/CNPJ "%" já está cadastrado.', NEW.CPF_CNPJ;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.validar_cpf_cnpj_cliente() OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 17146)
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

    IF data_montagem IS NOT NULL AND NEW.Data_Envio > data_montagem + INTERVAL '7 days' THEN
        dias_atraso := NEW.Data_Envio - data_montagem;
        INSERT INTO Log_Entregas_Atrasadas (Produto_ID, Data_Entrega, Dias_Atraso, Observacao)
        VALUES (NEW.FK_Produto_ID, NEW.Data_Envio, dias_atraso, 'Entrega após prazo de 7 dias da montagem.');
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.verificar_entrega_atrasada() OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 17159)
-- Name: verificar_produto_utilizacao(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verificar_produto_utilizacao(p_produto_id integer) RETURNS TABLE(foi_vendido boolean, foi_alugado boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        foi_vendido(p_produto_id) AS Foi_Vendido,
        foi_alugado(p_produto_id) AS Foi_Alugado;
END;
$$;


ALTER FUNCTION public.verificar_produto_utilizacao(p_produto_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 256 (class 1259 OID 16957)
-- Name: aluguel; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aluguel (
    aluguel_id integer NOT NULL,
    fk_produto_id integer NOT NULL,
    fk_cliente_id integer NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    preco_diario numeric(10,2) NOT NULL
);


ALTER TABLE public.aluguel OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 16956)
-- Name: aluguel_aluguel_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aluguel_aluguel_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.aluguel_aluguel_id_seq OWNER TO postgres;

--
-- TOC entry 5298 (class 0 OID 0)
-- Dependencies: 255
-- Name: aluguel_aluguel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aluguel_aluguel_id_seq OWNED BY public.aluguel.aluguel_id;


--
-- TOC entry 240 (class 1259 OID 16884)
-- Name: auditoria_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditoria_pedido (
    auditoria_id integer NOT NULL,
    pedido_id integer NOT NULL,
    data_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    acao character varying(20) NOT NULL
);


ALTER TABLE public.auditoria_pedido OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16883)
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
-- TOC entry 5299 (class 0 OID 0)
-- Dependencies: 239
-- Name: auditoria_pedido_auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auditoria_pedido_auditoria_id_seq OWNED BY public.auditoria_pedido.auditoria_id;


--
-- TOC entry 224 (class 1259 OID 16809)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    cliente_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    cpf_cnpj character varying(18) NOT NULL,
    endereco character varying(255),
    email character varying(100),
    telefone character varying(20)
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16808)
-- Name: cliente_cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cliente_cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_cliente_id_seq OWNER TO postgres;

--
-- TOC entry 5300 (class 0 OID 0)
-- Dependencies: 223
-- Name: cliente_cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cliente_cliente_id_seq OWNED BY public.cliente.cliente_id;


--
-- TOC entry 218 (class 1259 OID 16782)
-- Name: embalagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.embalagem (
    embalagem_id integer NOT NULL,
    tipo_embalagem character varying(50) NOT NULL,
    protecao_termica boolean DEFAULT false,
    etiqueta_rastreamento character varying(50)
);


ALTER TABLE public.embalagem OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16781)
-- Name: embalagem_embalagem_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.embalagem_embalagem_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.embalagem_embalagem_id_seq OWNER TO postgres;

--
-- TOC entry 5301 (class 0 OID 0)
-- Dependencies: 217
-- Name: embalagem_embalagem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.embalagem_embalagem_id_seq OWNED BY public.embalagem.embalagem_id;


--
-- TOC entry 234 (class 1259 OID 16857)
-- Name: entrega; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entrega (
    entrega_id integer NOT NULL,
    data_envio date NOT NULL,
    destino character varying(255) NOT NULL,
    status_entrega_cod integer NOT NULL,
    fk_produto_id integer NOT NULL
);


ALTER TABLE public.entrega OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16856)
-- Name: entrega_entrega_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.entrega_entrega_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.entrega_entrega_id_seq OWNER TO postgres;

--
-- TOC entry 5302 (class 0 OID 0)
-- Dependencies: 233
-- Name: entrega_entrega_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.entrega_entrega_id_seq OWNED BY public.entrega.entrega_id;


--
-- TOC entry 238 (class 1259 OID 16877)
-- Name: itens_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.itens_pedido (
    fk_produto_id integer NOT NULL,
    fk_pedido_id integer NOT NULL,
    quantidade integer NOT NULL,
    preco_unitario numeric(10,2) NOT NULL,
    CONSTRAINT itens_pedido_quantidade_check CHECK ((quantidade > 0))
);


ALTER TABLE public.itens_pedido OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16892)
-- Name: log_entregas_atrasadas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_entregas_atrasadas (
    log_id integer NOT NULL,
    produto_id integer NOT NULL,
    data_entrega date,
    dias_atraso integer,
    observacao text,
    data_log timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT log_entregas_atrasadas_dias_atraso_check CHECK ((dias_atraso > 0))
);


ALTER TABLE public.log_entregas_atrasadas OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16891)
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
-- TOC entry 5303 (class 0 OID 0)
-- Dependencies: 241
-- Name: log_entregas_atrasadas_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_entregas_atrasadas_log_id_seq OWNED BY public.log_entregas_atrasadas.log_id;


--
-- TOC entry 220 (class 1259 OID 16792)
-- Name: material; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material (
    material_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    fornecedor character varying(100),
    tipo_material_cod integer NOT NULL,
    custo_unitario numeric(10,2) NOT NULL,
    CONSTRAINT material_custo_unitario_check CHECK ((custo_unitario >= (0)::numeric))
);


ALTER TABLE public.material OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16791)
-- Name: material_material_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.material_material_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_material_id_seq OWNER TO postgres;

--
-- TOC entry 5304 (class 0 OID 0)
-- Dependencies: 219
-- Name: material_material_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.material_material_id_seq OWNED BY public.material.material_id;


--
-- TOC entry 232 (class 1259 OID 16847)
-- Name: montagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.montagem (
    montagem_id integer NOT NULL,
    responsavel character varying(100) NOT NULL,
    data_montagem date DEFAULT CURRENT_DATE,
    aprovado_qc boolean,
    fk_produto_id integer NOT NULL
);


ALTER TABLE public.montagem OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16846)
-- Name: montagem_montagem_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.montagem_montagem_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.montagem_montagem_id_seq OWNER TO postgres;

--
-- TOC entry 5305 (class 0 OID 0)
-- Dependencies: 231
-- Name: montagem_montagem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.montagem_montagem_id_seq OWNED BY public.montagem.montagem_id;


--
-- TOC entry 250 (class 1259 OID 16932)
-- Name: motorista_transporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motorista_transporte (
    motorista_transporte_id integer NOT NULL,
    fk_transporte_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    cnh character varying(20) NOT NULL,
    telefone character varying(20)
);


ALTER TABLE public.motorista_transporte OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 16931)
-- Name: motorista_transporte_motorista_transporte_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motorista_transporte_motorista_transporte_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motorista_transporte_motorista_transporte_id_seq OWNER TO postgres;

--
-- TOC entry 5306 (class 0 OID 0)
-- Dependencies: 249
-- Name: motorista_transporte_motorista_transporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motorista_transporte_motorista_transporte_id_seq OWNED BY public.motorista_transporte.motorista_transporte_id;


--
-- TOC entry 258 (class 1259 OID 16964)
-- Name: pagamento_aluguel; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pagamento_aluguel (
    pagamento_aluguel_id integer NOT NULL,
    fk_aluguel_id integer NOT NULL,
    metodo_pagamento character varying(50) NOT NULL,
    status_pagamento_cod integer NOT NULL,
    data_pagamento date
);


ALTER TABLE public.pagamento_aluguel OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 16963)
-- Name: pagamento_aluguel_pagamento_aluguel_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pagamento_aluguel_pagamento_aluguel_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagamento_aluguel_pagamento_aluguel_id_seq OWNER TO postgres;

--
-- TOC entry 5307 (class 0 OID 0)
-- Dependencies: 257
-- Name: pagamento_aluguel_pagamento_aluguel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pagamento_aluguel_pagamento_aluguel_id_seq OWNED BY public.pagamento_aluguel.pagamento_aluguel_id;


--
-- TOC entry 254 (class 1259 OID 16950)
-- Name: pagamento_venda; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pagamento_venda (
    pagamento_id integer NOT NULL,
    fk_venda_id integer NOT NULL,
    metodo_pagamento character varying(50) NOT NULL,
    status_pagamento_cod integer NOT NULL,
    data_pagamento date
);


ALTER TABLE public.pagamento_venda OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 16949)
-- Name: pagamento_venda_pagamento_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pagamento_venda_pagamento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagamento_venda_pagamento_id_seq OWNER TO postgres;

--
-- TOC entry 5308 (class 0 OID 0)
-- Dependencies: 253
-- Name: pagamento_venda_pagamento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pagamento_venda_pagamento_id_seq OWNED BY public.pagamento_venda.pagamento_id;


--
-- TOC entry 236 (class 1259 OID 16866)
-- Name: peca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.peca (
    peca_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    tipo_processo_cod integer,
    medidas character varying(50),
    fk_produto_id integer NOT NULL,
    fk_material_id integer NOT NULL
);


ALTER TABLE public.peca OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16865)
-- Name: peca_peca_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.peca_peca_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.peca_peca_id_seq OWNER TO postgres;

--
-- TOC entry 5309 (class 0 OID 0)
-- Dependencies: 235
-- Name: peca_peca_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.peca_peca_id_seq OWNED BY public.peca.peca_id;


--
-- TOC entry 237 (class 1259 OID 16872)
-- Name: peca_processo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.peca_processo (
    fk_peca_id integer NOT NULL,
    fk_processo_id integer NOT NULL,
    status_cod integer NOT NULL,
    tempo_real_data date
);


ALTER TABLE public.peca_processo OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16820)
-- Name: pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedido (
    pedido_id integer NOT NULL,
    data_pedido date DEFAULT CURRENT_DATE,
    tipo_pedido_numerico integer,
    fk_cliente_id integer NOT NULL
);


ALTER TABLE public.pedido OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16819)
-- Name: pedido_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedido_pedido_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedido_pedido_id_seq OWNER TO postgres;

--
-- TOC entry 5310 (class 0 OID 0)
-- Dependencies: 225
-- Name: pedido_pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedido_pedido_id_seq OWNED BY public.pedido.pedido_id;


--
-- TOC entry 228 (class 1259 OID 16828)
-- Name: processo_producao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processo_producao (
    processo_id integer NOT NULL,
    etapa_cod integer NOT NULL,
    ordem character varying(10) NOT NULL,
    descricao character varying(255),
    tempo_estimado_min integer,
    CONSTRAINT processo_producao_tempo_estimado_min_check CHECK ((tempo_estimado_min > 0))
);


ALTER TABLE public.processo_producao OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16827)
-- Name: processo_producao_processo_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.processo_producao_processo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.processo_producao_processo_id_seq OWNER TO postgres;

--
-- TOC entry 5311 (class 0 OID 0)
-- Dependencies: 227
-- Name: processo_producao_processo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.processo_producao_processo_id_seq OWNED BY public.processo_producao.processo_id;


--
-- TOC entry 222 (class 1259 OID 16800)
-- Name: produto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produto (
    produto_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    status_producao character varying(50) NOT NULL,
    tipo_produto character varying(20),
    data_criacao date DEFAULT CURRENT_DATE,
    dimensoes_m2 numeric(10,2),
    fk_embalagem_id integer,
    CONSTRAINT produto_dimensoes_m2_check CHECK ((dimensoes_m2 > (0)::numeric))
);


ALTER TABLE public.produto OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16799)
-- Name: produto_produto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.produto_produto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.produto_produto_id_seq OWNER TO postgres;

--
-- TOC entry 5312 (class 0 OID 0)
-- Dependencies: 221
-- Name: produto_produto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.produto_produto_id_seq OWNED BY public.produto.produto_id;


--
-- TOC entry 230 (class 1259 OID 16838)
-- Name: projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projeto (
    projeto_id integer NOT NULL,
    descricao character varying(255),
    designer character varying(100),
    software_utilizado character varying(50),
    data_conclusao date,
    data_inicio date NOT NULL,
    fk_produto_id integer
);


ALTER TABLE public.projeto OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16837)
-- Name: projeto_projeto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projeto_projeto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projeto_projeto_id_seq OWNER TO postgres;

--
-- TOC entry 5313 (class 0 OID 0)
-- Dependencies: 229
-- Name: projeto_projeto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projeto_projeto_id_seq OWNED BY public.projeto.projeto_id;


--
-- TOC entry 246 (class 1259 OID 16910)
-- Name: rota_transporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rota_transporte (
    rota_transporte_id integer NOT NULL,
    fk_transporte_id integer NOT NULL,
    descricao_rota character varying(255) NOT NULL,
    distancia_km numeric,
    CONSTRAINT rota_transporte_distancia_km_check CHECK ((distancia_km > (0)::numeric))
);


ALTER TABLE public.rota_transporte OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16909)
-- Name: rota_transporte_rota_transporte_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rota_transporte_rota_transporte_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rota_transporte_rota_transporte_id_seq OWNER TO postgres;

--
-- TOC entry 5314 (class 0 OID 0)
-- Dependencies: 245
-- Name: rota_transporte_rota_transporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rota_transporte_rota_transporte_id_seq OWNED BY public.rota_transporte.rota_transporte_id;


--
-- TOC entry 264 (class 1259 OID 16990)
-- Name: tipo_acessorios_moveis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_acessorios_moveis (
    acessorio_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    custo_adicional numeric(10,2),
    CONSTRAINT tipo_acessorios_moveis_custo_adicional_check CHECK ((custo_adicional >= (0)::numeric))
);


ALTER TABLE public.tipo_acessorios_moveis OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 16989)
-- Name: tipo_acessorios_moveis_acessorio_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_acessorios_moveis_acessorio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_acessorios_moveis_acessorio_id_seq OWNER TO postgres;

--
-- TOC entry 5315 (class 0 OID 0)
-- Dependencies: 263
-- Name: tipo_acessorios_moveis_acessorio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_acessorios_moveis_acessorio_id_seq OWNED BY public.tipo_acessorios_moveis.acessorio_id;


--
-- TOC entry 272 (class 1259 OID 17020)
-- Name: tipo_cor_moveis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_cor_moveis (
    cor_id integer NOT NULL,
    nome character varying(50) NOT NULL,
    codigo_hexadecimal character varying(7) NOT NULL
);


ALTER TABLE public.tipo_cor_moveis OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 17019)
-- Name: tipo_cor_moveis_cor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_cor_moveis_cor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_cor_moveis_cor_id_seq OWNER TO postgres;

--
-- TOC entry 5316 (class 0 OID 0)
-- Dependencies: 271
-- Name: tipo_cor_moveis_cor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_cor_moveis_cor_id_seq OWNED BY public.tipo_cor_moveis.cor_id;


--
-- TOC entry 266 (class 1259 OID 16998)
-- Name: tipo_designer_interno; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_designer_interno (
    designer_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    especialidade character varying(100)
);


ALTER TABLE public.tipo_designer_interno OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 16997)
-- Name: tipo_designer_interno_designer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_designer_interno_designer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_designer_interno_designer_id_seq OWNER TO postgres;

--
-- TOC entry 5317 (class 0 OID 0)
-- Dependencies: 265
-- Name: tipo_designer_interno_designer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_designer_interno_designer_id_seq OWNED BY public.tipo_designer_interno.designer_id;


--
-- TOC entry 260 (class 1259 OID 16971)
-- Name: tipo_estabelecimento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_estabelecimento (
    estabelecimento_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    endereco character varying(255) NOT NULL,
    telefone character varying(20),
    email character varying(100),
    categoria character varying(50)
);


ALTER TABLE public.tipo_estabelecimento OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 16970)
-- Name: tipo_estabelecimento_estabelecimento_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_estabelecimento_estabelecimento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_estabelecimento_estabelecimento_id_seq OWNER TO postgres;

--
-- TOC entry 5318 (class 0 OID 0)
-- Dependencies: 259
-- Name: tipo_estabelecimento_estabelecimento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_estabelecimento_estabelecimento_id_seq OWNED BY public.tipo_estabelecimento.estabelecimento_id;


--
-- TOC entry 270 (class 1259 OID 17013)
-- Name: tipo_estilo_moveis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_estilo_moveis (
    estilo_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao character varying(255)
);


ALTER TABLE public.tipo_estilo_moveis OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 17012)
-- Name: tipo_estilo_moveis_estilo_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_estilo_moveis_estilo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_estilo_moveis_estilo_id_seq OWNER TO postgres;

--
-- TOC entry 5319 (class 0 OID 0)
-- Dependencies: 269
-- Name: tipo_estilo_moveis_estilo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_estilo_moveis_estilo_id_seq OWNED BY public.tipo_estilo_moveis.estilo_id;


--
-- TOC entry 268 (class 1259 OID 17006)
-- Name: tipo_marca_moveis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_marca_moveis (
    marca_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    pais_origem character varying(100)
);


ALTER TABLE public.tipo_marca_moveis OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 17005)
-- Name: tipo_marca_moveis_marca_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_marca_moveis_marca_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_marca_moveis_marca_id_seq OWNER TO postgres;

--
-- TOC entry 5320 (class 0 OID 0)
-- Dependencies: 267
-- Name: tipo_marca_moveis_marca_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_marca_moveis_marca_id_seq OWNED BY public.tipo_marca_moveis.marca_id;


--
-- TOC entry 262 (class 1259 OID 16982)
-- Name: tipo_protecao_do_moveis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_protecao_do_moveis (
    protecao_id integer NOT NULL,
    descricao character varying(255) NOT NULL,
    custo_adicional numeric(10,2),
    CONSTRAINT tipo_protecao_do_moveis_custo_adicional_check CHECK ((custo_adicional >= (0)::numeric))
);


ALTER TABLE public.tipo_protecao_do_moveis OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 16981)
-- Name: tipo_protecao_do_moveis_protecao_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_protecao_do_moveis_protecao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_protecao_do_moveis_protecao_id_seq OWNER TO postgres;

--
-- TOC entry 5321 (class 0 OID 0)
-- Dependencies: 261
-- Name: tipo_protecao_do_moveis_protecao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_protecao_do_moveis_protecao_id_seq OWNED BY public.tipo_protecao_do_moveis.protecao_id;


--
-- TOC entry 244 (class 1259 OID 16903)
-- Name: transporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transporte (
    transporte_id integer NOT NULL,
    nome character varying(100) NOT NULL,
    tipo_pedido_numerico integer NOT NULL,
    tipo_de_transporte character varying(50) NOT NULL
);


ALTER TABLE public.transporte OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16902)
-- Name: transporte_transporte_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transporte_transporte_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transporte_transporte_id_seq OWNER TO postgres;

--
-- TOC entry 5322 (class 0 OID 0)
-- Dependencies: 243
-- Name: transporte_transporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transporte_transporte_id_seq OWNED BY public.transporte.transporte_id;


--
-- TOC entry 248 (class 1259 OID 16920)
-- Name: veiculo_transporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.veiculo_transporte (
    veiculo_transporte_id integer NOT NULL,
    fk_transporte_id integer NOT NULL,
    placa character varying(20) NOT NULL,
    modelo character varying(100) NOT NULL,
    capacidade_kg numeric,
    CONSTRAINT veiculo_transporte_capacidade_kg_check CHECK ((capacidade_kg > (0)::numeric))
);


ALTER TABLE public.veiculo_transporte OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16919)
-- Name: veiculo_transporte_veiculo_transporte_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.veiculo_transporte_veiculo_transporte_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.veiculo_transporte_veiculo_transporte_id_seq OWNER TO postgres;

--
-- TOC entry 5323 (class 0 OID 0)
-- Dependencies: 247
-- Name: veiculo_transporte_veiculo_transporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.veiculo_transporte_veiculo_transporte_id_seq OWNED BY public.veiculo_transporte.veiculo_transporte_id;


--
-- TOC entry 252 (class 1259 OID 16941)
-- Name: venda; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venda (
    venda_id integer NOT NULL,
    fk_produto_id integer NOT NULL,
    fk_cliente_id integer NOT NULL,
    data_venda date DEFAULT CURRENT_DATE,
    quantidade integer NOT NULL,
    preco_total numeric(10,2) NOT NULL,
    CONSTRAINT venda_quantidade_check CHECK ((quantidade > 0))
);


ALTER TABLE public.venda OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 16940)
-- Name: venda_venda_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venda_venda_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venda_venda_id_seq OWNER TO postgres;

--
-- TOC entry 5324 (class 0 OID 0)
-- Dependencies: 251
-- Name: venda_venda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.venda_venda_id_seq OWNED BY public.venda.venda_id;


--
-- TOC entry 278 (class 1259 OID 17186)
-- Name: vw_acessorios_protecoes_designers; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_acessorios_protecoes_designers AS
 SELECT a.acessorio_id,
    a.nome AS acessorio,
    a.custo_adicional AS custo_acessorio,
    p.protecao_id,
    p.descricao AS protecao,
    p.custo_adicional AS custo_protecao,
    d.designer_id,
    d.nome AS designer,
    d.especialidade
   FROM ((public.tipo_acessorios_moveis a
     CROSS JOIN public.tipo_protecao_do_moveis p)
     CROSS JOIN public.tipo_designer_interno d);


ALTER VIEW public.vw_acessorios_protecoes_designers OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 17173)
-- Name: vw_clientes_compras; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_clientes_compras AS
 SELECT c.cliente_id,
    c.nome AS cliente,
    count(DISTINCT v.venda_id) AS total_vendas,
    count(DISTINCT a.aluguel_id) AS total_alugueis
   FROM ((public.cliente c
     LEFT JOIN public.venda v ON ((v.fk_cliente_id = c.cliente_id)))
     LEFT JOIN public.aluguel a ON ((a.fk_cliente_id = c.cliente_id)))
  GROUP BY c.cliente_id, c.nome;


ALTER VIEW public.vw_clientes_compras OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 17194)
-- Name: vw_detalhes_itens_pedido; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_detalhes_itens_pedido AS
 SELECT i.fk_produto_id,
    i.fk_pedido_id,
    i.quantidade,
    i.preco_unitario,
    p.nome AS nome_produto,
    c.nome AS nome_cliente,
    ped.data_pedido
   FROM (((public.itens_pedido i
     JOIN public.produto p ON ((i.fk_produto_id = p.produto_id)))
     JOIN public.pedido ped ON ((i.fk_pedido_id = ped.pedido_id)))
     JOIN public.cliente c ON ((ped.fk_cliente_id = c.cliente_id)));


ALTER VIEW public.vw_detalhes_itens_pedido OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 17182)
-- Name: vw_entregas_pendentes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_entregas_pendentes AS
 SELECT e.entrega_id,
    pr.nome AS produto,
    e.data_envio,
    e.destino,
    e.status_entrega_cod
   FROM (public.entrega e
     JOIN public.produto pr ON ((e.fk_produto_id = pr.produto_id)))
  WHERE (e.status_entrega_cod <> 3);


ALTER VIEW public.vw_entregas_pendentes OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 17168)
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
  WHERE (ppx.status_cod IS DISTINCT FROM 2);


ALTER VIEW public.vw_producao_em_andamento OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 17178)
-- Name: vw_produtos_materiais; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_produtos_materiais AS
 SELECT pr.produto_id,
    pr.nome AS produto,
    m.material_id,
    m.nome AS material,
    m.fornecedor,
    m.custo_unitario
   FROM ((public.produto pr
     JOIN public.peca pc ON ((pc.fk_produto_id = pr.produto_id)))
     JOIN public.material m ON ((pc.fk_material_id = m.material_id)));


ALTER VIEW public.vw_produtos_materiais OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 17163)
-- Name: vw_resumo_pedidos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_resumo_pedidos AS
 SELECT p.pedido_id,
    c.nome AS cliente,
    pr.nome AS produto,
    ip.quantidade,
    ip.preco_unitario,
        CASE p.tipo_pedido_numerico
            WHEN 1 THEN 'Série'::text
            WHEN 2 THEN 'Sob Medida'::text
            ELSE 'Outro'::text
        END AS tipo_pedido,
    p.data_pedido
   FROM (((public.pedido p
     JOIN public.cliente c ON ((p.fk_cliente_id = c.cliente_id)))
     JOIN public.itens_pedido ip ON ((p.pedido_id = ip.fk_pedido_id)))
     JOIN public.produto pr ON ((ip.fk_produto_id = pr.produto_id)));


ALTER VIEW public.vw_resumo_pedidos OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 17190)
-- Name: vw_transportes_rotas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_transportes_rotas AS
 SELECT t.transporte_id,
    t.nome AS transporte,
    r.rota_transporte_id,
    r.descricao_rota,
    r.distancia_km
   FROM (public.transporte t
     JOIN public.rota_transporte r ON ((r.fk_transporte_id = t.transporte_id)));


ALTER VIEW public.vw_transportes_rotas OWNER TO postgres;

--
-- TOC entry 4955 (class 2604 OID 16960)
-- Name: aluguel aluguel_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aluguel ALTER COLUMN aluguel_id SET DEFAULT nextval('public.aluguel_aluguel_id_seq'::regclass);


--
-- TOC entry 4944 (class 2604 OID 16887)
-- Name: auditoria_pedido auditoria_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_pedido ALTER COLUMN auditoria_id SET DEFAULT nextval('public.auditoria_pedido_auditoria_id_seq'::regclass);


--
-- TOC entry 4935 (class 2604 OID 16812)
-- Name: cliente cliente_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente ALTER COLUMN cliente_id SET DEFAULT nextval('public.cliente_cliente_id_seq'::regclass);


--
-- TOC entry 4930 (class 2604 OID 16785)
-- Name: embalagem embalagem_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.embalagem ALTER COLUMN embalagem_id SET DEFAULT nextval('public.embalagem_embalagem_id_seq'::regclass);


--
-- TOC entry 4942 (class 2604 OID 16860)
-- Name: entrega entrega_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entrega ALTER COLUMN entrega_id SET DEFAULT nextval('public.entrega_entrega_id_seq'::regclass);


--
-- TOC entry 4946 (class 2604 OID 16895)
-- Name: log_entregas_atrasadas log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_entregas_atrasadas ALTER COLUMN log_id SET DEFAULT nextval('public.log_entregas_atrasadas_log_id_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 16795)
-- Name: material material_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material ALTER COLUMN material_id SET DEFAULT nextval('public.material_material_id_seq'::regclass);


--
-- TOC entry 4940 (class 2604 OID 16850)
-- Name: montagem montagem_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montagem ALTER COLUMN montagem_id SET DEFAULT nextval('public.montagem_montagem_id_seq'::regclass);


--
-- TOC entry 4951 (class 2604 OID 16935)
-- Name: motorista_transporte motorista_transporte_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motorista_transporte ALTER COLUMN motorista_transporte_id SET DEFAULT nextval('public.motorista_transporte_motorista_transporte_id_seq'::regclass);


--
-- TOC entry 4956 (class 2604 OID 16967)
-- Name: pagamento_aluguel pagamento_aluguel_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_aluguel ALTER COLUMN pagamento_aluguel_id SET DEFAULT nextval('public.pagamento_aluguel_pagamento_aluguel_id_seq'::regclass);


--
-- TOC entry 4954 (class 2604 OID 16953)
-- Name: pagamento_venda pagamento_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_venda ALTER COLUMN pagamento_id SET DEFAULT nextval('public.pagamento_venda_pagamento_id_seq'::regclass);


--
-- TOC entry 4943 (class 2604 OID 16869)
-- Name: peca peca_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca ALTER COLUMN peca_id SET DEFAULT nextval('public.peca_peca_id_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 16823)
-- Name: pedido pedido_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido ALTER COLUMN pedido_id SET DEFAULT nextval('public.pedido_pedido_id_seq'::regclass);


--
-- TOC entry 4938 (class 2604 OID 16831)
-- Name: processo_producao processo_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processo_producao ALTER COLUMN processo_id SET DEFAULT nextval('public.processo_producao_processo_id_seq'::regclass);


--
-- TOC entry 4933 (class 2604 OID 16803)
-- Name: produto produto_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto ALTER COLUMN produto_id SET DEFAULT nextval('public.produto_produto_id_seq'::regclass);


--
-- TOC entry 4939 (class 2604 OID 16841)
-- Name: projeto projeto_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto ALTER COLUMN projeto_id SET DEFAULT nextval('public.projeto_projeto_id_seq'::regclass);


--
-- TOC entry 4949 (class 2604 OID 16913)
-- Name: rota_transporte rota_transporte_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rota_transporte ALTER COLUMN rota_transporte_id SET DEFAULT nextval('public.rota_transporte_rota_transporte_id_seq'::regclass);


--
-- TOC entry 4959 (class 2604 OID 16993)
-- Name: tipo_acessorios_moveis acessorio_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_acessorios_moveis ALTER COLUMN acessorio_id SET DEFAULT nextval('public.tipo_acessorios_moveis_acessorio_id_seq'::regclass);


--
-- TOC entry 4963 (class 2604 OID 17023)
-- Name: tipo_cor_moveis cor_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_cor_moveis ALTER COLUMN cor_id SET DEFAULT nextval('public.tipo_cor_moveis_cor_id_seq'::regclass);


--
-- TOC entry 4960 (class 2604 OID 17001)
-- Name: tipo_designer_interno designer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_designer_interno ALTER COLUMN designer_id SET DEFAULT nextval('public.tipo_designer_interno_designer_id_seq'::regclass);


--
-- TOC entry 4957 (class 2604 OID 16974)
-- Name: tipo_estabelecimento estabelecimento_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_estabelecimento ALTER COLUMN estabelecimento_id SET DEFAULT nextval('public.tipo_estabelecimento_estabelecimento_id_seq'::regclass);


--
-- TOC entry 4962 (class 2604 OID 17016)
-- Name: tipo_estilo_moveis estilo_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_estilo_moveis ALTER COLUMN estilo_id SET DEFAULT nextval('public.tipo_estilo_moveis_estilo_id_seq'::regclass);


--
-- TOC entry 4961 (class 2604 OID 17009)
-- Name: tipo_marca_moveis marca_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_marca_moveis ALTER COLUMN marca_id SET DEFAULT nextval('public.tipo_marca_moveis_marca_id_seq'::regclass);


--
-- TOC entry 4958 (class 2604 OID 16985)
-- Name: tipo_protecao_do_moveis protecao_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_protecao_do_moveis ALTER COLUMN protecao_id SET DEFAULT nextval('public.tipo_protecao_do_moveis_protecao_id_seq'::regclass);


--
-- TOC entry 4948 (class 2604 OID 16906)
-- Name: transporte transporte_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transporte ALTER COLUMN transporte_id SET DEFAULT nextval('public.transporte_transporte_id_seq'::regclass);


--
-- TOC entry 4950 (class 2604 OID 16923)
-- Name: veiculo_transporte veiculo_transporte_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.veiculo_transporte ALTER COLUMN veiculo_transporte_id SET DEFAULT nextval('public.veiculo_transporte_veiculo_transporte_id_seq'::regclass);


--
-- TOC entry 4952 (class 2604 OID 16944)
-- Name: venda venda_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda ALTER COLUMN venda_id SET DEFAULT nextval('public.venda_venda_id_seq'::regclass);


--
-- TOC entry 5275 (class 0 OID 16957)
-- Dependencies: 256
-- Data for Name: aluguel; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.aluguel (aluguel_id, fk_produto_id, fk_cliente_id, data_inicio, data_fim, preco_diario) VALUES (1, 501, 1, '2025-10-15', '2025-10-20', 50.00);
INSERT INTO public.aluguel (aluguel_id, fk_produto_id, fk_cliente_id, data_inicio, data_fim, preco_diario) VALUES (2, 503, 3, '2025-10-18', '2025-10-25', 30.00);
INSERT INTO public.aluguel (aluguel_id, fk_produto_id, fk_cliente_id, data_inicio, data_fim, preco_diario) VALUES (3, 502, 2, '2025-10-22', '2025-10-30', 80.00);


--
-- TOC entry 5259 (class 0 OID 16884)
-- Dependencies: 240
-- Data for Name: auditoria_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.auditoria_pedido (auditoria_id, pedido_id, data_registro, acao) VALUES (1001, 401, '2025-09-15 10:00:00', 'INSERIDO');
INSERT INTO public.auditoria_pedido (auditoria_id, pedido_id, data_registro, acao) VALUES (1002, 402, '2025-09-20 11:30:00', 'INSERIDO');


--
-- TOC entry 5243 (class 0 OID 16809)
-- Dependencies: 224
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.cliente (cliente_id, nome, cpf_cnpj, endereco, email, telefone) VALUES (1, 'João Silva', '123.456.789-00', 'Rua A, 100', 'joao.silva@email.com', '(11) 98765-4321');
INSERT INTO public.cliente (cliente_id, nome, cpf_cnpj, endereco, email, telefone) VALUES (2, 'Móveis & Cia', '00.111.222/0001-33', 'Av. B, 500', 'contato@moveiscia.com.br', '(21) 3333-2222');
INSERT INTO public.cliente (cliente_id, nome, cpf_cnpj, endereco, email, telefone) VALUES (3, 'moveis & eletros', '235.250.621-00', 'Rua Rio Grande do Norte n.56', 'moveis&eletros@email.com.br', '(31) 99876-5432');


--
-- TOC entry 5237 (class 0 OID 16782)
-- Dependencies: 218
-- Data for Name: embalagem; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.embalagem (embalagem_id, tipo_embalagem, protecao_termica, etiqueta_rastreamento) VALUES (301, 'Caixa de Papelão Reforçada', true, 'BR123456789');
INSERT INTO public.embalagem (embalagem_id, tipo_embalagem, protecao_termica, etiqueta_rastreamento) VALUES (302, 'Pallet Encaixotado', false, 'BR987654321');
INSERT INTO public.embalagem (embalagem_id, tipo_embalagem, protecao_termica, etiqueta_rastreamento) VALUES (303, 'Embalagem Plástica Bolha', true, 'BR112233445');


--
-- TOC entry 5253 (class 0 OID 16857)
-- Dependencies: 234
-- Data for Name: entrega; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.entrega (entrega_id, data_envio, destino, status_entrega_cod, fk_produto_id) VALUES (801, '2025-10-06', 'Rua A, 100 - Cliente 1', 1, 501);
INSERT INTO public.entrega (entrega_id, data_envio, destino, status_entrega_cod, fk_produto_id) VALUES (802, '2025-10-12', 'Av. B, 500 - Cliente 2', 0, 502);


--
-- TOC entry 5257 (class 0 OID 16877)
-- Dependencies: 238
-- Data for Name: itens_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.itens_pedido (fk_produto_id, fk_pedido_id, quantidade, preco_unitario) VALUES (501, 401, 1, 350.00);
INSERT INTO public.itens_pedido (fk_produto_id, fk_pedido_id, quantidade, preco_unitario) VALUES (502, 402, 1, 2500.00);
INSERT INTO public.itens_pedido (fk_produto_id, fk_pedido_id, quantidade, preco_unitario) VALUES (503, 403, 2, 450.00);


--
-- TOC entry 5261 (class 0 OID 16892)
-- Dependencies: 242
-- Data for Name: log_entregas_atrasadas; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.log_entregas_atrasadas (log_id, produto_id, data_entrega, dias_atraso, observacao, data_log) VALUES (2001, 501, '2025-10-15', 5, 'Entrega atrasada devido a condições climáticas.', '2025-10-15 14:00:00');
INSERT INTO public.log_entregas_atrasadas (log_id, produto_id, data_entrega, dias_atraso, observacao, data_log) VALUES (2002, 502, '2025-10-18', 3, 'Entrega atrasada por falta de material.', '2025-10-18 09:30:00');


--
-- TOC entry 5239 (class 0 OID 16792)
-- Dependencies: 220
-- Data for Name: material; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.material (material_id, nome, fornecedor, tipo_material_cod, custo_unitario) VALUES (101, 'MDF Branco 15mm', 'Madeireira Delta', 1, 45.50);
INSERT INTO public.material (material_id, nome, fornecedor, tipo_material_cod, custo_unitario) VALUES (102, 'Vidro Temperado 6mm', 'Vidraçaria Gema', 3, 85.00);
INSERT INTO public.material (material_id, nome, fornecedor, tipo_material_cod, custo_unitario) VALUES (103, 'Madeira Maciça Carvalho', 'Floresta Viva', 2, 120.75);


--
-- TOC entry 5251 (class 0 OID 16847)
-- Dependencies: 232
-- Data for Name: montagem; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.montagem (montagem_id, responsavel, data_montagem, aprovado_qc, fk_produto_id) VALUES (701, 'Carlos Mendes', '2025-10-05', true, 501);
INSERT INTO public.montagem (montagem_id, responsavel, data_montagem, aprovado_qc, fk_produto_id) VALUES (702, 'Lucas Pereira', NULL, NULL, 502);


--
-- TOC entry 5269 (class 0 OID 16932)
-- Dependencies: 250
-- Data for Name: motorista_transporte; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.motorista_transporte (motorista_transporte_id, fk_transporte_id, nome, cnh, telefone) VALUES (1, 1, 'João Carvalho', 'MG1234567', '(31) 91234-5678');
INSERT INTO public.motorista_transporte (motorista_transporte_id, fk_transporte_id, nome, cnh, telefone) VALUES (2, 2, 'Maria Fernandes', 'SP7654321', '(11) 99876-5432');
INSERT INTO public.motorista_transporte (motorista_transporte_id, fk_transporte_id, nome, cnh, telefone) VALUES (3, 3, 'Carlos Silva', 'RJ1122334', '(21) 98765-4321');


--
-- TOC entry 5277 (class 0 OID 16964)
-- Dependencies: 258
-- Data for Name: pagamento_aluguel; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pagamento_aluguel (pagamento_aluguel_id, fk_aluguel_id, metodo_pagamento, status_pagamento_cod, data_pagamento) VALUES (1, 1, 'Cartão de Crédito', 1, '2025-10-21');
INSERT INTO public.pagamento_aluguel (pagamento_aluguel_id, fk_aluguel_id, metodo_pagamento, status_pagamento_cod, data_pagamento) VALUES (2, 2, 'Boleto Bancário', 0, NULL);
INSERT INTO public.pagamento_aluguel (pagamento_aluguel_id, fk_aluguel_id, metodo_pagamento, status_pagamento_cod, data_pagamento) VALUES (3, 3, 'Transferência Bancária', 1, '2025-10-31');


--
-- TOC entry 5273 (class 0 OID 16950)
-- Dependencies: 254
-- Data for Name: pagamento_venda; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pagamento_venda (pagamento_id, fk_venda_id, metodo_pagamento, status_pagamento_cod, data_pagamento) VALUES (1, 1, 'Cartão de Crédito', 1, '2025-10-02');
INSERT INTO public.pagamento_venda (pagamento_id, fk_venda_id, metodo_pagamento, status_pagamento_cod, data_pagamento) VALUES (2, 2, 'Boleto Bancário', 0, NULL);
INSERT INTO public.pagamento_venda (pagamento_id, fk_venda_id, metodo_pagamento, status_pagamento_cod, data_pagamento) VALUES (3, 3, 'Transferência Bancária', 1, '2025-10-11');


--
-- TOC entry 5255 (class 0 OID 16866)
-- Dependencies: 236
-- Data for Name: peca; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.peca (peca_id, nome, tipo_processo_cod, medidas, fk_produto_id, fk_material_id) VALUES (901, 'Tampo da Mesa', 1, '650x650x15', 501, 101);
INSERT INTO public.peca (peca_id, nome, tipo_processo_cod, medidas, fk_produto_id, fk_material_id) VALUES (902, 'Perna da Mesa (x4)', 2, '600x50x50', 501, 103);
INSERT INTO public.peca (peca_id, nome, tipo_processo_cod, medidas, fk_produto_id, fk_material_id) VALUES (903, 'Porta do Armário', 1, '2000x600x18', 502, 101);


--
-- TOC entry 5256 (class 0 OID 16872)
-- Dependencies: 237
-- Data for Name: peca_processo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.peca_processo (fk_peca_id, fk_processo_id, status_cod, tempo_real_data) VALUES (901, 201, 1, '2025-10-01');
INSERT INTO public.peca_processo (fk_peca_id, fk_processo_id, status_cod, tempo_real_data) VALUES (902, 201, 1, '2025-10-01');
INSERT INTO public.peca_processo (fk_peca_id, fk_processo_id, status_cod, tempo_real_data) VALUES (902, 203, 2, '2025-10-02');


--
-- TOC entry 5245 (class 0 OID 16820)
-- Dependencies: 226
-- Data for Name: pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pedido (pedido_id, data_pedido, tipo_pedido_numerico, fk_cliente_id) VALUES (401, '2025-09-15', 1, 1);
INSERT INTO public.pedido (pedido_id, data_pedido, tipo_pedido_numerico, fk_cliente_id) VALUES (402, '2025-09-20', 2, 2);
INSERT INTO public.pedido (pedido_id, data_pedido, tipo_pedido_numerico, fk_cliente_id) VALUES (403, '2025-09-25', 1, 3);


--
-- TOC entry 5247 (class 0 OID 16828)
-- Dependencies: 228
-- Data for Name: processo_producao; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.processo_producao (processo_id, etapa_cod, ordem, descricao, tempo_estimado_min) VALUES (201, 1, 'A1', 'Corte de chapas de MDF/Madeira', 60);
INSERT INTO public.processo_producao (processo_id, etapa_cod, ordem, descricao, tempo_estimado_min) VALUES (202, 2, 'B1', 'Furação para dobradiças', 30);
INSERT INTO public.processo_producao (processo_id, etapa_cod, ordem, descricao, tempo_estimado_min) VALUES (203, 3, 'C1', 'Acabamento e polimento', 45);


--
-- TOC entry 5241 (class 0 OID 16800)
-- Dependencies: 222
-- Data for Name: produto; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.produto (produto_id, nome, status_producao, tipo_produto, data_criacao, dimensoes_m2, fk_embalagem_id) VALUES (501, 'Mesa Lateral Padrão', 'Em Produção', 'Serie', '2025-09-01', 0.65, 301);
INSERT INTO public.produto (produto_id, nome, status_producao, tipo_produto, data_criacao, dimensoes_m2, fk_embalagem_id) VALUES (502, 'Armário Sob Medida - Cliente 2', 'Aguardando Projeto', 'Sob Medida', '2025-09-22', 1.80, 302);
INSERT INTO public.produto (produto_id, nome, status_producao, tipo_produto, data_criacao, dimensoes_m2, fk_embalagem_id) VALUES (503, 'Cadeira de Escritório Ergonômica', 'Produzido', 'Serie', '2025-08-15', 0.50, 303);


--
-- TOC entry 5249 (class 0 OID 16838)
-- Dependencies: 230
-- Data for Name: projeto; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.projeto (projeto_id, descricao, designer, software_utilizado, data_conclusao, data_inicio, fk_produto_id) VALUES (601, 'Projeto detalhado para Armário Sob Medida.', 'Ana Souza', 'AutoCAD', '2025-09-25', '2025-09-21', 502);
INSERT INTO public.projeto (projeto_id, descricao, designer, software_utilizado, data_conclusao, data_inicio, fk_produto_id) VALUES (602, 'Design inicial para Mesa Lateral Padrão.', 'Pedro Rocha', 'SketchUp', '2025-09-10', '2025-09-01', 501);


--
-- TOC entry 5265 (class 0 OID 16910)
-- Dependencies: 246
-- Data for Name: rota_transporte; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.rota_transporte (rota_transporte_id, fk_transporte_id, descricao_rota, distancia_km) VALUES (1, 1, 'São Paulo - Rio de Janeiro', 430);
INSERT INTO public.rota_transporte (rota_transporte_id, fk_transporte_id, descricao_rota, distancia_km) VALUES (2, 2, 'São Paulo - Brasília', 1015);
INSERT INTO public.rota_transporte (rota_transporte_id, fk_transporte_id, descricao_rota, distancia_km) VALUES (3, 3, 'Rio de Janeiro - Santos', 300);


--
-- TOC entry 5283 (class 0 OID 16990)
-- Dependencies: 264
-- Data for Name: tipo_acessorios_moveis; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_acessorios_moveis (acessorio_id, nome, custo_adicional) VALUES (1, 'Puxadores de Alumínio', 10.00);
INSERT INTO public.tipo_acessorios_moveis (acessorio_id, nome, custo_adicional) VALUES (2, 'Rodízios para Móveis', 20.00);
INSERT INTO public.tipo_acessorios_moveis (acessorio_id, nome, custo_adicional) VALUES (3, 'Suportes Metálicos', 15.00);


--
-- TOC entry 5291 (class 0 OID 17020)
-- Dependencies: 272
-- Data for Name: tipo_cor_moveis; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_cor_moveis (cor_id, nome, codigo_hexadecimal) VALUES (1, 'Branco', '#FFFFFF');
INSERT INTO public.tipo_cor_moveis (cor_id, nome, codigo_hexadecimal) VALUES (2, 'Preto', '#000000');
INSERT INTO public.tipo_cor_moveis (cor_id, nome, codigo_hexadecimal) VALUES (3, 'Vermelho', '#FF0000');


--
-- TOC entry 5285 (class 0 OID 16998)
-- Dependencies: 266
-- Data for Name: tipo_designer_interno; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_designer_interno (designer_id, nome, especialidade) VALUES (1, 'Ana Souza', 'Móveis Sob Medida');
INSERT INTO public.tipo_designer_interno (designer_id, nome, especialidade) VALUES (2, 'Pedro Rocha', 'Design de Interiores');
INSERT INTO public.tipo_designer_interno (designer_id, nome, especialidade) VALUES (3, 'Carla Dias', 'Soluções Funcionais');


--
-- TOC entry 5279 (class 0 OID 16971)
-- Dependencies: 260
-- Data for Name: tipo_estabelecimento; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_estabelecimento (estabelecimento_id, nome, endereco, telefone, email, categoria) VALUES (1, 'moveis & eletros', 'Rua Rio Grande do Norte n.56', '(31) 99876-5432', 'moveis&eletros@email.com.br', 'loja');
INSERT INTO public.tipo_estabelecimento (estabelecimento_id, nome, endereco, telefone, email, categoria) VALUES (2, 'João Silva', 'Rua A, 100', '(11) 98765-4321', 'joao.silva@email.com', 'Pessoa_fisica');
INSERT INTO public.tipo_estabelecimento (estabelecimento_id, nome, endereco, telefone, email, categoria) VALUES (3, 'Apple', 'EUA rua t,120', '(32) 45249573', 'Apple@email.com.br', 'industria');


--
-- TOC entry 5289 (class 0 OID 17013)
-- Dependencies: 270
-- Data for Name: tipo_estilo_moveis; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_estilo_moveis (estilo_id, nome, descricao) VALUES (1, 'Moderno', 'Linhas retas e design minimalista');
INSERT INTO public.tipo_estilo_moveis (estilo_id, nome, descricao) VALUES (2, 'Rústico', 'Uso de madeira natural e acabamentos rústicos');
INSERT INTO public.tipo_estilo_moveis (estilo_id, nome, descricao) VALUES (3, 'Clássico', 'Detalhes ornamentados e design tradicional');


--
-- TOC entry 5287 (class 0 OID 17006)
-- Dependencies: 268
-- Data for Name: tipo_marca_moveis; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_marca_moveis (marca_id, nome, pais_origem) VALUES (1, 'FurniCraft', 'Brasil');
INSERT INTO public.tipo_marca_moveis (marca_id, nome, pais_origem) VALUES (2, 'WoodWorks', 'Estados Unidos');
INSERT INTO public.tipo_marca_moveis (marca_id, nome, pais_origem) VALUES (3, 'DecoraHome', 'Itália');


--
-- TOC entry 5281 (class 0 OID 16982)
-- Dependencies: 262
-- Data for Name: tipo_protecao_do_moveis; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_protecao_do_moveis (protecao_id, descricao, custo_adicional) VALUES (1, 'Capa Protetora de Tecido', 25.00);
INSERT INTO public.tipo_protecao_do_moveis (protecao_id, descricao, custo_adicional) VALUES (2, 'Película Protetora de Vidro', 15.00);
INSERT INTO public.tipo_protecao_do_moveis (protecao_id, descricao, custo_adicional) VALUES (3, 'Revestimento Anti-Riscos', 30.00);


--
-- TOC entry 5263 (class 0 OID 16903)
-- Dependencies: 244
-- Data for Name: transporte; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.transporte (transporte_id, nome, tipo_pedido_numerico, tipo_de_transporte) VALUES (1, 'TransLog', 1, 'Rodoviário');
INSERT INTO public.transporte (transporte_id, nome, tipo_pedido_numerico, tipo_de_transporte) VALUES (2, 'FastShip', 2, 'Aéreo');
INSERT INTO public.transporte (transporte_id, nome, tipo_pedido_numerico, tipo_de_transporte) VALUES (3, 'SeaCargo', 1, 'Marítimo');


--
-- TOC entry 5267 (class 0 OID 16920)
-- Dependencies: 248
-- Data for Name: veiculo_transporte; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.veiculo_transporte (veiculo_transporte_id, fk_transporte_id, placa, modelo, capacidade_kg) VALUES (1, 1, 'ABC-1234', 'Caminhão Volvo', 15000);
INSERT INTO public.veiculo_transporte (veiculo_transporte_id, fk_transporte_id, placa, modelo, capacidade_kg) VALUES (2, 2, 'DEF-5678', 'Avião Cargo Boeing', 50000);
INSERT INTO public.veiculo_transporte (veiculo_transporte_id, fk_transporte_id, placa, modelo, capacidade_kg) VALUES (3, 3, 'GHI-9012', 'Navio Cargueiro', 200000);


--
-- TOC entry 5271 (class 0 OID 16941)
-- Dependencies: 252
-- Data for Name: venda; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.venda (venda_id, fk_produto_id, fk_cliente_id, data_venda, quantidade, preco_total) VALUES (1, 503, 3, '2025-10-01', 2, 900.00);
INSERT INTO public.venda (venda_id, fk_produto_id, fk_cliente_id, data_venda, quantidade, preco_total) VALUES (2, 501, 1, '2025-10-05', 1, 350.00);
INSERT INTO public.venda (venda_id, fk_produto_id, fk_cliente_id, data_venda, quantidade, preco_total) VALUES (3, 502, 2, '2025-10-10', 1, 2500.00);


--
-- TOC entry 5325 (class 0 OID 0)
-- Dependencies: 255
-- Name: aluguel_aluguel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.aluguel_aluguel_id_seq', 1, false);


--
-- TOC entry 5326 (class 0 OID 0)
-- Dependencies: 239
-- Name: auditoria_pedido_auditoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auditoria_pedido_auditoria_id_seq', 1, false);


--
-- TOC entry 5327 (class 0 OID 0)
-- Dependencies: 223
-- Name: cliente_cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cliente_cliente_id_seq', 1, false);


--
-- TOC entry 5328 (class 0 OID 0)
-- Dependencies: 217
-- Name: embalagem_embalagem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.embalagem_embalagem_id_seq', 1, false);


--
-- TOC entry 5329 (class 0 OID 0)
-- Dependencies: 233
-- Name: entrega_entrega_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.entrega_entrega_id_seq', 1, false);


--
-- TOC entry 5330 (class 0 OID 0)
-- Dependencies: 241
-- Name: log_entregas_atrasadas_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_entregas_atrasadas_log_id_seq', 1, false);


--
-- TOC entry 5331 (class 0 OID 0)
-- Dependencies: 219
-- Name: material_material_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_material_id_seq', 1, false);


--
-- TOC entry 5332 (class 0 OID 0)
-- Dependencies: 231
-- Name: montagem_montagem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.montagem_montagem_id_seq', 1, false);


--
-- TOC entry 5333 (class 0 OID 0)
-- Dependencies: 249
-- Name: motorista_transporte_motorista_transporte_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motorista_transporte_motorista_transporte_id_seq', 1, false);


--
-- TOC entry 5334 (class 0 OID 0)
-- Dependencies: 257
-- Name: pagamento_aluguel_pagamento_aluguel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pagamento_aluguel_pagamento_aluguel_id_seq', 1, false);


--
-- TOC entry 5335 (class 0 OID 0)
-- Dependencies: 253
-- Name: pagamento_venda_pagamento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pagamento_venda_pagamento_id_seq', 1, false);


--
-- TOC entry 5336 (class 0 OID 0)
-- Dependencies: 235
-- Name: peca_peca_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.peca_peca_id_seq', 1, false);


--
-- TOC entry 5337 (class 0 OID 0)
-- Dependencies: 225
-- Name: pedido_pedido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedido_pedido_id_seq', 1, false);


--
-- TOC entry 5338 (class 0 OID 0)
-- Dependencies: 227
-- Name: processo_producao_processo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.processo_producao_processo_id_seq', 1, false);


--
-- TOC entry 5339 (class 0 OID 0)
-- Dependencies: 221
-- Name: produto_produto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.produto_produto_id_seq', 1, false);


--
-- TOC entry 5340 (class 0 OID 0)
-- Dependencies: 229
-- Name: projeto_projeto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projeto_projeto_id_seq', 1, false);


--
-- TOC entry 5341 (class 0 OID 0)
-- Dependencies: 245
-- Name: rota_transporte_rota_transporte_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rota_transporte_rota_transporte_id_seq', 1, false);


--
-- TOC entry 5342 (class 0 OID 0)
-- Dependencies: 263
-- Name: tipo_acessorios_moveis_acessorio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_acessorios_moveis_acessorio_id_seq', 1, false);


--
-- TOC entry 5343 (class 0 OID 0)
-- Dependencies: 271
-- Name: tipo_cor_moveis_cor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_cor_moveis_cor_id_seq', 1, false);


--
-- TOC entry 5344 (class 0 OID 0)
-- Dependencies: 265
-- Name: tipo_designer_interno_designer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_designer_interno_designer_id_seq', 1, false);


--
-- TOC entry 5345 (class 0 OID 0)
-- Dependencies: 259
-- Name: tipo_estabelecimento_estabelecimento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_estabelecimento_estabelecimento_id_seq', 1, false);


--
-- TOC entry 5346 (class 0 OID 0)
-- Dependencies: 269
-- Name: tipo_estilo_moveis_estilo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_estilo_moveis_estilo_id_seq', 1, false);


--
-- TOC entry 5347 (class 0 OID 0)
-- Dependencies: 267
-- Name: tipo_marca_moveis_marca_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_marca_moveis_marca_id_seq', 1, false);


--
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 261
-- Name: tipo_protecao_do_moveis_protecao_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipo_protecao_do_moveis_protecao_id_seq', 1, false);


--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 243
-- Name: transporte_transporte_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transporte_transporte_id_seq', 1, false);


--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 247
-- Name: veiculo_transporte_veiculo_transporte_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.veiculo_transporte_veiculo_transporte_id_seq', 1, false);


--
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 251
-- Name: venda_venda_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venda_venda_id_seq', 1, false);


--
-- TOC entry 5033 (class 2606 OID 16962)
-- Name: aluguel aluguel_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aluguel
    ADD CONSTRAINT aluguel_pkey PRIMARY KEY (aluguel_id);


--
-- TOC entry 5013 (class 2606 OID 16890)
-- Name: auditoria_pedido auditoria_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_pedido
    ADD CONSTRAINT auditoria_pedido_pkey PRIMARY KEY (auditoria_id);


--
-- TOC entry 4983 (class 2606 OID 16816)
-- Name: cliente cliente_cpf_cnpj_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_cpf_cnpj_key UNIQUE (cpf_cnpj);


--
-- TOC entry 4985 (class 2606 OID 16818)
-- Name: cliente cliente_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_email_key UNIQUE (email);


--
-- TOC entry 4987 (class 2606 OID 16814)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (cliente_id);


--
-- TOC entry 4975 (class 2606 OID 16790)
-- Name: embalagem embalagem_etiqueta_rastreamento_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.embalagem
    ADD CONSTRAINT embalagem_etiqueta_rastreamento_key UNIQUE (etiqueta_rastreamento);


--
-- TOC entry 4977 (class 2606 OID 16788)
-- Name: embalagem embalagem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.embalagem
    ADD CONSTRAINT embalagem_pkey PRIMARY KEY (embalagem_id);


--
-- TOC entry 5003 (class 2606 OID 16864)
-- Name: entrega entrega_fk_produto_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entrega
    ADD CONSTRAINT entrega_fk_produto_id_key UNIQUE (fk_produto_id);


--
-- TOC entry 5005 (class 2606 OID 16862)
-- Name: entrega entrega_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entrega
    ADD CONSTRAINT entrega_pkey PRIMARY KEY (entrega_id);


--
-- TOC entry 5011 (class 2606 OID 16882)
-- Name: itens_pedido itens_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT itens_pedido_pkey PRIMARY KEY (fk_produto_id, fk_pedido_id);


--
-- TOC entry 5015 (class 2606 OID 16901)
-- Name: log_entregas_atrasadas log_entregas_atrasadas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_entregas_atrasadas
    ADD CONSTRAINT log_entregas_atrasadas_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4979 (class 2606 OID 16798)
-- Name: material material_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material
    ADD CONSTRAINT material_pkey PRIMARY KEY (material_id);


--
-- TOC entry 4999 (class 2606 OID 16855)
-- Name: montagem montagem_fk_produto_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montagem
    ADD CONSTRAINT montagem_fk_produto_id_key UNIQUE (fk_produto_id);


--
-- TOC entry 5001 (class 2606 OID 16853)
-- Name: montagem montagem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montagem
    ADD CONSTRAINT montagem_pkey PRIMARY KEY (montagem_id);


--
-- TOC entry 5025 (class 2606 OID 16939)
-- Name: motorista_transporte motorista_transporte_cnh_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motorista_transporte
    ADD CONSTRAINT motorista_transporte_cnh_key UNIQUE (cnh);


--
-- TOC entry 5027 (class 2606 OID 16937)
-- Name: motorista_transporte motorista_transporte_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motorista_transporte
    ADD CONSTRAINT motorista_transporte_pkey PRIMARY KEY (motorista_transporte_id);


--
-- TOC entry 5035 (class 2606 OID 16969)
-- Name: pagamento_aluguel pagamento_aluguel_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_aluguel
    ADD CONSTRAINT pagamento_aluguel_pkey PRIMARY KEY (pagamento_aluguel_id);


--
-- TOC entry 5031 (class 2606 OID 16955)
-- Name: pagamento_venda pagamento_venda_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_venda
    ADD CONSTRAINT pagamento_venda_pkey PRIMARY KEY (pagamento_id);


--
-- TOC entry 5007 (class 2606 OID 16871)
-- Name: peca peca_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca
    ADD CONSTRAINT peca_pkey PRIMARY KEY (peca_id);


--
-- TOC entry 5009 (class 2606 OID 16876)
-- Name: peca_processo peca_processo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca_processo
    ADD CONSTRAINT peca_processo_pkey PRIMARY KEY (fk_peca_id, fk_processo_id);


--
-- TOC entry 4989 (class 2606 OID 16826)
-- Name: pedido pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT pedido_pkey PRIMARY KEY (pedido_id);


--
-- TOC entry 4991 (class 2606 OID 16836)
-- Name: processo_producao processo_producao_etapa_cod_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processo_producao
    ADD CONSTRAINT processo_producao_etapa_cod_key UNIQUE (etapa_cod);


--
-- TOC entry 4993 (class 2606 OID 16834)
-- Name: processo_producao processo_producao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processo_producao
    ADD CONSTRAINT processo_producao_pkey PRIMARY KEY (processo_id);


--
-- TOC entry 4981 (class 2606 OID 16807)
-- Name: produto produto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto
    ADD CONSTRAINT produto_pkey PRIMARY KEY (produto_id);


--
-- TOC entry 4995 (class 2606 OID 16845)
-- Name: projeto projeto_fk_produto_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT projeto_fk_produto_id_key UNIQUE (fk_produto_id);


--
-- TOC entry 4997 (class 2606 OID 16843)
-- Name: projeto projeto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT projeto_pkey PRIMARY KEY (projeto_id);


--
-- TOC entry 5019 (class 2606 OID 16918)
-- Name: rota_transporte rota_transporte_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rota_transporte
    ADD CONSTRAINT rota_transporte_pkey PRIMARY KEY (rota_transporte_id);


--
-- TOC entry 5043 (class 2606 OID 16996)
-- Name: tipo_acessorios_moveis tipo_acessorios_moveis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_acessorios_moveis
    ADD CONSTRAINT tipo_acessorios_moveis_pkey PRIMARY KEY (acessorio_id);


--
-- TOC entry 5051 (class 2606 OID 17027)
-- Name: tipo_cor_moveis tipo_cor_moveis_codigo_hexadecimal_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_cor_moveis
    ADD CONSTRAINT tipo_cor_moveis_codigo_hexadecimal_key UNIQUE (codigo_hexadecimal);


--
-- TOC entry 5053 (class 2606 OID 17025)
-- Name: tipo_cor_moveis tipo_cor_moveis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_cor_moveis
    ADD CONSTRAINT tipo_cor_moveis_pkey PRIMARY KEY (cor_id);


--
-- TOC entry 5045 (class 2606 OID 17003)
-- Name: tipo_designer_interno tipo_designer_interno_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_designer_interno
    ADD CONSTRAINT tipo_designer_interno_pkey PRIMARY KEY (designer_id);


--
-- TOC entry 5037 (class 2606 OID 16980)
-- Name: tipo_estabelecimento tipo_estabelecimento_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_estabelecimento
    ADD CONSTRAINT tipo_estabelecimento_email_key UNIQUE (email);


--
-- TOC entry 5039 (class 2606 OID 16978)
-- Name: tipo_estabelecimento tipo_estabelecimento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_estabelecimento
    ADD CONSTRAINT tipo_estabelecimento_pkey PRIMARY KEY (estabelecimento_id);


--
-- TOC entry 5049 (class 2606 OID 17018)
-- Name: tipo_estilo_moveis tipo_estilo_moveis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_estilo_moveis
    ADD CONSTRAINT tipo_estilo_moveis_pkey PRIMARY KEY (estilo_id);


--
-- TOC entry 5047 (class 2606 OID 17011)
-- Name: tipo_marca_moveis tipo_marca_moveis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_marca_moveis
    ADD CONSTRAINT tipo_marca_moveis_pkey PRIMARY KEY (marca_id);


--
-- TOC entry 5041 (class 2606 OID 16988)
-- Name: tipo_protecao_do_moveis tipo_protecao_do_moveis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_protecao_do_moveis
    ADD CONSTRAINT tipo_protecao_do_moveis_pkey PRIMARY KEY (protecao_id);


--
-- TOC entry 5017 (class 2606 OID 16908)
-- Name: transporte transporte_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transporte
    ADD CONSTRAINT transporte_pkey PRIMARY KEY (transporte_id);


--
-- TOC entry 5021 (class 2606 OID 16928)
-- Name: veiculo_transporte veiculo_transporte_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.veiculo_transporte
    ADD CONSTRAINT veiculo_transporte_pkey PRIMARY KEY (veiculo_transporte_id);


--
-- TOC entry 5023 (class 2606 OID 16930)
-- Name: veiculo_transporte veiculo_transporte_placa_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.veiculo_transporte
    ADD CONSTRAINT veiculo_transporte_placa_key UNIQUE (placa);


--
-- TOC entry 5029 (class 2606 OID 16948)
-- Name: venda venda_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT venda_pkey PRIMARY KEY (venda_id);


--
-- TOC entry 5081 (class 2620 OID 17145)
-- Name: peca trg_adicionar_acabamento_madeira; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_adicionar_acabamento_madeira AFTER INSERT ON public.peca FOR EACH ROW EXECUTE FUNCTION public.adicionar_acabamento_para_madeira_macica();


--
-- TOC entry 5079 (class 2620 OID 17139)
-- Name: montagem trg_atualizar_status_produto_montagem; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualizar_status_produto_montagem AFTER INSERT OR UPDATE ON public.montagem FOR EACH ROW EXECUTE FUNCTION public.atualizar_status_produto_apos_montagem();


--
-- TOC entry 5077 (class 2620 OID 17149)
-- Name: pedido trg_auditoria_pedido; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_pedido AFTER INSERT ON public.pedido FOR EACH ROW EXECUTE FUNCTION public.fn_auditar_pedido();


--
-- TOC entry 5078 (class 2620 OID 17143)
-- Name: pedido trg_definir_data_pedido; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_definir_data_pedido BEFORE INSERT ON public.pedido FOR EACH ROW EXECUTE FUNCTION public.definir_data_pedido_default();


--
-- TOC entry 5082 (class 2620 OID 17151)
-- Name: peca_processo trg_finaliza_producao; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_finaliza_producao AFTER INSERT OR UPDATE ON public.peca_processo FOR EACH ROW EXECUTE FUNCTION public.fn_verificar_fim_producao();


--
-- TOC entry 5076 (class 2620 OID 17141)
-- Name: cliente trg_validar_cpf_cnpj_cliente; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validar_cpf_cnpj_cliente BEFORE INSERT OR UPDATE ON public.cliente FOR EACH ROW EXECUTE FUNCTION public.validar_cpf_cnpj_cliente();


--
-- TOC entry 5080 (class 2620 OID 17147)
-- Name: entrega trg_verificar_entrega_atrasada; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_verificar_entrega_atrasada AFTER INSERT ON public.entrega FOR EACH ROW EXECUTE FUNCTION public.verificar_entrega_atrasada();


--
-- TOC entry 5073 (class 2606 OID 17128)
-- Name: aluguel fk_aluguel_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aluguel
    ADD CONSTRAINT fk_aluguel_cliente FOREIGN KEY (fk_cliente_id) REFERENCES public.cliente(cliente_id) ON DELETE RESTRICT;


--
-- TOC entry 5074 (class 2606 OID 17123)
-- Name: aluguel fk_aluguel_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aluguel
    ADD CONSTRAINT fk_aluguel_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE RESTRICT;


--
-- TOC entry 5065 (class 2606 OID 17083)
-- Name: auditoria_pedido fk_auditoria_pedido; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_pedido
    ADD CONSTRAINT fk_auditoria_pedido FOREIGN KEY (pedido_id) REFERENCES public.pedido(pedido_id) ON DELETE CASCADE;


--
-- TOC entry 5058 (class 2606 OID 17048)
-- Name: entrega fk_entrega_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entrega
    ADD CONSTRAINT fk_entrega_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE RESTRICT;


--
-- TOC entry 5063 (class 2606 OID 17078)
-- Name: itens_pedido fk_ip_pedido; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT fk_ip_pedido FOREIGN KEY (fk_pedido_id) REFERENCES public.pedido(pedido_id) ON DELETE CASCADE;


--
-- TOC entry 5064 (class 2606 OID 17073)
-- Name: itens_pedido fk_ip_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT fk_ip_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE RESTRICT;


--
-- TOC entry 5066 (class 2606 OID 17088)
-- Name: log_entregas_atrasadas fk_log_entrega_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_entregas_atrasadas
    ADD CONSTRAINT fk_log_entrega_produto FOREIGN KEY (produto_id) REFERENCES public.produto(produto_id) ON DELETE CASCADE;


--
-- TOC entry 5057 (class 2606 OID 17043)
-- Name: montagem fk_montagem_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montagem
    ADD CONSTRAINT fk_montagem_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE CASCADE;


--
-- TOC entry 5069 (class 2606 OID 17103)
-- Name: motorista_transporte fk_motorista_transporte_transporte; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motorista_transporte
    ADD CONSTRAINT fk_motorista_transporte_transporte FOREIGN KEY (fk_transporte_id) REFERENCES public.transporte(transporte_id) ON DELETE CASCADE;


--
-- TOC entry 5075 (class 2606 OID 17133)
-- Name: pagamento_aluguel fk_pagamento_aluguel; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_aluguel
    ADD CONSTRAINT fk_pagamento_aluguel FOREIGN KEY (fk_aluguel_id) REFERENCES public.aluguel(aluguel_id) ON DELETE CASCADE;


--
-- TOC entry 5072 (class 2606 OID 17118)
-- Name: pagamento_venda fk_pagamento_venda; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_venda
    ADD CONSTRAINT fk_pagamento_venda FOREIGN KEY (fk_venda_id) REFERENCES public.venda(venda_id) ON DELETE CASCADE;


--
-- TOC entry 5059 (class 2606 OID 17058)
-- Name: peca fk_peca_material; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca
    ADD CONSTRAINT fk_peca_material FOREIGN KEY (fk_material_id) REFERENCES public.material(material_id) ON DELETE RESTRICT;


--
-- TOC entry 5060 (class 2606 OID 17053)
-- Name: peca fk_peca_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca
    ADD CONSTRAINT fk_peca_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE CASCADE;


--
-- TOC entry 5055 (class 2606 OID 17038)
-- Name: pedido fk_pedido_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido
    ADD CONSTRAINT fk_pedido_cliente FOREIGN KEY (fk_cliente_id) REFERENCES public.cliente(cliente_id) ON DELETE RESTRICT;


--
-- TOC entry 5061 (class 2606 OID 17063)
-- Name: peca_processo fk_pp_peca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca_processo
    ADD CONSTRAINT fk_pp_peca FOREIGN KEY (fk_peca_id) REFERENCES public.peca(peca_id) ON DELETE CASCADE;


--
-- TOC entry 5062 (class 2606 OID 17068)
-- Name: peca_processo fk_pp_processo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peca_processo
    ADD CONSTRAINT fk_pp_processo FOREIGN KEY (fk_processo_id) REFERENCES public.processo_producao(processo_id) ON DELETE CASCADE;


--
-- TOC entry 5054 (class 2606 OID 17028)
-- Name: produto fk_produto_embalagem; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto
    ADD CONSTRAINT fk_produto_embalagem FOREIGN KEY (fk_embalagem_id) REFERENCES public.embalagem(embalagem_id) ON DELETE SET NULL;


--
-- TOC entry 5056 (class 2606 OID 17033)
-- Name: projeto fk_projeto_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT fk_projeto_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE CASCADE;


--
-- TOC entry 5067 (class 2606 OID 17093)
-- Name: rota_transporte fk_rota_transporte_transporte; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rota_transporte
    ADD CONSTRAINT fk_rota_transporte_transporte FOREIGN KEY (fk_transporte_id) REFERENCES public.transporte(transporte_id) ON DELETE CASCADE;


--
-- TOC entry 5068 (class 2606 OID 17098)
-- Name: veiculo_transporte fk_veiculo_transporte_transporte; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.veiculo_transporte
    ADD CONSTRAINT fk_veiculo_transporte_transporte FOREIGN KEY (fk_transporte_id) REFERENCES public.transporte(transporte_id) ON DELETE CASCADE;


--
-- TOC entry 5070 (class 2606 OID 17113)
-- Name: venda fk_venda_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT fk_venda_cliente FOREIGN KEY (fk_cliente_id) REFERENCES public.cliente(cliente_id) ON DELETE RESTRICT;


--
-- TOC entry 5071 (class 2606 OID 17108)
-- Name: venda fk_venda_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT fk_venda_produto FOREIGN KEY (fk_produto_id) REFERENCES public.produto(produto_id) ON DELETE RESTRICT;


-- Completed on 2025-11-27 21:04:43

--
-- PostgreSQL database dump complete
--

