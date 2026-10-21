-- COEsprit — schéma PostgreSQL aligné maquette
-- Communauté = ligne sans parent. Périmètre de travail = ligne enfant.
-- Une personne = une communauté + un périmètre.
-- L'entité opérationnelle est unique (LibelleService) et non modifiable côté fiche.
DROP SCHEMA IF EXISTS coesprit CASCADE;
CREATE SCHEMA coesprit;
SET search_path TO coesprit;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS "COE_Communaute" (
    id         varchar(32) PRIMARY KEY,
    libelle    varchar(255) NOT NULL,
    active     boolean      NOT NULL DEFAULT true,
    parent_id  varchar(32)  REFERENCES "COE_Communaute" (id)
);

CREATE TABLE IF NOT EXISTS "COE_Membre" (
    id                  serial PRIMARY KEY,
    code_agent          varchar(32)  NOT NULL UNIQUE,
    nom_affiche         varchar(255) NOT NULL,
    mail                varchar(255),
    site                varchar(128),
    id_communaute       varchar(32)  NOT NULL REFERENCES "COE_Communaute" (id),
    id_perimetre        varchar(32)  NOT NULL REFERENCES "COE_Communaute" (id),
    role_local          varchar(16)  NOT NULL DEFAULT 'membre' CHECK (role_local IN ('membre', 'pilote')),
    pilote_communaute   boolean      NOT NULL DEFAULT false,
    role_session        varchar(16)  NOT NULL DEFAULT 'membre' CHECK (role_session IN ('membre', 'pilote', 'admin')),
    actif               boolean      NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS "COE_Domaine" (
    id            varchar(32) PRIMARY KEY,
    id_perimetre  varchar(32)  NOT NULL REFERENCES "COE_Communaute" (id),
    libelle       varchar(128) NOT NULL,
    tone          varchar(16)
);

CREATE TABLE IF NOT EXISTS "COE_Terme" (
    id            varchar(64) PRIMARY KEY,
    id_perimetre  varchar(32)  NOT NULL REFERENCES "COE_Communaute" (id),
    libelle       varchar(255) NOT NULL,
    statut        varchar(16)  NOT NULL DEFAULT 'propose' CHECK (statut IN ('propose', 'valide', 'refuse', 'archive')),
    domaine_id    varchar(32)  REFERENCES "COE_Domaine" (id),
    icon          varchar(32)
);

CREATE TABLE IF NOT EXISTS "COE_Fiche" (
    user_id                 varchar(32) PRIMARY KEY REFERENCES "COE_Membre" (code_agent) ON DELETE CASCADE,
    nom_affiche             varchar(255) NOT NULL,
    mail_si                 varchar(255),
    site                    varchar(128),
    id_perimetre            varchar(32)  NOT NULL REFERENCES "COE_Communaute" (id),
    entite_operationnelle   varchar(255),
    libelle_poste           varchar(255),
    activites_principales   text,
    sujets_aide             text,
    passions                text,
    canal_mail              varchar(255),
    canal_teams             varchar(255),
    photo_url               text,
    updated_at              timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "COE_FicheTerme" (
    fiche_user_id varchar(32) NOT NULL REFERENCES "COE_Fiche" (user_id) ON DELETE CASCADE,
    terme_id      varchar(64) NOT NULL REFERENCES "COE_Terme" (id) ON DELETE CASCADE,
    PRIMARY KEY (fiche_user_id, terme_id)
);

CREATE INDEX IF NOT EXISTS idx_coe_communaute_parent ON "COE_Communaute" (parent_id);
CREATE INDEX IF NOT EXISTS idx_coe_membre_communaute ON "COE_Membre" (id_communaute);
CREATE INDEX IF NOT EXISTS idx_coe_membre_perimetre ON "COE_Membre" (id_perimetre);
CREATE INDEX IF NOT EXISTS idx_coe_domaine_perimetre ON "COE_Domaine" (id_perimetre);
CREATE INDEX IF NOT EXISTS idx_coe_terme_perimetre ON "COE_Terme" (id_perimetre);
CREATE UNIQUE INDEX IF NOT EXISTS uq_coe_terme_perimetre_libelle
    ON "COE_Terme" (id_perimetre, lower(regexp_replace(btrim(libelle), '[[:space:]]+', ' ', 'g')))
    WHERE statut <> 'archive';
CREATE INDEX IF NOT EXISTS idx_coe_terme_domaine ON "COE_Terme" (domaine_id);
CREATE INDEX IF NOT EXISTS idx_coe_fiche_site ON "COE_Fiche" (site);
CREATE INDEX IF NOT EXISTS idx_coe_fiche_perimetre ON "COE_Fiche" (id_perimetre);

-- ---------------------------------------------------------------------------
-- Communautés et périmètres de travail
-- ---------------------------------------------------------------------------

INSERT INTO "COE_Communaute" (id, libelle, active, parent_id) VALUES
    ('c-da3c',  'Communauté DA3C',              true,  NULL),
    ('c-autre', 'Communauté démo (inactive)',   false, NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO "COE_Communaute" (id, libelle, active, parent_id) VALUES
    ('p-chefs-projet', 'Chefs de projet',       true, 'c-da3c'),
    ('p-demo-soeur',   'Périmètre démo sœur',   true, 'c-da3c')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Domaines du périmètre Chefs de projet
-- ---------------------------------------------------------------------------

INSERT INTO "COE_Domaine" (id, id_perimetre, libelle, tone) VALUES
    ('gce',       'p-chefs-projet', 'GCE',         'sky'),
    ('gci',       'p-chefs-projet', 'GCI',         'mint'),
    ('raf',       'p-chefs-projet', 'RAF',         'lilac'),
    ('projet',    'p-chefs-projet', 'Projet',      'peach'),
    ('processus', 'p-chefs-projet', 'Processus',   'sand'),
    ('outils',    'p-chefs-projet', 'Outils / SI', 'aqua')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Membres (code agent = user_id de la fiche)
-- role_local = pilote du périmètre. pilote_communaute = pilote de la communauté.
-- role_session = rôle de connexion (admin n'est pas un rôle d'appartenance).
-- ---------------------------------------------------------------------------

INSERT INTO "COE_Membre" (
    code_agent, nom_affiche, mail, site, id_communaute, id_perimetre,
    role_local, pilote_communaute, role_session, actif
) VALUES
    ('ac75001000', 'Aude Abril',        'aude.abril@urssaf.fr',        'Paris',       'c-da3c', 'p-chefs-projet', 'pilote', true,  'pilote', true),
    ('ac75001001', 'Hervé Heudebert',   'herve.heudebert@urssaf.fr',   'Lyon',        'c-da3c', 'p-chefs-projet', 'pilote', false, 'pilote', true),
    ('ac75001002', 'Anita Goujon',      'anita.goujon@urssaf.fr',      'Bordeaux',    'c-da3c', 'p-chefs-projet', 'membre', false, 'admin',  true),
    ('ac75001003', 'Audrey Sanz Vella', 'audrey.sanz-vella@urssaf.fr', 'Toulouse',    'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001004', 'Vincent Bayle',     'vincent.bayle@urssaf.fr',     'Paris',       'c-da3c', 'p-chefs-projet', 'membre', false, 'admin',  true),
    ('ac75001005', 'Christelle Faure',  'christelle.faure@urssaf.fr',  'Nantes',      'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001006', 'Julien Moreau',     'julien.moreau@urssaf.fr',     'Lille',       'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001007', 'Sarah Benali',      'sarah.benali@urssaf.fr',      'Marseille',   'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001008', 'Thomas Leroy',      'thomas.leroy@urssaf.fr',      'Strasbourg',  'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001009', 'Élise Durand',      'elise.durand@urssaf.fr',      'Rennes',      'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001010', 'Karim Haddad',      'karim.haddad@urssaf.fr',      'Paris',       'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001011', 'Nathalie Petit',    'nathalie.petit@urssaf.fr',    'Lyon',        'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001012', 'Maxime Rousseau',   'maxime.rousseau@urssaf.fr',   'Bordeaux',    'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001013', 'Inès Caron',        'ines.caron@urssaf.fr',        'Toulouse',    'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001014', 'Paul Girard',       'paul.girard@urssaf.fr',       'Nantes',      'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001015', 'Léa Fontaine',      'lea.fontaine@urssaf.fr',      'Paris',       'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001016', 'Benjamin Cros',     'benjamin.cros@urssaf.fr',     'Montpellier', 'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001017', 'Claire Mercier',    'claire.mercier@urssaf.fr',    'Dijon',       'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true),
    ('ac75001018', 'Yann Oliveira',     'yann.oliveira@urssaf.fr',     'Rouen',       'c-da3c', 'p-chefs-projet', 'membre', false, 'membre', true)
ON CONFLICT (code_agent) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Appétences du périmètre Chefs de projet
-- ---------------------------------------------------------------------------

INSERT INTO "COE_Terme" (id, id_perimetre, libelle, statut, domaine_id, icon) VALUES
    ('a-pilotage',     'p-chefs-projet', 'Pilotage de projet',                  'valide',  'projet',    'shield'),
    ('a-risques',      'p-chefs-projet', 'Analyse des risques',                 'valide',  'projet',    'people'),
    ('a-coord',        'p-chefs-projet', 'Coordination d''équipe',              'valide',  'projet',    'chat'),
    ('a-faisabilite',  'p-chefs-projet', 'Rédaction de note de faisabilité',    'valide',  'gce',       'doc'),
    ('a-budget',       'p-chefs-projet', 'Gestion budgétaire',                  'valide',  'raf',       'brain'),
    ('a-amelioration', 'p-chefs-projet', 'Amélioration continue',               'valide',  'processus', 'loop'),
    ('a-methode',      'p-chefs-projet', 'Méthode / Processus',                 'valide',  'processus', 'flow'),
    ('a-reporting',    'p-chefs-projet', 'Reporting',                           'valide',  'raf',       'chart'),
    ('a-collab',       'p-chefs-projet', 'Outils collaboratifs',                'valide',  'outils',    'laptop'),
    ('a-change',       'p-chefs-projet', 'Conduite du changement',              'valide',  'gci',       'change'),
    ('a-parties',      'p-chefs-projet', 'Gestion des parties prenantes',       'valide',  'gci',       'hands'),
    ('t-lcn',          'p-chefs-projet', 'Low-code / No-code',                  'propose', 'outils',    'star'),
    ('a-planning',     'p-chefs-projet', 'Planification',                       'valide',  'projet',    'chart'),
    ('a-jalons',       'p-chefs-projet', 'Suivi des jalons',                    'valide',  'projet',    'shield'),
    ('a-comite',       'p-chefs-projet', 'Animation de comité de pilotage',     'valide',  'projet',    'people'),
    ('a-arbitrage',    'p-chefs-projet', 'Arbitrage de priorités',              'valide',  'projet',    'flow'),
    ('a-dependances',  'p-chefs-projet', 'Gestion des dépendances',             'valide',  'projet',    'loop'),
    ('a-recette',      'p-chefs-projet', 'Préparation de recette',              'valide',  'projet',    'doc'),
    ('a-cadrage',      'p-chefs-projet', 'Cadrage de besoin',                   'valide',  'gce',       'doc'),
    ('a-expression',   'p-chefs-projet', 'Expression de besoin',                'valide',  'gce',       'doc'),
    ('a-chiffrage',    'p-chefs-projet', 'Chiffrage',                           'valide',  'gce',       'chart'),
    ('a-ao',           'p-chefs-projet', 'Appels d''offres',                    'valide',  'gce',       'doc'),
    ('a-marche',       'p-chefs-projet', 'Suivi de marché',                     'valide',  'gce',       'shield'),
    ('a-atelier',      'p-chefs-projet', 'Animation d''ateliers',               'valide',  'gci',       'people'),
    ('a-communication','p-chefs-projet', 'Plan de communication',               'valide',  'gci',       'chat'),
    ('a-formation',    'p-chefs-projet', 'Montée en compétence',                'valide',  'gci',       'brain'),
    ('a-resistance',   'p-chefs-projet', 'Accompagnement des résistances',      'valide',  'gci',       'hands'),
    ('a-forecast',     'p-chefs-projet', 'Prévisionnel',                        'valide',  'raf',       'chart'),
    ('a-couts',        'p-chefs-projet', 'Suivi des coûts',                     'valide',  'raf',       'chart'),
    ('a-facture',      'p-chefs-projet', 'Facturation fournisseurs',            'valide',  'raf',       'doc'),
    ('a-lean',         'p-chefs-projet', 'Lean',                                'valide',  'processus', 'loop'),
    ('a-cartographie', 'p-chefs-projet', 'Cartographie de processus',           'valide',  'processus', 'flow'),
    ('a-indicateurs',  'p-chefs-projet', 'Indicateurs de performance',          'valide',  'processus', 'chart'),
    ('a-qualite',      'p-chefs-projet', 'Démarche qualité',                    'valide',  'processus', 'shield'),
    ('a-jira',         'p-chefs-projet', 'Jira',                                'valide',  'outils',    'laptop'),
    ('a-confluence',   'p-chefs-projet', 'Confluence',                          'valide',  'outils',    'doc'),
    ('a-powerbi',      'p-chefs-projet', 'Power BI',                            'valide',  'outils',    'chart'),
    ('a-sharepoint',   'p-chefs-projet', 'SharePoint',                          'valide',  'outils',    'laptop'),
    ('a-teams-outils', 'p-chefs-projet', 'Teams et canaux',                     'valide',  'outils',    'chat'),
    ('a-convertigo',   'p-chefs-projet', 'Convertigo',                          'valide',  'outils',    'star')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Fiches
-- ---------------------------------------------------------------------------

INSERT INTO "COE_Fiche" (
    user_id, nom_affiche, mail_si, site, id_perimetre, entite_operationnelle,
    libelle_poste, activites_principales, sujets_aide, passions,
    canal_mail, canal_teams, photo_url, updated_at
) VALUES
    ('ac75001000', 'Aude Abril', 'aude.abril@urssaf.fr', 'Paris', 'p-chefs-projet', 'Service DA3C - Pilotage',
     'Pilote de communauté',
     'Pilotage de la communauté chefs de projet, accompagnement des portefeuilles.',
     'Lancer une communauté, structurer un plan d''animation, retours d''expérience transverses.',
     'Facilitation, design thinking',
     'aude.abril@urssaf.fr', 'aude.abril@urssaf.fr', NULL, '2026-10-14T09:20:00+00'),
    ('ac75001001', 'Hervé Heudebert', 'herve.heudebert@urssaf.fr', 'Lyon', 'p-chefs-projet', 'Service SI - Applications',
     'Chef de projet SI',
     'Cadrage, planification, suivi de livraisons et coordination multi-équipes sur le périmètre Est.',
     'Planification, risques projet, coordination multi-équipes, outillage collaboratif.',
     'Randonnée, photo',
     'herve.heudebert@urssaf.fr', 'herve.heudebert@urssaf.fr', NULL, '2026-10-15T16:45:00+00'),
    ('ac75001002', 'Anita Goujon', 'anita.goujon@urssaf.fr', 'Bordeaux', 'p-chefs-projet', 'Service DA3C - Pilotage',
     'Chef de projet métier',
     'Projets métier, mise en relation des expertises.',
     'Ateliers d''expression de besoin, animation d''équipes projet.',
     'Cuisine, lecture',
     'anita.goujon@urssaf.fr', 'anita.goujon@urssaf.fr', NULL, '2026-10-10T11:00:00+00'),
    ('ac75001003', 'Audrey Sanz Vella', 'audrey.sanz-vella@urssaf.fr', 'Toulouse', 'p-chefs-projet', 'Service SI - Applications',
     'Chef de projet',
     'Conduite de projets digitaux.',
     'Agilité, rituels d''équipe, priorisation backlog.',
     'Trail',
     'audrey.sanz-vella@urssaf.fr', 'audrey.sanz-vella@urssaf.fr', NULL, '2026-10-12T08:30:00+00'),
    ('ac75001004', 'Vincent Bayle', 'vincent.bayle@urssaf.fr', 'Paris', 'p-chefs-projet', 'Direction des Systèmes d''Information',
     'Architecte applicatif',
     'Architecture applicative, outillage communautés.',
     'Choix techniques, intégration SI, low-code.',
     'Open source',
     'vincent.bayle@urssaf.fr', 'vincent.bayle@urssaf.fr', NULL, '2026-10-13T14:10:00+00'),
    ('ac75001005', 'Christelle Faure', 'christelle.faure@urssaf.fr', 'Nantes', 'p-chefs-projet', 'Service RH',
     'Chef de projet métier',
     'Pilotage de projets métier et animation de rituels d''équipe.',
     'Animation, priorisation, facilitation.',
     'Voile',
     'christelle.faure@urssaf.fr', 'christelle.faure@urssaf.fr', NULL, '2026-10-08T10:00:00+00'),
    ('ac75001006', 'Julien Moreau', 'julien.moreau@urssaf.fr', 'Lille', 'p-chefs-projet', 'Service Production',
     'Chef de projet data',
     'Cadrage besoins et suivi des livraisons analytiques.',
     'Reporting, data, cadrage.',
     'Cyclisme',
     'julien.moreau@urssaf.fr', 'julien.moreau@urssaf.fr', NULL, '2026-10-09T15:20:00+00'),
    ('ac75001007', 'Sarah Benali', 'sarah.benali@urssaf.fr', 'Marseille', 'p-chefs-projet', 'Service Finances',
     'Chargé de conduite du changement',
     'Accompagnement au changement sur les projets SI régionaux.',
     'Change, parties prenantes.',
     'Théâtre',
     'sarah.benali@urssaf.fr', 'sarah.benali@urssaf.fr', NULL, '2026-10-11T09:40:00+00'),
    ('ac75001008', 'Thomas Leroy', 'thomas.leroy@urssaf.fr', 'Strasbourg', 'p-chefs-projet', 'Service SI - Applications',
     'Référent méthodes',
     'Méthodes projet et standardisation des processus de livraison.',
     'Processus, méthodes, amélioration continue.',
     'Échecs',
     'thomas.leroy@urssaf.fr', 'thomas.leroy@urssaf.fr', NULL, '2026-10-07T13:00:00+00'),
    ('ac75001009', 'Élise Durand', 'elise.durand@urssaf.fr', 'Rennes', 'p-chefs-projet', 'Service Communication',
     'Chargé de faisabilité',
     'Notes de faisabilité et appui au cadrage des initiatives GCE.',
     'Faisabilité, cadrage.',
     'Jardinage',
     'elise.durand@urssaf.fr', 'elise.durand@urssaf.fr', NULL, '2026-10-06T17:30:00+00'),
    ('ac75001010', 'Karim Haddad', 'karim.haddad@urssaf.fr', 'Paris', 'p-chefs-projet', 'Service DA3C - Pilotage',
     'Chef de projet',
     'Pilotage transverse national et reporting direction.',
     'Reporting, budget, pilotage.',
     'Basket',
     'karim.haddad@urssaf.fr', 'karim.haddad@urssaf.fr', NULL, '2026-10-14T11:15:00+00'),
    ('ac75001011', 'Nathalie Petit', 'nathalie.petit@urssaf.fr', 'Lyon', 'p-chefs-projet', 'Service DA3C - Pilotage',
     'Référent outillage collaboratif',
     'Outillage collaboratif et adoption des espaces Teams / SharePoint.',
     'Outils collaboratifs, conduite du changement.',
     'Photo',
     'nathalie.petit@urssaf.fr', 'nathalie.petit@urssaf.fr', NULL, '2026-10-05T08:50:00+00'),
    ('ac75001012', 'Maxime Rousseau', 'maxime.rousseau@urssaf.fr', 'Bordeaux', 'p-chefs-projet', 'Service Juridique',
     'Analyste risques projet',
     'Gestion des risques et plans de mitigation sur projets structurants.',
     'Risques, coordination.',
     'Surf',
     'maxime.rousseau@urssaf.fr', 'maxime.rousseau@urssaf.fr', NULL, '2026-10-04T12:00:00+00'),
    ('ac75001013', 'Inès Caron', 'ines.caron@urssaf.fr', 'Toulouse', 'p-chefs-projet', 'Service SI - Applications',
     'Référent méthodes',
     'Amélioration continue et ateliers méthodes avec les équipes projet.',
     'Amélioration continue, méthodes.',
     'Course à pied',
     'ines.caron@urssaf.fr', 'ines.caron@urssaf.fr', NULL, '2026-10-13T18:00:00+00'),
    ('ac75001014', 'Paul Girard', 'paul.girard@urssaf.fr', 'Nantes', 'p-chefs-projet', 'Service RH',
     'Chargé de reporting',
     'Suivi budgétaire et reporting des portefeuilles régionaux.',
     'Budget, reporting.',
     'Cuisine',
     'paul.girard@urssaf.fr', 'paul.girard@urssaf.fr', NULL, '2026-10-03T09:00:00+00'),
    ('ac75001015', 'Léa Fontaine', 'lea.fontaine@urssaf.fr', 'Paris', 'p-chefs-projet', 'Service Finances',
     'Pilote de communauté',
     'Animation de communautés de pratique et partage d''outils.',
     'Outils, coordination, parties prenantes.',
     'Design',
     'lea.fontaine@urssaf.fr', 'lea.fontaine@urssaf.fr', NULL, '2026-10-15T10:25:00+00'),
    ('ac75001016', 'Benjamin Cros', 'benjamin.cros@urssaf.fr', 'Montpellier', 'p-chefs-projet', 'Service Production',
     'Chargé de faisabilité',
     'Cadrage SI et notes de faisabilité pour les projets digitaux.',
     'Faisabilité, pilotage, low-code.',
     'Escalade',
     'benjamin.cros@urssaf.fr', 'benjamin.cros@urssaf.fr', NULL, '2026-10-02T16:00:00+00'),
    ('ac75001017', 'Claire Mercier', 'claire.mercier@urssaf.fr', 'Dijon', 'p-chefs-projet', 'Service Communication',
     'Chargé de conduite du changement',
     'Conduite du changement et accompagnement des managers de proximité.',
     'Change, parties prenantes.',
     'Lecture',
     'claire.mercier@urssaf.fr', 'claire.mercier@urssaf.fr', NULL, '2026-10-01T14:40:00+00'),
    ('ac75001018', 'Yann Oliveira', 'yann.oliveira@urssaf.fr', 'Rouen', 'p-chefs-projet', 'Service SI - Applications',
     'Chef de projet SI',
     'Pilotage opérationnel et coordination multi-équipes sur le Nord.',
     'Pilotage, coordination, risques.',
     'Musique',
     'yann.oliveira@urssaf.fr', 'yann.oliveira@urssaf.fr', NULL, '2026-09-28T11:10:00+00')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO "COE_FicheTerme" (fiche_user_id, terme_id) VALUES
    ('ac75001000', 'a-pilotage'), ('ac75001000', 'a-risques'), ('ac75001000', 'a-coord'), ('ac75001000', 'a-collab'),
    ('ac75001001', 'a-pilotage'), ('ac75001001', 'a-risques'), ('ac75001001', 'a-coord'),
    ('ac75001001', 'a-planning'), ('ac75001001', 'a-jalons'), ('ac75001001', 'a-comite'),
    ('ac75001001', 'a-arbitrage'), ('ac75001001', 'a-dependances'), ('ac75001001', 'a-recette'),
    ('ac75001001', 'a-faisabilite'), ('ac75001001', 'a-cadrage'), ('ac75001001', 'a-expression'),
    ('ac75001001', 'a-chiffrage'), ('ac75001001', 'a-ao'), ('ac75001001', 'a-marche'),
    ('ac75001001', 'a-budget'), ('ac75001001', 'a-reporting'), ('ac75001001', 'a-forecast'),
    ('ac75001001', 'a-couts'), ('ac75001001', 'a-facture'),
    ('ac75001001', 'a-methode'), ('ac75001001', 'a-amelioration'), ('ac75001001', 'a-lean'),
    ('ac75001001', 'a-cartographie'), ('ac75001001', 'a-indicateurs'), ('ac75001001', 'a-qualite'),
    ('ac75001001', 'a-change'), ('ac75001001', 'a-parties'), ('ac75001001', 'a-atelier'),
    ('ac75001001', 'a-communication'), ('ac75001001', 'a-formation'), ('ac75001001', 'a-resistance'),
    ('ac75001001', 'a-collab'), ('ac75001001', 't-lcn'),
    ('ac75001001', 'a-jira'), ('ac75001001', 'a-confluence'), ('ac75001001', 'a-powerbi'),
    ('ac75001001', 'a-sharepoint'), ('ac75001001', 'a-teams-outils'), ('ac75001001', 'a-convertigo'),
    ('ac75001002', 'a-coord'), ('ac75001002', 'a-parties'),
    ('ac75001003', 'a-pilotage'),
    ('ac75001004', 'a-collab'), ('ac75001004', 'a-methode'),
    ('ac75001005', 'a-coord'), ('ac75001005', 'a-pilotage'), ('ac75001005', 'a-amelioration'),
    ('ac75001006', 'a-reporting'), ('ac75001006', 'a-budget'), ('ac75001006', 'a-pilotage'),
    ('ac75001007', 'a-change'), ('ac75001007', 'a-parties'), ('ac75001007', 'a-coord'),
    ('ac75001008', 'a-methode'), ('ac75001008', 'a-amelioration'), ('ac75001008', 'a-risques'),
    ('ac75001009', 'a-faisabilite'), ('ac75001009', 'a-pilotage'), ('ac75001009', 'a-risques'),
    ('ac75001010', 'a-reporting'), ('ac75001010', 'a-budget'), ('ac75001010', 'a-pilotage'), ('ac75001010', 'a-parties'),
    ('ac75001011', 'a-collab'), ('ac75001011', 'a-change'),
    ('ac75001012', 'a-risques'), ('ac75001012', 'a-coord'), ('ac75001012', 'a-pilotage'),
    ('ac75001013', 'a-amelioration'), ('ac75001013', 'a-methode'), ('ac75001013', 'a-coord'),
    ('ac75001014', 'a-budget'), ('ac75001014', 'a-reporting'),
    ('ac75001015', 'a-collab'), ('ac75001015', 'a-coord'), ('ac75001015', 'a-parties'), ('ac75001015', 'a-change'),
    ('ac75001016', 'a-faisabilite'), ('ac75001016', 'a-pilotage'), ('ac75001016', 'a-collab'),
    ('ac75001017', 'a-change'), ('ac75001017', 'a-parties'),
    ('ac75001018', 'a-pilotage'), ('ac75001018', 'a-coord'), ('ac75001018', 'a-risques'), ('ac75001018', 'a-methode')
ON CONFLICT DO NOTHING;
