create table PRODOTTI (
     CodP char(5) not null PRIMARY KEY,
     PrezzoListino DEc(6, 2) not NULL);

create table OFFERTE(
    CodP char(5) not NULL REFERENCES PRODOTTI ,
    DATA Date NOT NULL,
    PrezzoOfferta DEc(6, 2) not NULL,
    NumPezzi Integer NOT NULL,
    CONSTRAINT chiave  UNIQUE (CodP, Data));
     
create table VENDITE (
     CodP char(5) not NULL REFERENCES PRODOTTI,
     DATA DATE not null,
     NumVenduti integer NOT NULL CHECK (NumVenduti > 0),
     CONSTRAINT chiave  UNIQUE (CodP, Data));

DROP TABLE prodotti;

DROP TABLE Offerte;

DROP TABLE VENDITE ;

--Per ogni data il rapporto tra pezzi complessivamente venduti e quelli messi in offerta, ma
--considerando solo i prodotti messi in offerta in almeno 2 giorni

WITH prodottiInOffertaDueGiorni(CodP)
AS (SELECT p.CodP
	FROM Prodotti p, Offerte o
	WHERE p.COdP = o.CodP
	GROUP BY p.CodP
	HAVING count(*) >= 2
)
SELECT  (1.0*COALESCE(sum(v.numvenduti), 0))/(1.0*COALESCE(sum(o.numpezzi), 1)) AS "rapporto"
FROM prodottiInOffertaDueGiorni p, (Offerte o  LEFT JOIN  VEndite v ON (o.DATA, o.codp) = (v.DATA, v.codp))
WHERE p.COdp = o.codp
GROUP BY o.DATA


--Il prodotto che in due sue offerte consecutive, entrambe con dei pezzi venduti, ha incassato
--di più


WITH coppieOfferteCons(cod, dataPrima, valorePrima, dataDopo, valoreDopo)
AS (
	SELECT o1.codp, o1.DATA, o1.prezzoofferta,o2.DATA, o2.prezzoofferta
	FROM offerte o1, offerte o2
	WHERE o1.codp = o2.codp
	AND o2.DATA AFTER o1.data
	AND o1.codp IN (
			SELECT v.codp
			FROM vendite v, offerte o3
			WHERE v.codp = o3.codp AND v.DATA = o3.data
	)
	GROUP BY o1.codp, o1.data, o2.data
	HAVING o2.DATA = min(
			SELECT o4.DATA
			FROM offerte o4, offerte o5
			WHERE o4.codp = o5.codp
			AND o4.DATA = o2.DATA
			AND o5.DATA IS AFTER o4.data
	)
		
)SELECT c.cod
FROM coppieOfferteCons c, vendite v1, vendite v2
WHERE v1.codp = c.cod AND v1.codp = v2.codp
AND v1.DATA = c.dataPRima AND v2.DATA = c.dataDOpo
GROUP BY c.cod
HAVING (v1.numvenduti * c.valorePrima + v2.numvenduti * c.valoredopo) >= max(
		SELECT v1.numvenduti * c.valorePrima + v2.numvenduti * c.valoredopo
		FROM coppieOfferteCons c1, vendite v3, vendite v4
		WHERE v3.codp = c1.cod AND v4.codp = v3.codp
		AND v3.DATA = c1.dataPRima AND v4.DATA = c1.dataDOpo 
)






WITH offerteCOnsecutive(cod, totale)
AS(
	SELECT o1.codp, (o1.prezzoofferta * v1.numvenduti + o2.prezzoofferta * v2.numvenduti) AS "totale"
	FROM vendite v1, vendite v2, offerte o1, offerte o2
	WHERE o1.DATA < o2.DATA
	AND o1.codp = o2.codp
	AND (o1.codp, o1.data) = (v1.codp, v1.data)
	AND (o2.codp, o2.data) = (v2.codp, v2.data)
	AND NOT EXISTS (
		SELECT *
		FROM offerte o3
		WHERE o3.DATA < o2.DATA
		AND o3.DATA > o2.DATA
		AND o3.codp = o2.codp
	)
)SELECT *
FROM offerteCOnsecutive a
WHERE a.totale = (
	SELECT max(a2.totale)
	FROM offerteCOnsecutive a2
)

--esercizio 3


