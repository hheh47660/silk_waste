create table CLIENTI(
    Nome char(10) NOT NULL PRIMARY KEY,
    TotSpese Dec(8,2) not NULL CHECK (totspese >= 0));

create table ACQUISTI(
    IDA char(5) not NULL PRIMARY KEY,
    Cliente char(10) NOT NULL REFERENCES CLIENTI,
    Importo DEc(8, 2) not NULL);

create table RATEPAGATE(
    IDA char(5) not NULL REFERENCES ACQUISTI,
    Num integer NOT NULL CHECK (Num >= 1),
    ImportoRata dec(6,2) NOT NULL CHECK (importorata > 0),  
    PagataIl Date,
    CONSTRAINT chiave  UNIQUE (IDA, Num));

DROP TABLE ratepagate

--esercizio 2 18:28
--Per ogni acquisto non ancora completamente pagato, ma per cui sono state pagate almeno
--2 rate, la percentuale pagata rispetto all’importo dell’acquisto

SELECT a.ida, 100* sum(importoRata)*1.0/a.importo  AS "Percentuale pagata"
FROM ratepagate r, acquisti a
WHERE r.ida = a.ida
AND r.ida IN (
	SELECT r1.ida
	FROM ratepagate r1
	GROUP BY r1.ida
	HAVING count(pagataIl) >= 2 
	AND count(pagataIl) <> max(r1.num)
)
AND r.pagataIl IS NOT null
GROUP BY a.ida, a.importo

--Per ogni cliente che ha pagato almeno 2 rate in tutti gli acquisti fatti, l’identificativo
--dell’acquisto in cui l’importo totale delle rate pagate è massimo
WITH clientiConDueRateAcquistoEImportoPagato(cliente, ida, importo)
as(
	SELECT a.cliente, r.ida, sum(r.importorata)
	FROM ratepagate r, acquisti a
	WHERE r.ida = a.ida
	AND r.pagatail IS NOT NULL
	GROUP BY a.cliente, r.ida
	HAVING (NOT EXISTS (
			SELECT a1.ida
			FROM ratepagate r1, acquisti a1
			WHERE r1.ida = a1.ida
			AND a1.cliente = a.cliente
			GROUP BY a1.ida
			HAVING count(r1.pagatail) < 2
	))
)
SELECT a.cliente, a.ida
FROM clientiConDueRateAcquistoEImportoPagato a
WHERE a.importo = (
		SELECT max(a1.importo) FROM clientiConDueRateAcquistoEImportoPagato a1 WHERE a1.cliente = a.cliente
) 
GROUP BY a.cliente, a.ida


--fine 18:44
--esercizio 3


create table DOGANIERI (
     CodID int NOT NULL PRIMARY KEY,-- Compound attribute -- not null,
     Nome char(10) not null,
     NumVerifiche integer  DEFAULT 0 not NULL CHECK (numverifiche >= 0));

DROP TABLE ps

create table PS (
     Quantita integer not NULL CHECK (quantita >= 0),
     CodSped char(5) not null,
     Data date not null,
     CodProd char(5) not null,
     Prezzo DEC(6,2) not NULL CHECK (prezzo >= 0),
     constraint ID_PS_ID primary key (CodSped, CodProd));

create table VERIFICA (
     CodID int NOT NULL REFERENCES doganieri,
     CodSped char(5) not null,
     CodProd char(5) not null,
     Esito char(5) DEFAULT NULL CHECK (esito IN ('OK', 'KO')),
     CONSTRAINT chiave FOREIGN KEY (codSped, CodProd) REFERENCES ps,
     constraint ID_VERIFICA_ID primary key (CodSped, CodProd));



CREATE OR replace TRIGGER aggiornamentoNumVerificheOk
AFTER UPDATE OF esito ON verifica
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (n.esito = 'OK') 
UPDATE doganieri
SET numverifiche = numverifiche + 1
WHERE codid = n.codid;


CREATE OR replace TRIGGER aggiornamentoNumVerificheKo
AFTER UPDATE OF esito ON verifica
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (n.esito = 'KO')
BEGIN ATOMIC 
UPDATE doganieri
SET numverifiche = numverifiche + 1
WHERE codid = n.codid;
UPDATE ps
SET quantita = 0
WHERE (codSped, codProd) = (n.codSped, n.codProd);
END 


--insert con un esito definito creerebbero problemi

INSERT INTO doganieri
VALUES (1, 'gino', 0)

INSERT INTO ps
VALUES (20, 'aa', CURRENT date, 'pino', 20)

INSERT INTO verifica
VALUES (1, 'aa', 'pino', default)

UPDATE verifica
SET esito = 'KO'
WHERE (codId, CodSped, CodProd) = (1, 'aa', 'pino')


--fine 19:27

--esercizio 4

CREATE TABLE E2(
	K1 INTEGER NOT NULL PRIMARY KEY,
	A INTEGER NOT NULL,
	B INTEGER NOT NULL,
	K1R1 INTEGER,
	D INTEGER,
	CONSTRAINT REFER CHECK ((D IS NULL AND K1R1 IS NULL) OR (D IS NOT NULL AND K1R1 IS NOT NULL))
)



CREATE TABLE E3(
	K1 INTEGER NOT NULL PRIMARY KEY,
	A INTEGER NOT NULL,
	C INTEGER NOT NULL
)

CREATE TABLE E4(
	K4 INTEGER NOT NULL PRIMARY KEY,
	E INTEGER NOT NULL,
	K1R2X INTEGER NOT NULL REFERENCES E3,
	K1R2Y INTEGER NOT NULL REFERENCES E3
)

--ref to E2/E3
CREATE OR replace TRIGGER refE1
BEFORE INSERT ON E2
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (NOT EXISTS (
	SELECT *
	FROM e2, e3
	WHERE e2.k1 = n.k1r1
	OR e3.k1 = n.k1r1
))
signal sqlstate '70001' ('K1R1 does not exist as E1 element')


--PUNTO C
CREATE OR replace TRIGGER puntoC
BEFORE INSERT ON E2
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (EXISTS (
	SELECT *
	FROM e3
	WHERE e3.k1 = n.k1r1
	AND C < 5
))
signal sqlstate '70001' ('Point c not respceted')

--PUNTO D
CREATE or replace trigger puntoD
BEFORE INSERT ON E4
REFERENCING NEW AS N
FOR EACH ROW 
WHEN (EXISTS (
	SELECT *
	FROM E2 
	WHERE E2.K1 = N.K1R2X
) AND (SELECT E3.C + COALESCE(E2.D, 0) FROM E3, E2 WHERE E3.K1 = N.K1R2X AND E3.K1 = E2.K1) > 10)
signal sqlstate '70002' ('Point d not respceted')


--fine 19:41



