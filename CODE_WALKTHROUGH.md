# Cricket Pipeline - Complete Code Walkthrough

End-to-end explanation of how the entire data pipeline works.

---

## **Pipeline Flow Overview**

```
┌─────────────────┐
│  Cricbuzz API   │ ← Step 1: Extract data
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ CSV File (Local)│ ← Step 2: Create CSV locally
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  GCS Bucket     │ ← Step 3: Upload to cloud storage
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│Cloud Function   │ ← Step 4: Detect file upload (event trigger)
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Google         │ ← Step 5: Transform & load to BigQuery
│  Dataflow       │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   BigQuery      │ ← Step 6: Store processed data
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ Looker Studio   │ ← Step 7: Visualize data
└─────────────────┘
```

---

## **STEP 1: Data Extraction from Cricbuzz API**

### **Files**: `extract_data.py` and `extract_and_push_gcs.py`

#### **What it does:**
Fetches ODI (One Day International) batsmen rankings from Cricbuzz API.

#### **Code Breakdown:**

**Step 1.1: Setup API Connection**
```python
url = 'https://cricbuzz-cricket.p.rapidapi.com/stats/v1/rankings/batsmen'
headers = {
    "X-RapidAPI-Key": "YOUR_API_KEY",  # Authentication token from RapidAPI
    "X-RapidAPI-Host": "cricbuzz-cricket.p.rapidapi.com"  # API host
}
params = {
    'formatType': 'odi'  # Get ODI rankings (not T20 or Test)
}
```

**What this does:**
- `X-RapidAPI-Key`: Your authentication token (you get this when signing up on RapidAPI)
- `X-RapidAPI-Host`: Identifies which API endpoint to use
- `formatType='odi'`: Filters to only ODI format rankings

**Step 1.2: Make API Request**
```python
response = requests.get(url, headers=headers, params=params)
```

**What this does:**
- Sends HTTP GET request to Cricbuzz API
- Includes headers for authentication
- API returns JSON with all ODI batsmen rankings

**Step 1.3: Parse Response**
```python
if response.status_code == 200:  # Check if request was successful
    data = response.json().get('rank', [])  # Extract 'rank' array from JSON
```

**What this does:**
- Checks HTTP status code (200 = success)
- Extracts the 'rank' field from JSON response
- `response.json()` converts JSON string to Python dict
- `.get('rank', [])` safely gets the 'rank' array (returns empty list if not found)

**Example API Response Structure:**
```json
{
  "rank": [
    {
      "rank": "1",
      "name": "Virat Kohli",
      "country": "India",
      "rating": 895,
      ...other fields...
    },
    {
      "rank": "2",
      "name": "Steve Smith",
      "country": "Australia",
      ...
    }
  ]
}
```

**Step 1.4: Create CSV File**
```python
field_names = ['rank', 'name', 'country']  # Only these 3 fields needed

with open('batsmen_rankings.csv', 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=field_names)
    for entry in data:
        writer.writerow({field: entry.get(field) for field in field_names})
```

**What this does:**
- Creates CSV file with 3 columns: rank, name, country
- Loops through each batsman in the data
- `entry.get(field)` safely extracts each field (returns None if field missing)
- Writes each row to CSV

**Example CSV Output:**
```csv
1,Virat Kohli,India
2,Steve Smith,Australia
3,Babar Azam,Pakistan
...
```

---

## **STEP 2: Upload to Google Cloud Storage (GCS)**

### **File**: `extract_and_push_gcs.py` (lines 32-41)

#### **What it does:**
Takes the CSV file and uploads it to GCS bucket in the cloud.

#### **Code Breakdown:**

```python
from google.cloud import storage  # Import GCS client library

bucket_name = 'bkt-ranking-data'  # Target bucket name
storage_client = storage.Client()  # Create GCS client
bucket = storage_client.bucket(bucket_name)  # Get reference to bucket
destination_blob_name = f'{csv_filename}'  # Name of file in GCS

blob = bucket.blob(destination_blob_name)  # Create blob (file) reference
blob.upload_from_filename(csv_filename)  # Upload the file

print(f"File {csv_filename} uploaded to GCS bucket {bucket_name}")
```

**What happens:**
1. `storage.Client()` - Authenticates using default credentials
2. `bucket_client.bucket()` - Gets reference to the GCS bucket
3. `bucket.blob()` - Creates a reference to a file in the bucket
4. `blob.upload_from_filename()` - Uploads local file to cloud

**Result in GCS:**
```
gs://bkt-ranking-data/
  └── batsmen_rankings.csv
```

