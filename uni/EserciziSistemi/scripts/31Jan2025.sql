 create table SOCIETA(
     IDSoc char(5) not null PRIMARY KEY,
     TotAzioni integer not NULL CHECK (TotAzioni > 0),
     Stato char(10) not null);

create table SOCI (
    Nome char(10) not null PRIMARY KEY,
	StatoResidenza char(10) not null);
     
create table QUOTE (
     IDSoc char(5) not NULL REFERENCES SOCIETA,
     Socio char(10) not NULL REFERENCES SOCI,
     NumAzioni integer NOT NULL CHECK (NumAzioni > 0));


--esercizio 1 inizio 10:18

--I dati delle società in cui la quota percentuale di azioni possedute da soci dello stesso stato
--della società e la quota posseduta da tutti gli altri soci differiscono di meno del 20%

WITH azioniStessSoci(idSoc, azioni)
as(
	SELECT s.idsoc, COALESCE(sum(q.numazioni), 0)
	FROM societa s, quote q, soci so
	WHERE s.idsoc = q.idsoc AND so.nome = q.socio
	AND so.statoresidenza <> s.stato
	GROUP BY s.idsoc
),azioniDivSoci(idSoc, azioni)
AS(
	SELECT s.idsoc, COALESCE(sum(q.numazioni), 0)
	FROM societa s, quote q, soci so
	WHERE s.idsoc = q.idsoc AND so.nome = q.socio
	AND so.statoresidenza = s.stato
	GROUP BY s.idsoc
)
SELECT *
FROM azioniStessSoci ass, azioniDivSoci adi, societa s 
WHERE ass.idSoc = adi.idSoc AND ass.idSoc = s.idSoc
AND (ass.azioni - adi.azioni)/s.totazioni < 0.2


--Le coppie di (nomi di) soci che in tutte le società in comune con almeno 3 soci
--possiedono almeno il 20% delle azioni a testa
SELECT q1.socio, q2.socio
FROM quote q1, quote q2, societa s
WHERE q1.idsoc = q2.idsoc AND q1.socio > q2.socio AND q1.idsoc = s.idsoc
AND q1.idsoc IN (
			SELECT q.idsoc
			FROM quote q
			GROUP BY q.idsoc
			HAVING count(q.socio) > 2
)
GROUP BY q1.socio, q2.socio
HAVING(NOT EXISTS (
		SELECT *
		FROM quote q3, quote q4, societa s1
		WHERE q3.socio = q1.socio AND q4.socio = q2.socio AND q3.idsoc = q4.idsoc AND s1.idsoc = q3.idsoc
		AND s1.idsoc IN (
			SELECT q.idsoc
			FROM quote q
			GROUP BY q.idsoc
			HAVING count(q.socio) > 2
		)
		AND q3.numazioni < s1.totazioni * 0.2
		AND q4.numazioni < s1.totazioni * 0.2
))

--giusto questo 
WITH coppieSoci(idSoc, socio1, socio2, percAzioni1, percAzioni2)
as(
	SELECT s.idsoc, q1.socio, q2.socio, q1.numazioni*1.0/s.totazioni, q2.numazioni*1.0/s.totazioni
	FROM quote q1, quote q2, societa s
	WHERE q1.idsoc = q2.idsoc AND q1.socio > q2.socio AND q1.idsoc = s.idsoc
	AND q1.idsoc IN (
				SELECT q.idsoc
				FROM quote q
				GROUP BY q.idsoc
				HAVING count(q.socio) > 2
	)
)
SELECT c.socio1, c.socio2
FROM coppieSoci c
GROUP BY c.socio1, c.socio2
HAVING (0.2 < ALL (SELECT c1.percAzioni1 FROM coppieSoci c1 WHERE c1.socio1 = c.socio1 AND c1.socio2 = c.socio2)
AND 0.2 < ALL (SELECT c1.percAzioni2 FROM coppieSoci c1 WHERE c1.socio1 = c.socio1 AND c1.socio2 = c.socio2))


--fine esercizio 2 10:54 

--esercizio 3

