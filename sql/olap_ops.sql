-- Q1 : Opération ROLL-UP (Hiérarchie Temporelle : Année -> Trimestre -> Mois -> Total Global)
SELECT 
    COALESCE(CAST(t.annee AS VARCHAR), 'TOUTES LES ANNEES') AS annee,
    COALESCE(CAST(t.trimestre AS VARCHAR), 'Tous Trimestres') AS trimestre,
    COALESCE(CAST(t.mois AS VARCHAR), 'Tous Mois') AS mois,
    SUM(f.montant_vente) AS ca_cumule,
    COUNT(DISTINCT f.transaction_id) AS nombre_ventes
FROM fact_ventes f
JOIN dim_temps t ON f.date_key = t.date_key
GROUP BY ROLLUP(t.annee, t.trimestre, t.mois)
ORDER BY t.annee, t.trimestre, t.mois;

-- Q2 : Opération DRILL-DOWN (Descente de l'Année 2025 -> Mois de Novembre -> Jours du mois)
SELECT 
    t.annee,
    t.mois,
    t.nom_mois,
    t.date AS jour_precis,
    SUM(f.montant_vente) AS chiffre_affaires_journalier,
    SUM(f.quantite) AS volume_vendu
FROM fact_ventes f
JOIN dim_temps t ON f.date_key = t.date_key
WHERE t.annee = 2025 AND t.mois = 11  -- Filtre ciblé sur l'année 2025 et le mois de Novembre
GROUP BY t.annee, t.mois, t.nom_mois, t.date
ORDER BY t.date;

-- Q3 : Opération SLICE (Isolation de la dimension Produit sur la catégorie 'Audio' uniquement)
SELECT 
    t.date,
    c.nom AS client,
    m.nom_magasin,
    p.nom_produit,
    f.quantite,
    f.montant_vente
FROM fact_ventes f
JOIN dim_temps t ON f.date_key = t.date_key
JOIN dim_client c ON f.client_key = c.client_key
JOIN dim_magasin m ON f.magasin_key = m.magasin_key
JOIN dim_produit p ON f.produit_key = p.produit_key
WHERE p.categorie = 'Audio'
ORDER BY t.date DESC
LIMIT 15;

-- Q4 : Opération DICE (Sélection simultanée : Région 'Lagunes' + Catégorie 'Informatique' + Année 2025)
SELECT 
    m.nom_magasin,
    p.nom_produit,
    t.annee,
    SUM(f.quantite) AS total_quantite,
    SUM(f.montant_vente) AS ca_total_realise
FROM fact_ventes f
JOIN dim_magasin m ON f.magasin_key = m.magasin_key
JOIN dim_produit p ON f.produit_key = p.produit_key
JOIN dim_temps t ON f.date_key = t.date_key
WHERE m.region = 'Lagunes' 
  AND p.categorie = 'Informatique'
  AND t.annee = 2025
GROUP BY m.nom_magasin, p.nom_produit, t.annee
ORDER BY ca_total_realise DESC;

-- Q5 : Opération PIVOT (Transformation des trimestres en colonnes pour comparer les magasins en 2025)
SELECT 
    m.nom_magasin,
    m.region,
    SUM(CASE WHEN t.trimestre = 1 THEN f.montant_vente ELSE 0 END) AS trimestre_1,
    SUM(CASE WHEN t.trimestre = 2 THEN f.montant_vente ELSE 0 END) AS trimestre_2,
    SUM(CASE WHEN t.trimestre = 3 THEN f.montant_vente ELSE 0 END) AS trimestre_3,
    SUM(CASE WHEN t.trimestre = 4 THEN f.montant_vente ELSE 0 END) AS trimestre_4,
    SUM(f.montant_vente) AS ca_annuel_global
FROM fact_ventes f
JOIN dim_magasin m ON f.magasin_key = m.magasin_key
JOIN dim_temps t ON f.date_key = t.date_key
WHERE t.annee = 2025
GROUP BY m.nom_magasin, m.region
ORDER BY ca_annuel_global DESC;