---

## **STEP 3: Cloud Function Trigger**

### **File**: `function.py`

#### **What it does:**
Detects when a file is uploaded to GCS and triggers the Dataflow job automatically.

#### **Code Breakdown:**

```python
def trigger_df_job(request):  # Triggered by Cloud Function event
    try:
        print("Starting Dataflow Job...")
        
        # Create Dataflow API client
        service = build("dataflow", "v1b3", cache_discovery=False)
        
        # Generate unique job name with timestamp
        job_name = f"bq-load-{int(time.time())}"
```

**What this does:**
- `trigger_df_job(request)` - Entry point for Cloud Function
- `build("dataflow", "v1b3")` - Creates client to communicate with Dataflow API
- `job_name = f"bq-load-{int(time.time())}"` - Creates unique job name (e.g., "bq-load-1687456789")

#### **Dataflow Job Configuration:**

```python
template_body = {
    "jobName": job_name,
    "parameters": {
        # Path to JavaScript transformation function in GCS
        "javascriptTextTransformGcsPath": "gs://batch09/udf.js",
        
        # Path to BigQuery schema file in GCS
        "JSONPath": "gs://batch09/bq.json",
        
        # Name of function to call in udf.js
        "javascriptTextTransformFunctionName": "transform",
        
        # Where to write processed data
        "outputTable": "batch-09-500405:batch_09_raw.batch_09_table",
        
        # Input CSV file location
        "inputFilePattern": "gs://batch09/batsmen_rankings.csv",
        
        # Temporary directory for staging data
        "bigQueryLoadingTemporaryDirectory": "gs://batch09/temp"
    },
    "environment": {
        # Service account for Dataflow to use
        "serviceAccountEmail": "dataflow-sa@batch-09-500405.iam.gserviceaccount.com",
        "tempLocation": "gs://batch09/temp"
    }
}
```

**Parameter Explanations:**

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `jobName` | Unique identifier for this job | bq-load-1687456789 |
| `javascriptTextTransformGcsPath` | Where transformation function is stored | gs://batch09/udf.js |
| `JSONPath` | Where BigQuery schema is stored | gs://batch09/bq.json |
| `outputTable` | Destination table in BigQuery | batch-09-500405:batch_09_raw.batch_09_table |
| `inputFilePattern` | Source CSV file | gs://batch09/batsmen_rankings.csv |
| `tempLocation` | Temporary storage for staging | gs://batch09/temp |

#### **Launch the Job:**

```python
request = (
    service.projects()
    .locations()
    .templates()
    .launch(
        projectId=PROJECT_ID,  # batch-09-500405
        location=REGION,  # us-central1
        gcsPath="gs://dataflow-templates-us-central1/latest/GCS_Text_to_BigQuery",
        body=template_body
    )
)

response = request.execute()  # Sends request to Dataflow API
print(response)  # Returns job ID and status
```

**What happens:**
1. Calls Google's Dataflow API
2. Uses pre-built "GCS_Text_to_BigQuery" template
3. Passes all parameters to the template
4. Dataflow service creates and starts the job

---

## **STEP 4: Data Transformation (UDF)**

### **File**: `udf.js`

#### **What it does:**
Transforms each CSV row into JSON format that BigQuery expects.

#### **Code Breakdown:**

```javascript
function transform(line) {
    // Input: "1,Virat Kohli,India"
    
    var values = line.split(',');
    // Result: ["1", "Virat Kohli", "India"]
    
    var obj = new Object();
    // Create empty object: {}
    
    obj.rank = values[0];      // obj.rank = "1"
    obj.name = values[1];      // obj.name = "Virat Kohli"
    obj.country = values[2];   // obj.country = "India"
    
    // Now obj = {rank: "1", name: "Virat Kohli", country: "India"}
    
    var jsonString = JSON.stringify(obj);
    // Convert to JSON string: '{"rank":"1","name":"Virat Kohli","country":"India"}'
    
    return jsonString;
}
```

**Transformation Process:**

```
INPUT (CSV Row):
  1,Virat Kohli,India

SPLIT by comma:
  ["1", "Virat Kohli", "India"]

CREATE OBJECT:
  {rank: "1", name: "Virat Kohli", country: "India"}

CONVERT TO JSON STRING:
  {"rank":"1","name":"Virat Kohli","country":"India"}

OUTPUT (One JSON object per line):
  {"rank":"1","name":"Virat Kohli","country":"India"}
```

