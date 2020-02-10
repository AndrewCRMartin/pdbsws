DROP TABLE sprot     CASCADE;
DROP TABLE idac      CASCADE;
DROP TABLE acac      CASCADE;
DROP TABLE pdbac     CASCADE;
DROP TABLE pdbsws    CASCADE;
DROP TABLE alignment CASCADE;

CREATE TABLE sprot 
(
   ac VARCHAR(8) PRIMARY KEY,
   sequence TEXT,
   date DATE
);
-- Might help when we update beyond 7.4.1
-- CREATE INDEX sprot_date_idx ON sprot (date);

CREATE TABLE idac
(
   id VARCHAR(16) PRIMARY KEY,
   ac VARCHAR(8)
);
CREATE INDEX idac_ac_idx ON idac (ac);

CREATE TABLE acac
(
   ac    VARCHAR(8),
   altac VARCHAR(8)
);
CREATE INDEX acac_ac_idx ON acac (ac);
CREATE INDEX acac_altac_idx ON acac (altac);

CREATE TABLE pdbac
(
   ac    VARCHAR(8),
   pdb   CHAR(4),
   done  BOOL
);
CREATE INDEX pdbac_ac_idx  ON pdbac (ac);
CREATE INDEX pdbac_pdb_idx ON pdbac (pdb);

CREATE TABLE pdbsws
(
   pdb         CHAR(4),
   chain       CHAR(1),
   ac          VARCHAR(16),
   valid       BOOL,
   source      VARCHAR(16),
   date        DATE,
   aligned     BOOL,
   identity    REAL,
   overlap     INT,
   length      INT,
   fracoverlap REAL,
   start       CHAR(5),
   stop        CHAR(5),
   CONSTRAINT  pdbsws_primary_key PRIMARY KEY (pdb, chain, ac, start)
);

CREATE INDEX pdbsws_ac_idx    ON pdbsws (ac);
CREATE INDEX pdbsws_pdb_idx   ON pdbsws (pdb);
CREATE INDEX pdbsws_chain_idx ON pdbsws (chain);

CREATE VIEW nchains 
AS SELECT pdb, COUNT(chain) 
FROM pdbsws 
GROUP BY pdb;

CREATE VIEW chimera
AS SELECT pdb, chain, COUNT(DISTINCT ac) AS count
FROM pdbsws
GROUP BY pdb, chain;

CREATE VIEW ndbref
AS SELECT pdb, chain, COUNT(ac) AS count
FROM pdbsws
GROUP BY pdb, chain;

CREATE TABLE alignment
(
   pdb      CHAR(4),
   chain    CHAR(1),
   pdbcount INT,
   resnam   VARCHAR(4),
   pdbaa    CHAR(1),
   resid    VARCHAR(6),
   ac       VARCHAR(8),
   swsaa    CHAR(1),
   swscount INT,
   CONSTRAINT alignment_primary_key PRIMARY KEY (pdb, chain, pdbcount)
);
CREATE INDEX alignment_pdb_chain_idx ON alignment (pdb, chain);
CREATE INDEX alignment_pdb_idx ON alignment (pdb);
CREATE INDEX alignment_ac_idx ON alignment (ac);

GRANT select ON sprot     TO public;
GRANT select ON idac      TO public;
GRANT select ON acac      TO public;
GRANT select ON pdbac     TO public;
GRANT select ON pdbsws    TO public;
GRANT select ON alignment TO public;

