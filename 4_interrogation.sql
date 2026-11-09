-- =====================================================================
--  Mini-projet BDD — Ligue de MMA
--  4_interrogation.sql : requêtes d'interrogation
--
--  SCÉNARIO D'UTILISATION (détaillé dans le README) :
--  Karine Duval, responsable du matchmaking de la ligue, prépare
--  l'événement LMMA 25 (Paris, février 2027) et le bilan sportif annuel.
--  Elle doit : connaître les champions et les prétendants, vérifier les
--  contrats, repérer les combattants disponibles / inactifs, analyser les
--  statistiques (méthodes de victoire, durées, juges) et préparer la
--  promotion (combattants spectaculaires, lieux).
-- =====================================================================
USE ligue_mma;

-- #####################################################################
-- A. PROJECTIONS ET SÉLECTIONS (tri, DISTINCT, LIKE, IN, BETWEEN)
-- #####################################################################

-- A1. Catégories féminines, de la plus légère à la plus lourde
--     (pour ouvrir un nouveau combat féminin sur la carte)
SELECT nom, limite_poids
FROM CATEGORIE
WHERE sexe = 'F'
ORDER BY limite_poids ASC;

-- A2. Liste des nationalités représentées dans la ligue (sans doublon)
--     (le service promotion veut cibler les marchés étrangers)
SELECT DISTINCT nationalite
FROM COMBATTANT
ORDER BY nationalite;

-- A3. Combattants possédant un surnom « à la française » (commençant par
--     'Le ' ou 'La ') — utile pour l'affiche d'un événement à Paris (masque LIKE)
SELECT prenom, nom, surnom
FROM COMBATTANT
WHERE surnom LIKE 'Le %' OR surnom LIKE 'La %'
ORDER BY surnom;

-- A4. Jeunes combattants (nés entre 1998 et 2002) — prospects à mettre en avant (BETWEEN)
SELECT prenom, nom, date_naissance, nationalite, taille
FROM COMBATTANT
WHERE date_naissance BETWEEN '1998-01-01' AND '2002-12-31'
ORDER BY date_naissance DESC;

-- A5. Finishes spectaculaires : combats gagnés par KO/TKO ou soumission
--     dès le 1er round (IN + sélection multiple)
SELECT id_evenement, num_ordre, methode_victoire, temps
FROM COMBAT
WHERE methode_victoire IN ('KO/TKO', 'Soumission')
  AND round_fin = 1
ORDER BY temps ASC;

-- A6. Contrats qui expirent dans les 12 prochains mois avec une bourse
--     d'au moins 20 000 € : à renégocier en priorité (BETWEEN sur dates)
SELECT num_contrat, id_combattant, date_fin, bourse_base
FROM CONTRAT
WHERE date_fin BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 12 MONTH)
  AND bourse_base >= 20000
ORDER BY date_fin, bourse_base DESC;


-- #####################################################################
-- B. FONCTIONS D'AGRÉGATION (GROUP BY / HAVING)
-- #####################################################################

-- B1. Nombre de combattants et taille moyenne par catégorie
--     (catégories ayant au moins 9 combattants = les plus « profondes »)
SELECT cat.nom AS categorie, COUNT(*) AS nb_combattants,
       ROUND(AVG(c.taille), 1) AS taille_moyenne
FROM COMBATTANT c
JOIN CATEGORIE cat ON cat.id_categorie = c.id_categorie
GROUP BY cat.id_categorie, cat.nom
HAVING COUNT(*) >= 9
ORDER BY nb_combattants DESC;

-- B2. Répartition des méthodes de victoire (en nombre et en %)
--     pour les méthodes apparaissant au moins 5 fois
SELECT methode_victoire, COUNT(*) AS nb,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM COMBAT WHERE methode_victoire IS NOT NULL), 1) AS pourcentage
FROM COMBAT
WHERE methode_victoire IS NOT NULL
GROUP BY methode_victoire
HAVING COUNT(*) >= 5
ORDER BY nb DESC;

