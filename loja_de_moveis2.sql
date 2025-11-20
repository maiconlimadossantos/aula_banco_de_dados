/* fabricademoveislogico_1: SCHEMA OTIMIZADO */

 1. TABELAS PRINCIPAIS (DDL)
-- (Inclui Chaves Primárias, Unique, Not Null e Check)
-- ==========================================================

-- EMBALAGEM
CREATE TABLE Embalagem (
    Embalagem_ID SERIAL PRIMARY KEY,
    Tipo_Embalagem VARCHAR(50) NOT NULL,
    Protecao_Termica BOOLEAN DEFAULT FALSE,
    Etiqueta_Rastreamento VARCHAR(50) UNIQUE
);

-- MATERIAL
CREATE TABLE Material (
    Material_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Fornecedor VARCHAR(100),
    Tipo_Material_Cod NUMERIC NOT NULL,
    Custo_Unitario DECIMAL(10,2) NOT NULL CHECK (Custo_Unitario >= 0)
);

-- PRODUTO
CREATE TABLE Produto (
    Produto_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Status_Producao VARCHAR(50) NOT NULL,
    Tipo_Produto VARCHAR(20),
    Data_Criacao DATE DEFAULT CURRENT_DATE,
    Dimensoes_m2 NUMERIC(10,2) CHECK (Dimensoes_m2 > 0),
    FK_Embalagem_ID INTEGER
);

-- CLIENTE
CREATE TABLE Cliente (
    Cliente_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    CPF_CNPJ VARCHAR(18) UNIQUE NOT NULL,
    Endereco VARCHAR(255),
    Email VARCHAR(100) UNIQUE,
    Telefone VARCHAR(20)
);

-- PEDIDO
CREATE TABLE Pedido (
    Pedido_ID SERIAL PRIMARY KEY,
    Data_Pedido DATE DEFAULT CURRENT_DATE,
    Tipo_Pedido_Numerico NUMERIC,
    FK_Cliente_ID INTEGER NOT NULL
);

-- PROCESSO DE PRODUÇÃO
CREATE TABLE Processo_Producao (
    Processo_ID SERIAL PRIMARY KEY,
    Etapa_Cod NUMERIC UNIQUE NOT NULL,
    Ordem VARCHAR(10) NOT NULL,
    Descricao VARCHAR(255),
    Tempo_Estimado_min INTEGER CHECK (Tempo_Estimado_min > 0)
);

-- PROJETO
CREATE TABLE Projeto (
    Projeto_ID SERIAL PRIMARY KEY,
    Descricao VARCHAR(255),
    Designer VARCHAR(100),
    Software_Utilizado VARCHAR(50),
    Data_Conclusao DATE,
    Data_Inicio DATE NOT NULL,
    FK_Produto_ID INTEGER UNIQUE
);

-- MONTAGEM
CREATE TABLE Montagem (
    Montagem_ID SERIAL PRIMARY KEY,
    Responsavel VARCHAR(100) NOT NULL,
    Data_Montagem DATE DEFAULT CURRENT_DATE,
    Aprovado_QC BOOLEAN,
    FK_Produto_ID INTEGER UNIQUE NOT NULL
);

-- ENTREGA
CREATE TABLE Entrega (
    Entrega_ID SERIAL PRIMARY KEY,
    Data_Envio DATE NOT NULL,
    Destino VARCHAR(255) NOT NULL,
    Status_Entrega_Cod NUMERIC NOT NULL,
    FK_Produto_ID INTEGER UNIQUE NOT NULL
);

-- PEÇA
CREATE TABLE Peca (
    Peca_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Tipo_Processo_Cod NUMERIC,
    Medidas VARCHAR(50),
    FK_Produto_ID INTEGER NOT NULL,
    FK_Material_ID INTEGER NOT NULL
);

-- PEÇA x PROCESSO (M:N)
CREATE TABLE Peca_Processo (
    FK_Peca_ID INTEGER,
    FK_Processo_ID INTEGER,
    Status_Cod NUMERIC NOT NULL, -- 0: Pendente, 1: Em Andamento, 2: Finalizado
    Tempo_Real_Data DATE,
    PRIMARY KEY (FK_Peca_ID, FK_Processo_ID)
);

