-- =====================================================================
--  Mini-projet BDD — Ligue de MMA
--  1_creation.sql : Modèle Physique de Données (MPD) — MySQL 8 / MariaDB
--  Contient : tables, clés primaires, clés étrangères (contraintes d'intégrité)
--  Gestion automatique des modifications / suppressions :
--    * ON UPDATE CASCADE partout : un changement de clé est répercuté
--    * ON DELETE CASCADE  pour les dépendances obligatoires (cardinalité 1,1
--      ou tables d'association) : les lignes dépendantes sont supprimées
--    * ON DELETE SET NULL pour les dépendances facultatives (cardinalité 0,1)
--  => aucune suppression / modification ne déclenche d'erreur de clé étrangère.
-- =====================================================================

DROP DATABASE IF EXISTS ligue_mma;
CREATE DATABASE ligue_mma CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ligue_mma;

-- ---------------------------------------------------------------------
-- Tables issues d'entités sans clé étrangère
-- ---------------------------------------------------------------------
CREATE TABLE CATEGORIE (
    id_categorie   INT            NOT NULL AUTO_INCREMENT,
    nom            VARCHAR(50)    NOT NULL,
    limite_poids   DECIMAL(5,2)   NOT NULL,          -- en kg
    sexe           CHAR(1)        NOT NULL,          -- 'M' ou 'F'
    CONSTRAINT pk_categorie PRIMARY KEY (id_categorie)
) ENGINE = InnoDB;

CREATE TABLE LIEU (
    id_lieu        INT            NOT NULL AUTO_INCREMENT,
    nom            VARCHAR(100)   NOT NULL,
    ville          VARCHAR(60)    NOT NULL,
    pays           VARCHAR(60)    NOT NULL,
    capacite       INT            NOT NULL,
    CONSTRAINT pk_lieu PRIMARY KEY (id_lieu)
) ENGINE = InnoDB;

CREATE TABLE TYPE_COMBAT (
    code_type      VARCHAR(10)    NOT NULL,
    titre          BOOLEAN        NOT NULL,          -- titre O/N
    nombre_rounds  TINYINT        NOT NULL,
    CONSTRAINT pk_type_combat PRIMARY KEY (code_type)
) ENGINE = InnoDB;

CREATE TABLE PERSONNEL (
    num_licence    VARCHAR(12)    NOT NULL,
    nom            VARCHAR(60)    NOT NULL,
    fonction       VARCHAR(30)    NOT NULL,          -- Arbitre, Juge, Médecin...
    CONSTRAINT pk_personnel PRIMARY KEY (num_licence)
) ENGINE = InnoDB;

CREATE TABLE MISE_A_JOUR_CLASSEMENT (
    date_maj       DATE           NOT NULL,
    CONSTRAINT pk_maj_classement PRIMARY KEY (date_maj)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- COMBATTANT : « appartient a » (1,1) -> clé étrangère id_categorie
-- ---------------------------------------------------------------------
CREATE TABLE COMBATTANT (
    id_combattant   INT           NOT NULL AUTO_INCREMENT,
    nom             VARCHAR(60)   NOT NULL,
    prenom          VARCHAR(60)   NOT NULL,
    surnom          VARCHAR(60),
    date_naissance  DATE          NOT NULL,
    nationalite     VARCHAR(60)   NOT NULL,
    taille          SMALLINT      NOT NULL,           -- en cm
    id_categorie    INT           NOT NULL,
    CONSTRAINT pk_combattant PRIMARY KEY (id_combattant),
    CONSTRAINT fk_combattant_categorie FOREIGN KEY (id_categorie)
        REFERENCES CATEGORIE (id_categorie)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- CONTRAT : « signe » (1,1) -> clé étrangère id_combattant
-- ---------------------------------------------------------------------
CREATE TABLE CONTRAT (
    num_contrat       INT           NOT NULL AUTO_INCREMENT,
    date_debut        DATE          NOT NULL,
    date_fin          DATE          NOT NULL,
    combats_garantis  TINYINT       NOT NULL,
    bourse_base       DECIMAL(10,2) NOT NULL,         -- en euros
    id_combattant     INT           NOT NULL,
    CONSTRAINT pk_contrat PRIMARY KEY (num_contrat),
    CONSTRAINT fk_contrat_combattant FOREIGN KEY (id_combattant)
        REFERENCES COMBATTANT (id_combattant)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- REGNE : entité faible identifiée relativement à CATEGORIE (« concerne » 1,1(R))
--         « detient le titre » (1,1) -> clé étrangère id_combattant
-- ---------------------------------------------------------------------
CREATE TABLE REGNE (
    id_categorie    INT   NOT NULL,
    date_debut      DATE  NOT NULL,
    id_combattant   INT   NOT NULL,
    CONSTRAINT pk_regne PRIMARY KEY (id_categorie, date_debut),
    CONSTRAINT fk_regne_categorie FOREIGN KEY (id_categorie)
        REFERENCES CATEGORIE (id_categorie)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_regne_combattant FOREIGN KEY (id_combattant)
        REFERENCES COMBATTANT (id_combattant)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- EST_CLASSE : association ternaire COMBATTANT / CATEGORIE / MISE_A_JOUR_CLASSEMENT
-- ---------------------------------------------------------------------
CREATE TABLE EST_CLASSE (
    id_combattant   INT      NOT NULL,
    id_categorie    INT      NOT NULL,
    date_maj        DATE     NOT NULL,
    position        TINYINT  NOT NULL,
    CONSTRAINT pk_est_classe PRIMARY KEY (id_combattant, id_categorie, date_maj),
    CONSTRAINT fk_classe_combattant FOREIGN KEY (id_combattant)
        REFERENCES COMBATTANT (id_combattant)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_classe_categorie FOREIGN KEY (id_categorie)
        REFERENCES CATEGORIE (id_categorie)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_classe_maj FOREIGN KEY (date_maj)
        REFERENCES MISE_A_JOUR_CLASSEMENT (date_maj)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- EVENEMENT : « acceuille » (1,1) -> id_lieu
--             « performance de la soirée » (0,1) -> id_combattant_perf (facultatif)
-- ---------------------------------------------------------------------
CREATE TABLE EVENEMENT (
    id_evenement        INT           NOT NULL AUTO_INCREMENT,
    nom                 VARCHAR(100)  NOT NULL,
    date_evenement      DATE          NOT NULL,
    id_lieu             INT           NOT NULL,
    id_combattant_perf  INT           NULL,
    CONSTRAINT pk_evenement PRIMARY KEY (id_evenement),
    CONSTRAINT fk_evenement_lieu FOREIGN KEY (id_lieu)
        REFERENCES LIEU (id_lieu)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_evenement_perf FOREIGN KEY (id_combattant_perf)
        REFERENCES COMBATTANT (id_combattant)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- EST_AFFECTE : association PERSONNEL (0,n) / EVENEMENT (1,n)
-- ---------------------------------------------------------------------
CREATE TABLE EST_AFFECTE (
    id_evenement   INT          NOT NULL,
    num_licence    VARCHAR(12)  NOT NULL,
    CONSTRAINT pk_est_affecte PRIMARY KEY (id_evenement, num_licence),
    CONSTRAINT fk_affecte_evenement FOREIGN KEY (id_evenement)
        REFERENCES EVENEMENT (id_evenement)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_affecte_personnel FOREIGN KEY (num_licence)
        REFERENCES PERSONNEL (num_licence)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- COMBAT : entité faible identifiée relativement à EVENEMENT (« comporte » 1,1(R))
--   « Se deroule en » (1,1)        -> id_categorie
--   « est de type » (1,1)          -> code_type
--   « arbitre » (1,1)              -> num_licence_arbitre
--   « remporte » (0,1)             -> id_vainqueur (NULL = nul / no contest / à venir)
--   « combat de la soirée » (0,1)  -> id_evenement_soiree (UNIQUE : 1 seul par soirée)
-- ---------------------------------------------------------------------
CREATE TABLE COMBAT (
    id_evenement          INT           NOT NULL,
    num_ordre             TINYINT       NOT NULL,
    methode_victoire      VARCHAR(30),
    round_fin             TINYINT,
    temps                 TIME,
    id_categorie          INT           NOT NULL,
    code_type             VARCHAR(10)   NOT NULL,
    num_licence_arbitre   VARCHAR(12)   NOT NULL,
    id_vainqueur          INT           NULL,
    id_evenement_soiree   INT           NULL,
    CONSTRAINT pk_combat PRIMARY KEY (id_evenement, num_ordre),
    CONSTRAINT fk_combat_evenement FOREIGN KEY (id_evenement)
        REFERENCES EVENEMENT (id_evenement)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_combat_categorie FOREIGN KEY (id_categorie)
        REFERENCES CATEGORIE (id_categorie)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_combat_type FOREIGN KEY (code_type)
        REFERENCES TYPE_COMBAT (code_type)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_combat_arbitre FOREIGN KEY (num_licence_arbitre)
        REFERENCES PERSONNEL (num_licence)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_combat_vainqueur FOREIGN KEY (id_vainqueur)
        REFERENCES COMBATTANT (id_combattant)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_combat_soiree FOREIGN KEY (id_evenement_soiree)
        REFERENCES EVENEMENT (id_evenement)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- OPPOSE : association COMBATTANT (0,n) / COMBAT (2,2)
-- ---------------------------------------------------------------------
CREATE TABLE OPPOSE (
    id_combattant  INT      NOT NULL,
    id_evenement   INT      NOT NULL,
    num_ordre      TINYINT  NOT NULL,
    CONSTRAINT pk_oppose PRIMARY KEY (id_combattant, id_evenement, num_ordre),
    CONSTRAINT fk_oppose_combattant FOREIGN KEY (id_combattant)
        REFERENCES COMBATTANT (id_combattant)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_oppose_combat FOREIGN KEY (id_evenement, num_ordre)
        REFERENCES COMBAT (id_evenement, num_ordre)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- NOTE : association ternaire COMBATTANT / COMBAT / PERSONNEL (juge), attribut score
-- ---------------------------------------------------------------------
CREATE TABLE NOTE (
    id_combattant  INT          NOT NULL,
    id_evenement   INT          NOT NULL,
    num_ordre      TINYINT      NOT NULL,
    num_licence    VARCHAR(12)  NOT NULL,
    score          TINYINT      NOT NULL,
    CONSTRAINT pk_note PRIMARY KEY (id_combattant, id_evenement, num_ordre, num_licence),
    CONSTRAINT fk_note_combattant FOREIGN KEY (id_combattant)
        REFERENCES COMBATTANT (id_combattant)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_note_combat FOREIGN KEY (id_evenement, num_ordre)
        REFERENCES COMBAT (id_evenement, num_ordre)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_note_personnel FOREIGN KEY (num_licence)
        REFERENCES PERSONNEL (num_licence)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;
