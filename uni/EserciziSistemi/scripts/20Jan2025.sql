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


--esercizio 1 inizio 18:59

--Per ogni socio, il numero di società in cui è socio singolo, includendo anche i soci che
--non sono mai soci singoli e ordinando il risultato per numero decrescente di società


WITH sociESOcietaSingola(socio, numeroSocieta) as
(SELECT so.nome, count(*)
FROM SOCIETA s, QUOTE q, SOCI so
WHERE so.Nome = q.Socio AND s.idsoc = q.idsoc
and q.numazioni = s.totazioni
GROUP BY so.nome)
SELECT so.nome, COALESCE(s.numeroSocieta, 0)
FROM soci so LEFT JOIN sociESOcietaSingola s ON (so.nome = s.socio)
GROUP BY so.nome, s.numerosocieta



--piu compatto
SELECT so.nome, COALESCE(count(a.idsoc), 0)
FROM SOCI so LEFT JOIN (
	SELECT s.idsoc, q.socio
	FROM quote q, societa s
	WHERE q.idsoc = s.idsoc
	AND q.numazioni = s.totazioni
) a ON (so.nome = a.socio)
GROUP BY so.nome

--I dati delle società con più di un socio in cui la maggioranza delle azioni (> 50%) è
--posseduta da soci dello stesso stato della società

SELECT s.idsoc, s.totazioni, s.stato
FROM quote q, societa s
WHERE q.idsoc = s.idsoc 
AND EXISTS(
	SELECT *
	FROM quote q1
	WHERE q1.idsoc = q.idsoc
	AND q1.socio <> q.socio
) 
GROUP BY s.idsoc, s.totazioni, s.stato
HAVING 0.5 * s.totazioni < (	SELECT 1.0*sum(q2.numazioni)
				FROM quote q2, soci so
				WHERE q2.idsoc = s.idsoc 
				AND so.nome = q2.socio
				AND so.statoresidenza = s.stato
)

--fine 19:18

--esercizio 3 19:27


create table RISULTATI (
     Gara char(5) not null,
     Punteggio integer not null,
     Posizione integer,
     NomeGiocatore char(10) not null,
     constraint ID_RISULTATI_ID primary key (Gara, NomeGiocatore));

DROP TABLE risultati

CREATE OR replace TRIGGER definizionePunteggio
AFTER INSERT on risultati
REFERENCING NEW AS n
FOR EACH ROW 
BEGIN ATOMIC
UPDATE risultati
SET posizione = (
	SELECT COALESCE(r.posizione, 1)
	FROM risultati r
	WHERE r.gara = n.gara
	AND r.punteggio = (
		SELECT max(r1.punteggio)
		FROM risultati r1
		WHERE r1.gara = n.gara
		AND r1.punteggio <= n.punteggio
	)
)
WHERE (risultati.gara, risultati.NomeGiocatore) = (n.gara, n.NomeGiocatore);
UPDATE risultati
SET posizione = posizione + 1
WHERE risultati.posizione <= (SELECT r3.posizione FROM risultati r3 WHERE (r3.gara, r3.nomegiocatore) = (n.gara, n.nomegiocatore))
AND risultati.gara = n.gara
AND risultati.nomegiocatore <> n.nomegiocatore;
END

INSERT INTO risultati(gara, punteggio, nomegiocatore)
VALUES ('devis', 30, 'Mirco')


--fine 19:54

--esercizio 4 


--di base un elemento di E1 partecipa ad R1 come X
CREATE TABLE E1(
	K1 INTEGER NOT NULL PRIMARY KEY,
	A INTEGER NOT NULL,
	K1R1 integer,
	D integer,
	CONSTRAINT relazione1 CHECK ((K1R1 IS NULL AND D IS NULL) OR (K1R1 IS NOT NULL AND D IS NOT NULL)),
	T char(1) NOT NULL CHECK (T IN ('A', 'B', 'C')),
	B integer,
	C integer,
	K1R2 integer,
	CONSTRAINT TIPOA CHECK ((T = 'A' AND B IS NULL AND C IS NULL AND K1R2 IS NULL) OR (T <> 'A')),
	CONSTRAINT TIPOB CHECK ((T = 'B' AND B IS NOT NULL AND C IS NULL AND K1R2 IS NULL) OR (t <> 'B')),
	CONSTRAINT TIPOC CHECK ((T = 'C' AND B IS NULL AND C IS NOT NULL AND K1R2 IS NOT NULL) OR (t <> 'C'))
	
)

DROP TABLE e1

--vincolo per R1
ALTER TABLE E1 ADD CONSTRAINT 
chiave FOREIGN KEY(K1R1) REFERENCES E1


--vincolo per R2
ALTER TABLE E1 ADD CONSTRAINT 
chiaveR2 FOREIGN KEY(K1R2) REFERENCES E1

CREATE OR replace TRIGGER verificaR2
BEFORE INSERT on E1
REFERENCING NEW AS N
FOR EACH ROW 
WHEN (N.T = 'C'
	AND NOT EXISTS (
		SELECT *
		FROM E1
		WHERE e1.k1 = n.K1R2
		AND e1.t = 'B'
	)
)
SIGNAL SQLSTATE '70001' ('R2 reference to E2 is not a E2 element')

--punto c
create or replace trigger puntoC
after insert on E1
referencing new as n
for each row 
when(exists (	select *
				from e1
				where e1.K1R2 = n.K1)
	and exists(
				select *
				from e1
				where e1.K1R1 = n.K1
				
	))
signal sqlstate '70000' ('Point c not respected')


--fine 20:21




