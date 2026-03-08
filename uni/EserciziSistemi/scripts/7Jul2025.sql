create table PRODOTTI (
     ProdID char(5) not null PRIMARY KEY,
     Categoria char(10) NOT NULL,
     Prezzo DEc(6, 2) not NULL);

create table RECLAMI(
    RID char(5) not NULL PRIMARY key,
    ProdID char(5) NOT NULL REFERENCES PRODOTTI,
    Data date not NULL,
    Cliente char(10) NOT NULL,
    Motivo char(50) NOT null);
     
create table ESITI (
     RID char(5) not NULL REFERENCES RECLAMI PRIMARY key,
     DataEsito DATE not null,
     Esito char(10) NOT NULL,
     Rimborso dec(6,2),
     CONSTRAINT rimb  CHECK (rimborso IS NULL OR (rimborso IS NOT NULL AND esito = 'RIMBORSO')));

DROP TABLE esisti

--es2 21:43

--Per ogni categoria, la media del rapporto Rimborso/Prezzo per i soli prodotti con più di un
--reclamo


--non so se devo considerare solo i prodotti rimborsati
select avg(coalesce(e.rimborso,0) * 1.0/p.prezzo ) 
from prodotti p, reclami r, esiti e
where p.prodid = r.prodid and e.rid = r.rid
and p.prodid in (
	select p1.prodid
	from prodotti p1, reclami r1
	where p1.prodid = r1.prodid
	group by p1.prodid
	having count(*) > 1
)
group by p.categoria


--La categoria per cui i reclami con esito definito sono stati in media più veloci

WITH avg_date(avg)
AS(
		SELECT avg(e1.dataesito - r1.DATA) AS "avg"
		from prodotti p1, reclami r1, esiti e1
		where p1.prodid = r1.prodid and e1.rid = r1.rid
		group by p1.categoria
)
select P.CATEGORIA, avg(DAYS(e.dataesito) - DAYS(r.data)) AS "MEDIA"
from prodotti p, reclami r, esiti e
where p.prodid = r.prodid and e.rid = r.rid
group by p.categoria
HAVING (avg(e.dataesito - r.DATA) = (
	select min(avg_date.avg)
	FROM avg_date
))


--esercizio 3


create table APP (
     Nome char(10) not null,
     Creatore char(10) not null,
     constraint ID_APP_ID primary key (Nome));

create table VERSIONI (
     Nome char(10) not null,
     Versione dec(6,2) not null,
     DataCrezione date not null,
     URLSito char(20),
     NDownloads integer CHECK (ndownloads >= 0),
     constraint ID_VERSIONI_ID primary key (Nome, Versione),
	 CONSTRAINT url_down CHECK ((urlsito IS NULL AND ndownloads IS NULL) OR (urlsito IS NOT NULL AND ndownloads IS NOT null)));

DROP TABLE versioni

alter table APP add constraint ID_APP_CHK1
     check(exists(select * from VERSIONI
                  where VERSIONI.Nome = Nome)); 

alter table VERSIONI add constraint FKAPPV
     foreign key (Nome)
     references APP;


--bisognerebbe inserire sempre una versione base

CREATE OR replace TRIGGER nuovaApp
AFTER INSERT ON app
REFERENCING NEW AS n
FOR EACH row
WHEN(NOT EXISTS (SELECT * FROM versioni v WHERE v.nome = n.nome))
INSERT INTO versioni(nome, versione, datacrezione)
VALUES (n.nome, 0, CURRENT date)


CREATE OR replace TRIGGER numDownloads
AFTER INSERT ON versioni
REFERENCING NEW AS n
FOR EACH ROW 
UPDATE versioni
SET ndownloads = 0
WHERE nome = n.nome
and urlsito in (
	select v.urlsito
	from versioni v
	where v.nome = n.nome
)


INSERT INTO app(nome, creatore)
values('facebook3', 'io')


INSERT INTO versioni
VALUES ('facebook1', 3, CURRENT date, 'bello', 4)


--22:32
--esercizio 4
CREATE TABLE E2(
	K1 INTEGER NOT NULL PRIMARY KEY,
	A INTEGER NOT NULL,
	B INTEGER NOT NULL
)

CREATE TABLE E3(
	K1 INTEGER NOT NULL PRIMARY KEY,
	A INTEGER NOT NULL,
	C INTEGER NOT NULL
)

CREATE TABLE E4(
	K4 INTEGER NOT NULL PRIMARY KEY,
	D INTEGER NOT NULL,
	K1R1 INTEGER NOT NULL
)

--ref to E2/E3
CREATE OR replace TRIGGER refE2E3
BEFORE INSERT ON E4
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
CREATE or replace trigger puntoC
before insert on E4
referencing new as n
for each row
when (exists (
		select *
		from E2, E3
		where E2.K1 = E3.K1
		AND E2.K1 = n.K1R1
))
signal sqlstate '70000' ('Violato punto c')

--bisognerebbe creare dei trigger anche per quando inseriamo un nuovo elemento in e2/e3


CREATE or replace trigger puntoC1
before insert on E2
referencing new as n
for each row
when (exists (
		select *
		from E4, E3
		where E3.K1 = E4.K1R1
		AND n.K1 = E3.K1
))
signal sqlstate '70000' ('Violato punto c')

CREATE or replace trigger puntoC2
before insert on E3
referencing new as n
for each row
when (exists (
		select *
		from E4, E2
		where E2.K1 = E4.K1R1
		AND n.K1 = E2.K1
))
signal sqlstate '70000' ('Violato punto c')