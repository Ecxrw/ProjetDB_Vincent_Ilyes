-- =====================================================================
--  Mini-projet BDD — Ligue de MMA
--  2_contraintes.sql : contraintes de validation (règles métier)
--  À exécuter après 1_creation.sql.
--  Types de contraintes couverts (cf. cours) :
--    DEFAULT, NOT NULL, UNIQUE, CHECK (comparaison, BETWEEN, IN, LIKE,
--    contrainte multi-colonnes, contrainte conditionnelle)
--  Remarque MySQL 8 : une contrainte CHECK ne peut pas porter sur une colonne
--  de clé étrangère ayant une action ON DELETE/ON UPDATE (erreur 3823). Les
--  règles concernant ces colonnes sont donc garanties par UNIQUE ou par la
--  structure (voir README, bilan critique).
-- =====================================================================
USE ligue_mma;

-- ---------------------------------------------------------------------
-- CATEGORIE
-- ---------------------------------------------------------------------
-- RM : le nom d'une catégorie est unique
ALTER TABLE CATEGORIE ADD CONSTRAINT uq_categorie_nom UNIQUE (nom);
-- RM : le sexe est codé 'M' ou 'F'
ALTER TABLE CATEGORIE ADD CONSTRAINT ck_categorie_sexe CHECK (sexe IN ('M', 'F'));
-- RM : la limite de poids est comprise entre 45 kg et 121 kg (poids lourds)
ALTER TABLE CATEGORIE ADD CONSTRAINT ck_categorie_poids CHECK (limite_poids BETWEEN 45 AND 121);

-- ---------------------------------------------------------------------
-- LIEU
-- ---------------------------------------------------------------------
-- RM : une salle accueille au moins 500 spectateurs
ALTER TABLE LIEU ADD CONSTRAINT ck_lieu_capacite CHECK (capacite >= 500);
-- RM : deux lieux ne peuvent pas avoir le même nom dans la même ville
ALTER TABLE LIEU ADD CONSTRAINT uq_lieu_nom_ville UNIQUE (nom, ville);
-- Valeur par défaut
ALTER TABLE LIEU ALTER COLUMN pays SET DEFAULT 'France';

-- ---------------------------------------------------------------------
-- TYPE_COMBAT
-- ---------------------------------------------------------------------
-- RM : un combat se dispute en 3 ou 5 rounds
ALTER TABLE TYPE_COMBAT ADD CONSTRAINT ck_type_rounds CHECK (nombre_rounds IN (3, 5));
-- RM : un combat pour le titre se dispute obligatoirement en 5 rounds (contrainte multi-colonnes)
ALTER TABLE TYPE_COMBAT ADD CONSTRAINT ck_type_titre_5rounds CHECK (titre = FALSE OR nombre_rounds = 5);
-- RM : le code type est en majuscules (lettres et _ ), ex. 'TITRE', 'MAIN_EVT'
ALTER TABLE TYPE_COMBAT ADD CONSTRAINT ck_type_code CHECK (code_type = UPPER(code_type));
ALTER TABLE TYPE_COMBAT ALTER COLUMN titre SET DEFAULT FALSE;
ALTER TABLE TYPE_COMBAT ALTER COLUMN nombre_rounds SET DEFAULT 3;

-- ---------------------------------------------------------------------
-- PERSONNEL
-- ---------------------------------------------------------------------
-- RM : le numéro de licence a le format 'LIC-' suivi de 4 caractères (masque LIKE)
ALTER TABLE PERSONNEL ADD CONSTRAINT ck_personnel_licence CHECK (num_licence LIKE 'LIC-____');
-- RM : fonctions autorisées
ALTER TABLE PERSONNEL ADD CONSTRAINT ck_personnel_fonction
    CHECK (fonction IN ('Arbitre', 'Juge', 'Medecin', 'Inspecteur', 'Cutman'));

-- ---------------------------------------------------------------------
-- MISE_A_JOUR_CLASSEMENT
-- ---------------------------------------------------------------------
-- RM : la ligue a été fondée en 2020, pas de classement antérieur
ALTER TABLE MISE_A_JOUR_CLASSEMENT ADD CONSTRAINT ck_maj_date CHECK (date_maj >= '2020-01-01');

