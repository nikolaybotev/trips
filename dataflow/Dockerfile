FROM apache/beam_python3.12_sdk:2.67.0

# Make your customizations here, for example:
COPY trips_to_staypoints/models.py .
COPY trips_to_staypoints/main.py .
COPY trips_to_staypoints/requirements.txt .

# Pre-install Python dependencies. For reproducibile builds,
# supply all of the dependencies and their versions in a requirements.txt file.
RUN pip install -r requirements.txt
