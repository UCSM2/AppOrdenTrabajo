--CREAR TABLAS Y RELACIONES
CREATE TABLE Fabricante (
    CodFabricante CHAR(6),
    CONSTRAINT PK_Fabricante PRIMARY KEY (CodFabricante)
);

CREATE TABLE Repuesto (
    CodRepuesto CHAR(6),
    CONSTRAINT PK_Repuesto PRIMARY KEY (CodRepuesto)
);

CREATE TABLE Encargado (
    CodEncargado CHAR(6),
    Nombre VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Encargado PRIMARY KEY (CodEncargado)
);

CREATE TABLE Maquinaria (
    CodMaquinaria CHAR(6),
    DescripcionMaquinaria VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Maquinaria PRIMARY KEY (CodMaquinaria)
);

CREATE TABLE Persona (
    CodPersona CHAR(6),
    Especialidad VARCHAR(30) NOT NULL,
    CONSTRAINT PK_Persona PRIMARY KEY (CodPersona)
);

CREATE TABLE Herramientas (
    CodHerramientas CHAR(6),
    DescripcionHerramientas VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Herramientas PRIMARY KEY (CodHerramientas)
);

CREATE TABLE Materiales (
    CodMateriales CHAR(6),
    CodRepuesto CHAR(6) NOT NULL,
    CodFabricante CHAR(6) NOT NULL,
    DescripcionMateriales VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Materiales PRIMARY KEY (CodMateriales),
    CONSTRAINT FK_Materiales_Repuesto FOREIGN KEY (CodRepuesto) REFERENCES Repuesto(CodRepuesto),
    CONSTRAINT FK_Materiales_Fabricante FOREIGN KEY (CodFabricante) REFERENCES Fabricante(CodFabricante)
);

CREATE TABLE CabeceraOrdenTrabajo (
    CodDocumento VARCHAR(10),
    CodEncargado CHAR(6) NOT NULL,
    DescripcionDocumento VARCHAR(200) NOT NULL,
    Fecha DATE NOT NULL,
    Estado VARCHAR(20) NOT NULL,
    CONSTRAINT PK_CabeceraOrdenTrabajo PRIMARY KEY (CodDocumento),
    CONSTRAINT FK_Cabecera_Encargado FOREIGN KEY (CodEncargado) REFERENCES Encargado(CodEncargado)
);

CREATE TABLE DetallePersona (
    CodDocumento VARCHAR(10),
    CodPersona CHAR(6),
    HorasPersona NUMERIC(4,2) NOT NULL,
    CantidadPersonas INTEGER NOT NULL,
    CONSTRAINT PK_DetallePersona PRIMARY KEY (CodDocumento, CodPersona),
    CONSTRAINT FK_DetallePersona_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetallePersona_Persona FOREIGN KEY (CodPersona) REFERENCES Persona(CodPersona)
);

CREATE TABLE DetalleHerramientas (
    CodDocumento VARCHAR(10),
    CodHerramientas CHAR(6),
    CantidadHerramientas INTEGER NOT NULL,
    HorasHerramientas NUMERIC(4,2) NOT NULL,
    CONSTRAINT PK_DetalleHerramientas PRIMARY KEY (CodDocumento, CodHerramientas),
    CONSTRAINT FK_DetalleHerramientas_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetalleHerramientas_Herramientas FOREIGN KEY (CodHerramientas) REFERENCES Herramientas(CodHerramientas)
);

CREATE TABLE DetalleMaquinaria (
    CodDocumento VARCHAR(10),
    CodMaquinaria CHAR(6),
    HorasMaquinaria NUMERIC(4,2) NOT NULL,
    CantidadMaquinaria INTEGER NOT NULL,
    CONSTRAINT PK_DetalleMaquinaria PRIMARY KEY (CodDocumento, CodMaquinaria),
    CONSTRAINT FK_DetalleMaquinaria_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetalleMaquinaria_Maquinaria FOREIGN KEY (CodMaquinaria) REFERENCES Maquinaria(CodMaquinaria)
);

CREATE TABLE DetalleMateriales (
    CodDocumento VARCHAR(10),
    CodMateriales CHAR(6),
    CantidadMateriales NUMERIC(5,2) NOT NULL,
    CONSTRAINT PK_DetalleMateriales PRIMARY KEY (CodDocumento, CodMateriales),
    CONSTRAINT FK_DetalleMateriales_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetalleMateriales_Materiales FOREIGN KEY (CodMateriales) REFERENCES Materiales(CodMateriales)
);
--Indices Ordinarios
CREATE INDEX IDX_Cabecera_Fecha ON CabeceraOrdenTrabajo (Fecha);
CREATE INDEX IDX_Cabecera_Estado ON CabeceraOrdenTrabajo (Estado);
CREATE INDEX IDX_Persona_Especialidad ON Persona (Especialidad);
CREATE INDEX IDX_Materiales_Descripcion ON Materiales (DescripcionMateriales);

--INSERTAR DATOS A LA Tabla
INSERT INTO Fabricante (CodFabricante) VALUES 
('CADTEM'),
('SAE20 '), 
('ISO220'), 
('PE806T'),
('304L  '),
('CATERP'),
('KOMATS');