-- ---------------------------------------------------------------------
-- COMBATTANT
-- ---------------------------------------------------------------------
-- RM : taille réaliste entre 150 et 220 cm
ALTER TABLE COMBATTANT ADD CONSTRAINT ck_combattant_taille CHECK (taille BETWEEN 150 AND 220);
-- RM : date de naissance postérieure à 1960 (pas de CURDATE() possible dans un CHECK)
ALTER TABLE COMBATTANT ADD CONSTRAINT ck_combattant_naissance CHECK (date_naissance >= '1960-01-01');
-- RM : un combattant est identifié de manière unique par (nom, prénom, date de naissance)
ALTER TABLE COMBATTANT ADD CONSTRAINT uq_combattant_identite UNIQUE (nom, prenom, date_naissance);
-- RM : le surnom, s'il existe, est unique dans la ligue
ALTER TABLE COMBATTANT ADD CONSTRAINT uq_combattant_surnom UNIQUE (surnom);
-- RM : le nom commence par une majuscule (masque)
ALTER TABLE COMBATTANT ADD CONSTRAINT ck_combattant_nom
    CHECK (LEFT(nom, 1) = UPPER(LEFT(nom, 1)) COLLATE utf8mb4_bin);

-- ---------------------------------------------------------------------
-- CONTRAT
-- ---------------------------------------------------------------------
-- RM : la date de fin est postérieure à la date de début (multi-colonnes)
ALTER TABLE CONTRAT ADD CONSTRAINT ck_contrat_dates CHECK (date_fin > date_debut);
-- RM : un contrat garantit entre 1 et 8 combats
ALTER TABLE CONTRAT ADD CONSTRAINT ck_contrat_combats CHECK (combats_garantis BETWEEN 1 AND 8);
-- RM : la bourse de base est d'au moins 10 000 € (minimum syndical de la ligue)
ALTER TABLE CONTRAT ADD CONSTRAINT ck_contrat_bourse CHECK (bourse_base >= 10000);
ALTER TABLE CONTRAT ALTER COLUMN combats_garantis SET DEFAULT 4;

-- ---------------------------------------------------------------------
-- EVENEMENT
-- ---------------------------------------------------------------------
-- RM : le nom d'un événement est unique
ALTER TABLE EVENEMENT ADD CONSTRAINT uq_evenement_nom UNIQUE (nom);
-- RM : pas d'événement avant la création de la ligue
ALTER TABLE EVENEMENT ADD CONSTRAINT ck_evenement_date CHECK (date_evenement >= '2020-01-01');

-- ---------------------------------------------------------------------
-- COMBAT
-- ---------------------------------------------------------------------
-- RM : un événement compte au plus 15 combats
ALTER TABLE COMBAT ADD CONSTRAINT ck_combat_ordre CHECK (num_ordre BETWEEN 1 AND 15);
-- RM : méthodes de victoire autorisées
ALTER TABLE COMBAT ADD CONSTRAINT ck_combat_methode
    CHECK (methode_victoire IN ('KO/TKO', 'Soumission', 'Decision unanime',
                                'Decision partagee', 'Decision majoritaire',
                                'Disqualification', 'No contest', 'Nul'));
-- RM : un combat se termine entre le 1er et le 5e round
ALTER TABLE COMBAT ADD CONSTRAINT ck_combat_round CHECK (round_fin BETWEEN 1 AND 5);
-- RM : un round dure 5 minutes maximum
ALTER TABLE COMBAT ADD CONSTRAINT ck_combat_temps CHECK (temps BETWEEN '00:00:01' AND '00:05:00');
-- RM (conditionnelle) : une décision des juges va forcément jusqu'à 5:00 du dernier round
ALTER TABLE COMBAT ADD CONSTRAINT ck_combat_decision
    CHECK (methode_victoire NOT LIKE 'Decision%' OR temps = '00:05:00');
-- RM (conditionnelle) : un résultat (méthode) implique round et temps renseignés
ALTER TABLE COMBAT ADD CONSTRAINT ck_combat_resultat_complet
    CHECK ((methode_victoire IS NULL AND round_fin IS NULL AND temps IS NULL)
        OR (methode_victoire IS NOT NULL AND round_fin IS NOT NULL AND temps IS NOT NULL));
-- RM : un seul « combat de la soirée » par événement
ALTER TABLE COMBAT ADD CONSTRAINT uq_combat_soiree UNIQUE (id_evenement_soiree);

-- ---------------------------------------------------------------------
-- EST_CLASSE
-- ---------------------------------------------------------------------
-- RM : position 0 = champion, puis 1 à 15
ALTER TABLE EST_CLASSE ADD CONSTRAINT ck_classe_position CHECK (position BETWEEN 0 AND 15);
-- RM : à une date donnée, une position n'est occupée que par un combattant par catégorie
ALTER TABLE EST_CLASSE ADD CONSTRAINT uq_classe_position UNIQUE (id_categorie, date_maj, position);

-- ---------------------------------------------------------------------
-- NOTE
-- ---------------------------------------------------------------------
-- RM : système des 10 points, une note de round est comprise entre 7 et 10,
--      le score total d'un combat (3 ou 5 rounds) est donc compris entre 21 et 50
ALTER TABLE NOTE ADD CONSTRAINT ck_note_score CHECK (score BETWEEN 21 AND 50);
