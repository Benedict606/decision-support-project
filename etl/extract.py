import os
import pandas as pd


def extract_raw_data(data_dir='../data/raw'):
  """Extrait l'ensemble des fichiers CSV bruts."""
  print('[ETL - Extract] Chargement des fichiers CSV bruts...')

  clients_df = pd.read_csv(os.path.join(data_dir, 'clients.csv'),
    encoding='latin1')
  produits_df = pd.read_csv(os.path.join(data_dir, 'produits.csv'),
    encoding='latin1')
  magasins_df = pd.read_csv(os.path.join(data_dir, 'magasins.csv'),
    encoding='latin1')
  ventes_df = pd.read_csv(os.path.join(data_dir, 'ventes_raw.csv'),
    encoding='latin1')

  print(f'   - Clients extraits    : {len(clients_df)}')
  print(f'   - Produits extraits   : {len(produits_df)}')
  print(f'   - Magasins extraits   : {len(magasins_df)}')
  print(f'   - Ventes brutes      : {len(ventes_df)}')

  return clients_df, produits_df, magasins_df, ventes_df
