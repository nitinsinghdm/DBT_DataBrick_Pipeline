# dbt Databricks Data Pipeline

## 📌 Project Overview

This project demonstrates an end-to-end modern data engineering pipeline built using **dbt (data build tool)** and **Databricks**. It implements a **Medallion Architecture (Bronze → Silver → Gold)** to transform raw data into analytics-ready datasets.

The pipeline includes:
- Source ingestion from Databricks tables using `source()`
- Transformation using modular dbt models
- Data quality testing (unique, not_null, accepted_values, custom tests)
- Deduplication using window functions
- Aggregations and joins across multiple dimensions
- Historical tracking using **SCD Type 2 snapshots**
- Multi-environment setup (dev and prod)

The project is structured to reflect real-world production-grade data pipelines.

---

## 🏗️ Architecture Overview

<p align="center">
Databricks Source Tables<br><br>
⬇️<br><br>
<strong>Bronze Layer</strong><br>
<em>Raw Ingestion via source()</em><br><br>
⬇️<br><br>
<strong>Silver Layer</strong><br>
<em>Joins, Calculations, Transformations</em><br><br>
⬇️<br><br>
<strong>Gold Layer</strong><br>
<em>Business Logic + Deduplication</em><br><br>
⬇️<br><br>
<strong>Snapshots</strong><br>
<em>SCD Type 2 History Tracking</em>
</p>

---
## 📊 Source Data (Databricks)

The project uses structured source tables stored in Databricks:

- fact_sales – Sales transactions  
- fact_returns – Product returns  
- dim_customer – Customer details  
- dim_product – Product information  
- dim_store – Store data  
- dim_date – Date dimension  
- items – Snapshot / incremental dataset  

These tables are defined using dbt `source()` and form the foundation of the Bronze layer.

## 🛠️ Tech Stack

### Core Technologies
- **dbt (v1.11)** – Data transformation and modeling
- **Databricks (Lakehouse)** – Data storage and processing platform
- **SQL** – Data querying and transformation
- **Jinja** – Dynamic SQL templating in dbt

### Data Engineering Concepts
- **Medallion Architecture** – Bronze, Silver, Gold layers
- **SCD Type 2** – Historical data tracking using snapshots
- **Data Modeling** – Layered and modular transformations
- **Data Quality Testing** – Ensuring reliability with tests

### dbt Features Used
- **Models** – Structured transformations across layers
- **Sources (`source()`)** – External table ingestion
- **References (`ref()`)** – Dependency management between models
- **Macros** – Reusable SQL logic (e.g., `multiply`)
- **Snapshots** – Change data capture (SCD Type 2)
- **Seeds** – Static CSV data integration
- **Tests** – Built-in and custom validations

### Tools & Workflow
- **Git & GitHub** – Version control and project management
- **VS Code** – Development environment
- **dbt CLI** – Running and managing pipeline execution

### Data Processing Techniques
- **Window Functions** – Deduplication using `ROW_NUMBER()`
- **Joins & Aggregations** – Combining multiple datasets
- **Incremental Logic (Extendable)** – For scalable pipelines

---

## 📂 Project Structure