**Why this is needed:**
- BigQuery needs JSON format for structured data
- CSV is just text, JSON is structured
- This function runs on every CSV row in Dataflow

---

## **STEP 5: BigQuery Schema Definition**

### **File**: `bq.json`

#### **What it does:**
Defines the table structure in BigQuery - what columns exist and their data types.

#### **Code:**

```json
{
    "BigQuery Schema": [
        {
            "name": "rank",
            "type": "STRING"
        },
        {
            "name": "name",
            "type": "STRING"
        },
        {
            "name": "country",
            "type": "STRING"
        }
    ]
}
```

#### **Explanation:**

| Column | Type | Description |
|--------|------|-------------|
| `rank` | STRING | Batsman's ranking (e.g., "1", "2", "3") |
| `name` | STRING | Batsman's full name (e.g., "Virat Kohli") |
| `country` | STRING | Country code/name (e.g., "India") |

**Why STRING for rank?**
- Rank could be 1, 2, 3...100+
- Could also be ranges like "1-10", "11-20"
- STRING is flexible, can store any text

**BigQuery Table Created:**
```sql
CREATE TABLE batch_09_raw.batch_09_table (
    rank STRING,
    name STRING,
    country STRING
);
```

---

## **STEP 6: Complete Data Flow in Dataflow**

### **What Dataflow Does:**

```
INPUT: gs://batch09/batsmen_rankings.csv
  │
  ├─ Read CSV file (each line)
  │   Line: "1,Virat Kohli,India"
  │
  ├─ Transform using UDF (udf.js)
  │   Function: transform(line)
  │   Output: {"rank":"1","name":"Virat Kohli","country":"India"}
  │
  ├─ Validate against schema (bq.json)
  │   Check: Has rank, name, country columns?
  │   Check: All values are strings?
  │
  ├─ Stage in temporary directory
  │   Location: gs://batch09/temp/
  │
  └─ Write to BigQuery
      Table: batch-09-500405:batch_09_raw.batch_09_table
      
OUTPUT: BigQuery Table with all rows loaded
```

---

## **STEP 7: Apache Airflow Orchestration (Optional)**

### **File**: `dag.py`

#### **What it does:**
Schedules the data extraction to run automatically every day.

#### **Code Breakdown:**

```python
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash_operator import BashOperator

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 12, 18),  # When to start scheduling
    'depends_on_past': False,  # Don't wait for previous runs
    'email': ['vishal.bulbule@techtrapture.com'],  # Alert email
    'email_on_failure': False,  # Don't email on success
    'retries': 1,  # Retry failed task once
    'retry_delay': timedelta(minutes=5),  # Wait 5 min before retry
}

dag = DAG(
    'fetch_cricket_stats',  # DAG name
    default_args=default_args,
    description='Runs an external Python script',
    schedule_interval='@daily',  # Run once per day at midnight
    catchup=False  # Don't backfill past dates
)

with dag:
    run_script_task = BashOperator(
        task_id='run_script',
        bash_command='python /home/airflow/gcs/dags/scripts/extract_and_push_gcs.py'
    )
```

#### **How it works:**

```
Airflow Scheduler (runs continuously)
    │
    ├─ Checks: Is it midnight?
    │
    ├─ If YES: Trigger BashOperator
    │
    └─ Executes: python extract_and_push_gcs.py
        ├─ Fetches data from Cricbuzz API
        ├─ Creates CSV locally
        ├─ Uploads to GCS
        ├─ Cloud Function detects upload
        ├─ Dataflow job starts
        └─ Data loads to BigQuery
```

**Airflow Scheduling:**
- `@daily` = Run at 00:00 (midnight) every day
- Alternative schedules:
  - `@hourly` - Every hour
  - `0 9 * * *` - At 9 AM every day (cron syntax)
  - `0 */4 * * *` - Every 4 hours

---

## **Complete End-to-End Timeline**

### **Example: June 25, 2026**

