import pandas as pd
import os

def transform_and_validate(clients_df, produits_df, magasins_df, ventes_df):
  print('[ETL - Transform & Validate] Nettoyage et validation...')

  # 1. Dédoublonnage des ventes brutes
  initial_len = len(ventes_df)
  ventes_df = ventes_df.drop_duplicates()
  print(f'   - Doublons supprimés : {initial_len - len(ventes_df)} lignes')

  # 2. Conversion et validation des dates
  ventes_df['date'] = pd.to_datetime(ventes_df['date'])

  # 3. Filtrage des valeurs aberrantes (prix <= 0 ou quantite <= 0)
  ventes_df = ventes_df[
      (ventes_df['quantite'] > 0) & (ventes_df['prix_unitaire'] > 0)
  ]

  # 4. Contrôle d'intégrité référentielle
  valid_clients = set(clients_df['client_id'])
  valid_produits = set(produits_df['produit_id'])
  valid_magasins = set(magasins_df['magasin_id'])

  ventes_df = ventes_df[
      ventes_df['client_id'].isin(valid_clients)
      & ventes_df['produit_id'].isin(valid_produits)
      & ventes_df['magasin_id'].isin(valid_magasins)
  ]

  # 5. Calcul de la métrique financière (Montant total = Quantite * Prix Unitaire)
  ventes_df['montant_vente'] = (
      ventes_df['quantite'] * ventes_df['prix_unitaire']
  )

  # 6. Génération dynamique de DIM_TEMPS à partir des dates réelles de ventes
  unique_dates = pd.Series(ventes_df['date'].unique()).sort_values()
  temps_list = []
  for d in unique_dates:
    temps_list.append({
        'date_key': int(d.strftime('%Y%m%d')),
        'date': d.date(),
        'jour': d.day,
        'mois': d.month,
        'nom_mois': d.strftime('%B'),
        'trimestre': d.quarter,
        'annee': d.year,
        'jour_semaine': d.strftime('%A'),
    })
  temps_df = pd.DataFrame(temps_list)

  # Ajout de la clé 'date_key' dans le DataFrame de ventes
  ventes_df['date_key'] = (
      ventes_df['date'].dt.strftime('%Y%m%d').astype(int)
  )

  print(
      f'   - Ventes valides nettoyées prêtes pour chargement : {len(ventes_df)}'
  )
  
  save_to_staging(clients_df, produits_df, magasins_df, temps_df, ventes_df)
  return clients_df, produits_df, magasins_df, temps_df, ventes_df




def save_to_staging(
    clients_df, produits_df, magasins_df, temps_df, ventes_clean_df
):
  """Enregistre les données nettoyées dans la zone Staging """
  staging_dir = '../data/staging'
  os.makedirs(staging_dir, exist_ok=True)

  print(
      ' [ETL - Staging] Sauvegarde des données nettoyées dans data/staging/...'
  )

  clients_df.to_csv(os.path.join(staging_dir, 'clients_staging.csv'), index=False)
  produits_df.to_csv(
      os.path.join(staging_dir, 'produits_staging.csv'), index=False
  )
  magasins_df.to_csv(
      os.path.join(staging_dir, 'magasins_staging.csv'), index=False
  )
  temps_df.to_csv(os.path.join(staging_dir, 'temps_staging.csv'), index=False)
  ventes_clean_df.to_csv(
      os.path.join(staging_dir, 'ventes_staging.csv'), index=False
  )

  print('   - Fichiers staging générés avec succès.')