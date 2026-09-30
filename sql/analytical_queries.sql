-- =============================================================================
-- DESCRIPTION : Jeu de 20 requêtes SQL décisionnelles
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CHIFFRE D'AFFAIRES ET VOLUME GLOBAL
-- -----------------------------------------------------------------------------

-- Q1 : Chiffre d'Affaires Total global de l'entreprise
SELECT SUM(montant_vente) AS ca_total
FROM fact_ventes;

-- Q2 : Volume global des transactions validées
SELECT COUNT(DISTINCT transaction_id) AS total_transactions
FROM fact_ventes;

-- Q3 : Quantité totale d'articles vendus
SELECT SUM(quantite) AS volume_articles_vendus
FROM fact_ventes;

-- Q4 : Panier moyen par transaction
SELECT 
    ROUND(SUM(montant_vente) / NULLIF(COUNT(DISTINCT transaction_id), 0), 2) AS panier_moyen
FROM fact_ventes;


-- -----------------------------------------------------------------------------
-- 2. TENDANCES TEMPORELLES ET ANALYSE CYCLIQUE
-- -----------------------------------------------------------------------------

-- Q5 : Chiffre d'affaires agrégé par année, trimestre et mois
SELECT 
    t.annee, 
    t.trimestre, 
    t.mois, 
    t.nom_mois, 
    SUM(f.montant_vente) AS chiffre_affaires,
    COUNT(DISTINCT f.transaction_id) AS nombre_ventes
FROM fact_ventes f
JOIN dim_temps t ON f.date_key = t.date_key
GROUP BY t.annee, t.trimestre, t.mois, t.nom_mois
ORDER BY t.annee, t.mois;

-- Q6 : Taux de croissance interannuel du chiffre d'affaires (YoY)
WITH ca_annuel AS (
    SELECT 
        t.annee, 
        SUM(f.montant_vente) AS ca
    FROM fact_ventes f
    JOIN dim_temps t ON f.date_key = t.date_key
    GROUP BY t.annee
)
SELECT 
    annee,
    ca AS chiffre_affaires_actuel,
    LAG(ca) OVER (ORDER BY annee) AS ca_annee_precedente,
    ROUND(((ca - LAG(ca) OVER (ORDER BY annee)) / NULLIF(LAG(ca) OVER (ORDER BY annee), 0)) * 100, 2) AS taux_croissance_yoy_pourcent
FROM ca_annuel;

-- Q7 : Analyse comparative des ventes par jour de la semaine
SELECT 
    t.jour_semaine,
    SUM(f.montant_vente) AS ca_total,
    ROUND(AVG(f.montant_vente), 2) AS vente_moyenne
FROM fact_ventes f
JOIN dim_temps t ON f.date_key = t.date_key
GROUP BY t.jour_semaine
ORDER BY ca_total DESC;


-- -----------------------------------------------------------------------------
-- 3. ANALYSE DES PRODUITS ET CATALOGUE (TOP & CLASSEMENTS)
-- -----------------------------------------------------------------------------

-- Q8 : Top 10 des produits générant le plus de chiffre d'affaires
SELECT 
    p.produit_id,
    p.nom_produit,
    p.categorie,
    SUM(f.quantite) AS volume_vendu,
    SUM(f.montant_vente) AS ca_genere
FROM fact_ventes f
JOIN dim_produit p ON f.produit_key = p.produit_key
GROUP BY p.produit_id, p.nom_produit, p.categorie
ORDER BY ca_genere DESC
LIMIT 10;

-- Q9 : Classement des produits par catégorie avec fonction de fenêtrage (RANK)
SELECT 
    p.categorie,
    p.nom_produit,
    SUM(f.montant_vente) AS ca_produit,
    RANK() OVER (PARTITION BY p.categorie ORDER BY SUM(f.montant_vente) DESC) AS rang_dans_categorie
FROM fact_ventes f
JOIN dim_produit p ON f.produit_key = p.produit_key
GROUP BY p.categorie, p.nom_produit;

-- Q10 : Part du chiffre d'affaires de chaque produit par rapport au total général
SELECT 
    p.nom_produit,
    SUM(f.montant_vente) AS ca_produit,
    ROUND((SUM(f.montant_vente) * 100.0) / (SELECT SUM(montant_vente) FROM fact_ventes), 2) AS pourcentage_ca_global
FROM fact_ventes f
JOIN dim_produit p ON f.produit_key = p.produit_key
GROUP BY p.nom_produit
ORDER BY ca_produit DESC;

-- Q11 : Produits dont le volume de vente est inférieur à la moyenne générale
SELECT 
    p.nom_produit,
    SUM(f.quantite) AS total_quantite
FROM fact_ventes f
JOIN dim_produit p ON f.produit_key = p.produit_key
GROUP BY p.nom_produit
HAVING SUM(f.quantite) < (
    SELECT AVG(somme_qte) FROM (
        SELECT SUM(quantite) AS somme_qte FROM fact_ventes GROUP BY produit_key
    ) sub
);


-- -----------------------------------------------------------------------------
-- 4. PERFORMANCE GÉOGRAPHIQUE ET DES MAGASINS
-- -----------------------------------------------------------------------------

