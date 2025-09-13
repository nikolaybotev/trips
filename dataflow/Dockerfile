FROM apache/beam_python3.12_sdk:2.67.0

# Make your customizations here, for example:
COPY models.py .
COPY trips_to_staypoints_dataflow.py .
COPY requirements.txt .

# Pre-install Python dependencies. For reproducibile builds,
# supply all of the dependencies and their versions in a requirements.txt file.
RUN pip install -r requirements.txt
