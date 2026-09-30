from datetime import datetime
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from sqlalchemy import create_engine

# --- 1. CONFIGURATION DE LA PAGE STREAMLIT ---
st.set_page_config(
    page_title="Tableau de Bord décisionnel - BI Ventes",
    page_icon="",
    layout="wide",
)

# --- 2. CONNEXION ET CHARGEMENT DES DONNÉES DEPUIS LE DATA WAREHOUSE ---
DB_URL = "postgresql+psycopg2://postgres:1111@localhost:5432/bi_ventes_db"


@st.cache_data
def load_data():
  engine = create_engine(DB_URL)
  query = """
        SELECT 
            f.vente_key,
            f.transaction_id,
            f.quantite,
            f.prix_unitaire,
            f.montant_vente,
            t.date,
            t.annee,
            t.trimestre,
            t.mois,
            t.nom_mois,
            c.client_id,
            c.nom AS client_nom,
            c.ville AS client_ville,
            p.nom_produit,
            p.categorie,
            m.nom_magasin,
            m.region
        FROM fact_ventes f
        JOIN dim_temps t ON f.date_key = t.date_key
        JOIN dim_client c ON f.client_key = c.client_key
        JOIN dim_produit p ON f.produit_key = p.produit_key
        JOIN dim_magasin m ON f.magasin_key = m.magasin_key
    """
  df = pd.read_sql(query, con=engine)
  df["date"] = pd.to_datetime(df["date"])
  return df


try:
  df_raw = load_data()
except Exception as e:
  st.error(
      f"Erreur de connexion au Data Warehouse PostgreSQL : {e}. Veuillez"
      " vérifier vos accès."
  )
  st.stop()


st.sidebar.header("Filtres dynamiques du Dashboard")

# Filtre par période (Années)
annees_disponibles = sorted(df_raw["annee"].unique())
selected_annees = st.sidebar.multiselect(
    "Filtrer par année", options=annees_disponibles, default=annees_disponibles
)

# Filtre par région
regions_disponibles = sorted(df_raw["region"].unique())
selected_regions = st.sidebar.multiselect(
    "Filtrer par région", options=regions_disponibles, default=regions_disponibles
)

# Filtre par magasin
magasins_disponibles = sorted(df_raw["nom_magasin"].unique())
selected_magasins = st.sidebar.multiselect(
    "Filtrer par magasin",
    options=magasins_disponibles,
    default=magasins_disponibles,
)

# Filtre par catégorie de produit
categories_disponibles = sorted(df_raw["categorie"].unique())
selected_categories = st.sidebar.multiselect(
    "Filtrer par Catégorie",
    options=categories_disponibles,
    default=categories_disponibles,
)

# Application des filtres sur le DataFrame global
df = df_raw[
    df_raw["annee"].isin(selected_annees)
    & df_raw["region"].isin(selected_regions)
    & df_raw["nom_magasin"].isin(selected_magasins)
    & df_raw["categorie"].isin(selected_categories)
]

st.title("Tableau de Bord exécutif - Pilotage des ventes")
st.markdown(
    "*Analyse multidimensionnelle connectée en temps réel au Data Warehouse'*"
)
st.markdown("---")

# --- 5. CARTES KPI PRINCIPALES ---
total_ca = df["montant_vente"].sum()
total_transactions = df["transaction_id"].nunique()
total_clients = df["client_id"].nunique()
panier_moyen = df["montant_vente"].mean() if len(df) > 0 else 0

col1, col2, col3, col4 = st.columns(4)

with col1:
  st.metric(
      label="Chiffre d'affaires total", value=f"{total_ca:,.2f} $"
  )
with col2:
  st.metric(
      label="Nombre de transactions", value=f"{total_transactions:,}"
  )
with col3:
  st.metric(label="Clients uniques", value=f"{total_clients:,}")
with col4:
  st.metric(label="Panier moyen", value=f"{panier_moyen:,.2f} $")

st.markdown("---")

# --- 6. GRAPHIQUES D'ÉVOLUTION ET DE PERFORMANCE ---
row1_col1, row1_col2 = st.columns(2)

# Graphique 1 : Évolution temporelle du CA
with row1_col1:
  st.subheader("Évolution temporelle du Chiffre d'Affaires")
  df_temps = (
      df.groupby(df["date"].dt.to_period("M"))["montant_vente"]
      .sum()
      .reset_index()
  )
  df_temps["date"] = df_temps["date"].dt.to_timestamp()
  fig_ca = px.line(
      df_temps,
      x="date",
      y="montant_vente",
      markers=True,
      labels={
          "date": "Période (Mois)",
          "montant_vente": "Chiffre d'Affaires ($)",
      },
      template="plotly_white",
  )
  fig_ca.update_traces(line_color="#1f77b4", line_width=3)
  st.plotly_chart(fig_ca, use_container_width=True)

# Graphique 2 : Performance par Région et par Magasin
with row1_col2:
  st.subheader("CA par magasin et par région")
  df_magasin = (
      df.groupby(["nom_magasin", "region"])["montant_vente"]
      .sum()
      .reset_index()
      .sort_values(by="montant_vente", ascending=True)
  )
  fig_mag = px.bar(
      df_magasin,
      x="montant_vente",
      y="nom_magasin",
      color="region",
      orientation="h",
      labels={
          "montant_vente": "Chiffre d'Affaires ($)",
          "nom_magasin": "Magasin",
          "region": "Région",
      },
      template="plotly_white",
  )
  st.plotly_chart(fig_mag, use_container_width=True)

row2_col1, row2_col2 = st.columns(2)

# Graphique 3 : Performance par catégorie de produit (Camembert / Donut)
with row2_col1:
  st.subheader("Répartition par catégorie de produits")
  df_cat = df.groupby("categorie")["montant_vente"].sum().reset_index()
  fig_cat = px.pie(
      df_cat,
      names="categorie",
      values="montant_vente",
      hole=0.4,
      template="plotly_white",
  )
  st.plotly_chart(fig_cat, use_container_width=True)

# Classements Top 10 (Clients et Produits)
with row2_col2:
  st.subheader("Classements Clés (Top 10)")
  tab_top1, tab_top2 = st.tabs(["Top 10 Produits", "Top 10 Clients"])

  with tab_top1:
    top_produits = (
        df.groupby("nom_produit")["montant_vente"]
        .sum()
        .reset_index()
        .sort_values(by="montant_vente", ascending=False)
        .head(10)
    )
    fig_p = px.bar(
        top_produits,
        x="montant_vente",
        y="nom_produit",
        orientation="h",
        template="plotly_white",
    )
    fig_p.update_layout(yaxis={"categoryorder": "total ascending"})
    st.plotly_chart(fig_p, use_container_width=True)

  with tab_top2:
    top_clients = (
        df.groupby("client_nom")["montant_vente"]
        .sum()
        .reset_index()
        .sort_values(by="montant_vente", ascending=False)
        .head(10)
    )
    fig_c = px.bar(
        top_clients,
        x="montant_vente",
        y="client_nom",
        orientation="h",
        template="plotly_white",
    )
    fig_c.update_layout(yaxis={"categoryorder": "total ascending"})
    st.plotly_chart(fig_c, use_container_width=True)