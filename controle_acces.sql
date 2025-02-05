-- Requêtes pour : Révoquer tous les privilèges pour les deux rôles (si besoin)
--REVOKE ALL ON ALL TABLES IN SCHEMA public FROM admin_user, standard_user;
--REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM admin_user, standard_user;

-- Requête pour : Supprimer les rôles existants (si présents)
--DROP ROLE IF EXISTS admin_user, standard_user;



-- Création des rôles
CREATE ROLE admin_user WITH LOGIN PASSWORD 'securepassword' SUPERUSER;
CREATE ROLE standard_user WITH LOGIN PASSWORD 'userpassword' NOSUPERUSER;

-- Permissions de base : restreindre l'accès par défaut
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- Permissions sur les tables et fonctions pour les administrateurs
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO admin_user;
