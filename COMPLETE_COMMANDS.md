# Complete Resource Setup - Command Reference

All commands to set up the cricket pipeline infrastructure.

## Configuration Variables

```bash
PROJECT_ID="batch-09-500405"
REGION="us-central1"
ZONE="us-central1-a"
BUCKET_DATA="bkt-ranking-data"
BUCKET_METADATA="bkt-dataflow-metadata"
DATASET="cricket_dataset"
TABLE="icc_odi_batsman_ranking"
SERVICE_ACCOUNT="cricket-sa"
```

---

## STEP 1: Authentication & Project Setup

### Set Project
```bash
gcloud config set project batch-09-500405
```

### Verify Project
```bash
gcloud config get-value project
gcloud projects describe batch-09-500405
```

### Login
```bash
gcloud auth login
gcloud auth list
```

---

## STEP 2: Enable Required APIs

### Enable Storage API
```bash
gcloud services enable storage-api.googleapis.com --project=batch-09-500405
```

### Enable BigQuery API
```bash
gcloud services enable bigquery.googleapis.com --project=batch-09-500405
```

### Enable Dataflow API
```bash
gcloud services enable dataflow.googleapis.com --project=batch-09-500405
```

### Enable Cloud Functions API
```bash
gcloud services enable cloudfunctions.googleapis.com --project=batch-09-500405
```

### Enable IAM API
```bash
gcloud services enable iam.googleapis.com --project=batch-09-500405
```

### Enable Compute API
```bash
gcloud services enable compute.googleapis.com --project=batch-09-500405
```

### Enable All at Once
```bash
gcloud services enable \
    storage-api.googleapis.com \
    bigquery.googleapis.com \
    dataflow.googleapis.com \
    cloudfunctions.googleapis.com \
    iam.googleapis.com \
    compute.googleapis.com \
    --project=batch-09-500405
```

### Verify APIs Enabled
```bash
gcloud services list --enabled --project=batch-09-500405
```

---

## STEP 3: Create Service Account

### Create Service Account
```bash
gcloud iam service-accounts create cricket-sa \
    --display-name="Cricket Pipeline Service Account" \
    --project=batch-09-500405
```

### Get Service Account Email
```bash
gcloud iam service-accounts list --project=batch-09-500405
```

**Output will show**: `cricket-sa@batch-09-500405.iam.gserviceaccount.com`

### Verify Service Account
```bash
gcloud iam service-accounts describe cricket-sa@batch-09-500405.iam.gserviceaccount.com \
    --project=batch-09-500405
```

---

## STEP 4: Grant IAM Roles

### Grant Storage Admin
```bash
gcloud projects add-iam-policy-binding batch-09-500405 \
    --member="serviceAccount:cricket-sa@batch-09-500405.iam.gserviceaccount.com" \
    --role="roles/storage.admin"
```

### Grant BigQuery Admin
```bash
gcloud projects add-iam-policy-binding batch-09-500405 \
    --member="serviceAccount:cricket-sa@batch-09-500405.iam.gserviceaccount.com" \
    --role="roles/bigquery.admin"
```

### Grant Dataflow Admin
```bash
gcloud projects add-iam-policy-binding batch-09-500405 \
    --member="serviceAccount:cricket-sa@batch-09-500405.iam.gserviceaccount.com" \
    --role="roles/dataflow.admin"
```

### Grant Cloud Functions Developer
```bash
gcloud projects add-iam-policy-binding batch-09-500405 \
    --member="serviceAccount:cricket-sa@batch-09-500405.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.developer"
```

### Grant Service Account User
```bash
gcloud projects add-iam-policy-binding batch-09-500405 \
    --member="serviceAccount:cricket-sa@batch-09-500405.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

### Verify IAM Bindings
```bash
gcloud projects get-iam-policy batch-09-500405 \
    --flatten="bindings[].members" \
    --filter="bindings.members:cricket-sa*"
```

---

## STEP 5: Create GCS Buckets

### Create Data Bucket
```bash
gsutil mb \
    -p batch-09-500405 \
    -c STANDARD \
    -l us-central1 \
    gs://bkt-ranking-data/
```

### Create Metadata Bucket
```bash
gsutil mb \
    -p batch-09-500405 \
    -c STANDARD \
    -l us-central1 \
    gs://bkt-dataflow-metadata/