create table AZIONI (
     Nome char(10) not null,
     Valore DEC(6, 2) not NULL,
     constraint ID_AZIONI_ID primary key (Nome));

create table PORTAFOGLI (
     ValoreTotale dec(6,2) not NULL DEFAULT 0,
     PID char(5) not null,
     Warning integer not null default 0 check (warning in (0, 1)),
     constraint ID_PORTAFOGLI_ID primary key (PID));

DROP TABLE portafogli

create table AP (
     Nome char(10) not null,
     PID char(5) not null,
     Quantita integer not NULL CHECK (quantita > 0),
     constraint ID_AP_ID primary key (Nome, PID));


alter table AP add constraint FKAP_POR_FK
     foreign key (PID)
     references PORTAFOGLI;

alter table AP add constraint FKAP_AZI
     foreign key (Nome)
     references AZIONI;


CREATE OR replace TRIGGER aggiornamentoValTotaleInserimentoInAP
AFTER INSERT ON ap
REFERENCING NEW AS n
FOR EACH ROW 
UPDATE portafogli
SET valoreTotale = valoreTotale + n.quantita * (SELECT a.valore FROM azioni a WHERE a.nome = n.nome)
WHERE portafogli.pid = n.pid

CREATE OR replace TRIGGER aggiornamentoValTotaleUpdateInAzioni
AFTER update of valore ON azioni
REFERENCING NEW AS n
FOR EACH row
UPDATE portafogli
SET valoreTotale = (
	SELECT sum(az.valore * a.quantita)
	FROM ap a, azioni az
	WHERE a.nome = az.nome
	GROUP BY a.nome
)
WHERE portafogli.pid IN (
	SELECT a.pid
	FROM ap a
	WHERE a.nome = n.nome
)

CREATE OR replace TRIGGER setWarning
AFTER UPDATE OF valoreTotale ON portafogli
REFERENCING NEW AS n OLD AS o
FOR EACH ROW 
WHEN (ABS(n.valoreTotale - o.valoreTotale) > 1000)
UPDATE portafogli
SET portafogli.warning = 1
WHERE pid = n.pid


INSERT INTO portafogli (pid)
VALUES('1')

INSERT INTO azioni
VALUES('corpi', 20)

INSERT INTO ap
VALUES('corpi', '1', 4)

UPDATE azioni
SET valore = 10
WHERE nome = 'corpi'

--fine 11:36

--esercizio 4

CREATE TABLE e1(
	k1 integer NOT NULL PRIMARY KEY,
	a integer NOT NULL,
	B integer  NOT NULL
)


CREATE TABLE e3(
	k3 integer NOT NULL PRIMARY KEY,
	c1 integer,
	c2 integer,
	K1R1 integer REFERENCES e1,
	K2R1 integer REFERENCES e1,
	CONSTRAINT attrComposto CHECK (NOT(C1 IS NULL AND C2 IS NOT NULL)),
	CONSTRAINT referComposta CHECK ((K1R1 IS NOT NULL AND K2R1 IS NOT NULL) OR (K1R1 IS NULL AND K2R1 IS NULL))
)

DROP TABLE e1


--reference to e2
CREATE OR replace TRIGGER refE2
before INSERT on e3
REFERENCING NEW AS n 
FOR EACH ROW 
WHEN (n.K2R1 IS NOT NULL
AND NOT EXISTS (
	SELECT *
	FROM e1
	WHERE k1 = n.K2r1
	AND B IS NOT NULL
))
SIGNAL SQLSTATE '70000' ('K2R1 reference is not a E2 entity')


--punto c
CREATE OR replace TRIGGER puntoC
AFTER INSERT on e3
REFERENCING NEW AS n 
FOR EACH ROW 
WHEN (n.c1 IS NOT NULL
AND (SELECT el1.a * el2.b FROM E1 el1, E1 el2 WHERE el1.K1 = n.K1R1 AND el2.K1 = n.K2R1) < n.c1*COALESCE(n.c2, 1)
)
SIGNAL SQLSTATE '70001' ('point c violated')


--aggiornamenti alle istanze di E1, E2 o E3 portebbero violare il punto c senza che venga ritornato alcun errore

--fine 11:59