-- B3. Les combattants les plus victorieux (au moins 4 victoires)
SELECT c.prenom, c.nom, COUNT(*) AS victoires
FROM COMBAT cb
JOIN COMBATTANT c ON c.id_combattant = cb.id_vainqueur
GROUP BY c.id_combattant, c.prenom, c.nom
HAVING COUNT(*) >= 4
ORDER BY victoires DESC, c.nom;

-- B4. Masse salariale par nationalité : bourse moyenne, min, max des contrats
--     (nationalités dont la bourse moyenne dépasse 30 000 €)
SELECT c.nationalite, COUNT(*) AS nb_contrats,
       ROUND(AVG(ct.bourse_base)) AS bourse_moy,
       MIN(ct.bourse_base) AS bourse_min, MAX(ct.bourse_base) AS bourse_max
FROM CONTRAT ct
JOIN COMBATTANT c ON c.id_combattant = ct.id_combattant
GROUP BY c.nationalite
HAVING AVG(ct.bourse_base) > 30000
ORDER BY bourse_moy DESC;

-- B5. Durée moyenne d'un combat (en minutes) par catégorie
--     durée = (round_fin - 1) * 5 min + temps du dernier round
SELECT cat.nom AS categorie, COUNT(*) AS nb_combats,
       ROUND(AVG((cb.round_fin - 1) * 300 + TIME_TO_SEC(cb.temps)) / 60, 2) AS duree_moy_min
FROM COMBAT cb
JOIN CATEGORIE cat ON cat.id_categorie = cb.id_categorie
WHERE cb.temps IS NOT NULL
GROUP BY cat.id_categorie, cat.nom
ORDER BY duree_moy_min ASC;

-- B6. Charge de travail des arbitres : nombre de combats arbitrés
--     (arbitres ayant officié plus de 25 combats)
SELECT p.nom, COUNT(*) AS nb_combats_arbitres
FROM COMBAT cb
JOIN PERSONNEL p ON p.num_licence = cb.num_licence_arbitre
GROUP BY p.num_licence, p.nom
HAVING COUNT(*) > 25
ORDER BY nb_combats_arbitres DESC;

-- B7. Score moyen attribué par chaque juge (détection de juges trop sévères/généreux)
SELECT p.nom AS juge, COUNT(*) AS nb_notes, ROUND(AVG(n.score), 2) AS score_moyen,
       MIN(n.score) AS score_min, MAX(n.score) AS score_max
FROM NOTE n
JOIN PERSONNEL p ON p.num_licence = n.num_licence
GROUP BY p.num_licence, p.nom
HAVING COUNT(*) >= 20
ORDER BY score_moyen;


-- #####################################################################
-- C. JOINTURES (internes, externes, auto-jointure, multiples)
-- #####################################################################

-- C1. Carte complète du prochain événement LMMA 23 : les deux adversaires de
--     chaque combat côte à côte (jointure multiple + auto-jointure sur OPPOSE)
SELECT cb.num_ordre, cb.code_type, cat.nom AS categorie,
       CONCAT(c1.prenom, ' ', c1.nom) AS combattant_1,
       CONCAT(c2.prenom, ' ', c2.nom) AS combattant_2
FROM COMBAT cb
JOIN EVENEMENT e   ON e.id_evenement = cb.id_evenement
JOIN CATEGORIE cat ON cat.id_categorie = cb.id_categorie
JOIN OPPOSE o1     ON o1.id_evenement = cb.id_evenement AND o1.num_ordre = cb.num_ordre
JOIN OPPOSE o2     ON o2.id_evenement = cb.id_evenement AND o2.num_ordre = cb.num_ordre
                  AND o1.id_combattant < o2.id_combattant
JOIN COMBATTANT c1 ON c1.id_combattant = o1.id_combattant
JOIN COMBATTANT c2 ON c2.id_combattant = o2.id_combattant
WHERE e.nom = 'LMMA 23 : Paris'
ORDER BY cb.num_ordre DESC;

