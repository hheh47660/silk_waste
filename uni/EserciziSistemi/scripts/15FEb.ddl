-- *********************************************
-- * Standard SQL generation                   
-- *--------------------------------------------
-- * DB-MAIN version: 11.0.2              
-- * Generator date: Sep 20 2021              
-- * Generation date: Sun Dec 28 21:40:06 2025 
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

create table TORNEI (
     CodT char(1) not null,
     Descrizione char(1) not null,
     GIocatori -- Compound attribute --,
     constraint ID_TORNEI_ID primary key (CodT),
     constraint SID_TORNEI_ID unique (CodG));

create table Terminati (
     CodT char(1) not null,
     VIncitore char(1) not null,
     constraint FKTOR_Ter_ID primary key (CodT));


-- Constraints Section
-- ___________________ 

alter table Terminati add constraint FKTOR_Ter_FK
     foreign key (CodT)
     references TORNEI;


-- Index Section
-- _____________ 

create unique index ID_TORNEI_IND
     on TORNEI (CodT);

create unique index SID_TORNEI_IND
     on TORNEI (CodG);

create unique index FKTOR_Ter_IND
     on Terminati (CodT);

