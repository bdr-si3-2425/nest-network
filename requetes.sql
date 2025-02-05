-- Fonction qui permet d'obtenir les logements disponibles entre deux dates données
CREATE OR REPLACE FUNCTION obtenir_logements_disponibles(date_debut_souhaitee DATE, date_fin_souhaitee DATE)
RETURNS TABLE(ID_logement INT, type_logement VARCHAR, emplacement VARCHAR, nb_chambres INT, prix_logement NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT l.ID_logement, l.type_logement, c.emplacement, l.nb_chambres, l.prix_jour
    FROM logement l
    JOIN complexe c ON l.ID_complexe = c.ID_complexe
    LEFT JOIN reservation r ON l.ID_logement = r.ID_logement
    WHERE NOT EXISTS (
        SELECT 1 FROM reservation r2
        WHERE r2.ID_logement = l.ID_logement
        AND  (r2.date_fin >= date_debut_souhaitee AND r2.date_debut <= date_fin_souhaitee)
    )
	ORDER BY id_logement;
END;
$$
LANGUAGE plpgsql;



-- Fonction qui permet de filtrer les logements disponibles selon certains critères
CREATE OR REPLACE FUNCTION filtrer_logements_disponibles(
    type_souhaite VARCHAR, 
    emplacement_souhaite VARCHAR, 
    prix_max_souhaite NUMERIC, 
    date_debut_souhaitee DATE, 
    date_fin_souhaitee DATE
)
RETURNS TABLE(ID_logement INT, type_logement VARCHAR, emplacement VARCHAR, nb_chambres INT, prix_jour NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT l.ID_logement, l.type_logement, c.emplacement, l.nb_chambres, l.prix_jour
    FROM logement l
    JOIN complexe c ON l.ID_complexe = c.ID_complexe
    JOIN reservation r ON l.ID_logement = r.ID_logement
    WHERE l.type_logement = type_souhaite
      AND c.emplacement = emplacement_souhaite
      AND l.prix_jour  <= prix_max_souhaite
      AND r.date_debut >= date_debut_souhaitee
      AND r.date_fin <= date_fin_souhaitee;
END;
$$
LANGUAGE plpgsql;



-- Fonction qui permet d'obtenir la demande de logements, c'est-à-dire le nombre de réservations par type de logement
CREATE OR REPLACE FUNCTION obtenir_demande_logements()
RETURNS TABLE(type_logement VARCHAR, nombre_reservations BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT l.type_logement, COUNT(r.ID_reservation) AS nombre_reservations
    FROM logement l
    JOIN reservation r ON l.ID_logement = r.ID_logement
    GROUP BY l.type_logement;
END;
$$
LANGUAGE plpgsql;



-- Fonction qui permet d'analyser les améliorations possibles des logements en fonction de leur demande
CREATE OR REPLACE FUNCTION suggerer_ameliorations_pour_logements_faibles()
RETURNS TABLE (
    type_logement VARCHAR,
    nombre_reservations BIGINT,
    suggestions TEXT
) AS $$
DECLARE
    moyenne_reservations NUMERIC;
BEGIN
    -- Calcul de la moyenne des réservations
    SELECT AVG(nombre_reservations) INTO moyenne_reservations
    FROM (
        SELECT COUNT(ID_reservation) AS nombre_reservations1
        FROM reservation
        GROUP BY ID_logement
    ) AS reservations;

    -- Retour des résultats avec suggestions
    RETURN QUERY
    SELECT
        l.type_logement,
        COUNT(r.ID_reservation) AS nombre_reservations,
        CASE
            WHEN COUNT(r.ID_reservation) < moyenne_reservations THEN
                'Améliorer les équipements pour rendre le logement plus attractif.'
            ELSE
                'Envisager de réduire les prix pour augmenter la demande.'
        END AS suggestions
    FROM logement l
    LEFT JOIN reservation r ON l.ID_logement = r.ID_logement
    GROUP BY l.type_logement;
END;
$$ LANGUAGE plpgsql;




-- Vue d'une table affichant les logements et leur nombre de chambres libres
CREATE OR REPLACE VIEW chambres_libres AS
	SELECT id_logement, nb_chambres - nb_occupees AS nb_libres
	FROM (
		SELECT l.id_logement, l.nb_chambres, COUNT(r.id_reservation) AS nb_occupees
		FROM obtenir_logements_disponibles(CURRENT_DATE, CURRENT_DATE) AS l LEFT JOIN reservation AS r
		ON l.id_logement = r.id_logement
		GROUP BY l.id_logement, l.nb_chambres
		ORDER BY l.id_logement
	)
	WHERE nb_chambres > nb_occupees
	ORDER BY nb_libres, id_logement;

-- Permissions sur la vue pour le rôle admin
GRANT SELECT ON chambres_libres TO admin_user;



-- Fonction qui renvoie le logement avec le moins de places disponibles qui peut quand même accueillir un nombre de personnes donné
CREATE OR REPLACE FUNCTION logement_optimal(nb_reservations int)
RETURNS TABLE(id_logement INT) AS $$
BEGIN
	RETURN QUERY
	SELECT id
	FROM (
		SELECT chambres_libres.id_logement as id, nb_libres
		FROM chambres_libres
	)
	WHERE nb_libres >= nb_reservations
	LIMIT 1;
END;
$$ LANGUAGE plpgsql;



-- Procedure qui remplis une reservation dans le logement optimal
CREATE OR REPLACE PROCEDURE reserver_optimal(id_client INT, date_debut DATE, date_fin DATE)
LANGUAGE PLPGSQL
AS $$
BEGIN
	INSERT INTO reservation(
		id_reservation, id_logement, id_personne, date_debut, date_fin)
		VALUES (
			(SELECT MAX(id_reservation) FROM reservation) + 1,
			logement_optimal(1),
			id_client,
			date_debut,
			date_fin
		);
END
$$;



-- Procedure qui remplit une reservation
CREATE OR REPLACE PROCEDURE reserver_logement(id_client INT, id_logement INT, date_debut DATE, date_fin DATE)
LANGUAGE PLPGSQL
AS $$
BEGIN
	INSERT INTO reservation(
		id_reservation, id_logement, id_personne, date_debut, date_fin)
		VALUES (
			(SELECT MAX(id_reservation) FROM reservation) + 1,
			id_logement,
			id_client,
			date_debut,
			date_fin
		);
END
$$;



-- Fonction affiche_residents : récupère tous les résidents ayant effectué une réservation
CREATE OR REPLACE FUNCTION affiche_residents()
RETURNS TABLE (
  ID_personne INTEGER, 
  nom VARCHAR, 
  prenom VARCHAR, 
  date_de_naissance DATE, 
  mail VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.ID_personne, p.nom, p.prenom, p.date_de_naissance, p.mail
  FROM personne p
  JOIN reservation r ON p.ID_personne = r.ID_personne
  ORDER BY p.nom, p.prenom;
END;
$$
LANGUAGE plpgsql;



-- Fonction affiche_residents_actuels : récupère tous les résidents ayant effectué une réservation actuellement
CREATE OR REPLACE FUNCTION affiche_residents_actuels()
RETURNS TABLE (
  ID_personne INTEGER, 
  nom VARCHAR, 
  prenom VARCHAR, 
  date_de_naissance DATE, 
  mail VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.ID_personne, p.nom, p.prenom, p.date_de_naissance, p.mail
  FROM personne p
  JOIN reservation r ON p.ID_personne = r.ID_personne
  WHERE NOW() BETWEEN r.date_debut AND r.date_fin
  ORDER BY p.nom, p.prenom;
END;
$$
LANGUAGE plpgsql;



-- Requête pour : Suppression de la vue si elle existe déjà (si besoin)
--DROP VIEW IF EXISTS residents_actuels_limite;



-- Création de la vue sécurisée pour protéger les résidents actuels
CREATE OR REPLACE VIEW residents_actuels_limite AS
SELECT nom, prenom
FROM get_current_residents();

-- Permissions sur la vue pour le rôle admin_user
GRANT SELECT ON residents_actuels_limite TO admin_user;



-- Fonction affiche_residents_interactions : récupère les interactions des résidents avec leurs logements et activités
CREATE OR REPLACE FUNCTION affiche_residents_interactions()
RETURNS TABLE (
  logement_id INTEGER,
  resident_nom VARCHAR,
  resident_prenom VARCHAR,
  activite_description VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT l.ID_logement, p.nom, p.prenom, a.description
  FROM logement l
  JOIN reservation r ON l.ID_logement = r.ID_logement
  JOIN affiche_residents_actuels() p ON r.ID_personne = p.ID_personne
  LEFT JOIN participation pa ON pa.ID_personne = p.ID_personne
  LEFT JOIN organisation o ON pa.ID_organisation = o.ID_organisation
  LEFT JOIN activite a ON o.ID_activite = a.ID_activite
  ORDER BY l.ID_logement;
END;
$$
LANGUAGE plpgsql;



-- Fonction affiche_maintenance_logements : récupère les interventions de maintenance pour chaque logement
CREATE OR REPLACE FUNCTION affiche_maintenance_logements()
RETURNS TABLE (
  logement_id INTEGER,
  nb_interventions INTEGER,
  raisons TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT i.ID_logement, CAST(COUNT(i.ID_intervention) AS INTEGER) AS nb_interventions,
         STRING_AGG(i.description, ', ') AS raisons
  FROM intervention i
  GROUP BY i.ID_logement
  ORDER BY nb_interventions DESC;
END;
$$
LANGUAGE plpgsql;



-- Fonction affiche_sejours_prolonges : récupère les résidents ayant des séjours prolongés
CREATE OR REPLACE FUNCTION affiche_sejours_prolonges()
RETURNS TABLE (
  ID_personne INTEGER, 
  nom VARCHAR, 
  prenom VARCHAR, 
  date_de_naissance DATE, 
  mail VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT p.ID_personne, p.nom, p.prenom, p.date_de_naissance, p.mail
  FROM reservation r1
  JOIN reservation r2 ON r1.ID_personne = r2.ID_personne 
                      AND r1.ID_logement = r2.ID_logement 
                      AND r1.date_fin = r2.date_debut
  JOIN personne p ON r1.ID_personne = p.ID_personne
  ORDER BY p.ID_personne;
END;
$$
LANGUAGE plpgsql;



-- Procedure qui remplit la table organisation
CREATE OR REPLACE PROCEDURE organiser_activite(id_activite INT, date_activite DATE, id_complexe INT)
LANGUAGE PLPGSQL
AS $$
BEGIN
	INSERT INTO organisation(
		id_organisation, id_activite, date_organisation, id_complexe)
		VALUES (
			(SELECT MAX(id_organisation) FROM organisation) + 1,
			id_activite,
			date_activite,
			id_complexe
		);
END
$$;



-- Procedure qui remplit la table organisation pour toucher le plus possible les habitants d'un logement donné
CREATE OR REPLACE PROCEDURE organiser_pour_logement(id_activite INT, id_logement_selectionne INT)
LANGUAGE PLPGSQL
AS $$
BEGIN
	INSERT INTO organisation(
		id_organisation, id_activite, date_organisation, id_complexe)
		VALUES (
			(SELECT MAX(id_organisation) FROM organisation) + 1,
			id_activite,
			CURRENT_DATE + 2, /*evenement dans 2 jours */
			(SELECT id_complexe FROM logement WHERE id_logement = id_logement_selectionne)
		);
END
$$;





-- Procedures de creations d'entrees dans les tables

CREATE OR REPLACE PROCEDURE ajouter_complexe(
  id_complexe_nouveau INT,
  emplacement_nouveau VARCHAR
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM complexe 
    WHERE complexe.ID_complexe = id_complexe_nouveau
  ) THEN 
    INSERT INTO complexe(
      ID_complexe, emplacement
    )
    VALUES (
      id_complexe_nouveau, 
      emplacement_nouveau
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_logement(
  id_logement_nouveau INT,
  id_complexe_nouveau INT,
  type_logement_nouveau VARCHAR,
  nb_chambres_nouveau INT,
  prix_jour_nouveau NUMERIC
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM logement 
    WHERE logement.ID_logement = id_logement_nouveau
  ) THEN 
    INSERT INTO logement(
      ID_logement, ID_complexe, type_logement, nb_chambres, prix_jour
    )
    VALUES (
      id_logement_nouveau, 
      id_complexe_nouveau, 
      type_logement_nouveau, 
      nb_chambres_nouveau, 
      prix_jour_nouveau
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_personne(
  id_personne_nouveau INT,
  nom_nouveau VARCHAR,
  prenom_nouveau VARCHAR,
  date_de_naissance_nouvelle DATE,
  mail_nouveau VARCHAR
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM personne 
    WHERE personne.ID_personne = id_personne_nouveau
  ) THEN 
    INSERT INTO personne(
      ID_personne, nom, prenom, date_de_naissance, mail
    )
    VALUES (
      id_personne_nouveau, 
      nom_nouveau, 
      prenom_nouveau, 
      date_de_naissance_nouvelle, 
      mail_nouveau
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_activite(
  id_activite_nouvelle INT,
  description_nouvelle VARCHAR
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM activite 
    WHERE activite.ID_activite = id_activite_nouvelle
  ) THEN 
    INSERT INTO activite(
      ID_activite, description
    )
    VALUES (
      id_activite_nouvelle, 
      description_nouvelle
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_organisation(
  id_organisation_nouvelle INT,
  id_activite_nouvelle INT,
  date_organisation_nouvelle TIMESTAMP,
  id_complexe_nouveau INT
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM organisation 
    WHERE organisation.ID_organisation = id_organisation_nouvelle
  ) THEN 
    INSERT INTO organisation(
      ID_organisation, ID_activite, date_organisation, ID_complexe
    )
    VALUES (
      id_organisation_nouvelle, 
      id_activite_nouvelle, 
      date_organisation_nouvelle, 
      id_complexe_nouveau
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_participation(id_personne_nouveau INT, id_organisation_nouveau INT)
LANGUAGE PLPGSQL
AS $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM participation WHERE participation.id_personne = id_personne_nouveau AND participation.id_organisation = id_organisation_nouveau
	) THEN 
		INSERT INTO participation(
			id_personne, id_organisation)
			VALUES (
				id_personne_nouveau,
				id_organisation_nouveau
			);
	END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_reservation(
  id_reservation_nouvelle INT,
  id_logement_nouveau INT,
  id_personne_nouvelle INT,
  date_debut_nouvelle TIMESTAMP,
  date_fin_nouvelle TIMESTAMP
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM reservation 
    WHERE reservation.ID_reservation = id_reservation_nouvelle
  ) THEN 
    INSERT INTO reservation(
      ID_reservation, ID_logement, ID_personne, date_debut, date_fin
    )
    VALUES (
      id_reservation_nouvelle, 
      id_logement_nouveau, 
      id_personne_nouvelle, 
      date_debut_nouvelle, 
      date_fin_nouvelle
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_equipement(
  id_equipement_nouveau INT,
  id_logement_nouveau INT,
  description_nouvelle VARCHAR
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM equipement 
    WHERE equipement.ID_equipement = id_equipement_nouveau
  ) THEN 
    INSERT INTO equipement(
      ID_equipement, ID_logement, description
    )
    VALUES (
      id_equipement_nouveau, 
      id_logement_nouveau, 
      description_nouvelle
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_intervenant(
  id_intervenant_nouveau INT,
  id_personne_nouvelle INT,
  domaine_nouveau VARCHAR,
  entreprise_nouvelle VARCHAR
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM intervenant 
    WHERE intervenant.ID_intervenant = id_intervenant_nouveau
  ) THEN 
    INSERT INTO intervenant(
      ID_intervenant, ID_personne, domaine, entreprise
    )
    VALUES (
      id_intervenant_nouveau, 
      id_personne_nouvelle, 
      domaine_nouveau, 
      entreprise_nouvelle
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_intervention(
  id_intervention_nouvelle INT,
  id_intervenant_nouveau INT,
  description_nouvelle VARCHAR,
  id_logement_nouveau INT,
  urgence_nouvelle urgence_type
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM intervention 
    WHERE intervention.ID_intervention = id_intervention_nouvelle
  ) THEN 
    INSERT INTO intervention(
      ID_intervention, ID_intervenant, description, ID_logement, urgence
    )
    VALUES (
      id_intervention_nouvelle, 
      id_intervenant_nouveau, 
      description_nouvelle, 
      id_logement_nouveau, 
      urgence_nouvelle
    );
  END IF;
END
$$;

CREATE OR REPLACE PROCEDURE ajouter_interv_equi(
  id_intervention_nouvelle INT,
  id_equipement_nouveau INT,
  id_remplacement_nouveau INT
)
LANGUAGE PLPGSQL
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM interv_equi 
    WHERE interv_equi.ID_intervention = id_intervention_nouvelle
      AND interv_equi.ID_equipement = id_equipement_nouveau
      AND interv_equi.ID_remplacement = id_remplacement_nouveau
  ) THEN 
    INSERT INTO interv_equi(
      ID_intervention, ID_equipement, ID_remplacement
    )
    VALUES (
      id_intervention_nouvelle, 
      id_equipement_nouveau, 
      id_remplacement_nouveau
    );
  END IF;
END
$$;

