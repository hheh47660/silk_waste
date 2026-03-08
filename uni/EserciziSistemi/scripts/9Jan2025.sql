create table CLIENTI(
    CodCl char(5) not NULL PRIMARY key,
    Nome char(10) NOT NULL,
    Via char(20) not NULL,
    Comune char(20) NOT NULL);

create table ORDINI(
    IDOrd char(5) not NULL PRIMARY KEY,
    CodCl char(5) NOT NULL REFERENCES CLIENTI,
    Data DATE NOT NULL,
    Importo DEc(6, 2) not NULL);

create table TRACKING(
    IDOrd char(5) not NULL REFERENCES ORDINI,
    Stato char(20) NOT NULL CHECK (Stato = 'spedito' OR Stato = 'arrivato' OR Stato = 'consegnato'),  
    Data Date NOT null,
    CONSTRAINT chiave  UNIQUE (IDOrd, Stato));

DROP TABLE ordini

--esericio 2 inizio 10:36

--Per ogni comune, considerando solo gli ordini spediti lo stesso giorno in cui è stato fatto
--l’ordine e che sono stati consegnati, l’importo medio di un ordine

SELECT c.Comune, COALESCE(sum(o.importo)*1.0/count(*), 0) AS "Media"
FROM clienti c, ordini o, tracking t1
WHERE o.IDOrd = t1.IDOrd AND t1.stato = 'spedito'
AND c.CodCl = o.CodCl
AND o.DATA = t1.data
AND EXISTS (
	SELECT *
	FROM tracking t2
	WHERE t2.IDOrd = o.IDOrd
	AND t2.stato = 'consegnato'
)
GROUP BY c.Comune

--L’identificativo degli ordini per cui la durata di un passaggio di stato (da ‘spedito’ ad
--‘arrivato’ o da ‘arrivato’ a ‘consegnato’) è stata massima (se l’ordine non è stato consegnato il
--passaggio da ‘arrivato’ a ‘consegnato’ non va considerato, idem se un ordine non è ‘arrivato’)


