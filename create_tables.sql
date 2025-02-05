-- Drop les tables existantes
/*
DROP TABLE IF EXISTS complexe CASCADE;
DROP TABLE IF EXISTS logement CASCADE;
DROP TABLE IF EXISTS personne CASCADE;
DROP TABLE IF EXISTS activite CASCADE;
DROP TABLE IF EXISTS organisation CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS participation CASCADE;
DROP TABLE IF EXISTS equipement CASCADE;
DROP TABLE IF EXISTS intervenant CASCADE;
DROP TYPE IF EXISTS urgence_type CASCADE;
DROP TABLE IF EXISTS intervention CASCADE;
DROP TABLE IF EXISTS interv_equi CASCADE;
*/

CREATE TABLE complexe (
  ID_complexe INTEGER PRIMARY KEY,
  emplacement VARCHAR
);

CREATE TABLE logement (
  ID_logement INTEGER PRIMARY KEY,
  ID_complexe INTEGER,
  type_logement VARCHAR,
  nb_chambres INTEGER,
  prix_jour NUMERIC,
  FOREIGN KEY (ID_complexe) REFERENCES complexe(ID_complexe)
);

CREATE TABLE personne (
  ID_personne INTEGER PRIMARY KEY,
  nom VARCHAR,
  prenom VARCHAR,
  date_de_naissance DATE,
  mail VARCHAR
);

CREATE TABLE activite (
  ID_activite INTEGER PRIMARY KEY,
  description VARCHAR
);

CREATE TABLE organisation (
  ID_organisation INTEGER PRIMARY KEY,
  ID_activite INTEGER,
  date_organisation TIMESTAMP,
  ID_complexe INTEGER,
  FOREIGN KEY (ID_activite) REFERENCES activite(ID_activite),
  FOREIGN KEY (ID_complexe) REFERENCES complexe(ID_complexe)
);

CREATE TABLE reservation (
  ID_reservation INTEGER PRIMARY KEY,
  ID_logement INTEGER,
  ID_personne INTEGER,
  date_debut TIMESTAMP,
  date_fin TIMESTAMP,
  FOREIGN KEY (ID_logement) REFERENCES logement(ID_logement),
  FOREIGN KEY (ID_personne) REFERENCES personne(ID_personne)
);

CREATE TABLE participation (
  ID_personne INTEGER,
  ID_organisation INTEGER,
  PRIMARY KEY (ID_personne, ID_organisation),
  FOREIGN KEY (ID_personne) REFERENCES personne(ID_personne),
  FOREIGN KEY (ID_organisation) REFERENCES organisation(ID_organisation)
);

CREATE TABLE equipement (
  ID_equipement INTEGER PRIMARY KEY,
  ID_logement INTEGER,
  description VARCHAR,
  FOREIGN KEY (ID_logement) REFERENCES logement(ID_logement)
);

CREATE TABLE intervenant (
  ID_intervenant INTEGER PRIMARY KEY,
  ID_personne INTEGER,
  domaine VARCHAR,
  entreprise VARCHAR,
  FOREIGN KEY (ID_personne) REFERENCES personne(ID_personne)
);

CREATE TYPE urgence_type AS ENUM ('basse', 'moyenne', 'haute');

CREATE TABLE intervention (
  ID_intervention INTEGER PRIMARY KEY,
  ID_intervenant INTEGER,
  description VARCHAR,
  ID_logement INTEGER,
  urgence urgence_type,
  FOREIGN KEY (ID_intervenant) REFERENCES intervenant(ID_intervenant),
  FOREIGN KEY (ID_logement) REFERENCES logement(ID_logement)
);

CREATE TABLE interv_equi (
  ID_intervention INTEGER,
  ID_equipement INTEGER,
  ID_remplacement INTEGER,
  PRIMARY KEY (ID_intervention, ID_equipement, ID_remplacement),
  FOREIGN KEY (ID_intervention) REFERENCES intervention(ID_intervention),
  FOREIGN KEY (ID_equipement) REFERENCES equipement(ID_equipement),
  FOREIGN KEY (ID_remplacement) REFERENCES equipement(ID_equipement)
);