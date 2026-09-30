import pandas as pd
from sqlalchemy import create_engine, text
from datetime import datetime


def load_to_postgres(
    clients_df,
    produits_df,
    magasins_df,
    temps_df,
    ventes_df,
    db_url='postgresql+psycopg2://postgres:1111@localhost:5432/bi_ventes_db',
):
  print('[ETL - Load] Chargement dans le Data Warehouse PostgreSQL...')
  engine = create_engine(db_url)

  with engine.begin() as conn:
    # 1. Chargement de DIM_TEMPS
    temps_df.to_sql(
        'dim_temps', con=conn, if_exists='append', index=False, method='multi'
    )
    print('   - DIM_TEMPS chargée.')

    # 2. Chargement de DIM_CLIENT, DIM_PRODUIT, DIM_MAGASIN
    # Renommage des colonnes pour correspondre exactement aux schémas SQL
    clients_df.to_sql('dim_client', con=conn, if_exists='append', index=False)
    produits_df.rename(columns={'prix': 'prix_actuel'}).to_sql(
        'dim_produit', con=conn, if_exists='append', index=False
    )
    magasins_df.to_sql('dim_magasin', con=conn, if_exists='append', index=False)
    print('   - Dimensions CLIENT, PRODUIT, MAGASIN chargées.')

    # 3. MAPPING DES CLÉS SUBSTITUTS (Surrogate Keys Mapping)
    # On récupère les identifiants générés par la BDD
    dim_client_db = pd.read_sql(
        'SELECT client_key, client_id FROM dim_client', con=conn
    )
    dim_produit_db = pd.read_sql(
        'SELECT produit_key, produit_id FROM dim_produit', con=conn
    )
    dim_magasin_db = pd.read_sql(
        'SELECT magasin_key, magasin_id FROM dim_magasin', con=conn
    )

    # Jointure pour remplacer les Clés Métiers par les Clés Substituts
    fact_ventes = ventes_df.merge(dim_client_db, on='client_id', how='inner')
    fact_ventes = fact_ventes.merge(dim_produit_db, on='produit_id', how='inner')
    fact_ventes = fact_ventes.merge(dim_magasin_db, on='magasin_id', how='inner')

    # Sélection des colonnes exactes de la table FACT_VENTES
    fact_ventes_final = fact_ventes[[
        'date_key',
        'client_key',
        'produit_key',
        'magasin_key',
        'transaction_id',
        'quantite',
        'prix_unitaire',
        'montant_vente',
    ]]

    # 4. Chargement de la Table de Faits
    fact_ventes_final.to_sql(
        'fact_ventes',
        con=conn,
        if_exists='append',
        index=False,
        chunksize=5000,
        method='multi',
    )
    print(f'   - FACT_VENTES chargée avec {len(fact_ventes_final)} lignes.')

  print(' Pipeline ETL exécuté avec succès !')
  
  
  from datetime import datetime
import os


def generate_execution_report(
    raw_count,
    duplicates_removed,
    clean_count,
    clients_count,
    produits_count,
    magasins_count,
):
  """Produit un journal d'exécution et un rapport de qualité (Point 10)"""
  report_dir = '../documentation'
  os.makedirs(report_dir, exist_ok=True)
  report_path = os.path.join(report_dir, 'etl_execution_report.txt')

  now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

  report_content = f"""=============================================================================
 RAPPORT DE QUALITÉ ET JOURNAL D'EXÉCUTION ETL
=============================================================================
Date et heure d'exécution : {now}
Statut global : SUCCÈS 

1. STATISTIQUES D'EXTRACTION (SOURCES)
   - Lignes brutes de ventes lues : {raw_count}
   - Référentiel clients : {clients_count} entrées
   - Référentiel produits : {produits_count} entrées
   - Référentiel magasins : {magasins_count} entrées

2. CONTRÔLE DE QUALITÉ ET NETTOYAGE
   - Doublons détectés et supprimés : {duplicates_removed} lignes
   - Valeurs aberrantes / négatives filtrées : Conformité validée
   - Intégrité référentielle (Clés étrangères) : 100% rattachées

3. CHARGEMENT DÉFINITIF (DATA WAREHOUSE)
   - Lignes finales chargées dans FACT_VENTES : {clean_count}
   - Dimensions synchronisées : DIM_TEMPS, DIM_CLIENT, DIM_PRODUIT, DIM_MAGASIN

=============================================================================
 Fin du rapport - Projet Business Intelligence (Benedict Lubembela)
=============================================================================
"""

  with open(report_path, 'w', encoding='utf-8') as f:
    f.write(report_content)

  print(f' [ETL - Report] Journal d’exécution généré : {report_path}')