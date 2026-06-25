#!/bin/bash

################################################################################
# CRICKET PIPELINE - COMPLETE INFRASTRUCTURE SETUP
# This script creates ALL resources needed for the pipeline
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="batch-09-500405"
REGION="us-central1"
ZONE="us-central1-a"
BUCKET_DATA="bkt-ranking-data"
BUCKET_METADATA="bkt-dataflow-metadata"
DATASET="cricket_dataset"
TABLE="icc_odi_batsman_ranking"
SERVICE_ACCOUNT="cricket-sa"

echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   CRICKET PIPELINE - INFRASTRUCTURE SETUP              ║${NC}"
echo -e "${YELLOW}║   Project: $PROJECT_ID                    ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# STEP 1: AUTHENTICATION & PROJECT SETUP
# ============================================================================

echo -e "${GREEN}[STEP 1] Setting up authentication and project...${NC}"

gcloud auth login
gcloud config set project $PROJECT_ID

echo -e "${GREEN}✓ Project set to: $PROJECT_ID${NC}"
echo ""

# ============================================================================
# STEP 2: ENABLE REQUIRED APIS
# ============================================================================

echo -e "${GREEN}[STEP 2] Enabling required Google Cloud APIs...${NC}"

gcloud services enable storage-api.googleapis.com \
    --project=$PROJECT_ID

gcloud services enable bigquery.googleapis.com \
    --project=$PROJECT_ID

gcloud services enable dataflow.googleapis.com \
    --project=$PROJECT_ID

gcloud services enable cloudfunctions.googleapis.com \
    --project=$PROJECT_ID

gcloud services enable iam.googleapis.com \
    --project=$PROJECT_ID

gcloud services enable compute.googleapis.com \
    --project=$PROJECT_ID

echo -e "${GREEN}✓ All APIs enabled${NC}"
echo ""

# ============================================================================
# STEP 3: CREATE SERVICE ACCOUNT
# ============================================================================

echo -e "${GREEN}[STEP 3] Creating service account...${NC}"

gcloud iam service-accounts create $SERVICE_ACCOUNT \
    --display-name="Cricket Pipeline Service Account" \
    --project=$PROJECT_ID || echo "Service account may already exist"

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"

echo -e "${GREEN}✓ Service account: $SERVICE_ACCOUNT_EMAIL${NC}"
echo ""

# ============================================================================
# STEP 4: GRANT IAM ROLES TO SERVICE ACCOUNT
# ============================================================================

echo -e "${GREEN}[STEP 4] Granting IAM roles to service account...${NC}"

# Storage Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/storage.admin" \
    --condition=None

# BigQuery Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/bigquery.admin" \
    --condition=None

# Dataflow Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/dataflow.admin" \
    --condition=None

# Cloud Functions Developer
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/cloudfunctions.developer" \
    --condition=None

echo -e "${GREEN}✓ IAM roles granted${NC}"
echo ""

# ============================================================================
# STEP 5: CREATE GCS BUCKETS
# ============================================================================

echo -e "${GREEN}[STEP 5] Creating GCS buckets...${NC}"

# Create data bucket
gsutil mb \
    -p $PROJECT_ID \
    -c STANDARD \
    -l $REGION \
    "gs://${BUCKET_DATA}/" || echo "Bucket $BUCKET_DATA may already exist"

echo -e "${GREEN}✓ Created bucket: gs://${BUCKET_DATA}/$(NC)"

# Create metadata bucket
gsutil mb \
    -p $PROJECT_ID \
    -c STANDARD \
    -l $REGION \
    "gs://${BUCKET_METADATA}/" || echo "Bucket $BUCKET_METADATA may already exist"

echo -e "${GREEN}✓ Created bucket: gs://${BUCKET_METADATA}/${NC}"
echo ""

# ============================================================================
# STEP 6: CREATE TEMP DIRECTORIES IN GCS
# ============================================================================

echo -e "${GREEN}[STEP 6] Creating temporary directories...${NC}"

# Create temp folder for Dataflow staging
echo "" | gsutil cp - "gs://${BUCKET_METADATA}/temp/.keep"

echo -e "${GREEN}✓ Created temp directory: gs://${BUCKET_METADATA}/temp/${NC}"
echo ""

# ============================================================================
# STEP 7: UPLOAD METADATA FILES TO GCS
# ============================================================================

echo -e "${GREEN}[STEP 7] Uploading metadata files to GCS...${NC}"

