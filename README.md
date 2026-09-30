# Système Décisionnel pour l'Analyse des Ventes (Decision Support System)

## À propos du projet

Ce projet consiste en la conception et l'implémentation de bout en bout d'un **système décisionnel (Business Intelligence)** complet destiné à automatiser l'ingestion, le stockage, l'analyse multidimensionnelle (OLAP) et la restitution visuelle des performances commerciales d'une entreprise.

Il intègre également des extensions de **Machine Learning** pour la segmentation comportementale de la clientèle (RFM & K-Means) et la prévision des ventes.

---

## Stack Technologique

- **Langage :** Python 3.10+ (`pandas`, `numpy`, `scikit-learn`, `sqlalchemy`, `psycopg2`)
- **Base de données :** PostgreSQL (Data Warehouse - Schéma en Étoile)
- **Interface & Visualisation :** Streamlit, Plotly
- **Orchestration & Déploiement :** Docker & Docker Compose
- **Environnement de recherche :** Jupyter Notebooks

---

## Organisation du Dépôt

```text
decision-support-project/
├── data/
│   ├── raw/                 # Données sources brutes initiales
│   ├── staging/             # Zone de transit et de nettoyage intermédiaire
│   └── processed/           # Jeux de données finaux et enrichis
├── etl/
│   ├── extract.py           # Ingestion des données sources
│   ├── transform.py         # Nettoyage, validation et calculs dérivés
│   ├── load.py              # Chargement dans le Data Warehouse PostgreSQL
│   └── main.py              # Script orchestrateur du pipeline ETL
├── sql/
│   ├── create_schema.sql    # Modélisation du schéma en étoile (faits et dimensions)
│   ├── analytical_queries.sql # Requêtes SQL décisionnelles avancées
│   └── olap_ops.sql         # Opérations OLAP (Roll-up, Drill-down, Slice, Dice, Pivot)
├── notebooks/
│   ├── sales_analysis.ipynb # Analyse exploratoire des données (EDA) & KPI
│   └── ml_extensions.ipynb  # Clustering K-Means, RFM et modélisation prédictive
├── dashboard/
│   └── dashboard_app.py     # Application web interactive (Streamlit)
├── documentation/           # Schémas, rapports de qualité et documentation technique
├── Dockerfile               # Configuration de l'image de l'application
├── docker-compose.yml       # Orchestration des services (PostgreSQL + Streamlit)
├── requirements.txt         # Dépendances du projet Python
└── README.md                # Documentation principale du projet

```

---

## Guide de Démarrage Rapide (Pour l'évaluation)

Le projet est entièrement conteneurisé. La manière la plus simple et rapide de lancer l'application et la base de données sans configuration locale lourde est d'utiliser **Docker**.

### Prérequis

- [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/) installés sur votre machine.

### Instructions de lancement

1. Clonez le dépôt sur votre machine :

```bash
git clone [https://github.com/votre-nom-utilisateur/decision-support-project.git](https://github.com/votre-nom-utilisateur/decision-support-project.git)
cd decision-support-project

```

2. Lancez l'environnement complet via Docker Compose :

```bash
docker compose up --build

```

3. Accédez aux services :

- **Tableau de bord décisionnel (Streamlit) :** Ouvrez votre navigateur à l'adresse [http://localhost:8501](http://localhost:8501)
- **Base de données (PostgreSQL) :** Accessible sur le port `5432` (`db:5432`).

---

## Fonctionnalités Clés du Système

1. **Pipeline ETL Automatisé :** Traitement robuste de plus de 50 000 transactions avec contrôle de la qualité et intégrité référentielle.
2. **Entrepôt de Données Optimisé :** Modèle dimensionnel en étoile garantissant des performances accrues pour les requêtes analytiques complexes.
3. **Analyses OLAP & SQL :** Exploitation des fonctions de fenêtrage et cubes multidimensionnels pour l'étude de la saisonnalité, des performances géographiques et du panier moyen.
4. **Intelligence Artificielle & Marketing :** Segmentation de la clientèle par classification non supervisée (_K-Means_) et analyse RFM.
5. **Restitution Exécutive :** Dashboard interactif avec filtres croisés dynamiques et cartes KPI en temps réel.

---

## Auteur

- **Benedict Lubembela**
- MSc Student – Université Catholique de Bukavu

```

```