-- C2. Historique des règnes de champion : catégorie, champion, date de début
--     (jointure interne multiple)
SELECT cat.nom AS categorie, r.date_debut, c.prenom, c.nom, c.surnom
FROM REGNE r
JOIN CATEGORIE cat ON cat.id_categorie = r.id_categorie
JOIN COMBATTANT c  ON c.id_combattant = r.id_combattant
ORDER BY cat.nom, r.date_debut;

-- C3. Combattants sous contrat n'ayant encore jamais combattu
--     (jointure externe gauche + IS NULL) : à programmer en priorité
SELECT c.id_combattant, c.prenom, c.nom, cat.nom AS categorie
FROM COMBATTANT c
JOIN CATEGORIE cat ON cat.id_categorie = c.id_categorie
LEFT JOIN OPPOSE o ON o.id_combattant = c.id_combattant
WHERE o.id_combattant IS NULL;

-- C4. Tous les lieux avec le nombre d'événements accueillis, y compris
--     les salles jamais utilisées (LEFT JOIN + agrégat)
SELECT l.nom, l.ville, l.pays, l.capacite, COUNT(e.id_evenement) AS nb_evenements
FROM LIEU l
LEFT JOIN EVENEMENT e ON e.id_lieu = l.id_lieu
GROUP BY l.id_lieu, l.nom, l.ville, l.pays, l.capacite
ORDER BY nb_evenements DESC, l.capacite DESC;

-- C5. Membres du personnel jamais affectés à un événement (RIGHT JOIN)
SELECT p.num_licence, p.nom, p.fonction
FROM EST_AFFECTE a
RIGHT JOIN PERSONNEL p ON p.num_licence = a.num_licence
WHERE a.id_evenement IS NULL
ORDER BY p.fonction;

-- C6. Palmarès des « performances de la soirée » : événement, lieu, combattant
--     (jointure multiple, la ligne apparaît même si aucune performance n'a été
--      attribuée grâce au LEFT JOIN)
SELECT e.nom AS evenement, e.date_evenement, l.ville,
       COALESCE(CONCAT(c.prenom, ' ', c.nom), '(non attribuée)') AS performance_soiree
FROM EVENEMENT e
JOIN LIEU l ON l.id_lieu = e.id_lieu
LEFT JOIN COMBATTANT c ON c.id_combattant = e.id_combattant_perf
WHERE e.date_evenement < CURDATE()
ORDER BY e.date_evenement;