# Upload bq.json
gsutil cp bq.json "gs://${BUCKET_METADATA}/"
echo -e "${GREEN}✓ Uploaded bq.json${NC}"

# Upload udf.js
gsutil cp udf.js "gs://${BUCKET_METADATA}/"
echo -e "${GREEN}✓ Uploaded udf.js${NC}"

echo ""

# ============================================================================
# STEP 8: CONFIGURE BUCKET VERSIONING
# ============================================================================

echo -e "${GREEN}[STEP 8] Configuring bucket versioning...${NC}"

# Enable versioning on data bucket
gsutil versioning set on "gs://${BUCKET_DATA}/"
echo -e "${GREEN}✓ Versioning enabled on ${BUCKET_DATA}${NC}"

# Enable versioning on metadata bucket
gsutil versioning set on "gs://${BUCKET_METADATA}/"
echo -e "${GREEN}✓ Versioning enabled on ${BUCKET_METADATA}${NC}"

echo ""

# ============================================================================
# STEP 9: CREATE BIGQUERY DATASET
# ============================================================================

echo -e "${GREEN}[STEP 9] Creating BigQuery dataset...${NC}"

bq mk \
    --dataset \
    --location=$REGION \
    --description="Cricket statistics dataset" \
    --project_id=$PROJECT_ID \
    $DATASET || echo "Dataset may already exist"

echo -e "${GREEN}✓ Created dataset: $DATASET${NC}"
echo ""

# ============================================================================
# STEP 10: CREATE BIGQUERY TABLE
# ============================================================================

echo -e "${GREEN}[STEP 10] Creating BigQuery table...${NC}"

bq mk \
    --table \
    --project_id=$PROJECT_ID \
    --schema=bq.json \
    "${DATASET}.${TABLE}" || echo "Table may already exist"

echo -e "${GREEN}✓ Created table: ${DATASET}.${TABLE}${NC}"
echo ""

# ============================================================================
# STEP 11: VERIFY ALL RESOURCES
# ============================================================================

echo -e "${GREEN}[STEP 11] Verifying all resources...${NC}"
echo ""

echo -e "${YELLOW}GCS Buckets:${NC}"
gsutil ls | grep -E "bkt-ranking-data|bkt-dataflow-metadata" || echo "Buckets found"
echo ""

echo -e "${YELLOW}BigQuery Datasets:${NC}"
bq ls | grep $DATASET || echo "Dataset found"
echo ""

echo -e "${YELLOW}BigQuery Tables:${NC}"
bq ls $DATASET | grep $TABLE || echo "Table found"
echo ""

echo -e "${YELLOW}Service Account:${NC}"
gcloud iam service-accounts list --filter="email:$SERVICE_ACCOUNT_EMAIL" --format="value(email)"
echo ""

# ============================================================================
# STEP 12: DISPLAY CONFIGURATION
# ============================================================================

echo -e "${GREEN}[STEP 12] Configuration Summary${NC}"
echo ""

cat << EOF
╔════════════════════════════════════════════════════════════╗
║              INFRASTRUCTURE SETUP COMPLETE                 ║
╚════════════════════════════════════════════════════════════╝

PROJECT CONFIGURATION:
  Project ID:           $PROJECT_ID
  Region:               $REGION
  Service Account:      $SERVICE_ACCOUNT_EMAIL

GCS BUCKETS:
  Data Bucket:          gs://${BUCKET_DATA}/
  Metadata Bucket:      gs://${BUCKET_METADATA}/

BIGQUERY:
  Dataset:              $DATASET
  Table:                ${TABLE}
  Full Path:            ${PROJECT_ID}:${DATASET}.${TABLE}

NEXT STEPS:
  1. Upload CSV data:
     gsutil cp batsmen_rankings.csv gs://${BUCKET_DATA}/

  2. Deploy Cloud Function:
     gcloud functions deploy trigger_df_job \
       --runtime python39 \
       --trigger-resource gs://${BUCKET_DATA} \
       --trigger-event google.storage.object.finalize \
       --entry-point trigger_df_job

  3. Test the pipeline:
     python extract_and_push_gcs.py

IMPORTANT FILES:
  Schema:   gs://${BUCKET_METADATA}/bq.json
  UDF:      gs://${BUCKET_METADATA}/udf.js
  Data:     gs://${BUCKET_DATA}/batsmen_rankings.csv

═══════════════════════════════════════════════════════════════
EOF

echo ""
echo -e "${GREEN}✓ All resources created successfully!${NC}"
echo ""
