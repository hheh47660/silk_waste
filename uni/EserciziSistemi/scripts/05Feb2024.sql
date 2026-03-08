 create table PRODOTTI (
     CodP char(5) not null PRIMARY KEY,
     Categoria varchar(30) not NULL,
     Prezzo DEC(6, 2) not null);

create table SCONTI (
    Codice char(5) not null PRIMARY KEY,
	Sconto integer not null CHECK (Sconto > 0 AND Sconto < 100));
     
create table VENDITE (
     CodP char(5) not NULL REFERENCES PRODOTTI,
     DATA DATE not null,
     Quantita integer NOT NULL CHECK (Quantita > 0),
     CodSconto char(5) REFERENCES SCONTI);


--2.1 Per ogni codice sconto e ogni categoria, il prezzo medio a cui sono stati venduti i relativi
--prodotti (prezzo medio: incasso totale diviso quantità totale)

SELECT s.Codice, p.Categoria, sum(p.prezzo - (p.prezzo * s.Sconto)/100)/sum(Quantita) AS "Prezzo Medio"
FROM  SCONTI s, VENDITE v, PRODOTTI p
WHERE v.CodP = p.CodP AND v.CodSconto = s.Codice
GROUP BY s.Codice, p.Categoria


--2.2 L’incasso totale per ogni prodotto, ordinando il risultato per codice prodotto : Inizio 18:22


WITH SCONTATI(Cod, IncassoTotale)
AS (
	SELECT p.CodP, sum(v.quantita * (p.prezzo - (p.prezzo * s.Sconto)/100)) AS "Incasso Totale"
	FROM SCONTI s, VENDITE v, PRODOTTI p
	WHERE v.CodP = p.CodP AND v.CodSconto = s.Codice
	GROUP BY  p.CodP
)
WITH NONSCONTATI(Cod, IncassoTotale)
AS (
	SELECT p.CodP, sum(v.quantita * (p.prezzo)) AS "Incasso Totale"
	FROM VENDITE v, PRODOTTI p
	WHERE v.CodP = p.CodP AND v.CodSconto = s.Codice AND v.CodSconto IS NULL
	GROUP BY  p.CodP
)
SELECT s.Cod, coalesce(ns.incassototale, 0)  + colesce(s.incassototale,0) AS "incassoTotael"
FROM NONSCONTati ns, SCONTATI s
WHERE ns.Cod = s.Cod
GROUP BY s.Cod
ORDER BY s.Cod




--- TERZO ESERCIZI

create table MEDICI_DI_BASE (
     CodM char(5) not null,
     Nome char(20) not null,
     constraint ID_MEDICI_DI_BASE_ID primary key (CodM));

create table Correnti (
     CodM char(5) not null,
     Nome char(20) not null,
     CodP char(5) NOT NULL,
     Data_Scelta DATE not null,
     constraint ID_Correnti_ID primary key (CodM, Nome, CodP));

create table Vecchi (
     CodM char(5) not null,
     Nome char(20) not null,
     CodP char(5) NOT NULL,
     Data_Scelta DATE not null,
     constraint ID_Vecchi_ID primary key (CodM, Nome, CodP));

DROP TABLE vecchi

DROP TABLE correnti

alter table Correnti add constraint FKMED_Cor
     foreign key (CodM, Nome)
     references MEDICI_DI_BASE;

alter table Vecchi add constraint FKMED_Vec
     foreign key (CodM, Nome)
     references MEDICI_DI_BASE;


CREATE OR replace TRIGGER nouvo_medico_di_base
after UPDATE ON Correnti
REFERENCING OLD AS O
FOR EACH ROW
INSERT INTO Vecchi
VALUES (O.CodM, O.NOme, O.CodP, O.Data_Scelta)

UPDATE correnti


---esercizio 4



DROP TABLE e1

CREATE TABLE E1(
	k1 integer PRIMARY KEY NOT NULL,
	A INTEGER NOT NULL,
	B integer
)

CREATE TABLE E3(
	k3 integer PRIMARY KEY NOT NULL,
	c integer NOT NULL,
	R_E1 integer NOT NULL REFERENCES E1,
	R_E2 integer NOT NULL REFERENCES e1,
	D integer
)

--controlli sulla relazione R

CREATE OR replace TRIGGER R_E2_DeveAvereBDefinito
BEFORE INSERT ON E3
REFERENCING NEW AS n
FOR EACH ROW
WHEN (NOT EXISTS (
	SELECT B
	FROM E1 
	WHERE k1 = n.R_E2
))
SIGNAL SQLSTATE '70000'('Ret to E2 is not E2 type')

--unicita di B

CREATE OR replace TRIGGER R_E2_deveessereunico
BEFORE INSERT ON E3
REFERENCING NEW AS n
FOR EACH ROW
WHEN (EXISTS (
	SELECT *
	FROM E3 e
	WHERE e.R_E2 = n.R_E2
	AND e.K3 <> n.K3
))
SIGNAL SQLSTATE '70001'('Ret to E2 already exists and is not allowed')


--punto c

CREATE OR replace TRIGGER puntoC
before INSERT ON E3
REFERENCING NEW AS n
FOR EACH ROW
WHEN (n.C < (
	SELECT e1.A + e2.B
	FROM E1 e1, E1 e2
	WHERE e1.k1 = n.R_E1
	AND e1.k1 = n.R_E2
))
SIGNAL SQLSTATE '70001'('Ret to E2 already exists and is not allowed')






