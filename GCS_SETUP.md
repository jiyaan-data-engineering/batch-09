# Google Cloud Storage (GCS) Setup Guide

Complete guide to set up GCS buckets for the Cricket Pipeline.

## Prerequisites

1. **Install Google Cloud SDK**
   - Download: https://cloud.google.com/sdk/docs/install

2. **Authenticate**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

## Create Buckets

### **Main Buckets Needed**

| Bucket | Purpose |
|--------|---------|
| `bkt-ranking-data` | Store CSV data files |
| `bkt-dataflow-metadata` | Store configs (bq.json, udf.js) |

### **Create Buckets**

```bash
# Create main data bucket
gsutil mb gs://bkt-ranking-data/

# Create metadata bucket
gsutil mb gs://bkt-dataflow-metadata/

# Verify creation
gsutil ls
```

## Upload Files

```bash
# Upload schema definition
gsutil cp bq.json gs://bkt-dataflow-metadata/

# Upload transformation function
gsutil cp udf.js gs://bkt-dataflow-metadata/

# Verify
gsutil ls gs://bkt-dataflow-metadata/
```

## Common Commands

### **Upload**
```bash
gsutil cp batsmen_rankings.csv gs://bkt-ranking-data/
gsutil cp *.json *.js gs://bkt-dataflow-metadata/
```

### **List**
```bash
gsutil ls gs://bkt-ranking-data/
gsutil ls -lh gs://bkt-ranking-data/
gsutil du -sh gs://bkt-ranking-data/
```

### **Download**
```bash
gsutil cp gs://bkt-ranking-data/batsmen_rankings.csv ./
```

### **Delete**
```bash
gsutil rm gs://bkt-ranking-data/batsmen_rankings.csv
gsutil rb gs://bkt-ranking-data/
```

## Quick Setup

```bash
#!/bin/bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gsutil mb gs://bkt-ranking-data/
gsutil mb gs://bkt-dataflow-metadata/
gsutil cp bq.json gs://bkt-dataflow-metadata/
gsutil cp udf.js gs://bkt-dataflow-metadata/
gsutil ls
```

## References

- [gsutil Documentation](https://cloud.google.com/storage/docs/gsutil)
- [Cloud Storage Pricing](https://cloud.google.com/storage/pricing)
- [IAM Roles](https://cloud.google.com/storage/docs/access-control/iam-roles)
