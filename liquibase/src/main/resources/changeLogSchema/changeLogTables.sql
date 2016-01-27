--liquibase formatted sql

--changeset jiwalker:addAflow
CREATE TABLE aflow 
(
  id serial NOT NULL,
  site_abb varchar(4),
  site_qw_id varchar(15),
  site_flow_id varchar(15),
  wy integer,
  flow numeric(22,11)
);
--rollback DROP TABLE aflow;

--changeset jiwalker:addAloads
CREATE TABLE aloads
(
  id serial NOT NULL,
  site_abb varchar(4),
  site_qw_id varchar(15),
  site_flow_id varchar(15),
  constit varchar(7),
  wy integer,
  modtype varchar(10),
  tons numeric(22,11),
  tons_l95 numeric(22,11),
  tons_u95 numeric(22,11),
  fwc numeric(22,11),
  yield numeric(22,11)
);
--rollback DROP TABLE aloads;

--changeset jiwalker:addDflow
CREATE TABLE dflow
(
  id serial NOT NULL,
  site_abb varchar(4),
  site_qw_id varchar(15),
  site_flow_id varchar(15),
  date date,
  flow numeric(22,11),
  wy integer
);
--rollback DROP TABLE dflow;

--changeset jiwalker:addDiscqw
CREATE TABLE discqw
(
  id serial NOT NULL,
  site_abb varchar(4),
  site_qw_id varchar(15),
  site_flow_id varchar(15),
  constit varchar(7),
  date date,
  wy integer,
  concentration numeric(22,11),
  remark varchar(1)
);
--rollback DROP TABLE discqw;

--changeset jiwalker:addMflow
CREATE TABLE mflow
(
  id serial NOT NULL,
  site_abb varchar(4),
  site_qw_id varchar(15),
  site_flow_id varchar(15),
  wy integer,
  month integer,
  flow numeric(22,11)
);
--rollback DROP TABLE discqw;

--changeset jiwalker:addMloads
CREATE TABLE mloads
(
  id serial NOT NULL,
  site_abb varchar(4),
  site_qw_id varchar(15),
  site_flow_id varchar(15),
  constit varchar(7),
  wy integer,
  month integer,
  modtype varchar(10),
  tons numeric(22,11),
  tons_l95 numeric(22,11),
  tons_u95 numeric(22,11)
);
--rollback DROP TABLE mloads;