WITH ordiniConDurataConsegna(IDOrd, durataConsegna)
as(
	SELECT o.idord, DAYS(t2.data) - DAYS(t1.data)
	FROM ordini o, tracking t1, tracking t2
	WHERE o.IDOrd = t.IDOrd AND t1.idord = t2.idord
	AND t1.stato = 'arrivato' AND t2.stato = 'consegnato'
), ordiniConDurataArrivo(IDOrd, durataArrivo)
as(
	SELECT o.idord, DAYS(t2.data) - DAYS(t1.data)
	FROM ordini o, tracking t1, tracking t2
	WHERE o.IDOrd = t.IDOrd AND t1.idord = t2.idord
	AND t1.stato = 'spedito' AND t2.stato = 'arrivato'
)
SELECT c.IDOrd
FROM ordiniConDurataConsegna c, ordiniConDurataArrivo a 
WHERE c.IDOrd = a.IDOrd
GROUP BY c.IDOrd
HAVING (c.durataConsegna = (SELECT max(c1.durataConsegna) FROM ordiniConDurataConsegna c1)
		OR a.durataArrivo = (SELECT max(c1.durataArrivo) FROM ordiniConDurataArrivo a1)


--fine 10:54
		
--inizio esercizio 3

create table RECLAMI (
     Motivo char(10) not null,
     CodProdotto char(5) not null,
     IdOrdine char(5) not null);

create table ORDINI (
     IdOrdine char(5) not null,
     Importo dec(6, 4) not null,
     constraint ID_ORDINI_ID primary key (IdOrdine));

create table PRODOTTI (
     CodProdotto char(5) not null,
     Prezzo DEC(6,4) not null,
     NumReclami integer not NULL DEFAULT 0,
     constraint ID_PRODOTTI_ID primary key (CodProdotto));

create table OP (
     IdOrdine char(5) not null,
     CodProdotto char(5) not null,
     Quantita integer not null,
     constraint ID_OP_ID primary key (CodProdotto, IdOrdine));


-- Constraints Section
-- ___________________ 

alter table RECLAMI add constraint FKR_FK
     foreign key (CodProdotto, IdOrdine)
     references OP;

alter table ORDINI add constraint ID_ORDINI_CHK
     check(exists(select * from OP
                  where OP.IdOrdine = IdOrdine)); 

alter table OP add constraint FKOP_PRO
     foreign key (CodProdotto)
     references PRODOTTI;

alter table OP add constraint FKOP_ORD_FK
     foreign key (IdOrdine)
     references ORDINI;

CREATE OR replace TRIGGER aggiornaNumReclami
AFTER INSERT ON reclami
REFERENCING NEW AS n
FOR EACH ROW 
UPDATE prodotti
SET numReclami = numReclami + 1
WHERE (
	prodotti.CodProdotto = n.CodProdotto
)

CREATE OR replace triggere aggionamentoIMporto
AFTER INSERT ON op
REFERENCING NEW AS n
FOR EACH ROW
UPDATE ON ordini
SET ordini.importo = (SELECT sum(p.prezzo * o.quantita)
					  FROM op o, prodotti p 
					  WHERE o.codprodott = p.codprodotto AND o.idordine = n.idordine
					  )
WHERE ordini.idordine = n.idordine

CREATE OR replace TRIGGER eliminazione
AFTER UPDATE OF numReclami ON prodotti
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (n.numReclami >= 4)
BEGIN ATOMIC 
DELETE FROM prodotti 
WHERE prodotti.CodProdotto = n.CodProdotto
DELETE FROM op
WHERE op.CodProdotto = n.codProdotto
DELETE FROM reclami 
WHERE reclami.codProdotto = n.codprodotto
end


INSERT INTO prodotti 
VALUES ('a', 10, 0)

INSERT INTO ordini 
VALUES ('1', 50)

INSERT INTO op
VALUES ('1', 'a', 2)

INSERT INTO reclami 
VALUES ('brutto', 'a', '1')

--fine 11:50

--parte 4



CREATE table E1(
	K1 integer NOT NULL PRIMARY KEY,
	A integer NOT null
)

CREATE TABLE E2(
	K2 integer NOT NULL PRIMARY KEY,
	B integer NOT NULL,
	K1_R1 integer NOT NULL REFERENCES E1
)

CREATE TABLE E3(
	C integer NOT NULL,
	K1_R2 integer NOT NULL REFERENCES E1,
	K2_R2 integer NOT NULL REFERENCES E2,
	K1_R3 integer,
	D integer,
	CONSTRAINT chiave PRIMARY key(k2_r2, c),
	CONSTRAINT DDiR3 CHECK (D IS NULL AND K1_R3 IS NULL) OR (D IS NOT NULL AND K1_R3 IS NOT NULL))
)

CREATE OR REPLACE TRIGGER refToK1fromE3
BEFORE INSERT INTO  E3
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (n.K1_R3 IS NOT NULL
AND NOT EXISTS (
	SELECT *
	FROM E1 WHERE E1.K1 = n.K1_R3
))
SIGNAL SQLSTATE '70000' ("Referecnes does not exists in E1")

--punto b : devo farlo sia per E2 che per E3 

--uintile il punto per E2
CREATE OR replace TRIGGER puntoBE2
BEFORE INSERT ON E2
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (EXISTS (
		SELECT *
		FROM E3 
		WHERE E3.k1_r2 = N.K1_R1
		AND E3.K2_R2 = N.K2
))
SIGNAL SQLSTATE '70001' ("Elements alreayd take part in R2 relation")

CREATE OR replace TRIGGER puntoBE3
BEFORE INSERT ON E3
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (EXISTS (
		SELECT *
		FROM E2
		WHERE E2.k1_r1 = N.K1_R2
		AND E2.K2 = N.K2_R2
))
SIGNAL SQLSTATE '70001' ("Elements alreayd take part in R1 relation")


--punto c
CREATE OR replace TRIGGER puntoC
before INSERT ON E3
REFERENCING NEW AS n
FOR EACH ROW 
WHEN n.K1_R3 IS NOT NULL
AND (EXISTS (
		SELECT *
		FROM E3
		WHERE E3.K1_R3 IS NOT NULL
		AND E3.K2_R2 = n.K2_R2
		AND E3.C <> n.C
))
SIGNAL SQLSTATE '70002' ("Mutiple elements of E3 with same K2 take part in R3 relation violating C point")

--fine 12:09
