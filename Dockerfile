FROM python:3.10-slim

WORKDIR /app

# Installer les dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier et installer les exigences Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le reste du projet
COPY . .

# Exposer le port de Streamlit
EXPOSE 8501

# Commande de lancement par défaut
CMD ["streamlit", "run", "dashboard/dashboard_app.py", "--server.address=0.0.0.0"]