-- C7. REQUÊTE ÉTUDIÉE DANS LE README (plans d'exécution) :
--     Combattants ayant gagné par KO/TKO lors d'un événement organisé en France
--     (pour l'affiche « LMMA 25 : Paris »)
--     Algèbre : π nom,prenom ( σ pays='France'(LIEU) ⋈ EVENEMENT
--                              ⋈ σ methode='KO/TKO'(COMBAT) ⋈ COMBATTANT )
SELECT DISTINCT c.nom, c.prenom
FROM LIEU l
JOIN EVENEMENT e  ON e.id_lieu = l.id_lieu
JOIN COMBAT cb    ON cb.id_evenement = e.id_evenement
JOIN COMBATTANT c ON c.id_combattant = cb.id_vainqueur
WHERE l.pays = 'France'
  AND cb.methode_victoire = 'KO/TKO'
ORDER BY c.nom;


-- #####################################################################
-- D. REQUÊTES IMBRIQUÉES ((NOT) IN, (NOT) EXISTS, ANY, ALL)
-- #####################################################################

-- D1. Invaincus : combattants ayant combattu (combat terminé) sans jamais perdre
--     (IN + NOT IN)
SELECT c.prenom, c.nom, c.surnom
FROM COMBATTANT c
WHERE c.id_combattant IN (SELECT id_vainqueur FROM COMBAT WHERE id_vainqueur IS NOT NULL)
  AND c.id_combattant NOT IN (
        SELECT o.id_combattant
        FROM OPPOSE o
        JOIN COMBAT cb ON cb.id_evenement = o.id_evenement AND cb.num_ordre = o.num_ordre
        WHERE cb.id_vainqueur IS NOT NULL
          AND cb.id_vainqueur <> o.id_combattant);

-- D2. Combattants ayant déjà disputé un combat pour le titre (EXISTS corrélé)
SELECT c.prenom, c.nom
FROM COMBATTANT c
WHERE EXISTS (
    SELECT *
    FROM OPPOSE o
    JOIN COMBAT cb ON cb.id_evenement = o.id_evenement AND cb.num_ordre = o.num_ordre
    JOIN TYPE_COMBAT t ON t.code_type = cb.code_type
    WHERE o.id_combattant = c.id_combattant
      AND t.titre = TRUE)
ORDER BY c.nom;

-- D3. Prétendants DISPONIBLES : combattants classés dans le top 5 à la dernière
--     mise à jour du classement et non programmés sur un événement à venir
--     (sous-requête scalaire + NOT EXISTS)
SELECT cat.nom AS categorie, ec.position, c.prenom, c.nom
FROM EST_CLASSE ec
JOIN COMBATTANT c  ON c.id_combattant = ec.id_combattant
JOIN CATEGORIE cat ON cat.id_categorie = ec.id_categorie
WHERE ec.date_maj = (SELECT MAX(date_maj) FROM MISE_A_JOUR_CLASSEMENT)
  AND ec.position BETWEEN 1 AND 5
  AND NOT EXISTS (
        SELECT *
        FROM OPPOSE o
        JOIN EVENEMENT e ON e.id_evenement = o.id_evenement
        WHERE o.id_combattant = c.id_combattant
          AND e.date_evenement >= CURDATE())
ORDER BY cat.nom, ec.position;

-- D4. Salles plus grandes que TOUTES les salles françaises (> ALL)
--     -> candidates pour un événement « géant » à l'étranger
SELECT nom, ville, pays, capacite
FROM LIEU
WHERE capacite > ALL (SELECT capacite FROM LIEU WHERE pays = 'France')
ORDER BY capacite DESC;

-- D5. Combattantes plus grandes qu'au moins un combattant masculin des poids
--     mouches (> ANY) : pour une démonstration d'entraînement mixte
SELECT c.prenom, c.nom, c.taille
FROM COMBATTANT c
JOIN CATEGORIE cat ON cat.id_categorie = c.id_categorie
WHERE cat.sexe = 'F'
  AND c.taille > ANY (SELECT c2.taille
                      FROM COMBATTANT c2
                      JOIN CATEGORIE k ON k.id_categorie = c2.id_categorie
                      WHERE k.nom = 'Poids mouches (H)')
ORDER BY c.taille DESC;

-- D6. Combattants ayant plus de victoires que la moyenne des vainqueurs
--     (sous-requête dans le HAVING et dans le FROM)
SELECT c.prenom, c.nom, COUNT(*) AS victoires
FROM COMBAT cb
JOIN COMBATTANT c ON c.id_combattant = cb.id_vainqueur
GROUP BY c.id_combattant, c.prenom, c.nom
HAVING COUNT(*) > (SELECT AVG(nb)
                   FROM (SELECT COUNT(*) AS nb
                         FROM COMBAT
                         WHERE id_vainqueur IS NOT NULL
                         GROUP BY id_vainqueur) AS t)
ORDER BY victoires DESC;

-- D7. Champions actuels de chaque catégorie : le règne le plus récent
--     (sous-requête corrélée avec MAX)
SELECT cat.nom AS categorie, c.prenom, c.nom, r.date_debut AS champion_depuis
FROM REGNE r
JOIN CATEGORIE cat ON cat.id_categorie = r.id_categorie
JOIN COMBATTANT c  ON c.id_combattant = r.id_combattant
WHERE r.date_debut = (SELECT MAX(r2.date_debut)
                      FROM REGNE r2
                      WHERE r2.id_categorie = r.id_categorie)
ORDER BY cat.limite_poids, cat.sexe;