```

### List All Buckets
```bash
gsutil ls
```

### Get Bucket Details
```bash
gsutil ls -L gs://bkt-ranking-data/
gsutil ls -L gs://bkt-dataflow-metadata/
```

---

## STEP 6: Create Temporary Directories

### Create temp directory in metadata bucket
```bash
echo "" | gsutil cp - gs://bkt-dataflow-metadata/temp/.keep
```

### Verify directory
```bash
gsutil ls gs://bkt-dataflow-metadata/
```

---

## STEP 7: Upload Metadata Files

### Upload bq.json
```bash
gsutil cp bq.json gs://bkt-dataflow-metadata/
```

### Upload udf.js
```bash
gsutil cp udf.js gs://bkt-dataflow-metadata/
```

### Upload both files
```bash
gsutil cp bq.json udf.js gs://bkt-dataflow-metadata/
```

### Verify uploads
```bash
gsutil ls gs://bkt-dataflow-metadata/
```

### View file content
```bash
gsutil cat gs://bkt-dataflow-metadata/bq.json
gsutil cat gs://bkt-dataflow-metadata/udf.js
```

---

## STEP 8: Configure Bucket Versioning

### Enable versioning on data bucket
```bash
gsutil versioning set on gs://bkt-ranking-data/
```

### Enable versioning on metadata bucket
```bash
gsutil versioning set on gs://bkt-dataflow-metadata/
```

### Check versioning status
```bash
gsutil versioning get gs://bkt-ranking-data/
gsutil versioning get gs://bkt-dataflow-metadata/
```

---

## STEP 9: Create BigQuery Dataset

### Create dataset
```bash
bq mk \
    --dataset \
    --location=us-central1 \
    --description="Cricket statistics dataset" \
    --project_id=batch-09-500405 \
    cricket_dataset
```

### List datasets
```bash
bq ls --project_id=batch-09-500405
```

### Get dataset details
```bash
bq show --project_id=batch-09-500405 cricket_dataset
```

---

## STEP 10: Create BigQuery Table

### Create table with schema
```bash
bq mk \
    --table \
    --project_id=batch-09-500405 \
    --schema=bq.json \
    cricket_dataset.icc_odi_batsman_ranking
```

### Alternative: Create with inline schema
```bash
bq mk \
    --table \
    --project_id=batch-09-500405 \
    cricket_dataset.icc_odi_batsman_ranking \
    rank:STRING,name:STRING,country:STRING
```

### List tables in dataset
```bash
bq ls cricket_dataset --project_id=batch-09-500405
```

### Get table schema
```bash
bq show --schema cricket_dataset.icc_odi_batsman_ranking
```

### Get table details
```bash
bq show cricket_dataset.icc_odi_batsman_ranking
```

---

## STEP 11: Set Bucket Permissions

### Grant service account access to data bucket
```bash
gsutil iam ch \
    serviceAccount:cricket-sa@batch-09-500405.iam.gserviceaccount.com:objectAdmin \
    gs://bkt-ranking-data/
```

### Grant service account access to metadata bucket
```bash
gsutil iam ch \
    serviceAccount:cricket-sa@batch-09-500405.iam.gserviceaccount.com:objectAdmin \
    gs://bkt-dataflow-metadata/
```

### View bucket permissions
```bash
gsutil iam get gs://bkt-ranking-data/
gsutil iam get gs://bkt-dataflow-metadata/
```

---

## STEP 12: Verify All Resources

### List all buckets
```bash
gsutil ls
```

### List all datasets
```bash
bq ls --project_id=batch-09-500405
```

### List all tables
```bash
bq ls cricket_dataset
```

### Get row count
```bash
bq query --use_legacy_sql=false \
    "SELECT COUNT(*) as row_count FROM \`batch-09-500405.cricket_dataset.icc_odi_batsman_ranking\`"
```

### List service accounts
```bash
gcloud iam service-accounts list --project=batch-09-500405
```

### List enabled APIs
```bash
gcloud services list --enabled --project=batch-09-500405
```

---

## STEP 13: Upload Test Data

### Upload sample CSV to data bucket
```bash
gsutil cp batsmen_rankings.csv gs://bkt-ranking-data/
```

### Verify upload
```bash
gsutil ls -lh gs://bkt-ranking-data/
```

### View file content
```bash
gsutil cat gs://bkt-ranking-data/batsmen_rankings.csv | head -5
```

---

## STEP 14: Deploy Cloud Function

### Create function.py for Cloud Function
```bash
gcloud functions deploy trigger_df_job \
    --runtime python39 \
    --trigger-resource gs://bkt-ranking-data \
    --trigger-event google.storage.object.finalize \
    --entry-point trigger_df_job \
    --project=batch-09-500405 \
    --region=us-central1 \
    --service-account=cricket-sa@batch-09-500405.iam.gserviceaccount.com