-- Q12 : Performance globale des points de vente (Magasins)
SELECT 
    m.magasin_id,
    m.nom_magasin,
    m.ville,
    m.region,
    COUNT(DISTINCT f.transaction_id) AS nombre_transactions,
    SUM(f.montant_vente) AS chiffre_affaires
FROM fact_ventes f
JOIN dim_magasin m ON f.magasin_key = m.magasin_key
GROUP BY m.magasin_id, m.nom_magasin, m.ville, m.region
ORDER BY chiffre_affaires DESC;

-- Q13 : Ventilation du chiffre d'affaires par région administrative
SELECT 
    m.region,
    SUM(f.montant_vente) AS ca_region,
    ROUND((SUM(f.montant_vente) * 100.0) / (SELECT SUM(montant_vente) FROM fact_ventes), 2) AS part_marche_region
FROM fact_ventes f
JOIN dim_magasin m ON f.magasin_key = m.magasin_key
GROUP BY m.region
ORDER BY ca_region DESC;

-- Q14 : Comparaison des performances des magasins par trimestre (Pivot)
SELECT 
    m.nom_magasin,
    SUM(CASE WHEN t.trimestre = 1 THEN f.montant_vente ELSE 0 END) AS ca_T1,
    SUM(CASE WHEN t.trimestre = 2 THEN f.montant_vente ELSE 0 END) AS ca_T2,
    SUM(CASE WHEN t.trimestre = 3 THEN f.montant_vente ELSE 0 END) AS ca_T3,
    SUM(CASE WHEN t.trimestre = 4 THEN f.montant_vente ELSE 0 END) AS ca_T4,
    SUM(f.montant_vente) AS ca_total_annuel
FROM fact_ventes f
JOIN dim_magasin m ON f.magasin_key = m.magasin_key
JOIN dim_temps t ON f.date_key = t.date_key
WHERE t.annee = 2025
GROUP BY m.nom_magasin;


-- -----------------------------------------------------------------------------
-- 5. ANALYSE ET SEGMENTATION DE LA CLIENTÈLE
-- -----------------------------------------------------------------------------

-- Q15 : Nombre de clients uniques actifs
SELECT COUNT(DISTINCT client_key) AS clients_actifs_uniques
FROM fact_ventes;

-- Q16 : Top 10 des clients ayant généré le plus de revenus (Valeur client)
SELECT 
    c.client_id,
    c.nom,
    c.ville,
    COUNT(DISTINCT f.transaction_id) AS frequence_achats,
    SUM(f.montant_vente) AS montant_total_depense
FROM fact_ventes f
JOIN dim_client c ON f.client_key = c.client_key
GROUP BY c.client_id, c.nom, c.ville
ORDER BY montant_total_depense DESC
LIMIT 10;

-- Q17 : Répartition des clients actifs par tranche d'âge
SELECT 
    CASE 
        WHEN c.age < 25 < 25 THEN 'Moins de 25 ans'
        WHEN c.age BETWEEN 25 AND 35 THEN '25 - 35 ans'
        WHEN c.age BETWEEN 36 AND 50 THEN '36 - 50 ans'
        ELSE 'Plus de 50 ans'
    END AS tranche_age,
    COUNT(DISTINCT c.client_key) AS nombre_clients,
    SUM(f.montant_vente) AS ca_genere
FROM fact_ventes f
JOIN dim_client c ON f.client_key = c.client_key
GROUP BY tranche_age
ORDER BY ca_genere DESC;

-- Q18 : Taux de fidélité client (Clients ayant réalisé plus d'un achat)

WITH stats_achats AS (
    SELECT 
        c.client_key,
        COUNT(DISTINCT f.transaction_id) AS nb_achats
    FROM fact_ventes f
    JOIN dim_client c ON f.client_key = c.client_key
    GROUP BY c.client_key
)
SELECT 
    COUNT(CASE WHEN nb_achats > 1 THEN 1 END) AS clients_fides,
    COUNT(*) AS total_clients_uniques,
    ROUND((COUNT(CASE WHEN nb_achats > 1 THEN 1 END) * 100.0) / COUNT(*), 2) AS taux_fidelite_pourcent
FROM stats_achats;

-- Q19 : Panier moyen et performance par genre de client

SELECT 
    c.sexe,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    SUM(f.montant_vente) AS ca_total,
    ROUND(SUM(f.montant_vente) / NULLIF(COUNT(DISTINCT f.transaction_id), 0), 2) AS panier_moyen
FROM fact_ventes f
JOIN dim_client c ON f.client_key = c.client_key
GROUP BY c.sexe
ORDER BY ca_total DESC;

-- Q20 : Identification du "Meilleur Mois" de vente de l'historique (Pic de performance)

SELECT 
    t.annee,
    t.nom_mois,
    SUM(f.montant_vente) AS chiffre_affaires_mensuel
FROM fact_ventes f
JOIN dim_temps t ON f.date_key = t.date_key
GROUP BY t.annee, t.mois, t.nom_mois
ORDER BY chiffre_affaires_mensuel DESC
LIMIT 1;


