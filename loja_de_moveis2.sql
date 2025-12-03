/* fabricademoveislogico_1: SCHEMA OTIMIZADO */

-- ==========================================================
-- 1. TABELAS PRINCIPAIS (DDL) - Correções de sintaxe e tipos
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
    Tipo_Material_Cod INTEGER NOT NULL, -- Alterado de NUMERIC para INTEGER (assumindo códigos inteiros)
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
    FK_Embalagem_ID INTEGER -- Chave estrangeira
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
    Tipo_Pedido_Numerico INTEGER, -- Alterado de NUMERIC para INTEGER
    FK_Cliente_ID INTEGER NOT NULL
);

-- PROCESSO DE PRODUÇÃO
CREATE TABLE Processo_Producao (
    Processo_ID SERIAL PRIMARY KEY,
    Etapa_Cod INTEGER UNIQUE NOT NULL, -- Alterado de NUMERIC para INTEGER
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
    FK_Produto_ID INTEGER UNIQUE -- Chave estrangeira
);

-- MONTAGEM
CREATE TABLE Montagem (
    Montagem_ID SERIAL PRIMARY KEY,
    Responsavel VARCHAR(100) NOT NULL,
    Data_Montagem DATE DEFAULT CURRENT_DATE,
    Aprovado_QC BOOLEAN,
    FK_Produto_ID INTEGER UNIQUE NOT NULL -- Chave estrangeira
);

-- ENTREGA
CREATE TABLE Entrega (
    Entrega_ID SERIAL PRIMARY KEY,
    Data_Envio DATE NOT NULL,
    Destino VARCHAR(255) NOT NULL,
    Status_Entrega_Cod INTEGER NOT NULL, -- Alterado de NUMERIC para INTEGER
    FK_Produto_ID INTEGER UNIQUE NOT NULL -- Chave estrangeira
);

-- PEÇA
CREATE TABLE Peca (
    Peca_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Tipo_Processo_Cod INTEGER, -- Alterado de NUMERIC para INTEGER
    Medidas VARCHAR(50),
    FK_Produto_ID INTEGER NOT NULL, -- Chave estrangeira
    FK_Material_ID INTEGER NOT NULL -- Chave estrangeira
);

