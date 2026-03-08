create table ATTRAZIONI(
    ACode char(5) not NULL PRIMARY key,
    Nome char(10) NOT NULL,
    Prezzo DEc(6, 2) not NULL CHECK(prezzo >= 0 ));

create table BIGLIETTI(
    ACode char(5) not NULL REFERENCES ATTRAZIONI,
    Cliente char(10) NOT NULL,
    NumBiglietti integer NOT NULL CHECK (NumBiglietti >=0),
    Data date not NULL,
    CONSTRAINT chiave  UNIQUE (ACode, Cliente));

create table VALUTAZIONI(
    ACode char(5) not NULL,
    Cliente char(10) NOT NULL,
    TEsto char(50),
    Voto integer not NULL CHECK (voto <= 10 AND voto >= 1),
    CONSTRAINT chiave  UNIQUE (ACode, Cliente),
	FOREIGN KEY (ACOde, Cliente)  REFERENCES BIGLIETTI(ACode, Cliente));



--es 2 11:32
--I dati delle attrazioni che in un giorno hanno incassato complessivamente almeno 1000€,
--considerando solo i clienti che hanno valutato l’attrazione inserendo anche un testo


SELECT DISTINCT(a.acode)
FROM biglietti b, valutazioni v, attrazioni a
WHERE b.acode = v.acode AND b.cliente = v.cliente AND b.acode = a.acode
AND v.testo IS NOT NULL
GROUP BY a.acode, b.DATA
HAVING sum(b.numBiglietti * a.prezzo) >= 1000


--I clienti che in uno stesso giorno hanno acquistato biglietti per 2 o più attrazioni, e che per
--ognuna di queste hanno lasciato una valutazione positiva (Voto >= 6)
SELECT DISTINCT b.cliente
FROM valutazioni v, biglietti b
WHERE v.acode = b.acode AND b.cliente = v.cliente
AND v.voto >= 6
GROUP BY b.cliente, b.data
HAVING count(DISTINCT b.acode) >= 2

--es 3 11:53


create table BIRRERIE (
     BID numeric(5) not null,
     Nome char(10) not null,
     NumRece integer not NULL DEFAULT 0 CHECK (numrece >= 0),
     constraint ID_BIRRERIE_ID primary key (BID));

DROP TABLE recensioni

create table Recensioni (
     BID NUMERIC(5) NOT NULL REFERENCES birrerie, 
     Data date not null,
     Testo char(40) not null,
     CodCliente char(5) not null);


CREATE OR replace TRIGGER aggiornamentoNumRece
AFTER INSERT ON recensioni
REFERENCING NEW AS n
FOR EACH ROW 
UPDATE birrerie
SET numrece = numrece + 1
WHERE bid = n.bid

CREATE OR replace TRIGGER delAfter3
AFTER INSERT ON recensioni
REFERENCING NEW AS n
FOR EACH ROW 
WHEN ((SELECT count(*) FROM recensioni r WHERE r.bid = n.bid) > 3)
DELETE FROM recensioni
WHERE bid = n.bid
AND DATA = (
	SELECT min(r.data)
	FROM recensioni r
	WHERE r.bid = n.bid
)

insert into birrerie 
values (1, 'Vespina', 0)

insert into recensioni
values (1, '01/01/1999', 'buona', 'mirco')

insert into recensioni
values (1, '01/01/2000', 'buona', 'mirco')

insert into recensioni
values (1, '01/01/2001', 'buona', 'mirco')


insert into recensioni
values (1, '01/01/2003', 'buona', 'mirco')

--es4 12:06

DROP TABLE e3

CREATE TABLE E1(
	k1 integer PRIMARY KEY NOT NULL,
	A INTEGER NOT NULL,
	B integer
)

CREATE TABLE E3(
	k3 integer PRIMARY KEY NOT NULL,
	c integer NOT NULL,
	K1R1 integer NOT NULL REFERENCES E1,
	K1R2 integer NOT NULL REFERENCES E1,
	CONSTRAINT refDiff CHECK (K1R1 <> K1R2)
)

--controlli sulla relazione R1/R2

CREATE OR replace TRIGGER R1_2REFERENCE
BEFORE INSERT ON E3
REFERENCING NEW AS n
FOR EACH ROW
WHEN (NOT EXISTS (
	SELECT *
	FROM E1, E1 E2
	WHERE E1.k1 = n.K1R1
	AND E2.K1 = n.K1R2
	AND E2.B IS NOT NULL
))
SIGNAL SQLSTATE '70000'('ReF to E2/E1 does not exist')

--punto d


--il punto d puo essere violato solo con un inserimento in E3 (o modifica in E1)
CREATE OR replace TRIGGER puntoD
BEFORE INSERT ON e3
REFERENCING NEW AS n
FOR EACH ROW 
WHEN (NOT EXISTS (
	SELECT *
	FROM E1, E1 E2
	WHERE E1.K1 = n.k1r1
	AND E2.K1 = N.K1R2
	AND E2.B IS NOT NULL
	AND E1.A + E2.B < 20
))
SIGNAL SQLSTATE '70001'('Point D violated')


--modifiche ad E1 non sono tollerate

--fine 12:17
