# Architecture Diagram

```mermaid
graph LR
    A["🔗 Cricbuzz API<br/>ODI Rankings<br/>RapidAPI"]
    
    B["☁️ Google Cloud Storage<br/>bkt-ranking-data/<br/>batsmen_rankings.csv"]
    
    C["⚡ Cloud Function<br/>Event Trigger<br/>function.py"]
    
    D["🔄 Google Dataflow<br/>GCS_Text_to_BigQuery<br/>Apache Beam"]
    
    E["📊 Google BigQuery<br/>cricket_dataset<br/>icc_odi_batsman_ranking"]
    
    F["📈 Looker Studio<br/>Live Dashboard<br/>Visualization"]
    
    G["📄 Schema Config<br/>bq.json<br/>rank, name, country"]
    
    H["🔧 UDF Transform<br/>udf.js<br/>CSV → JSON"]
    
    I["📦 Metadata<br/>bkt-dataflow-metadata/<br/>Config & Temp"]
    
    J["🔗 Apache Airflow<br/>dag.py<br/>Schedule @daily"]
    
    A -->|extract_and_push_gcs.py| B
    B -->|file upload event| C
    C -->|launch job| D
    G -.->|schema definition| D
    H -.->|transformation| D
    I -.->|config & staging| D
    D -->|load data| E
    E -->|query data| F
    J -.->|trigger extraction| A
    
    style A fill:#4F46E5,stroke:#3730A3,color:#fff
    style B fill:#F59E0B,stroke:#D97706,color:#fff
    style C fill:#EC4899,stroke:#BE123C,color:#fff
    style D fill:#10B981,stroke:#059669,color:#fff
    style E fill:#8B5CF6,stroke:#6D28D9,color:#fff
    style F fill:#F97316,stroke:#C2410C,color:#fff
    style G fill:#06B6D4,stroke:#0891B2,color:#fff
    style H fill:#06B6D4,stroke:#0891B2,color:#fff
    style I fill:#06B6D4,stroke:#0891B2,color:#fff
    style J fill:#14B8A6,stroke:#0D9488,color:#fff
```

## Architecture Overview

### Data Flow Pipeline

1. **Data Extraction** → Cricbuzz API extracts ODI batsmen rankings
2. **Cloud Storage** → CSV uploaded to Google Cloud Storage
3. **Event Trigger** → Cloud Function detects file upload
4. **Processing** → Google Dataflow processes data using template
5. **Transformation** → JavaScript UDF converts CSV to JSON format
6. **Data Loading** → Transformed data loads into BigQuery
7. **Visualization** → Looker Studio queries BigQuery for dashboards

### Supporting Components

- **Schema Definition (bq.json)** → Defines BigQuery table structure
- **UDF Transformation (udf.js)** → Converts CSV rows to JSON objects
- **Metadata Storage** → Holds configuration and temporary files
- **Airflow DAG (dag.py)** → Schedules daily data extraction

### Technology Stack

| Component | Service | Purpose |
|-----------|---------|---------|
| Data Source | Cricbuzz API (RapidAPI) | Fetch cricket statistics |
| Storage | Google Cloud Storage | Store raw CSV data |
| Orchestration | Cloud Functions / Airflow | Trigger processing pipeline |
| Processing | Google Dataflow | Transform and load data |
| Data Warehouse | Google BigQuery | Store processed data |
| Visualization | Looker Studio | Create interactive dashboards |

