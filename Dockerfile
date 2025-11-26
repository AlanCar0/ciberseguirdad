# Usamos Python ligero compatible con Mac M3
FROM python:3.9-slim

WORKDIR /app

# Copiamos las dependencias
COPY requirements.txt .

# Instalamos dependencias (Punto clave de evaluación)
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos el código fuente
COPY . .

# Exponemos el puerto
EXPOSE 5000

# Ejecutamos la app
CMD ["python", "vulnerable_app.py"]