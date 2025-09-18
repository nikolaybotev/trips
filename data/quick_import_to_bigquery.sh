#!/bin/bash
# Quick script to import CSV files to BigQuery using bq command line tool

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-your-project-id}"
DATASET_ID="${DATASET_ID:-trips_data}"
TABLE_ID="${TABLE_ID:-trips}"
CSV_FOLDER="${1:-./trips_data}"
BUCKET_NAME="${BUCKET_NAME:-your-bucket-name}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}BigQuery CSV Import Script${NC}"
echo "=================================="
echo "Project ID: $PROJECT_ID"
echo "Dataset ID: $DATASET_ID"
echo "Table ID: $TABLE_ID"
echo "CSV Folder: $CSV_FOLDER"
echo ""

# Check if bq command is available
if ! command -v bq &> /dev/null; then
    echo -e "${RED}Error: bq command not found. Please install Google Cloud SDK.${NC}"
    exit 1
fi

# Check if CSV folder exists
if [ ! -d "$CSV_FOLDER" ]; then
    echo -e "${RED}Error: CSV folder '$CSV_FOLDER' not found.${NC}"
    exit 1
fi

# Count CSV files
CSV_COUNT=$(find "$CSV_FOLDER" -name "*.csv" | wc -l)
if [ "$CSV_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No CSV files found in '$CSV_FOLDER'.${NC}"
    exit 1
fi

echo -e "${YELLOW}Found $CSV_COUNT CSV files${NC}"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [CSV_FOLDER] [METHOD]"
    echo ""
    echo "Methods:"
    echo "  1. direct    - Direct import using bq load (default)"
    echo "  2. gcs       - Upload to GCS first, then import"
    echo "  3. python    - Use Python script with pandas"
    echo ""
    echo "Examples:"
    echo "  $0 ./trips_data direct"
    echo "  $0 ./trips_data gcs"
    echo "  $0 ./trips_data python"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_ID    - GCP Project ID (default: your-project-id)"
    echo "  DATASET_ID    - BigQuery Dataset ID (default: trips_data)"
    echo "  TABLE_ID      - BigQuery Table ID (default: trips)"
    echo "  BUCKET_NAME   - GCS Bucket Name (required for gcs method)"
}

# Get method from second argument
METHOD="${2:-direct}"

case $METHOD in
    "direct")
        echo -e "${YELLOW}Method: Direct import using bq load${NC}"
        echo ""

        # Create dataset if it doesn't exist
        echo "Creating dataset if it doesn't exist..."
        bq mk --dataset --location=US "$PROJECT_ID:$DATASET_ID" 2>/dev/null || true

        # Import CSV files
        echo "Importing CSV files..."
        for csv_file in "$CSV_FOLDER"/*.csv; do
            if [ -f "$csv_file" ]; then
                echo "Processing: $(basename "$csv_file")"
                bq load --source_format=CSV \
                    --skip_leading_rows=1 \
                    --field_delimiter=, \
                    --quote="" \
                    --replace=false \
                    "$PROJECT_ID.$DATASET_ID.$TABLE_ID" \
                    "$csv_file" \
                    "user_id:STRING,trip_start_time:TIMESTAMP,trip_end_time:TIMESTAMP,start_lat:FLOAT,start_lng:FLOAT,end_lat:FLOAT,end_lng:FLOAT"
            fi
        done
        ;;

    "gcs")
        echo -e "${YELLOW}Method: Upload to GCS first, then import${NC}"
        echo ""

        if [ -z "$BUCKET_NAME" ] || [ "$BUCKET_NAME" = "your-bucket-name" ]; then
            echo -e "${RED}Error: BUCKET_NAME environment variable not set.${NC}"
            echo "Please set BUCKET_NAME to your GCS bucket name."
            exit 1
        fi

        # Check if gsutil is available
        if ! command -v gsutil &> /dev/null; then
            echo -e "${RED}Error: gsutil command not found. Please install Google Cloud SDK.${NC}"
            exit 1
        fi

        # Create bucket if it doesn't exist
        echo "Creating GCS bucket if it doesn't exist..."
        gsutil mb "gs://$BUCKET_NAME" 2>/dev/null || true

        # Upload CSV files to GCS
        echo "Uploading CSV files to GCS..."
        gsutil -m cp "$CSV_FOLDER"/*.csv "gs://$BUCKET_NAME/trips/"

        # Create dataset if it doesn't exist
        echo "Creating dataset if it doesn't exist..."
        bq mk --dataset --location=US "$PROJECT_ID:$DATASET_ID" 2>/dev/null || true

        # Import from GCS
        echo "Importing from GCS to BigQuery..."
        bq load --source_format=CSV \
            --skip_leading_rows=1 \
            --field_delimiter=, \
            --quote="" \
            "$PROJECT_ID.$DATASET_ID.$TABLE_ID" \
            "gs://$BUCKET_NAME/trips/*.csv" \
            "user_id:STRING,trip_start_time:TIMESTAMP,trip_end_time:TIMESTAMP,start_lat:FLOAT,start_lng:FLOAT,end_lat:FLOAT,end_lng:FLOAT"
        ;;

    "python")
        echo -e "${YELLOW}Method: Python script with pandas${NC}"
        echo ""

        # Check if Python script exists
        if [ ! -f "import_csv_to_bigquery.py" ]; then
            echo -e "${RED}Error: import_csv_to_bigquery.py not found in current directory.${NC}"
            exit 1
        fi

        # Run Python script
        echo "Running Python import script..."
        python3 import_csv_to_bigquery.py \
            --project-id "$PROJECT_ID" \
            --dataset-id "$DATASET_ID" \
            --table-id "$TABLE_ID" \
            --csv-folder "$CSV_FOLDER" \
            --method 1
        ;;

    "help"|"-h"|"--help")
        show_usage
        exit 0
        ;;

    *)
        echo -e "${RED}Error: Unknown method '$METHOD'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Import completed successfully!${NC}"
echo ""
echo "You can now query your data:"
echo "bq query --use_legacy_sql=false \"SELECT COUNT(*) FROM \`$PROJECT_ID.$DATASET_ID.$TABLE_ID\`\""
echo ""
echo "Or view in BigQuery Console:"
echo "https://console.cloud.google.com/bigquery?project=$PROJECT_ID"
