-- COEsprit — annuaire hors SI pour Admin et Pilote.
-- Additif : ne rejoue pas 001_ddl.sql (celui-ci detruit le schema).
-- La transaction de lecture sera remplacee plus tard par APP_AgentPortefeuille.
-- LibelleService vide = ajout refuse.

SET search_path TO coesprit;

CREATE TABLE IF NOT EXISTS "COE_Agent" (
    code_agent      varchar(32) PRIMARY KEY,
    nom             varchar(255) NOT NULL,
    mail            varchar(255),
    site            varchar(128),
    libelle_service varchar(255)
);

CREATE INDEX IF NOT EXISTS idx_coe_agent_nom ON "COE_Agent" (lower(nom));

INSERT INTO "COE_Agent" (code_agent, nom, mail, site, libelle_service) VALUES
    ('ac75002001', 'Sophie Lambert', 'sophie.lambert@urssaf.fr', 'Paris', 'Service RH'),
    ('ac75002002', 'Marc Dupont', 'marc.dupont@urssaf.fr', 'Lyon', 'Service Production'),
    ('ac75002003', 'Nadia Benali', 'nadia.benali@urssaf.fr', 'Marseille', 'Service Finances'),
    ('ac75002004', 'Olivier Garnier', 'olivier.garnier@urssaf.fr', 'Bordeaux', 'Service SI - Applications'),
    ('ac75002005', 'Isabelle Roux', 'isabelle.roux@urssaf.fr', 'Nantes', 'Service Communication'),
    ('ac75002006', 'Pierre Morel', 'pierre.morel@urssaf.fr', 'Toulouse', 'Service Juridique'),
    ('ac75002007', 'Fatima Zahra', 'fatima.zahra@urssaf.fr', 'Lille', 'Service DA3C - Pilotage'),
    ('ac75002008', 'Antoine Blanc', 'antoine.blanc@urssaf.fr', 'Strasbourg', 'Service SI - Infrastructures'),
    ('ac75002009', 'Julie Perrin', 'julie.perrin@urssaf.fr', 'Rennes', 'Direction des Systèmes d’Information'),
    ('ac75002010', 'Karim Bouzid', 'karim.bouzid@urssaf.fr', 'Montpellier', 'Service Production'),
    ('ac75002011', 'Émilie Costa', 'emilie.costa@urssaf.fr', 'Dijon', 'Service RH'),
    ('ac75002012', 'Nicolas Faure', 'nicolas.faure@urssaf.fr', 'Rouen', 'Service Finances'),
    ('ac75002013', 'Amélie Chevalier', 'amelie.chevalier@urssaf.fr', 'Paris', 'Service SI - Applications'),
    ('ac75002014', 'David Nguyen', 'david.nguyen@urssaf.fr', 'Lyon', 'Service DA3C - Pilotage'),
    ('ac75002015', 'Laura Martinez', 'laura.martinez@urssaf.fr', 'Nice', 'Service Communication')
ON CONFLICT (code_agent) DO UPDATE SET
    nom = EXCLUDED.nom,
    mail = EXCLUDED.mail,
    site = EXCLUDED.site,
    libelle_service = EXCLUDED.libelle_service;

INSERT INTO "COE_Agent" (code_agent, nom, mail, site, libelle_service) VALUES
    ('ac75009999', 'Agent Sans Mapping', 'sans.mapping@urssaf.fr', 'Paris', NULL)
ON CONFLICT (code_agent) DO NOTHING;

INSERT INTO "COE_Agent" (code_agent, nom, mail, site, libelle_service)
SELECT
    m.code_agent,
    m.nom_affiche,
    m.mail,
    m.site,
    NULLIF(btrim(COALESCE(f.entite_operationnelle, '')), '')
FROM "COE_Membre" m
LEFT JOIN "COE_Fiche" f ON UPPER(f.user_id) = UPPER(m.code_agent)
ON CONFLICT (code_agent) DO UPDATE SET
    nom = EXCLUDED.nom,
    mail = COALESCE(EXCLUDED.mail, "COE_Agent".mail),
    site = COALESCE(EXCLUDED.site, "COE_Agent".site),
    libelle_service = COALESCE("COE_Agent".libelle_service, EXCLUDED.libelle_service);
