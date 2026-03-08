-- *********************************************
-- * Standard SQL generation                   
-- *--------------------------------------------
-- * DB-MAIN version: 11.0.2              
-- * Generator date: Sep 20 2021              
-- * Generation date: Tue Dec 30 18:41:01 2025 
-- * LUN file:  
-- * Schema: SCHEMA_trad/SQL 
-- ********************************************* 


-- Database Section
-- ________________ 

create database SCHEMA_trad;


-- DBSpace Section
-- _______________


-- Tables Section
-- _____________ 

create table RECENSIONI (
     Cliente char(1) not null,
     Data char(1) not null,
     Testo char(1),
     Voto char(1) not null,
     Prodotto char(1) not null,
     Prezzo char(1) not null,
     constraint ID_RECENSIONI_ID primary key (Cliente, Prodotto));

create table REC_PASSATE (
     Cliente char(1) not null,
     Data char(1) not null,
     Testo char(1),
     Voto char(1) not null,
     Prodotto char(1) not null,
     Prezzo char(1) not null,
     constraint ID_REC_PASSATE_ID primary key (Cliente, Data, Prodotto));


-- Constraints Section
-- ___________________ 


-- Index Section
-- _____________ 

create unique index ID_RECENSIONI_IND
     on RECENSIONI (Cliente, Prodotto);

create unique index ID_REC_PASSATE_IND
     on REC_PASSATE (Cliente, Data, Prodotto);