```
00:00 (Midnight) - Airflow Scheduler
  └─ Triggers DAG
      └─ Executes extract_and_push_gcs.py

00:01 - extract_and_push_gcs.py Starts
  ├─ Calls Cricbuzz API
  │  Request: GET /stats/v1/rankings/batsmen?formatType=odi
  │  Response: JSON with 100 batsmen rankings
  │
  ├─ Creates CSV File
  │  File: batsmen_rankings.csv
  │  Size: ~5 KB
  │  Rows: ~100
  │
  └─ Uploads to GCS
     Destination: gs://batch09/batsmen_rankings.csv
     Time: ~2 seconds

00:03 - Cloud Function Detects Upload
  ├─ Event: google.storage.object.finalize
  ├─ Triggered by: gs://batch09/batsmen_rankings.csv
  └─ Calls: function.py trigger_df_job()

00:04 - Dataflow Job Starts
  ├─ Job Name: bq-load-1687411440
  ├─ Template: GCS_Text_to_BigQuery
  ├─ Region: us-central1
  │
  ├─ Read from: gs://batch09/batsmen_rankings.csv
  ├─ Transform: Each row via udf.js
  ├─ Validate: Against bq.json schema
  └─ Write to: BigQuery table

00:08 - Dataflow Job Completes
  ├─ Status: SUCCESS
  ├─ Rows Processed: 100
  ├─ Errors: 0
  └─ Data loaded to BigQuery

00:10 - Data Available in BigQuery
  ├─ Table: batch_09_raw.batch_09_table
  ├─ New rows: 100
  └─ Ready for Looker Studio

00:15 - Looker Studio Dashboard Updates
  ├─ Refreshes automatically
  ├─ Shows latest rankings
  └─ Available for viewing

NEXT DAY (00:00) - Process Repeats
  └─ Another Airflow trigger...
```

---

## **Data Quality at Each Stage**

### **Stage 1: API Response**
```
Status: 200 OK ✓
Data: Valid JSON ✓
Fields: rank, name, country present ✓
```

### **Stage 2: CSV File**
```
Format: Valid CSV ✓
Encoding: UTF-8 ✓
Rows: 100 records ✓
Missing: No headers (comment on line 25)
```

### **Stage 3: GCS Upload**
```
Bucket: gs://batch09 ✓
File: batsmen_rankings.csv ✓
Permissions: Cloud Function can read ✓
```

### **Stage 4: Dataflow Transformation**
```
Input rows: 100
Transform: Each row via udf.js ✓
Output format: Valid JSON ✓
Schema validation: Passes bq.json ✓
```

### **Stage 5: BigQuery**
```
Table: batch_09_table ✓
Columns: rank, name, country ✓
Data types: All STRING ✓
Rows inserted: 100 ✓
```

---

## **Error Handling**

### **What happens if API fails (403 error)?**
```python
if response.status_code == 200:
    # Process data
else:
    print("Failed to fetch data:", response.status_code)
    # Script exits, no CSV created, no upload
    # Cloud Function never triggered
    # Looker data doesn't update
```

### **What happens if GCS upload fails?**
```python
try:
    blob.upload_from_filename(csv_filename)
except Exception as e:
    print(f"Upload failed: {e}")
    # Cloud Function not triggered
    # Data doesn't process
```

### **What happens if Dataflow fails?**
```python
except Exception as e:
    print(f"Dataflow launch failed: {str(e)}")
    return (f"Error: {str(e)}", 500)
    # Cloud Function returns error
    # BigQuery not updated
    # Looker shows stale data
```

---

## **Key Learnings**

✅ **API Integration**: How to authenticate and fetch data from external APIs  
✅ **Data Pipeline**: Multi-stage processing (Extract → Transform → Load)  
✅ **Cloud Services**: Using GCS, Dataflow, BigQuery together  
✅ **Event-Driven**: Cloud Function automatically triggers on file upload  
✅ **Transformation**: JavaScript UDF converts formats (CSV → JSON)  
✅ **Scheduling**: Airflow automates daily execution  
✅ **Error Handling**: Try-catch blocks prevent crashes  

---

## **Technologies Used**

| Technology | Purpose | In Code |
|------------|---------|---------|
| Python | Main scripting language | extract_*.py, dag.py |
| requests | HTTP library for API calls | `requests.get()` |
| google.cloud.storage | GCS client library | `storage.Client()` |
| googleapiclient | Dataflow API client | `build("dataflow")` |
| JavaScript | Data transformation | udf.js |
| JSON | Configuration format | bq.json |
| Airflow | Workflow orchestration | dag.py |
| Dataflow | Distributed processing | Triggered by function.py |
| BigQuery | Data warehouse | Destination table |

---

## **Next Steps to Run**

1. **Add RapidAPI Key** (Line 7 in extract_*.py)
2. **Create GCS Buckets** (gs://batch09/)
3. **Deploy Cloud Function** (function.py)
4. **Create BigQuery Table** (batch_09_raw.batch_09_table)
5. **Test Manually** (python extract_and_push_gcs.py)
6. **Deploy Airflow DAG** (Optional, for automation)