INSERT INTO Repuesto (CodRepuesto) VALUES 
('CADTEM'),
('SAE20 '),
('ISO220'),
('AM2238'),
('304L  '),
('REP001'),
('REP002');

INSERT INTO Encargado (CodEncargado, Nombre) VALUES 
('ENC001', 'ALEGRE, Paul'),
('ENC002', 'GOMEZ, Carlos');

INSERT INTO Maquinaria (CodMaquinaria, DescripcionMaquinaria) VALUES 
('MAQ001', 'Camión Minero Caterpillar 797F'),
('MAQ002', 'Excavadora Hidráulica Komatsu PC3000'),
('MAQ003', 'Montacargas Industrial Toyota 8FGU25'),
('MAQ004', 'Grúa Móvil Automotriz Grove GMK5250'),
('PER006', 'Operador de Maquinaria Pesada');

INSERT INTO Persona (CodPersona, Especialidad) VALUES 
('PER001', 'Técnico Instrumentista'),
('PER002', 'Serv. Ext. Confiabilidad'),
('PER003', 'Servicios Externos - Chancado'),
('PER004', 'Técnico Mecánico Chancado'),
('PER005', 'Servicio Lubricacion'),
('PER006', 'Operador de Maquinaria Pesada');

INSERT INTO Herramientas (CodHerramientas, DescripcionHerramientas) VALUES 
('HER001', 'Caja de herramientas básica MEI'),
('HER002', 'Caja de herramientas Mecánica'),
('HER003', 'Equipo de Alineación Láser');

INSERT INTO Materiales (CodMateriales, CodRepuesto, CodFabricante, DescripcionMateriales) VALUES 
('MAT001', 'CADTEM', 'CADTEM', 'Cadena TEM 27'),
('MAT002', 'SAE20 ', 'SAE20 ', 'Lubricante SAE20'),
('MAT003', 'ISO220', 'ISO220', 'Aceite ISO VG220'),
('MAT004', 'AM2238', 'PE806T', 'MANGAS PLISADAS FILTRANTES DE POLIESTER CON TRATAMIENTO OLEO E HIDROFOBICO. Ø160 X L2.030mm'),
('MAT005', '304L  ', '304L  ', 'CANASTILLOS DE ACERO INOXIDABLE 304L Ø152 X L2050mm'),
('MAT006', 'REP001', 'CATERP', 'Filtro de Aire Primario para Motor Pesado Cat');

INSERT INTO CabeceraOrdenTrabajo (CodDocumento, CodEncargado, DescripcionDocumento, Fecha, Estado) VALUES 
('DOC0000001', 'ENC001', '6M/D INS INST FILTRO AIRE FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000002', 'ENC001', '6M/D PREV MECA FILTRO AIRE FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000003', 'ENC001', '6M/D C/O MECA MANGAS FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000004', 'ENC001', '1M/D PREV MECA FILTRO AIRE FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000005', 'ENC002', 'MANTENIMIENTO CORRECTIVO DE CELDAS DE FLOTACIÓN', '2021-07-22', 'En Proceso'); 

INSERT INTO DetallePersona (CodDocumento, CodPersona, HorasPersona, CantidadPersonas) VALUES 
('DOC0000001', 'PER001', 8.00, 2),
('DOC0000002', 'PER002', 1.00, 1),
('DOC0000002', 'PER003', 36.00, 2),
('DOC0000002', 'PER004', 3.00, 2),
('DOC0000002', 'PER005', 2.50, 1),
('DOC0000003', 'PER003', 18.00, 2),
('DOC0000004', 'PER002', 1.00, 1),
('DOC0000004', 'PER004', 3.00, 2),
('DOC0000004', 'PER005', 1.00, 1),
('DOC0000005', 'PER006', 12.00, 1);

INSERT INTO DetalleHerramientas (CodDocumento, CodHerramientas, CantidadHerramientas, HorasHerramientas) VALUES 
('DOC0000001', 'HER001', 1, 4.00),
('DOC0000002', 'HER002', 5, 4.87),
('DOC0000003', 'HER002', 3, 3.00),
('DOC0000004', 'HER002', 1, 1.50),
('DOC0000005', 'HER003', 1, 6.50);

INSERT INTO DetalleMaquinaria (CodDocumento, CodMaquinaria, HorasMaquinaria, CantidadMaquinaria) VALUES 
('DOC0000002', 'MAQ003', 4.50, 1), 
('DOC0000003', 'MAQ004', 6.00, 1), 
('DOC0000005', 'MAQ002', 10.00, 1);

INSERT INTO DetalleMateriales (CodDocumento, CodMateriales, CantidadMateriales) VALUES 
('DOC0000002', 'MAT001', 1.00),
('DOC0000002', 'MAT002', 0.25),
('DOC0000002', 'MAT003', 5.00),
('DOC0000002', 'MAT004', 152.00),
('DOC0000002', 'MAT005', 152.00),
('DOC0000003', 'MAT004', 152.00),
('DOC0000004', 'MAT002', 0.25),
('DOC0000005', 'MAT006', 2.00);