-- PRODUTO x PEDIDO (M:N) - Tabela de itens do pedido
CREATE TABLE Itens_Pedido (
    FK_Produto_ID INTEGER,
    FK_Pedido_ID INTEGER,
    Quantidade INTEGER NOT NULL CHECK (Quantidade > 0),
    Preco_Unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (FK_Produto_ID, FK_Pedido_ID)
);

-- AUDITORIA E LOGS
CREATE TABLE Auditoria_Pedido (
    Auditoria_ID SERIAL PRIMARY KEY,
    Pedido_ID INTEGER NOT NULL,
    Data_Registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Acao VARCHAR(20) NOT NULL
);

CREATE TABLE Log_Entregas_Atrasadas (
    Log_ID SERIAL PRIMARY KEY,
    Produto_ID INTEGER NOT NULL,
    Data_Entrega DATE,
    Dias_Atraso INTEGER CHECK (Dias_Atraso > 0),
    Observacao TEXT,
    Data_Log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Tranporte(
transporte_id SERIAL PRIMARY KEY,
Nome VARCHAR(100) NOT NULL,
Tipo_Pedido_Numerico NUMERIC NOT NULL,
tipo_de_TRANSPORTE VARCHAR(50) NOT NULL,
);

CREATE TABLE Rota_Transporte(
    Rota_Transporte_ID SERIAL PRIMARY KEY,
    transporte_id INTEGER NOT NULL,
    Descricao_Rota VARCHAR(255) NOT NULL,
    Distancia_km NUMERIC CHECK (Distancia_km > 0
);

CREATE TABLE Veiculo_Transporte(
    Veiculo_Transporte_ID SERIAL PRIMARY KEY,
    transporte_id INTEGER NOT NULL,
    Placa VARCHAR(20) UNIQUE NOT NULL,
    Modelo VARCHAR(100) NOT NULL,
    Capacidade_kg NUMERIC CHECK (Capacidade_kg > 0)
);

CREATE TABLE Motorista_Transporte(
    Motorista_Transporte_ID SERIAL PRIMARY KEY,
    transporte_id INTEGER NOT NULL,
    Nome VARCHAR(100) NOT NULL,
    CNH VARCHAR(20) UNIQUE NOT NULL,
    Telefone VARCHAR(20)
);

CREATE TABLE VENDA(
    Venda_ID SERIAL PRIMARY KEY,
    FK_Produto_ID INTEGER NOT NULL,
    FK_Cliente_ID INTEGER NOT NULL,
    Data_Venda DATE DEFAULT CURRENT_DATE,
    Quantidade INTEGER NOT NULL CHECK (Quantidade > 0),
    Preco_Total DECIMAL(10,2) NOT NULL
);
CREATE TABLE Pagamento_Venda(
    Pagamento_ID SERIAL PRIMARY KEY,
    FK_Venda_ID INTEGER NOT NULL,
    Metodo_Pagamento VARCHAR(50) NOT NULL,
    Status_Pagamento_Cod NUMERIC NOT NULL,
    Data_Pagamento DATE
);

CREATE TABLE ALUGUALO(
    Aluguel_ID SERIAL PRIMARY KEY,
    FK_Produto_ID INTEGER NOT NULL,
    FK_Cliente_ID INTEGER NOT NULL,
    Data_Inicio DATE NOT NULL,
    Data_Fim DATE NOT NULL,
    Preco_Diario DECIMAL(10,2) NOT NULL
);
CREATE TABLE Pagamento_Aluguel(
    Pagamento_Aluguel_ID SERIAL PRIMARY KEY,
    FK_Aluguel_ID INTEGER NOT NULL,
    Metodo_Pagamento VARCHAR(50) NOT NULL,
    Status_Pagamento_Cod NUMERIC NOT NULL,
    Data_Pagamento DATE
);

CREATE TABLE TIPO_ESTABELRECIMENTO(
    Estabelecimento_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Endereco VARCHAR(255) NOT NULL,
    Telefone VARCHAR(20),
    Email VARCHAR(100) UNIQUE
);

CREATE TABLE TIPO_PROTECAO_DO_MOVEIS(
    Protecao_ID SERIAL PRIMARY KEY,
    Descricao VARCHAR(255) NOT NULL,
    Custo_Adicional DECIMAL(10,2) CHECK (Custo_Adicional >= 0)
);

CREATE TABLE TIPO_ACESSORIOS_MOVEIS(
    Acessorio_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Custo_Adicional DECIMAL(10,2) CHECK (Custo_Adicional >= 0)
);

CREATE TABLE TIPO_DESIGNER_INTERNO(
    Designer_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Especialidade VARCHAR(100)
);
CREATE TABLE TIPO_MARCA_MOVEIS(
    Marca_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Pais_Origem VARCHAR(100)
);

CREATE TABLE TIPO_ESTILO_MOVEIS(
    Estilo_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Descricao VARCHAR(255)
);
CREATE TABLE TIPO_COR_MOVEIS(
    Cor_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Codigo_Hexadecimal VARCHAR(7) UNIQUE NOT NULL
);


-- ==========================================================
-- 2. CHAVES ESTRANGEIRAS
-- ==========================================================

ALTER TABLE Produto ADD CONSTRAINT FK_Produto_Embalagem
    FOREIGN KEY (FK_Embalagem_ID) REFERENCES Embalagem (Embalagem_ID)
    ON DELETE SET NULL;

ALTER TABLE Projeto ADD CONSTRAINT FK_Projeto_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE CASCADE;

ALTER TABLE Pedido ADD CONSTRAINT FK_Pedido_Cliente
    FOREIGN KEY (FK_Cliente_ID) REFERENCES Cliente (Cliente_ID)
    ON DELETE RESTRICT;

ALTER TABLE Montagem ADD CONSTRAINT FK_Montagem_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE CASCADE;

ALTER TABLE Entrega ADD CONSTRAINT FK_Entrega_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE RESTRICT;

ALTER TABLE Peca ADD CONSTRAINT FK_Peca_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE CASCADE;

ALTER TABLE Peca ADD CONSTRAINT FK_Peca_Material
    FOREIGN KEY (FK_Material_ID) REFERENCES Material (Material_ID)
    ON DELETE RESTRICT;

ALTER TABLE Peca_Processo ADD CONSTRAINT FK_PP_Peca
    FOREIGN KEY (FK_Peca_ID) REFERENCES Peca (Peca_ID)
    ON DELETE CASCADE;

ALTER TABLE Peca_Processo ADD CONSTRAINT FK_PP_Processo
    FOREIGN KEY (FK_Processo_ID) REFERENCES Processo_Producao (Processo_ID)
    ON DELETE CASCADE;

ALTER TABLE Itens_Pedido ADD CONSTRAINT FK_IP_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE RESTRICT;

ALTER TABLE Itens_Pedido ADD CONSTRAINT FK_IP_Pedido
    FOREIGN KEY (FK_Pedido_ID) REFERENCES Pedido (Pedido_ID)
    ON DELETE CASCADE;

ALTER TABLE Auditoria_Pedido ADD CONSTRAINT FK_Auditoria_Pedido
    FOREIGN KEY (Pedido_ID) REFERENCES Pedido (Pedido_ID)
    ON DELETE CASCADE;
ALTER TABLE Log_Entregas_Atrasadas ADD CONSTRAINT FK_Log_Entrega_Produto
    FOREIGN KEY (Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE CASCADE;

ALTER TABLE VENDA ADD CONSTRAINT FK_Venda_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE RESTRICT;
ALTER TABLE VENDA ADD CONSTRAINT FK_Venda_Cliente
    FOREIGN KEY (FK_Cliente_ID) REFERENCES Cliente (Cliente_ID)
    ON DELETE RESTRICT;
ALTER TABLE Pagamento_Venda ADD CONSTRAINT FK_Pagamento_Venda
    FOREIGN KEY (FK_Venda_ID) REFERENCES VENDA (Venda_ID)
    ON DELETE CASCADE;
ALTER TABLE ALUGUALO ADD CONSTRAINT FK_Aluguel_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE RESTRICT;
ALTER TABLE ALUGUALO ADD CONSTRAINT FK_Aluguel_Cliente
    FOREIGN KEY (FK_Cliente_ID) REFERENCES Cliente (Cliente_ID)
    ON DELETE RESTRICT;
ALTER TABLE Pagamento_Aluguel ADD CONSTRAINT FK_Pagamento_Aluguel
    FOREIGN KEY (FK_Aluguel_ID) REFERENCES ALUGUALO (Aluguel_ID)
    ON DELETE CASCADE;

-- ==========================================================
-- 3. INSERÇÃO DE DADOS (DML) - Corrigida
-- ==========================================================

-- CLIENTE
INSERT INTO Cliente (Cliente_ID, Nome, CPF_CNPJ, Endereco, Email, Telefone) VALUES
(1, 'João Silva', '123.456.789-00', 'Rua A, 100', 'joao.silva@email.com', '(11) 98765-4321'),
(2, 'Móveis & Cia', '00.111.222/0001-33', 'Av. B, 500', 'contato@moveiscia.com.br', '(21) 3333-2222');

-- MATERIAL
INSERT INTO Material (Material_ID, Nome, Fornecedor, Tipo_Material_Cod, Custo_Unitario) VALUES
(101, 'MDF Branco 15mm', 'Madeireira Delta', 1, 45.50),
(102, 'Vidro Temperado 6mm', 'Vidraçaria Gema', 3, 85.00),
(103, 'Madeira Maciça Carvalho', 'Floresta Viva', 2, 120.75); -- Tipo_Material_Cod = 2 para Madeira Maciça

-- PROCESSO_PRODUCAO
INSERT INTO Processo_Producao (Processo_ID, Etapa_Cod, Ordem, Descricao, Tempo_Estimado_min) VALUES
(201, 1, 'A1', 'Corte de chapas de MDF/Madeira', 60),
(202, 2, 'B1', 'Furação para dobradiças', 30),
(203, 3, 'C1', 'Acabamento e polimento', 45); -- Etapa_Cod = 3 para Acabamento

-- EMBALAGEM
INSERT INTO Embalagem (Embalagem_ID, Tipo_Embalagem, Protecao_Termica, Etiqueta_Rastreamento) VALUES
(301, 'Caixa de Papelão Reforçada', TRUE, 'BR123456789'),
(302, 'Pallet Encaixotado', FALSE, 'BR987654321');

-- PRODUTO
INSERT INTO Produto (Produto_ID, Nome, Status_Producao, Tipo_Produto, Data_Criacao, Dimensoes_m2, FK_Embalagem_ID) VALUES
(501, 'Mesa Lateral Padrão', 'Em Produção', 'Serie', '2025-09-01', 0.65, 301),
(502, 'Armário Sob Medida - Cliente 2', 'Aguardando Projeto', 'Sob Medida', '2025-09-22', 1.80, 302);

-- PEDIDO (Corrigida a remoção do FK_Produto_ID)
INSERT INTO Pedido (Pedido_ID, FK_Cliente_ID, Data_Pedido, Tipo_Pedido_Numerico) VALUES
(401, 1, '2025-09-15', 1),
(402, 2, '2025-09-20', 2);

-- ITENS_PEDIDO (Corrigida a tabela e a inclusão de Quantidade e Preco_Unitario)
INSERT INTO Itens_Pedido (FK_Produto_ID, FK_Pedido_ID, Quantidade, Preco_Unitario) VALUES
(501, 401, 1, 350.00), -- 1 Mesa Lateral no Pedido 401
(502, 402, 1, 2500.00); -- 1 Armário no Pedido 402

-- PROJETO (Corrigida a remoção do FK_Material_ID)
INSERT INTO Projeto (Projeto_ID, Descricao, Designer, Software_Utilizado, Data_Conclusao, Data_Inicio, FK_Produto_ID) VALUES
(601, 'Projeto detalhado para Armário Sob Medida.', 'Ana Souza', 'AutoCAD', '2025-09-25', '2025-09-21', 502);

-- MONTAGEM
INSERT INTO Montagem (Montagem_ID, Responsavel, Data_Montagem, Aprovado_QC, FK_Produto_ID) VALUES
(701, 'Carlos Mendes', '2025-10-05', TRUE, 501);

-- ENTREGA
INSERT INTO Entrega (Entrega_ID, Data_Envio, Destino, Status_Entrega_Cod, FK_Produto_ID) VALUES
(801, '2025-10-06', 'Rua A, 100 - Cliente 1', 1, 501);

-- PEÇA
INSERT INTO Peca (Peca_ID, Nome, Tipo_Processo_Cod, Medidas, FK_Produto_ID, FK_Material_ID) VALUES
(901, 'Tampo da Mesa', 1, '650x650x15', 501, 101), -- MDF Branco
(902, 'Perna da Mesa (x4)', 2, '600x50x50', 501, 103); -- Madeira Maciça Carvalho (Tipo_Material_Cod 2)

-- PECA_PROCESSO
INSERT INTO Peca_Processo (FK_Peca_ID, FK_Processo_ID, Status_Cod, Tempo_Real_Data) VALUES
(901, 201, 1, '2025-10-01'), -- Tampo: Corte (Em Andamento)
(902, 201, 1, '2025-10-01'), -- Perna: Corte (Em Andamento)
(902, 203, 2, '2025-10-02'); -- Perna: Acabamento (Finalizado) - Erro de lógica, processo 203 é acabamento/polimento. Status 2 = Finalizado.

-- ==========================================================
-- 4. FUNÇÕES E TRIGGERS (PL/pgSQL) - Funções Corrigidas
-- (As funções que dependiam de FK_Produto_ID em Pedido foram corrigidas)
-- ==========================================================

-- FUNÇÃO 1: Atualiza Status do Produto após Montagem
CREATE OR REPLACE FUNCTION atualizar_status_produto_apos_montagem()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Aprovado_QC = TRUE THEN
        UPDATE Produto
        SET Status_Producao = 'Montado'
        WHERE Produto_ID = NEW.FK_Produto_ID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualizar_status_produto_montagem
AFTER INSERT OR UPDATE ON Montagem
FOR EACH ROW
EXECUTE FUNCTION atualizar_status_produto_apos_montagem();

-- FUNÇÃO 2: Validação de CPF/CNPJ (Mantida)
CREATE OR REPLACE FUNCTION validar_cpf_cnpj_cliente()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Cliente WHERE CPF_CNPJ = NEW.CPF_CNPJ AND Cliente_ID != NEW.Cliente_ID
    ) THEN
        RAISE EXCEPTION 'CPF/CNPJ "%" já está cadastrado.', NEW.CPF_CNPJ;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_cpf_cnpj_cliente
BEFORE INSERT OR UPDATE ON Cliente
FOR EACH ROW
EXECUTE FUNCTION validar_cpf_cnpj_cliente();

-- FUNÇÃO 3: Definir data de pedido default (Mantida)
CREATE OR REPLACE FUNCTION definir_data_pedido_default()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Data_Pedido IS NULL THEN
        NEW.Data_Pedido := CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_definir_data_pedido
BEFORE INSERT ON Pedido
FOR EACH ROW
EXECUTE FUNCTION definir_data_pedido_default();

-- FUNÇÃO 4: Adicionar Processo de Acabamento para Madeira Maciça (Mantida)
CREATE OR REPLACE FUNCTION adicionar_acabamento_para_madeira_macica()
RETURNS TRIGGER AS $$
DECLARE
    tipo_material_cod NUMERIC;
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_adicionar_acabamento_madeira
AFTER INSERT ON Peca
FOR EACH ROW
EXECUTE FUNCTION adicionar_acabamento_para_madeira_macica();

-- FUNÇÃO 5: Verificar Entrega Atrasada (Mantida)
CREATE OR REPLACE FUNCTION verificar_entrega_atrasada()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verificar_entrega_atrasada
AFTER INSERT ON Entrega
FOR EACH ROW
EXECUTE FUNCTION verificar_entrega_atrasada();

-- FUNÇÃO 6: Auditoria de Pedido (Mantida)
CREATE OR REPLACE FUNCTION fn_auditar_pedido()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Auditoria_Pedido (Pedido_ID, Acao)
    VALUES (NEW.Pedido_ID, 'INSERIDO');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_pedido
AFTER INSERT ON Pedido
FOR EACH ROW
EXECUTE FUNCTION fn_auditar_pedido();

-- FUNÇÃO 7: Verificar Fim de Produção (Mantida)
CREATE OR REPLACE FUNCTION fn_verificar_fim_producao()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_finaliza_producao
AFTER INSERT OR UPDATE ON Peca_Processo
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_fim_producao();


-- ==========================================================
-- 5. FUNÇÕES DE CONSULTA (Corrigidas)
-- ==========================================================

-- FUNÇÃO DE CONSULTA 1: Buscar Pedidos por Cliente (Corrigida para usar Itens_Pedido)
CREATE OR REPLACE FUNCTION buscar_pedidos_cliente(p_nome_cliente VARCHAR)
RETURNS TABLE (
    Pedido_ID INTEGER,
    Data_Pedido DATE,
    Tipo_Pedido NUMERIC,
    Produto_Nome VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.Pedido_ID,
        p.Data_Pedido,
        p.Tipo_Pedido_Numerico,
        pr.Nome
    FROM Pedido p
    JOIN Cliente c ON p.FK_Cliente_ID = c.Cliente_ID
    JOIN Itens_Pedido ip ON p.Pedido_ID = ip.FK_Pedido_ID  -- Correção: Usar Itens_Pedido
    JOIN Produto pr ON ip.FK_Produto_ID = pr.Produto_ID
    WHERE c.Nome ILIKE '%' || p_nome_cliente || '%';
END;
$$ LANGUAGE plpgsql;

-- FUNÇÃO DE CONSULTA 2: Custo Total de Materiais do Produto (Mantida)
CREATE OR REPLACE FUNCTION custo_total_materiais_produto(p_produto_id INTEGER)
RETURNS DECIMAL(10,2) AS $$
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
$$ LANGUAGE plpgsql;

-- FUNÇÃO DE CONSULTA 3: Tempo Estimado Total de Produção (Mantida)
CREATE OR REPLACE FUNCTION tempo_estimado_total_producao(p_produto_id INTEGER)
RETURNS INTEGER AS $$
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
$$ LANGUAGE plpgsql;

-- FUNÇÃO DE CONSULTA 4: Listar Produtos por Status (Mantida)
CREATE OR REPLACE FUNCTION listar_produtos_por_status(p_status VARCHAR)
RETURNS TABLE (
    Produto_ID INTEGER,
    Nome VARCHAR,
    Tipo_Produto VARCHAR,
    Status_Producao VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT Produto_ID, Nome, Tipo_Produto, Status_Producao
    FROM Produto
    WHERE Status_Producao ILIKE '%' || p_status || '%';
END;
$$ LANGUAGE plpgsql;

-- FUNÇÃO DE CONSULTA 5: Verificar se Produto Foi Entregue (Mantida)
CREATE OR REPLACE FUNCTION produto_foi_entregue(p_produto_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM Entrega WHERE FK_Produto_ID = p_produto_id
    ) INTO existe;

    RETURN existe;
END;
$$ LANGUAGE plpgsql;


-- ==========================================================
-- 6. VIEWS (Corrigidas)
-- ==========================================================

-- VIEW 1: Resumo de Pedidos (Corrigida para usar Itens_Pedido)
CREATE OR REPLACE VIEW vw_resumo_pedidos AS
SELECT 
    p.Pedido_ID,
    c.Nome AS Cliente,
    pr.Nome AS Produto,
    ip.Quantidade,
    ip.Preco_Unitario,
    CASE p.Tipo_Pedido_Numerico
        WHEN 1 THEN 'Série'
        WHEN 2 THEN 'Sob Medida'
        ELSE 'Outro'
    END AS Tipo_Pedido,
    p.Data_Pedido
FROM Pedido p
JOIN Cliente c ON p.FK_Cliente_ID = c.Cliente_ID
JOIN Itens_Pedido ip ON p.Pedido_ID = ip.FK_Pedido_ID -- Correção: Usar Itens_Pedido
JOIN Produto pr ON ip.FK_Produto_ID = pr.Produto_ID;

-- VIEW 2: Produção em Andamento (Mantida)
CREATE OR REPLACE VIEW vw_producao_em_andamento AS
SELECT 
    pr.Produto_ID,
    pr.Nome AS Produto,
    pc.Peca_ID,
    pc.Nome AS Peca,
    pp.Processo_ID,
    pp.Descricao AS Processo,
    ppx.Status_Cod,
    ppx.Tempo_Real_Data
FROM Produto pr
JOIN Peca pc ON pc.FK_Produto_ID = pr.Produto_ID
JOIN Peca_Processo ppx ON ppx.FK_Peca_ID = pc.Peca_ID
JOIN Processo_Producao pp ON pp.Processo_ID = ppx.FK_Processo_ID
WHERE ppx.Status_Cod IS DISTINCT FROM 2; -- 2 = Finalizado

