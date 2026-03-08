
create table ACQUISTI(
    CodA char(5) not NULL PRIMARY key,
    DATA Date NOT NULL,
    Totale DEc(6, 2) not NULL,
    Cliente char(20) NOT NULL);

create table DETTAGLI(
    CodA char(5) not NULL REFERENCES acquisti,
    CodProdotto char(5) NOT NULL,
    Qta integer NOT NULL,
    Importo DEc(6, 2) not NULL,
    CONSTRAINT chiave  UNIQUE (CodA, CodProdotto));

create table RECENSIONI(
    CodA char(5) not NULL,
    CodProdotto char(5) NOT NULL,
    TEsto char(50) NOT NULL,
    Voto integer not NULL CHECK (voto <= 10 AND voto >= 1),
    CONSTRAINT chiave  UNIQUE (CodA, CodProdotto),
	FOREIGN KEY (COdA, codprodotto)  REFERENCES dettagli(COdA, CodProdotto));




--esercizio 2 inizio 17:43

--  Per ogni cliente, l’importo complessivo pagato per ogni singolo prodotto, considerando solo
--  i prodotti recensiti (da quel cliente o da altri) sempre con un voto almeno pari a 6


SELECT a.cliente, d.codprodotto, sum(d.importo)
FROM DEttagli d, acquisti a
WHERE d.COda = a.coda
GROUP BY a.cliente, d.CodProdotto
HAVING (
	6 <= ALL (SELECT voto
	FROM recensioni r
	WHERE codprodotto = d.codprodotto)
	AND 
	EXISTS (
		SELECT *
		FROM recensioni r
		WHERE codprodotto = d.codprodotto)
)

--- fine primo punto 17:58

-- Per ogni cliente, i prodotti che quel cliente ha comprato ogni volta che ha effettuato un
-- acquisto

SELECT a.cliente, d.codProdotto
FROM DEttagli d, acquisti a
WHERE d.COda = a.coda
GROUP BY a.cliente, d.CodProdotto
HAVING (
	NOT EXISTS (
		SELECT a1.coda
		FROM acquisti a1, dettagli d1
		where a1.cliente = a.cliente
		AND a1.coda = d1.coda
		GROUP BY a1.coda
		HAVING d.codprodotto <> ALL (
				SELECT d2.codprodotto
				FROM dettagli d2
				WHERE d2.coda = a1.coda
		)
	)
)


--esercizio 2 fine 18:16 --> resoconot : la soluzione del professore e' diversa ma chat dice che e' equivalente
--alla mia, anche se le mie soluzioni sono piu' complesse

--esercizio 3 inizio 18:21
create table RECENSIONI (
     Cliente char(10) not null,
     Data date not null,
     Testo char(20),
     Voto integer not NULL CHECK (voto > 0 AND voto <= 10),
     Prodotto char(5) not null,
     Prezzo integer not null,
     constraint ID_RECENSIONI_ID primary key (Cliente, Prodotto));

create table REC_PASSATE (
     Cliente char(10) not null,
     Data date not null,
     Testo char(20),
     Voto integer not NULL CHECK (voto > 0 AND voto <= 10),
     Prodotto char(5) not null,
     Prezzo integer not null,
     constraint ID_REC_PASSATE_ID primary key (Cliente, DATA, voto, Prodotto));


DROP TABLE rec_passate

CREATE OR replace TRIGGER aggiuntaInPassate
AFTER UPDATE OF voto ON recensioni
REFERENCING NEW AS n OLD AS o
FOR EACH ROW 
WHEN (n.voto < o.voto)
INSERT INTO REC_PASSATE
VALUES (o.cliente, o.DATA, o.testo, o.voto, o.prodotto, o.prezzo)

INSERT INTO recensioni
VALUES ('pino', CURRENT date, 'bello', 9, 'pasta', 40),
('alermo', CURRENT date, 'caruccio', 6, 'pasta', 40),
('daniele', CURRENT date, 'maronna', 2,  'pasta', 40)

UPDATE  recensioni
SET voto = 4
WHERE cliente = 'alermo'

--esercizio 3 fine 18:55

--esercizio 4 inizio 18:56

DROP TABLE e3

CREATE TABLE e1(
	k1 integer NOT NULL PRIMARY KEY,
	a integer NOT NULL,
	R2K3 integer  NOT NULL
)

ALTER TABLE e1
ADD CONSTRAINT chiave FOREIGN KEY (R2K3) REFERENCES E2

CREATE TABLE e2(
	k2 integer NOT NULL PRIMARY KEY,
	b integer NOT NULL,
	c integer,
	R1K1 integer NOT NULL REFERENCES e1,
	D integer
)

--mi devo assicuare che R2K3 faccia riferimento ad un entita E3, quindi deve avere C definto
--sia per insert che update

CREATE OR replace TRIGGER check_cond_R2
AFTER INSERT on e1
REFERENCING NEW AS n 
FOR EACH ROW 
WHEN (NOT EXISTS (
	SELECT *
	FROM e2
	WHERE k2 = n.R2K3
	AND C IS NOT NULL
))
SIGNAL SQLSTATE '70000' ('R2K3 reference is not a R3 entity')

CREATE OR replace TRIGGER check_cond_R2_update
AFTER UPDATE OF r2k3 ON e1
REFERENCING NEW AS n 
FOR EACH ROW 
WHEN (NOT EXISTS (
	SELECT *
	FROM e2
	WHERE k2 = n.R2K3
	AND C IS NOT NULL
))
SIGNAL SQLSTATE '70000' ('R2K3 reference is not a R3 entity')

CREATE OR replace TRIGGER check_cond_R2_update_1
AFTER UPDATE OF C ON e2
REFERENCING NEW AS n 
FOR EACH ROW 
WHEN (EXISTS (
	SELECT *
	FROM e1
	WHERE n.k2 = R2K3
	AND c IS null
))
SIGNAL SQLSTATE '70001' ('cannot update R3 entity to an R2 entity because is referenced from e1 entity')

--punto c : un’istanza di E2 non è mai associata, tramite R1, a un’istanza di
--E1 che referenzia, tramite R2, un’istanza di E3 con C > 10;

CREATE OR replace TRIGGER puntoC
AFTER INSERT on e2
REFERENCING NEW AS n 
FOR EACH ROW 
WHEN ( 10 < (
	SELECT a.C
	FROM e2 a
	WHERE a.k2 = (
		SELECT e1.r2k3
		FROM e1
		WHERE e1.k1 = n.r1k1
	)
)
)
SIGNAL SQLSTATE '70002' ('point c violated')

CREATE OR replace TRIGGER puntoCup
AFTER UPDATE OF r1k1 on e2
REFERENCING NEW AS n 
FOR EACH ROW 
WHEN ( 10 < (
	SELECT a.C
	FROM e2 a
	WHERE a.k2 = (
		SELECT e1.r2k3
		FROM e1
		WHERE e1.k1 = n.r1k1
	)
)
)
SIGNAL SQLSTATE '70002' ('point c violated')

--esercizio 4 inizio 19:14

