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

No external dependencies required - uses only Python standard library.

```bash
git clone https://github.com/yourusername/trips.git
cd trips
```

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
├── generate_trips.py          # Main Python script
├── generate_multiple_trips.sh # Batch generation script
├── requirements.txt          # Dependencies (none required)
├── .vscode/
│   └── settings.json        # VS Code settings
├── README.md                # This file
└── LICENSE                  # MIT License
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Use Cases

- **Database Testing**: Generate test data for trip tracking systems
- **Performance Benchmarking**: Test query performance with large datasets
- **Machine Learning**: Create training data for trip prediction models
- **Analytics**: Generate data for trip pattern analysis
- **Load Testing**: Stress test applications with realistic data volumes
