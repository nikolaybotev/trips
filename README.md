# Trip Data Generator

A Python script for generating large-scale random trip data in CSV format. Perfect for testing, benchmarking, and data analysis applications that require realistic trip datasets.

## Features

- **Memory Efficient**: Uses Python generators to stream data without holding everything in memory
- **Configurable**: Command-line arguments for number of trips and output filename
- **Realistic Data**: Generates trips with realistic distributions and time ranges
- **Scalable**: Can generate millions or billions of trips efficiently
- **Parallel Processing**: Bash script for generating multiple files simultaneously

## Data Schema

Each trip record contains:
- `user_id`: UUID v4 identifier
- `trip_start_time`: ISO timestamp (UTC)
- `trip_end_time`: ISO timestamp (UTC)
- `start_lat`: Starting latitude (-90 to 90)
- `start_lng`: Starting longitude (-180 to 180)
- `end_lat`: Ending latitude (-90 to 90)
- `end_lng`: Ending longitude (-180 to 180)

## Installation

### Quick Setup

```bash
git clone https://github.com/yourusername/trips.git
cd trips
source ./setup.sh
```

The `setup.sh` script will:
1. Create a Python 3.12 virtual environment
2. Activate the virtual environment
3. Install all required dependencies

### Manual Setup

If you prefer to set up manually:

```bash
git clone https://github.com/yourusername/trips.git
cd trips

# Create virtual environment with Python 3.12 (required for Apache Beam compatibility)
python3.12 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

**Note**: This project requires Python 3.12 for Apache Beam compatibility. Python 3.13 is not supported by Apache Beam 2.67.

## Usage

### Basic Usage

```bash
# Generate 1 million trips (default)
python3 generate_trips.py

# Generate 500,000 trips
python3 generate_trips.py --trips 500000

# Generate trips to custom file
python3 generate_trips.py --trips 1000000 --output my_trips.csv
```

### Command Line Options

- `--trips, -t`: Number of trips to generate (default: 1,000,000)
- `--output, -o`: Output CSV filename (default: trips.csv)

### Batch Generation

Generate multiple files simultaneously:

```bash
# Generate 1 billion total trips across 10 files (100M per file)
./generate_multiple_trips.sh 1000000000

# Generate 3 billion total trips across 10 files (300M per file)
./generate_multiple_trips.sh 3000000000
```

## Trip Distribution

- **Time Range**: 1 month (30 days) from current date
- **Trip Frequency**: Average 3 trips per day per user (1-20 range)
- **Trip Duration**: 5 minutes to 4 hours
- **User Distribution**: Automatically calculated based on trip count

## Performance

- **Memory Usage**: Constant (~1-2MB) regardless of dataset size
- **Generation Speed**: ~10,000-50,000 trips per second (varies by system)
- **File Size**: ~50-70 bytes per trip record

## Examples

### Small Dataset
```bash
python3 generate_trips.py --trips 10000 --output small_trips.csv
```

### Large Dataset
```bash
python3 generate_trips.py --trips 100000000 --output large_trips.csv
```

### Massive Parallel Generation
```bash
./generate_multiple_trips.sh 10000000000  # 10 billion trips total
```

## File Structure

```
trips/
├── data/                     # Data generation scripts and utilities
│   ├── generate_trips.py     # Main Python script
│   ├── generate_multiple_trips.sh # Batch generation script
│   ├── print_pandas.py       # Pandas data analysis utility
│   ├── trips_to_staypoints.sql # SQL conversion script
│   ├── starburst_import.sql  # Starburst import script
│   └── STARBURST_SETUP.md    # Starburst setup guide
├── dataflow/                 # Apache Beam Dataflow jobs
│   ├── trips_to_staypoints/
│   │   ├── main.py           # Main Dataflow pipeline
│   │   ├── models.py         # Data models
│   │   └── requirements.txt  # Dataflow dependencies
│   ├── cicd/                 # Infrastructure as Code
│   │   └── terraform/        # Terraform configuration
│   │       ├── *.tf          # Terraform resource files
│   │       ├── terraform.tfvars # Configuration variables
│   │       └── README.md      # Terraform documentation
│   ├── input/                # Sample input data (Parquet files)
│   ├── output/               # Dataflow job outputs
│   ├── Dockerfile            # Container image definition
│   ├── config.sh             # Configuration loader
│   ├── run_dataflow_job.sh   # Cloud deployment script
│   ├── test_dataflow_local.sh # Local testing script
│   └── README.md             # Dataflow documentation
├── requirements.txt          # Main project dependencies
├── setup.sh                  # Environment setup script
├── README.md                 # This file
└── LICENSE                   # MIT License
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Data Processing Pipeline

This repository includes a complete data processing pipeline:

### 1. Data Generation (`data/`)
- Generate realistic trip data with configurable parameters
- Support for massive parallel generation across multiple CPU cores
- Output in CSV format for easy import into various systems

### 2. Data Processing (`dataflow/`)
- **Apache Beam Dataflow job** that converts trips to staypoints
- **Containerized deployment** using Docker for reproducible builds
- **Infrastructure as Code** with Terraform for GCP resources
- **Multiple output formats**: JSON, CSV, and Hive-partitioned Parquet
- **Scalable processing** with automatic worker scaling

### 3. Data Analysis (`data/`)
- SQL scripts for trip-to-staypoints conversion
- Starburst/Trino integration for large-scale analytics
- Pandas utilities for data exploration

## Infrastructure Setup

The project includes Terraform configuration for Google Cloud Platform:

```bash
cd dataflow/cicd/terraform
terraform init
terraform plan
terraform apply
```

This creates:
- Dataflow service account with appropriate permissions
- Artifact Registry for container images
- GCS buckets for data storage
- VPC subnet for secure Dataflow execution

## Use Cases

- **Database Testing**: Generate test data for trip tracking systems
- **Performance Benchmarking**: Test query performance with large datasets
- **Machine Learning**: Create training data for trip prediction models
- **Analytics**: Generate data for trip pattern analysis
- **Load Testing**: Stress test applications with realistic data volumes
- **Big Data Processing**: Process massive datasets using Apache Beam/Dataflow
- **Cloud Analytics**: Deploy scalable data pipelines on Google Cloud Platform