**dbt_project/**

- **models/**
  - **bronze/** – Raw ingestion models  
  - **silver/** – Transformations and joins  
  - **gold/** – Business logic models  
  - **source/** – Source definitions  

- **snapshots/** – SCD Type 2 snapshot logic  
- **seeds/** – Static CSV data  
- **macros/** – Reusable SQL logic  
- **tests/** – Data quality tests  
- **analyses/** – Exploration queries  

- **dbt_project.yml** – Model configurations


---

## 🔄 Data Pipeline Flow

### 1. Source Layer

Raw data is ingested directly from Databricks tables using dbt `source()`.

Example:
```sql
SELECT *
FROM {{ source('source', 'fact_sales') }}
```

### 2. Bronze Layer (Raw Data)

Each bronze model directly maps to a source table:

1. bronze_sales

2. bronze_product

3. bronze_customer

4. bronze_store

5. bronze_date

6. bronze_returns

Example:
```sql
SELECT *
FROM {{ source('source', 'dim_customer') }}
```
### 3. Silver Layer (Transformations)

The silver layer performs:

- Joins across tables
- Calculations using macros
- Aggregations

Example (core transformation):
```sql
{{ multiply('unit_price', 'quantity') }} as calculated_gross_amount
```
Full transformation:

- Joins sales + product + customer
- Groups by category and gender  
- Calculates total sales

### 4. Gold Layer (Business Logic)

Implements deduplication logic using window functions:
```sql
ROW_NUMBER() OVER (PARTITION BY id ORDER BY update_date DESC)
```
Final model keeps only latest records per ID.

### 5. Snapshots (SCD Type 2)

Tracks historical changes in data using dbt snapshots.

# ⚙️ Advanced dbt Features Used

## 🔹 Macros
```sql
{% macro multiply(col1, col2) %}
    {{ col1 }}*{{ col2 }}
{% endmacro %}
```
Usage:
```sql
{{ multiply('unit_price', 'quantity') }}
```
## 🔹 Dynamic Schema Handling
```sql
{% macro generate_schema_name(custom_schema_name, node) %}
    {% set default_schema = target.schema %}
    {% if custom_schema_name is none %}
        {{ default_schema }}
    {% else %}
        {{ custom_schema_name | trim }}
    {% endif %}
{% endmacro %}
```
## 🔹 Source Configuration
```yml
sources:
  - name: source
    catalog: '{{ target.catalog }}'
    schema: source
    tables:
      - name: fact_sales
      - name: fact_returns
      - name: dim_date
      - name: dim_store
      - name: dim_product
      - name: dim_customer
      - name: items
```
## 🔹 Snapshot (SCD Type 2)
```yml
snapshots:
  - name: gold_items
    relation: ref('source_gold_items')
    config:
      unique_key: id
      strategy: timestamp
      updated_at: update_date
```
## 🔹 Incremental Logic (Jinja)
```sql
{% if inc_flag == 1 %}
    WHERE date_sk > {{ last_load }}
{% endif %}
```
## 🔹 Seed Usage
```sql
SELECT * FROM {{ ref("lookups") }}
```
## 🔹 Jinja Example
```sql
{% set var_name = 'DBT Project' %}
{{ var_name }}
```
# 🧪 Data Quality Tests

Defined in properties.yml:

- unique
- not_null
- accepted_values
- custom test: generic_non_negative

Example:
```yml
- name: sales_id
  data_tests:
    - unique
    - not_null
```

# ⚙️ Configuration

## dbt Project Configuration

```yml
models:
  dbt_project:
    bronze:
      +materialized: table
      +schema: bronze
    silver:
      +materialized: table
      +schema: silver
    gold:
      +materialized: table
      +schema: gold
```
# 🧱 Environment Separation

- dbt_project → Development

- dbt_project_prod → Production

dbt dynamically switches catalogs using target.catalog.

# 🚀 Deployment Strategy

The project uses a multi-environment deployment approach:

- Development environment for testing (dbt_project)
- Production environment for final models (dbt_project_prod)

Models are promoted using:
```bash
dbt build --target prod
```
This setup is designed to be extended into a full CI/CD pipeline using tools like GitHub Actions or dbt Cloud.

# ▶️ How to Run the Project

- Install dependencies:
```bash
dbt deps
```
- Run models:
```bash
dbt run
```
- Run tests:
```bash
dbt test
```
- Run snapshots:
```bash
dbt snapshot
```
- Run full pipeline:
```bash
dbt build
```

# 📸 Screenshots

## Databricks Catalog

## dbt Lineage DAG

## Gold Layer Output

## Snapshot Table (SCD Type 2)

🚀 Key Highlights

- Built end-to-end dbt pipeline on Databricks
- Implemented Medallion Architecture (Bronze → Silver → Gold)
- Used macros for reusable calculations
- Applied window functions for deduplication
- Designed SCD Type 2 snapshot system
- Implemented robust data testing framework
- Structured project for scalability and modularity
- CI/CD - ready deployment structure

# 📈 Future Improvements

- Implement CI/CD using GitHub Actions
- Add orchestration (Airflow / dbt Cloud)
- Implement incremental models
- Add monitoring and alerting

# 👤 Author

Nitin Singh
Data Analytics & Data Engineering

⭐ If you like this project

Give it a star ⭐ on GitHub
