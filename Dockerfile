# Usamos Python ligero
FROM python:3.9-slim

WORKDIR /app

# Copiamos primero los requirements para aprovechar caché de Docker
COPY requirements.txt .

# Instalamos dependencias sin caché para reducir tamaño
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos el resto del código (incluyendo vulnerable_app.py y test_app.py)
COPY . .

# Exponemos el puerto de Flask
EXPOSE 5000

# Ejecutamos la app
CMD ["python", "vulnerable_app.py"]