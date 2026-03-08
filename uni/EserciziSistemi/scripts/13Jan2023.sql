create table CLIENTI(
    Nome char(10) NOT NULL PRIMARY KEY,
    TotSpese Dec(6,2) not NULL CHECK (totspese >= 0));

create table ACQUISTI(
    IDA char(5) not NULL PRIMARY KEY,
    Cliente char(10) NOT NULL REFERENCES CLIENTI,
    NumRate integer NOT NULL CHECK (numrate >= 1),
    Importo DEc(6, 2) not NULL);

create table RATEPAGATE(
    IDA char(5) not NULL REFERENCES ACQUISTI,
    ImportoRata dec(6,2) NOT NULL CHECK (importorata > 0),  
    Data Date NOT null,
    CONSTRAINT chiave  UNIQUE (IDA, Data));


--esercizio 2 12:46
--I nomi dei clienti che hanno un totale spese maggiore di 5000€ e che hanno fatto almeno
--un acquisto di 3 o più rate in cui l’importo delle rate pagate (almeno 2) è sempre aumentato,
--riportando in output anche l'identificativo dell'acquisto

SELECT c.nome, a.ida
FROM clienti c, acquisti a, ratepagate r
WHERE c.nome = a.cliente AND a.ida = r.ida
AND c.totspese > 5000 
AND a.numrate >= 3
AND a.ida IN (
	SELECT r1.ida
	FROM ratepagate r1
	GROUP BY r1.ida
	HAVING count(*) >= 2
)
GROUP BY a.ida, c.nome
HAVING (NOT EXISTS (
		SELECT *
		FROM ratepagate r1, ratepagate r2
		WHERE r1.ida = a.ida AND r1.ida = r2.ida
		AND r1.DATA < r2.DATA
		AND r1.importorata >= r1.importorata
))

--Considerando solo gli acquisti per cui sono state pagate almeno 2 rate, l’identificativo
--dell’acquisto e il relativo cliente per cui il tempo trascorso tra una rata e la successiva è stato
--massimo



WITH acquistiConTutteDiffDateConsec(cliente, ida, diff)
as(
	SELECT a.cliente, r1.ida, DAYS(r1.DATA) - DAYS(r2.DATA)
	FROM ratepagate r1, ratepagate r2, acquisti a
	WHERE r1.ida = r2.ida AND r1.DATA < r2.DATA AND a.ida = r1.ida 
	GROUP BY r1.ida, r1.DATA, r2.DATA, a.cliente
	HAVING (
		NOT EXISTS (
			SELECT *
			FROM ratepagate r3
			WHERE r3.ida = r1.ida
			AND r3.DATA > r1.DATA
			AND r3.DATA < r2.data
		)
	)
)
SELECT a.ida, a.cliente
FROM acquistiConTutteDiffDateConsec a
WHERE a.ida IN (
	SELECT r1.ida
	FROM ratepagate r1
	GROUP BY r1.ida
	HAVING count(*) >= 2
)
GROUP BY a.ida, a.cliente, a.diff
HAVING a.diff = (SELECT max(a2.diff) FROM acquistiConTutteDiffDateConsec a2)


--fine 13:07

--esercizio 3

create table ACQUISTI (
     Ida char(10) not null,
     Importo dec(6,2) not null,
     ImportoRata dec(6,2) not null,
     ImportoResiduo dec(6,2) not 'NULL',
     Pagato char(2) CHECK (pagato IS NULL OR pagato = 'SI'),
     constraint ID_ACQUISTI_ID primary key (Ida));

create table RATE (
     Ida char(10) not NULL,
     Data date not null,
     constraint ID_RATE_ID primary key (Ida, Data));


DROP TABLE acquisti

-- Constraints Section
-- ___________________ 

alter table RATE add constraint FKAR
     foreign key (Ida)
     references ACQUISTI;


CREATE OR replace TRIGGER setImportoResiduo
AFTER INSERT ON acquisti
REFERENCING NEW AS n
FOR EACH ROW 
UPDATE acquisti
SET importoresiduo = importo
WHERE ida = n.ida

CREATE OR replace TRIGGER aggiornamentoImportoResiduo
AFTER INSERT ON rate
REFERENCING NEW AS n
FOR EACH ROW 
UPDATE acquisti
--SET importoResiduo = importoResiduo - importorata
SET importoResiduo = importo - importoRata * (SELECT count(*) FROM rate r WHERE r.ida = n.ida)
WHERE ida = n.ida

CREATE OR replace TRIGGER aggiornamentoPagato
AFTER UPDATE OF importoResiduo ON acquisti
REFERENCING NEW AS n
FOR EACH ROW 
UPDATE acquisti 
SET pagato = 'SI'
WHERE ida = n.ida 
AND importoResiduo <= 0


INSERT INTO acquisti(ida, importo, importorata, importoresiduo)
VALUES ('bidet', 50, 10, 0)


INSERT INTO rate 
VALUES ('bidet', '10/10/1903')


--fine 13:25


--esercizio 4

CREATE TABLE E1 (
	K1 INT NOT NULL PRIMARY KEY,
	A INT NOT NULL,
	TIPO SMALLINT NOT NULL CHECK (TIPO IN (1,2,3)), -- 2: istanza di E2, 3: istanza di E3
	B INT,
	K1R1 INT,
	D INT,
	C INT,
	CONSTRAINT E2 CHECK ((TIPO = 1 AND B IS NULL AND K1R1 IS NULL AND C IS NULL) 
						OR (TIPO = 2 AND B IS NOT NULL AND K1R1 IS NOT NULL AND C IS NULL) 
						OR (TIPO = 3 AND B IS NOT NULL AND K1R1 IS NOT NULL AND C IS NOT NULL)),
	CONSTRAINT R1 CHECK ((K1R1 IS NULL AND D IS NULL) OR (K1R1 IS NOT NULL AND D IS NOT NULL)));



CREATE TABLE E4(
	K4 INT NOT NULL PRIMARY KEY,
	E INT NOT NULL,
	K1R2 INT NOT NULL REFERENCES E1
)

alter table E1 add constraint FKK1
     foreign key (K1R1)
     references E1;

DROP TABLE E1

--punto c
CREATE OR replace TRIGGER puntoCE4
BEFORE INSERT ON E4
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (EXISTS (
	SELECT *
	FROM E1
	WHERE E1.K1R1 = n.K1R2
))
SIGNAL SQLSTATE '70000' ('Point C not respected')



CREATE OR replace TRIGGER puntoCE2
before INSERT ON E1
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (n.tipo IN (2,3) AND 
	EXISTS (
	SELECT *
	FROM E4
	WHERE E4.K1R2 = n.K1R1
))
SIGNAL SQLSTATE '70000' ('Point C not respected')

--fine 13:38
