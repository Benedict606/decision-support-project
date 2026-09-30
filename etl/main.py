from extract import extract_raw_data
from load import load_to_postgres, generate_execution_report
from transform import transform_and_validate

if __name__ == '__main__':

  DB_URL = 'postgresql+psycopg2://postgres:1111@localhost:5432/bi_ventes_db'

  # 1. Extraction
  clients, produits, magasins, ventes = extract_raw_data()
  raw_count = len(ventes)

  # 2. Transformation & Validation
  clients, produits, magasins, temps, ventes_clean = transform_and_validate(
      clients, produits, magasins, ventes
  )
  
  duplicates_removed = raw_count - len(ventes_clean)  # Estimation simple

  # 3. Chargement dans le DW
  load_to_postgres(clients, produits, magasins, temps, ventes_clean, db_url=DB_URL)
  
  # 10. Production du journal d'exécution et rapport de qualité
  generate_execution_report(
      raw_count=raw_count,
      duplicates_removed=duplicates_removed,
      clean_count=len(ventes_clean),
      clients_count=len(clients),
      produits_count=len(produits),
      magasins_count=len(magasins),
  )