-- PEÇA x PROCESSO (M:N)
CREATE TABLE Peca_Processo (
    FK_Peca_ID INTEGER,
    FK_Processo_ID INTEGER,
    Status_Cod INTEGER NOT NULL, -- 0: Pendente, 1: Em Andamento, 2: Finalizado. Alterado de NUMERIC para INTEGER
    Tempo_Real_Data DATE, -- Coluna renomeada de Tempo_Real_Data para Data_Conclusao_Processo (mais clara) ou mantida (manterei para não quebrar as funções existentes)
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

-- TRANSPORTE (Corrigido o nome da tabela de Tranporte para Transporte)
CREATE TABLE Transporte (
    Transporte_ID SERIAL PRIMARY KEY, -- Corrigido de transporte_id para Transporte_ID
    Nome VARCHAR(100) NOT NULL,
    Tipo_Pedido_Numerico INTEGER NOT NULL, -- Alterado de NUMERIC para INTEGER
    Tipo_de_Transporte VARCHAR(50) NOT NULL -- Corrigido o case
);

-- ROTA_TRANSPORTE
CREATE TABLE Rota_Transporte (
    Rota_Transporte_ID SERIAL PRIMARY KEY,
    FK_Transporte_ID INTEGER NOT NULL, -- Corrigido de transporte_id para FK_Transporte_ID para clareza
    Descricao_Rota VARCHAR(255) NOT NULL,
    Distancia_km NUMERIC CHECK (Distancia_km > 0) -- Corrigido parêntese de fechamento
);

-- VEICULO_TRANSPORTE
CREATE TABLE Veiculo_Transporte (
    Veiculo_Transporte_ID SERIAL PRIMARY KEY,
    FK_Transporte_ID INTEGER NOT NULL, -- Corrigido de transporte_id para FK_Transporte_ID
    Placa VARCHAR(20) UNIQUE NOT NULL,
    Modelo VARCHAR(100) NOT NULL,
    Capacidade_kg NUMERIC CHECK (Capacidade_kg > 0)
);

-- MOTORISTA_TRANSPORTE
CREATE TABLE Motorista_Transporte (
    Motorista_Transporte_ID SERIAL PRIMARY KEY,
    FK_Transporte_ID INTEGER NOT NULL, -- Corrigido de transporte_id para FK_Transporte_ID
    Nome VARCHAR(100) NOT NULL,
    CNH VARCHAR(20) UNIQUE NOT NULL,
    Telefone VARCHAR(20)
);

-- VENDA
CREATE TABLE VENDA (
    Venda_ID SERIAL PRIMARY KEY,
    FK_Produto_ID INTEGER NOT NULL,
    FK_Cliente_ID INTEGER NOT NULL,
    Data_Venda DATE DEFAULT CURRENT_DATE,
    Quantidade INTEGER NOT NULL CHECK (Quantidade > 0),
    Preco_Total DECIMAL(10,2) NOT NULL
);

-- PAGAMENTO_VENDA
CREATE TABLE Pagamento_Venda (
    Pagamento_ID SERIAL PRIMARY KEY,
    FK_Venda_ID INTEGER NOT NULL,
    Metodo_Pagamento VARCHAR(50) NOT NULL,
    Status_Pagamento_Cod INTEGER NOT NULL, -- Alterado de NUMERIC para INTEGER
    Data_Pagamento DATE
);

-- ALUGUEL (Corrigido o nome da tabela de ALUGUALO para ALUGUEL)
CREATE TABLE ALUGUEL (
    Aluguel_ID SERIAL PRIMARY KEY, -- Corrigido de Aluguel_ID para Aluguel_ID
    FK_Produto_ID INTEGER NOT NULL,
    FK_Cliente_ID INTEGER NOT NULL,
    Data_Inicio DATE NOT NULL,
    Data_Fim DATE NOT NULL,
    Preco_Diario DECIMAL(10,2) NOT NULL
);

-- PAGAMENTO_ALUGUEL
CREATE TABLE Pagamento_Aluguel (
    Pagamento_Aluguel_ID SERIAL PRIMARY KEY,
    FK_Aluguel_ID INTEGER NOT NULL,
    Metodo_Pagamento VARCHAR(50) NOT NULL,
    Status_Pagamento_Cod INTEGER NOT NULL, -- Alterado de NUMERIC para INTEGER
    Data_Pagamento DATE
);

-- TIPO_ESTABELECIMENTO (Corrigido o nome da tabela de TIPO_ESTABELRECIMENTO para TIPO_ESTABELECIMENTO)
CREATE TABLE TIPO_ESTABELECIMENTO (
    Estabelecimento_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Endereco VARCHAR(255) NOT NULL,
    Telefone VARCHAR(20),
    Email VARCHAR(100) UNIQUE,
    Categoria VARCHAR(50) -- Corrigido a sintaxe da coluna
);

-- TIPO_PROTECAO_DO_MOVEIS
CREATE TABLE TIPO_PROTECAO_DO_MOVEIS (
    Protecao_ID SERIAL PRIMARY KEY,
    Descricao VARCHAR(255) NOT NULL,
    Custo_Adicional DECIMAL(10,2) CHECK (Custo_Adicional >= 0)
);

-- TIPO_ACESSORIOS_MOVEIS
CREATE TABLE TIPO_ACESSORIOS_MOVEIS (
    Acessorio_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Custo_Adicional DECIMAL(10,2) CHECK (Custo_Adicional >= 0)
);

-- TIPO_DESIGNER_INTERNO
CREATE TABLE TIPO_DESIGNER_INTERNO (
    Designer_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Especialidade VARCHAR(100)
);

-- TIPO_MARCA_MOVEIS
CREATE TABLE TIPO_MARCA_MOVEIS (
    Marca_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Pais_Origem VARCHAR(100)
);

-- TIPO_ESTILO_MOVEIS
CREATE TABLE TIPO_ESTILO_MOVEIS (
    Estilo_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Descricao VARCHAR(255)
);

-- TIPO_COR_MOVEIS
CREATE TABLE TIPO_COR_MOVEIS (
    Cor_ID SERIAL PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Codigo_Hexadecimal VARCHAR(7) UNIQUE NOT NULL
);


-- ==========================================================
-- 2. CHAVES ESTRANGEIRAS - Adicionadas as FKs de Transporte e Aluguel
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

-- Chaves Estrangeiras de Transporte
ALTER TABLE Rota_Transporte ADD CONSTRAINT FK_Rota_Transporte_Transporte
    FOREIGN KEY (FK_Transporte_ID) REFERENCES Transporte (Transporte_ID)
    ON DELETE CASCADE;

ALTER TABLE Veiculo_Transporte ADD CONSTRAINT FK_Veiculo_Transporte_Transporte
    FOREIGN KEY (FK_Transporte_ID) REFERENCES Transporte (Transporte_ID)
    ON DELETE CASCADE;

ALTER TABLE Motorista_Transporte ADD CONSTRAINT FK_Motorista_Transporte_Transporte
    FOREIGN KEY (FK_Transporte_ID) REFERENCES Transporte (Transporte_ID)
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

-- Chaves Estrangeiras de ALUGUEL (Corrigido o nome da tabela)
ALTER TABLE ALUGUEL ADD CONSTRAINT FK_Aluguel_Produto
    FOREIGN KEY (FK_Produto_ID) REFERENCES Produto (Produto_ID)
    ON DELETE RESTRICT;
ALTER TABLE ALUGUEL ADD CONSTRAINT FK_Aluguel_Cliente
    FOREIGN KEY (FK_Cliente_ID) REFERENCES Cliente (Cliente_ID)
    ON DELETE RESTRICT;
ALTER TABLE Pagamento_Aluguel ADD CONSTRAINT FK_Pagamento_Aluguel
    FOREIGN KEY (FK_Aluguel_ID) REFERENCES ALUGUEL (Aluguel_ID)
    ON DELETE CASCADE;


-- ==========================================================
-- 3. INSERÇÃO DE DADOS (DML) - Corrigidos erros de sintaxe (INSERTs repetidos)
-- ==========================================================

-- CLIENTE (Dados mantidos)
INSERT INTO Cliente (Cliente_ID, Nome, CPF_CNPJ, Endereco, Email, Telefone) VALUES
(1, 'João Silva', '123.456.789-00', 'Rua A, 100', 'joao.silva@email.com', '(11) 98765-4321'),
(2, 'Móveis & Cia', '00.111.222/0001-33', 'Av. B, 500', 'contato@moveiscia.com.br', '(21) 3333-2222'),
(3, 'moveis & eletros', '235.250.621-00', 'Rua Rio Grande do Norte n.56', 'moveis&eletros@email.com.br', '(31) 99876-5432')
ON CONFLICT (Cliente_ID) DO NOTHING; -- Adicionado ON CONFLICT para evitar erros de chave primária em reexecução

-- MATERIAL (Dados mantidos)
INSERT INTO Material (Material_ID, Nome, Fornecedor, Tipo_Material_Cod, Custo_Unitario) VALUES
(101, 'MDF Branco 15mm', 'Madeireira Delta', 1, 45.50),
(102, 'Vidro Temperado 6mm', 'Vidraçaria Gema', 3, 85.00),
(103, 'Madeira Maciça Carvalho', 'Floresta Viva', 2, 120.75)
ON CONFLICT (Material_ID) DO NOTHING;

-- PROCESSO_PRODUCAO (Dados mantidos)
INSERT INTO Processo_Producao (Processo_ID, Etapa_Cod, Ordem, Descricao, Tempo_Estimado_min) VALUES
(201, 1, 'A1', 'Corte de chapas de MDF/Madeira', 60),
(202, 2, 'B1', 'Furação para dobradiças', 30),
(203, 3, 'C1', 'Acabamento e polimento', 45)
ON CONFLICT (Processo_ID) DO NOTHING;

-- EMBALAGEM (Dados mantidos)
INSERT INTO Embalagem (Embalagem_ID, Tipo_Embalagem, Protecao_Termica, Etiqueta_Rastreamento) VALUES
(301, 'Caixa de Papelão Reforçada', TRUE, 'BR123456789'),
(302, 'Pallet Encaixotado', FALSE, 'BR987654321'),
(303, 'Embalagem Plástica Bolha', TRUE, 'BR112233445')
ON CONFLICT (Embalagem_ID) DO NOTHING;

-- PRODUTO (Dados mantidos)
INSERT INTO Produto (Produto_ID, Nome, Status_Producao, Tipo_Produto, Data_Criacao, Dimensoes_m2, FK_Embalagem_ID) VALUES
(501, 'Mesa Lateral Padrão', 'Em Produção', 'Serie', '2025-09-01', 0.65, 301),
(502, 'Armário Sob Medida - Cliente 2', 'Aguardando Projeto', 'Sob Medida', '2025-09-22', 1.80, 302),
(503, 'Cadeira de Escritório Ergonômica', 'Produzido', 'Serie', '2025-08-15', 0.50, 303)
ON CONFLICT (Produto_ID) DO NOTHING;

-- PEDIDO (Dados mantidos)
INSERT INTO Pedido (Pedido_ID, FK_Cliente_ID, Data_Pedido, Tipo_Pedido_Numerico) VALUES
(401, 1, '2025-09-15', 1),
(402, 2, '2025-09-20', 2),
(403, 3, '2025-09-25', 1)
ON CONFLICT (Pedido_ID) DO NOTHING;

-- ITENS_PEDIDO (Dados mantidos)
INSERT INTO Itens_Pedido (FK_Produto_ID, FK_Pedido_ID, Quantidade, Preco_Unitario) VALUES
(501, 401, 1, 350.00),
(502, 402, 1, 2500.00),
(503, 403, 2, 450.00)
ON CONFLICT (FK_Produto_ID, FK_Pedido_ID) DO NOTHING;

-- PROJETO (Dados mantidos. O projeto 603 para o produto 501 é possível por ser UNIQUE na FK_Produto_ID, mas a sua inserção é inválida por violar a restrição UNIQUE.
-- Apenas os dois primeiros serão mantidos, pois a restrição UNIQUE na FK_Produto_ID só permite uma entrada por produto.)
INSERT INTO Projeto (Projeto_ID, Descricao, Designer, Software_Utilizado, Data_Conclusao, Data_Inicio, FK_Produto_ID) VALUES
(601, 'Projeto detalhado para Armário Sob Medida.', 'Ana Souza', 'AutoCAD', '2025-09-25', '2025-09-21', 502),
(602, 'Design inicial para Mesa Lateral Padrão.', 'Pedro Rocha', 'SketchUp', '2025-09-10', '2025-09-01', 501)
ON CONFLICT (Projeto_ID) DO NOTHING;
-- O INSERT 603 está duplicado, se necessário, use um ID diferente e um FK_Produto_ID diferente

-- MONTAGEM (Dados mantidos. O Montagem 703 para o produto 501 é possível por ser UNIQUE na FK_Produto_ID.
-- Apenas um Montagem por Produto é permitido. A primeira inserção (701) será mantida, a segunda (703) não.
INSERT INTO Montagem (Montagem_ID, Responsavel, Data_Montagem, Aprovado_QC, FK_Produto_ID) VALUES
(701, 'Carlos Mendes', '2025-10-05', TRUE, 501),
(702, 'Lucas Pereira', NULL, NULL, 502)
ON CONFLICT (Montagem_ID) DO NOTHING;
-- O INSERT 703 está duplicado, se necessário, use um ID diferente e um FK_Produto_ID diferente

-- ENTREGA (Dados mantidos. O Entrega 803 para o produto 503 não é válido por violar a restrição UNIQUE.
-- Apenas a primeira inserção (801) será mantida, a segunda (802) será mantida, a terceira (803) não.
INSERT INTO Entrega (Entrega_ID, Data_Envio, Destino, Status_Entrega_Cod, FK_Produto_ID) VALUES
(801, '2025-10-06', 'Rua A, 100 - Cliente 1', 1, 501),
(802, '2025-10-12', 'Av. B, 500 - Cliente 2', 0, 502)
ON CONFLICT (Entrega_ID) DO NOTHING;
-- O INSERT 803 está duplicado, se necessário, use um ID diferente e um FK_Produto_ID diferente

-- PEÇA (Dados mantidos)
INSERT INTO Peca (Peca_ID, Nome, Tipo_Processo_Cod, Medidas, FK_Produto_ID, FK_Material_ID) VALUES
(901, 'Tampo da Mesa', 1, '650x650x15', 501, 101),
(902, 'Perna da Mesa (x4)', 2, '600x50x50', 501, 103),
(903, 'Porta do Armário', 1, '2000x600x18', 502, 101)
ON CONFLICT (Peca_ID) DO NOTHING;

-- PECA_PROCESSO (Dados mantidos)
INSERT INTO Peca_Processo (FK_Peca_ID, FK_Processo_ID, Status_Cod, Tempo_Real_Data) VALUES
(901, 201, 1, '2025-10-01'),
(902, 201, 1, '2025-10-01'),
(902, 203, 2, '2025-10-02')
ON CONFLICT (FK_Peca_ID, FK_Processo_ID) DO NOTHING;

-- AUDITORIA_PEDIDO (Corrigido erro de sintaxe com o ';' duplicado e o INSERT duplicado)
INSERT INTO Auditoria_Pedido (Auditoria_ID, Pedido_ID, Data_Registro, Acao) VALUES
(1001, 401, '2025-09-15 10:00:00', 'INSERIDO'),
(1002, 402, '2025-09-20 11:30:00', 'INSERIDO')
ON CONFLICT (Auditoria_ID) DO NOTHING;

-- LOG_ENTREGAS_ATRASADAS (Corrigido erro de sintaxe com o ';' duplicado e o INSERT duplicado)
INSERT INTO Log_Entregas_Atrasadas (Log_ID, Produto_ID, Data_Entrega, Dias_Atraso, Observacao, Data_Log) VALUES
(2001, 501, '2025-10-15', 5, 'Entrega atrasada devido a condições climáticas.', '2025-10-15 14:00:00'),
(2002, 502, '2025-10-18', 3, 'Entrega atrasada por falta de material.', '2025-10-18 09:30:00')
ON CONFLICT (Log_ID) DO NOTHING;

-- TRANSPORTE (Corrigido o nome da tabela de Tranporte para Transporte)
INSERT INTO Transporte (Transporte_ID, Nome, Tipo_Pedido_Numerico, Tipo_de_Transporte) VALUES
(1, 'TransLog', 1, 'Rodoviário'),
(2, 'FastShip', 2, 'Aéreo'),
(3, 'SeaCargo', 1, 'Marítimo')
ON CONFLICT (Transporte_ID) DO NOTHING;

-- ROTA_TRANSPORTE (Corrigido de transporte_id para FK_Transporte_ID)
INSERT INTO Rota_Transporte (Rota_Transporte_ID, FK_Transporte_ID, Descricao_Rota, Distancia_km) VALUES
(1, 1, 'São Paulo - Rio de Janeiro', 430),
(2, 2, 'São Paulo - Brasília', 1015),
(3, 3, 'Rio de Janeiro - Santos', 300)
ON CONFLICT (Rota_Transporte_ID) DO NOTHING;

-- VEICULO_TRANSPORTE (Corrigido de transporte_id para FK_Transporte_ID)
INSERT INTO Veiculo_Transporte (Veiculo_Transporte_ID, FK_Transporte_ID, Placa, Modelo, Capacidade_kg) VALUES
(1, 1, 'ABC-1234', 'Caminhão Volvo', 15000),
(2, 2, 'DEF-5678', 'Avião Cargo Boeing', 50000),
(3, 3, 'GHI-9012', 'Navio Cargueiro', 200000)
ON CONFLICT (Veiculo_Transporte_ID) DO NOTHING;

-- MOTORISTA_TRANSPORTE (Corrigido de transporte_id para FK_Transporte_ID)
INSERT INTO Motorista_Transporte (Motorista_Transporte_ID, FK_Transporte_ID, Nome, CNH, Telefone) VALUES
(1, 1, 'João Carvalho', 'MG1234567', '(31) 91234-5678'),
(2, 2, 'Maria Fernandes', 'SP7654321', '(11) 99876-5432'),
(3, 3, 'Carlos Silva', 'RJ1122334', '(21) 98765-4321')
ON CONFLICT (Motorista_Transporte_ID) DO NOTHING;

-- VENDA (Dados mantidos)
INSERT INTO VENDA (Venda_ID, FK_Produto_ID, FK_Cliente_ID, Data_Venda, Quantidade, Preco_Total) VALUES
(1, 503, 3, '2025-10-01', 2, 900.00),
(2, 501, 1, '2025-10-05', 1, 350.00),
(3, 502, 2, '2025-10-10', 1, 2500.00)
ON CONFLICT (Venda_ID) DO NOTHING;

-- PAGAMENTO_VENDA (Dados mantidos)
INSERT INTO Pagamento_Venda (Pagamento_ID, FK_Venda_ID, Metodo_Pagamento, Status_Pagamento_Cod, Data_Pagamento) VALUES
(1, 1, 'Cartão de Crédito', 1, '2025-10-02'),
(2, 2, 'Boleto Bancário', 0, NULL),
(3, 3, 'Transferência Bancária', 1, '2025-10-11')
ON CONFLICT (Pagamento_ID) DO NOTHING;

-- ALUGUEL (Corrigido o nome da tabela de ALUGUALO para ALUGUEL)
INSERT INTO ALUGUEL (Aluguel_ID, FK_Produto_ID, FK_Cliente_ID, Data_Inicio, Data_Fim, Preco_Diario) VALUES
(1, 501, 1, '2025-10-15', '2025-10-20', 50.00),
(2, 503, 3, '2025-10-18', '2025-10-25', 30.00),
(3, 502, 2, '2025-10-22', '2025-10-30', 80.00)
ON CONFLICT (Aluguel_ID) DO NOTHING;

-- PAGAMENTO_ALUGUEL (Dados mantidos)
INSERT INTO Pagamento_Aluguel (Pagamento_Aluguel_ID, FK_Aluguel_ID, Metodo_Pagamento, Status_Pagamento_Cod, Data_Pagamento) VALUES
(1, 1, 'Cartão de Crédito', 1, '2025-10-21'),
(2, 2, 'Boleto Bancário', 0, NULL),
(3, 3, 'Transferência Bancária', 1, '2025-10-31')
ON CONFLICT (Pagamento_Aluguel_ID) DO NOTHING;

-- TIPO_ESTABELECIMENTO (Corrigido o nome da tabela e a sintaxe da coluna)
INSERT INTO TIPO_ESTABELECIMENTO (Estabelecimento_ID, Nome, Endereco, Telefone, Email, Categoria) VALUES
(1, 'moveis & eletros', 'Rua Rio Grande do Norte n.56', '(31) 99876-5432', 'moveis&eletros@email.com.br', 'loja'),
(2, 'João Silva', 'Rua A, 100', '(11) 98765-4321', 'joao.silva@email.com', 'Pessoa_fisica'), -- Corrigido o erro de sintaxe com parênteses extra
(3, 'Apple', 'EUA rua t,120', '(32) 45249573', 'Apple@email.com.br', 'industria')
ON CONFLICT (Estabelecimento_ID) DO NOTHING;

-- TIPO_PROTECAO_DO_MOVEIS (Dados mantidos)
INSERT INTO TIPO_PROTECAO_DO_MOVEIS (Protecao_ID, Descricao, Custo_Adicional) VALUES
(1, 'Capa Protetora de Tecido', 25.00),
(2, 'Película Protetora de Vidro', 15.00),
(3, 'Revestimento Anti-Riscos', 30.00)
ON CONFLICT (Protecao_ID) DO NOTHING;

-- TIPO_ACESSORIOS_MOVEIS (Dados mantidos)
INSERT INTO TIPO_ACESSORIOS_MOVEIS (Acessorio_ID, Nome, Custo_Adicional) VALUES
(1, 'Puxadores de Alumínio', 10.00),
(2, 'Rodízios para Móveis', 20.00),
(3, 'Suportes Metálicos', 15.00)
ON CONFLICT (Acessorio_ID) DO NOTHING;

-- TIPO_DESIGNER_INTERNO (Dados mantidos)
INSERT INTO TIPO_DESIGNER_INTERNO (Designer_ID, Nome, Especialidade) VALUES
(1, 'Ana Souza', 'Móveis Sob Medida'),
(2, 'Pedro Rocha', 'Design de Interiores'),
(3, 'Carla Dias', 'Soluções Funcionais')
ON CONFLICT (Designer_ID) DO NOTHING;

-- TIPO_MARCA_MOVEIS (Dados mantidos)
INSERT INTO TIPO_MARCA_MOVEIS (Marca_ID, Nome, Pais_Origem) VALUES
(1, 'FurniCraft', 'Brasil'),
(2, 'WoodWorks', 'Estados Unidos'),
(3, 'DecoraHome', 'Itália')
ON CONFLICT (Marca_ID) DO NOTHING;

-- TIPO_ESTILO_MOVEIS (Dados mantidos)
INSERT INTO TIPO_ESTILO_MOVEIS (Estilo_ID, Nome, Descricao) VALUES
(1, 'Moderno', 'Linhas retas e design minimalista'),
(2, 'Rústico', 'Uso de madeira natural e acabamentos rústicos'),
(3, 'Clássico', 'Detalhes ornamentados e design tradicional')
ON CONFLICT (Estilo_ID) DO NOTHING;

-- TIPO_COR_MOVEIS (Dados mantidos)
INSERT INTO TIPO_COR_MOVEIS (Cor_ID, Nome, Codigo_Hexadecimal) VALUES
(1, 'Branco', '#FFFFFF'),
(2, 'Preto', '#000000'),
(3, 'Vermelho', '#FF0000')
ON CONFLICT (Cor_ID) DO NOTHING;


-- ==========================================================
-- 4. FUNÇÕES E TRIGGERS (PL/pgSQL) - Funções Corrigidas (Tipo de dado em parâmetro)
-- ==========================================================

-- FUNÇÃO 1: Atualiza Status do Produto após Montagem (Mantida)
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

CREATE OR REPLACE TRIGGER trg_atualizar_status_produto_montagem
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

CREATE OR REPLACE TRIGGER trg_validar_cpf_cnpj_cliente
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

CREATE OR REPLACE TRIGGER trg_definir_data_pedido
BEFORE INSERT ON Pedido
FOR EACH ROW
EXECUTE FUNCTION definir_data_pedido_default();

-- FUNÇÃO 4: Adicionar Processo de Acabamento para Madeira Maciça (Corrigido Tipo de dado)
CREATE OR REPLACE FUNCTION adicionar_acabamento_para_madeira_macica()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_adicionar_acabamento_madeira
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

CREATE OR REPLACE TRIGGER trg_verificar_entrega_atrasada
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

CREATE OR REPLACE TRIGGER trg_auditoria_pedido
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

CREATE OR REPLACE TRIGGER trg_finaliza_producao
AFTER INSERT OR UPDATE ON Peca_Processo
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_fim_producao();


-- ==========================================================
-- 5. FUNÇÕES DE CONSULTA (Corrigidas)
-- ==========================================================

-- FUNÇÃO DE CONSULTA 1: Buscar Pedidos por Cliente (Corrigido Tipo de dado em retorno)
CREATE OR REPLACE FUNCTION buscar_pedidos_cliente(p_nome_cliente VARCHAR)
RETURNS TABLE (
    Pedido_ID INTEGER,
    Data_Pedido DATE,
    Tipo_Pedido INTEGER, -- Alterado de NUMERIC para INTEGER
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
    JOIN Itens_Pedido ip ON p.Pedido_ID = ip.FK_Pedido_ID
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

-- FUNÇÃO foi_alugado (Corrigido o nome da tabela de ALUGUALO para ALUGUEL)
CREATE OR REPLACE FUNCTION foi_alugado(p_produto_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM ALUGUEL WHERE FK_Produto_ID = p_produto_id -- Corrigido o nome da tabela
    ) INTO existe;

    RETURN existe;
END;
$$ LANGUAGE plpgsql;

-- FUNÇÃO foi_vendido (Mantida)
CREATE OR REPLACE FUNCTION foi_vendido(p_produto_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM VENDA WHERE FK_Produto_ID = p_produto_id
    ) INTO existe;

    RETURN existe;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION verificar_produto_utilizacao(p_produto_id INTEGER)
RETURNS TABLE (
    Foi_Vendido BOOLEAN,
    Foi_Alugado BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        foi_vendido(p_produto_id) AS Foi_Vendido,
        foi_alugado(p_produto_id) AS Foi_Alugado;
END;
$$ LANGUAGE plpgsql;

-- FUNÇÃO calcular_preco_aluguel_total (Corrigido o nome da tabela de ALUGUALO para ALUGUEL)
CREATE OR REPLACE FUNCTION calcular_preco_aluguel_total(p_produto_id INTEGER, p_data_inicio DATE, p_data_fim DATE)
RETURNS DECIMAL(10,2) AS $$
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
$$ LANGUAGE plpgsql;

-- FUNÇÃO calcular_preco_venda_total (Mantida)
CREATE OR REPLACE FUNCTION calcular_preco_venda_total(p_produto_id INTEGER, p_quantidade INTEGER)
RETURNS DECIMAL(10,2) AS $$
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
$$ LANGUAGE plpgsql;

-- FUNÇÃO Rotas_de_Transporte_efeitas (Corrigido erro de sintaxe 'reaplace' para 'REPLACE' e nome da coluna)
CREATE OR REPLACE FUNCTION rotas_de_transporte_efetivas(p_transporte_id INTEGER) -- Corrigido o nome da função
RETURNS integer AS $$
DECLARE
    total_rotas INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_rotas
    FROM Rota_Transporte
    WHERE FK_Transporte_ID = p_transporte_id; -- Corrigido o nome da coluna
    RETURN total_rotas;
END;
$$ LANGUAGE plpgsql;

-- ==========================================================
-- 6. VIEWS (Corrigidas)
-- ==========================================================

-- VIEW 1: Resumo de Pedidos (Mantida)
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
JOIN Itens_Pedido ip ON p.Pedido_ID = ip.FK_Pedido_ID
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

-- VIEW vw_clientes_compras (Corrigido o nome da tabela ALUGUALO para ALUGUEL)
CREATE OR REPLACE VIEW vw_clientes_compras AS
SELECT
    c.Cliente_ID,
    c.Nome AS Cliente,
    COUNT(DISTINCT v.Venda_ID) AS Total_Vendas,
    COUNT(DISTINCT a.Aluguel_ID) AS Total_Alugueis
FROM Cliente c
LEFT JOIN VENDA v ON v.FK_Cliente_ID = c.Cliente_ID
LEFT JOIN ALUGUEL a ON a.FK_Cliente_ID = c.Cliente_ID -- Corrigido o nome da tabela
GROUP BY c.Cliente_ID, c.Nome;

-- VIEW 3: Produtos e seus Materiais (Mantida)
CREATE OR REPLACE VIEW vw_produtos_materiais AS
SELECT
    pr.Produto_ID,
    pr.Nome AS Produto,
    m.Material_ID,
    m.Nome AS Material,
    m.Fornecedor,
    m.Custo_Unitario
FROM Produto pr
JOIN Peca pc ON pc.FK_Produto_ID = pr.Produto_ID
JOIN Material m ON pc.FK_Material_ID = m.Material_ID;

-- VIEW 4: Entregas Pendentes (Mantida)
CREATE OR REPLACE VIEW vw_entregas_pendentes AS
SELECT
    e.Entrega_ID,
    pr.Nome AS Produto,
    e.Data_Envio,
    e.Destino,
    e.Status_Entrega_Cod
FROM Entrega e
JOIN Produto pr ON e.FK_Produto_ID = pr.Produto_ID
WHERE e.Status_Entrega_Cod <> 3; -- Supondo 3 = Entregue

-- VIEW vw_ACESSORIOS_PROTECOES_DESIGNERS (Mantida)
CREATE OR REPLACE VIEW vw_acessorios_protecoes_designers AS -- Alterado para letras minúsculas no nome da view
SELECT
    a.Acessorio_ID,
    a.Nome AS Acessorio,
    a.Custo_Adicional AS Custo_Acessorio,
    p.Protecao_ID,
    p.Descricao AS Protecao,
    p.Custo_Adicional AS Custo_Protecao,
    d.Designer_ID,
    d.Nome AS Designer,
    d.Especialidade
FROM TIPO_ACESSORIOS_MOVEIS a
CROSS JOIN TIPO_PROTECAO_DO_MOVEIS p
CROSS JOIN TIPO_DESIGNER_INTERNO d;

-- VIEW 5: Transportes e suas Rotas (Corrigido o nome da tabela de Tranporte para Transporte e da coluna)
CREATE OR REPLACE VIEW vw_transportes_rotas AS
SELECT
    t.Transporte_ID, -- Corrigido o nome da coluna
    t.Nome AS Transporte,
    r.Rota_Transporte_ID,
    r.Descricao_Rota,
    r.Distancia_km
FROM Transporte t -- Corrigido o nome da tabela
JOIN Rota_Transporte r ON r.FK_Transporte_ID = t.Transporte_ID; -- Corrigido o nome da coluna

-- VIEW VW_DETALHES_FOI_Itens_Pedido (Corrigido erro de sintaxe 'CRATE' para 'CREATE' e nome da VIEW)
CREATE OR REPLACE VIEW vw_detalhes_itens_pedido AS -- Alterado o nome da view para um mais conciso
SELECT
    I.FK_Produto_ID,
    I.FK_Pedido_ID,
    I.Quantidade,
    I.Preco_Unitario,
    P.Nome AS Nome_Produto,
    C.Nome AS Nome_Cliente,
    PED.Data_Pedido
FROM Itens_Pedido I
JOIN Produto P ON I.FK_Produto_ID = P.Produto_ID
JOIN Pedido PED ON I.FK_Pedido_ID = PED.Pedido_ID
JOIN Cliente C ON PED.FK_Cliente_ID = C.Cliente_ID;