```

### List deployed functions
```bash
gcloud functions list --project=batch-09-500405
```

### Get function details
```bash
gcloud functions describe trigger_df_job \
    --project=batch-09-500405 \
    --region=us-central1
```

### View function logs
```bash
gcloud functions logs read trigger_df_job \
    --project=batch-09-500405 \
    --region=us-central1 \
    --limit 50
```

---

## STEP 15: Test the Pipeline

### Run data extraction script
```bash
python extract_and_push_gcs.py
```

### Monitor Dataflow job
```bash
gcloud dataflow jobs list --project=batch-09-500405 --region=us-central1
```

### View specific job details
```bash
gcloud dataflow jobs describe JOB_ID \
    --project=batch-09-500405 \
    --region=us-central1
```

### Query BigQuery to verify data loaded
```bash
bq query --use_legacy_sql=false \
    "SELECT * FROM \`batch-09-500405.cricket_dataset.icc_odi_batsman_ranking\` LIMIT 10"
```

---

## Additional Useful Commands

### Delete resources (if needed)

#### Delete bucket
```bash
gsutil rb -f gs://bkt-ranking-data/
gsutil rb -f gs://bkt-dataflow-metadata/
```

#### Delete dataset (with tables)
```bash
bq rm -r -d -f cricket_dataset
```

#### Delete service account
```bash
gcloud iam service-accounts delete \
    cricket-sa@batch-09-500405.iam.gserviceaccount.com \
    --project=batch-09-500405
```

#### Delete Cloud Function
```bash
gcloud functions delete trigger_df_job \
    --project=batch-09-500405 \
    --region=us-central1
```

---

## Monitoring Commands

### Check bucket size
```bash
gsutil du -sh gs://bkt-ranking-data/
gsutil du -sh gs://bkt-dataflow-metadata/
```

### Check quota usage
```bash
gcloud compute project-info describe --project=batch-09-500405
```

### View BigQuery usage
```bash
bq show --project_id=batch-09-500405
```

### Get storage logs
```bash
gsutil logging get gs://bkt-ranking-data/
```

---

## Quick Setup (All at Once)

```bash
#!/bin/bash

PROJECT_ID="batch-09-500405"
REGION="us-central1"

# Set project
gcloud config set project $PROJECT_ID

# Enable APIs
gcloud services enable storage-api.googleapis.com bigquery.googleapis.com \
    dataflow.googleapis.com cloudfunctions.googleapis.com iam.googleapis.com

# Create service account
gcloud iam service-accounts create cricket-sa --display-name="Cricket SA"

# Grant roles
SA_EMAIL="cricket-sa@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" --role="roles/storage.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" --role="roles/bigquery.admin"

# Create buckets
gsutil mb -l $REGION gs://bkt-ranking-data/
gsutil mb -l $REGION gs://bkt-dataflow-metadata/

# Upload files
gsutil cp bq.json udf.js gs://bkt-dataflow-metadata/

# Create BigQuery resources
bq mk --dataset --location=$REGION cricket_dataset
bq mk --table cricket_dataset.icc_odi_batsman_ranking rank:STRING,name:STRING,country:STRING

echo "✓ All resources created!"
```

---

## Troubleshooting

### If authentication fails
```bash
gcloud auth login
gcloud auth application-default login
```

### If bucket creation fails
```bash
# Check if bucket already exists
gsutil ls -L gs://bkt-ranking-data/

# List all buckets in project
gsutil ls -p batch-09-500405
```

### If BigQuery access fails
```bash
# Check dataset permissions
bq show cricket_dataset

# Check table permissions
bq show cricket_dataset.icc_odi_batsman_ranking
```

### If service account fails
```bash
# List all service accounts
gcloud iam service-accounts list --project=batch-09-500405

# Check roles
gcloud projects get-iam-policy batch-09-500405
```
