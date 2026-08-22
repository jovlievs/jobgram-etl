# Job Aggregator ETL — Microsoft Fabric

End-to-end ETL pipeline for Uzbekistan's job market data, built on Microsoft Fabric with medallion architecture (Bronze → Silver → Gold).

7 raw CSV files containing job vacancies, companies, required skills, locations, and channels get cleaned, standardized, and loaded into a star schema for analytics.

## The Problem

The raw data is messy:
- **Scattered across files** — job name is in `jobs.csv`, location is in `job_locations.csv`, skills in `requirement_skills.csv`. You can't see the full picture without connecting them.
- **Salary chaos** — salary column has values like "10 000 000", "Kelishiladi", "$500", "3 mln", or just empty. Can't do math on that.
- **Skills packed together** — "Python, SQL, Power BI" sitting in one cell. Need them split for proper analysis.

## Architecture

```
Raw CSVs ──→ Bronze (as-is) ──→ Silver (cleaned) ──→ Gold (star schema)
```

### Bronze (`nb_bronze`)
Reads all CSVs from `Files/raw/` into Delta tables. Uses `multiLine` + `quote` + `escape` options to handle embedded newlines in fields.

### Silver (`nb_silver`)
- Text cleaning — trims whitespace, nullifies junk values ("n/a", "not specified", "null")
- Date casting — `try_cast` to standard date format
- Salary standardization — converts USD, RUB, hourly/daily/weekly/yearly rates into monthly UZS. Caps outliers at 100M
- Skills normalization — splits comma-separated skills into individual rows

### Gold (`nb_gold`)
- Dimension tables: `dim_locations`, `dim_occupations`, `dim_skills`, `dim_channels`
- Bridge table: `bridge_job_skills` (many-to-many between jobs and skills)
- Salary imputation — fills missing salaries with occupation average, then overall average
- Fact table: `fact_jobs` with foreign keys to all dimensions

## Star Schema

```
              dim_locations
                   |
dim_channels — fact_jobs — dim_occupations
                   |
           bridge_job_skills
                   |
              dim_skills
```

## Pipeline

Three notebooks chained sequentially in a Fabric pipeline:

```
run_bronze → run_silver → run_gold
```

## Business Questions

With the Gold layer ready, you can answer questions like:

- **Top skills in demand** — Which 5 skills are most requested in IT?
- **Regional salary gap** — How much does Tashkent pay vs other regions?
- **Golden occupations** — Which jobs have few vacancies but high salaries?
- **Channel quality** — Which Telegram channels post the best vacancies?

## How to Run

1. Create a Fabric Lakehouse
2. Upload the 7 CSV files to `Files/raw/`
3. Create 3 notebooks, paste code from `nb_bronze`, `nb_silver`, `nb_gold`
4. Attach all notebooks to the Lakehouse
5. Create a pipeline chaining the 3 notebooks
6. Run

## Data

Open data from the Uzbekistan job market — vacancies, companies, skills, and locations collected from Telegram channels.

## Credits

Project based on the Databek ETL series.

- Telegram: [@Databek](https://t.me/databek)
- Article: [Databek: ETL Journey (Part 2) — Job Aggregator](https://mensenvau.medium.com/databek-etl-journey-part-2-job-aggregator-fe0b115a29cd)
