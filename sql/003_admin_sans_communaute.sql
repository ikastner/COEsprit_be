-- Admin sans communauté ni périmètre. Ne pas rejouer 001_ddl.sql.
SET search_path TO coesprit;

ALTER TABLE "COE_Membre" ALTER COLUMN id_communaute DROP NOT NULL;
ALTER TABLE "COE_Membre" ALTER COLUMN id_perimetre DROP NOT NULL;