create table TORNEI (
     CodT char(5) not null,
     Descrizione char(40) not null,
     CodG char(5) NOT NULL,
     NomeG char(10) NOT NULL,
     Punti integer NOT NULL,
     constraint ID_TORNEI_ID primary key (CodT, CodG));


create table Terminati (
     CodT char(5) not null,
     CodVincitore char(5));

DROP TABLE tornei;

alter table Terminati add constraint FKTOR_Ter_FK
     foreign key (CodT)
     references TORNEI;

CREATE OR replace trigger updateVIncitore
after INSERT on terminati
REFERENCING NEW AS n
FOR EACH ROW
update terminati
SET CodVincitore = (
	SELECT t.codG
	FROM tornei t
	WHERE n.codt = t.codt
	and t.punti = (
		SELECT max(t1.punti)
		FROM tornei t1
		WHERE t1.codt = t.codt
	)
)WHERE terminati.codt = n.codt



INSERT INTO tornei 
VALUES ('aa', 'bello', 'aaaa', 'antonio', 20),
('aaaaa', 'bello', 'bbbbb', 'giulio', 20),
('aaaaa', 'bello', 'ccccc', 'merluccio', 10)


INSERT INTO terminati(codT)
VALUES ('aaaaa')




--esercizio 4

CREATE TABLE E1(
	K1 integer NOT NULL PRIMARY KEY,
	A integer NOT NULL,
	tipo char(1) NOT NULL CHECK (tipo IN ('x', 'y', 'z')),
	K1_R1_X integer REFERENCES e1,
	K1_R1_Y integer REFERENCES e1, 
	K1_R1_Z integer REFERENCES e1,
	CONSTRAINT tipo CHECK ((tipo = 'x' AND K1_R1_X IS NULL)
						OR (tipo = 'y' AND K1_R1_Y IS NULL)
						OR (tipo = 'z' AND K1_R1_Z IS NULL))
)

CREATE TABLE E2(
	K2 integer NOT NULL PRIMARY KEY,
	B integer NOT NULL,
	K1_R2 integer REFERENCES E1,
	C integer,
	CONSTRAINT coerenza CHECK ((K1_R2 IS NULL AND C IS NULL) OR (K1_R2 IS NOT NULL AND C IS NOT NULL))
)


DROP TABLE E1


--cardinalita di X
CREATE OR replace TRIGGER cardinalitaX
BEFORE INSERT on E1
REFERENCING NEW AS n
FOR EACH ROW
WHEN (n.K1_R1_X IS NOT NULL
AND (EXISTS (
	SELECT *
	FROM E1 e 
	WHERE e.tipo = n.tipo
	AND e.K1_R1_X = n.K1_R1_X
)))
SIGNAL SQLSTATE '70001' ('Violata cardinalita di X')
	



--punto b
ALTER TABLE E1
ADD CONSTRAINT R1_rule
	CHECK ((K1 <> K1_R1_X) AND (k1 <> k1_R1_Y) AND (k1 <> k1_R1_Z)
		AND (K1_R1_X <> K1_R1_Y) AND (K1_R1_X <> K1_R1_Z)
		AND (K1_R1_Y <> K1_R1_Z))

CREATE OR replace TRIGGER puntoB
AFTER INSERT on E1
REFERENCING NEW AS n
FOR EACH row
WHEN(
	(	SELECT COALESCE(x.a, 0) + COALESCE(y.a, 0) + COALESCE(z.a, 0)
		FROM E1 x, E1 y, E1 z
		WHERE x.k1 = N.K1_R1_X
		AND Y.k1 = N.K1_R1_Y
		AND Z.K1 = N.K1_R1_Z
		AND x.k1 <> y.k1 AND y.k1 <> z.k1 AND x.k1 <> z.k1) >= 50
)
SIGNAL SQLSTATE '70002' ('Violato punto b')


--punto c
CREATE OR replace TRIGGER puntoB
AFTER INSERT on E2
REFERENCING NEW AS n
FOR EACH ROW 
WHEN(
	EXISTS (
		SELECT *
		FROM e1 e
		WHERE e.k1 = n.K1_R2
		AND e.tipo = 'c'
	)
)
SIGNAL SQLSTATE '70003' ('Violato punto c')


--un elemento di E2 che referencia un elemento di E1 viene sempre inserito 
--dopo che l'eleemnto di E1 e gia stato inserito


