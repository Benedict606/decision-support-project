-- =============================================================================
-- SCRIPT DE CRÉATION DU SCHÉMA DÉCISIONNEL EN ÉTOILE (PostgreSQL)
-- Fichier : sql/create_schema.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. NETTOYAGE DES TABLES EXISTANTES (Pour réexécutions idempotentes)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS FACT_VENTES CASCADE;
DROP TABLE IF EXISTS DIM_MAGASIN CASCADE;
DROP TABLE IF EXISTS DIM_PRODUIT CASCADE;
DROP TABLE IF EXISTS DIM_CLIENT CASCADE;
DROP TABLE IF EXISTS DIM_TEMPS CASCADE;

-- -----------------------------------------------------------------------------
-- 1. CRÉATION DES TABLES DE DIMENSIONS
-- -----------------------------------------------------------------------------

-- Dimension Temps
CREATE TABLE DIM_TEMPS (
    date_key        INT PRIMARY KEY,              -- Format AAAAMMJJ (ex: 20260929)
    date            DATE NOT NULL,
    jour            INT NOT NULL CHECK (jour BETWEEN 1 AND 31),
    mois            INT NOT NULL CHECK (mois BETWEEN 1 AND 12),
    nom_mois        VARCHAR(20) NOT NULL,
    trimestre       INT NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    annee           INT NOT NULL,
    jour_semaine    VARCHAR(20) NOT NULL
);

-- Dimension Client
CREATE TABLE DIM_CLIENT (
    client_key      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Clé substituée (Surrogate Key)
    client_id       VARCHAR(50) NOT NULL,                        -- Clé naturelle (Business Key)
    nom             VARCHAR(100) NOT NULL,
    sexe            VARCHAR(10),
    age             INT CHECK (age >= 0),
    ville           VARCHAR(100),
    region          VARCHAR(100)
);

-- Dimension Produit
CREATE TABLE DIM_PRODUIT (
    produit_key     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Clé substituée
    produit_id      VARCHAR(50) NOT NULL,                        -- Clé naturelle
    nom_produit     VARCHAR(150) NOT NULL,
    categorie       VARCHAR(100) NOT NULL,
    sous_categorie  VARCHAR(100),
    marque          VARCHAR(100),
    prix_actuel     NUMERIC(10, 2) CHECK (prix_actuel >= 0)
);

-- Dimension Magasin
CREATE TABLE DIM_MAGASIN (
    magasin_key     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Clé substituée
    magasin_id      VARCHAR(50) NOT NULL,                        -- Clé naturelle
    nom_magasin     VARCHAR(100) NOT NULL,
    ville           VARCHAR(100) NOT NULL,
    region          VARCHAR(100) NOT NULL
);

-- -----------------------------------------------------------------------------
-- 2. CRÉATION DE LA TABLE DE FAITS
-- -----------------------------------------------------------------------------

CREATE TABLE FACT_VENTES (
    vente_key       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key        INT NOT NULL,
    client_key      INT NOT NULL,
    produit_key     INT NOT NULL,
    magasin_key     INT NOT NULL,
    transaction_id  VARCHAR(50) NOT NULL,
    quantite        INT NOT NULL CHECK (quantite > 0),
    prix_unitaire   NUMERIC(10, 2) NOT NULL CHECK (prix_unitaire >= 0),
    montant_vente   NUMERIC(12, 2) NOT NULL CHECK (montant_vente >= 0),

    -- Contraintes de clés étrangères (Relations avec les dimensions)
    CONSTRAINT fk_ventes_temps   FOREIGN KEY (date_key)    REFERENCES DIM_TEMPS(date_key),
    CONSTRAINT fk_ventes_client  FOREIGN KEY (client_key)   REFERENCES DIM_CLIENT(client_key),
    CONSTRAINT fk_ventes_produit FOREIGN KEY (produit_key)  REFERENCES DIM_PRODUIT(produit_key),
    CONSTRAINT fk_ventes_magasin FOREIGN KEY (magasin_key)  REFERENCES DIM_MAGASIN(magasin_key)
);

-- -----------------------------------------------------------------------------
-- 3. CRÉATION DES INDEX (Optimisation des requêtes d'analyse OLAP / Joitures)
-- -----------------------------------------------------------------------------
CREATE INDEX idx_fact_ventes_date    ON FACT_VENTES(date_key);
CREATE INDEX idx_fact_ventes_client  ON FACT_VENTES(client_key);
CREATE INDEX idx_fact_ventes_produit ON FACT_VENTES(produit_key);
CREATE INDEX idx_fact_ventes_magasin ON FACT_VENTES(magasin_key);


-- psql -U postgres
-- CREATE DATABASE bi_ventes_db;
-- \c bi_ventes_db
