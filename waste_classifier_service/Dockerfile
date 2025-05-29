# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies that might be needed by Pillow or other libraries
# OpenCV (cv2) often needs libgl1-mesa-glx, for example.
# For basic Pillow and TensorFlow CPU, this might be minimal.
# Add more if you encounter missing shared library errors during runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Example: libgl1-mesa-glx libglib2.0-0
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
# Using --no-cache-dir to reduce image size
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Make port 8080 available to the world outside this container
# Cloud Run will automatically use this port if your app listens on it.
# Gunicorn will bind to 0.0.0.0:8080 by default based on PORT env var.
ENV PORT 8080
EXPOSE 8080

# Define environment variable for Flask (optional, gunicorn handles this)
# ENV FLASK_APP app.py
# ENV FLASK_RUN_HOST 0.0.0.0

# Run app.py when the container launches using Gunicorn
# CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"] # For development
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "8", "--timeout", "0", "app:app"]
# Explanation of Gunicorn command:
# --bind 0.0.0.0:8080 : Listen on all interfaces on port 8080
# --workers 1 : Number of worker processes. For Cloud Run (typically 1 vCPU), 1 worker is often fine.
#               You can adjust based on your instance's vCPUs and load.
# --threads 8 : Number of threads per worker.
# --timeout 0 : Disables worker timeout (useful for long model loading or predictions, Cloud Run has its own request timeout).
# app:app :     Look for an object named 'app' in the 'app.py' file.
