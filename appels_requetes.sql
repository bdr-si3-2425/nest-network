SELECT * FROM obtenir_logements_disponibles('2025-02-01', '2025-02-10');

SELECT * FROM filtrer_logements_disponibles('Studio', 'montagne', 500.0, '2000-02-01', '2030-02-10');

SELECT * FROM obtenir_demande_logements();

SELECT * FROM suggerer_ameliorations_pour_logements_faibles();

SELECT * FROM chambres_libres;

SELECT * FROM logement_optimal(1);

CALL reserver_optimal(10, '2025-02-01', '2025-02-10');
SELECT * FROM reservation;

CALL reserver_logement(10, 1, '2025-02-01', '2025-02-10');
CALL reserver_logement(10, 1, '2025-02-10', '2025-03-10');
SELECT * FROM reservation;

SELECT * FROM affiche_residents();

SELECT * FROM affiche_residents_actuels();

SELECT * FROM residents_actuels_limite;

SELECT * FROM affiche_residents_interactions();

SELECT * FROM affiche_maintenance_logements();

SELECT * FROM affiche_sejours_prolonges();

CALL organiser_activite(10, '2025-02-01', 1);
SELECT * FROM organisation;

CALL organiser_pour_logement(10, 82);
SELECT * FROM organisation;

CALL ajouter_logement(1, 2, 'Appartement', 3, 100.0);
SELECT * FROM logement;

CALL ajouter_personne(10, 'Dupont', 'Pierre', '1985-06-15', 'pierre.dupont@example.com');
SELECT * FROM personne;

CALL ajouter_activite(5, 'Tennis');
SELECT * FROM activite;

CALL ajouter_organisation(2, 5, '2025-02-05 14:00:00', 3);
SELECT * FROM organisation;

CALL ajouter_participation(10, 1);
SELECT * FROM participation;

CALL ajouter_reservation(1, 2, 10, '2025-02-06 14:00:00', '2025-02-07 11:00:00');
SELECT * FROM reservation;

CALL ajouter_equipement(1, 2, 'Climatisation');
SELECT * FROM equipement;

CALL ajouter_intervention(1, 3, 'Réparation fuite d eau', 2, 'haute');
SELECT * FROM intervention;

CALL ajouter_interv_equi(1, 1, 2);
SELECT * FROM interv_equi;

CALL ajouter_complexe(3, 'Centre-ville');
SELECT * FROM complexe;