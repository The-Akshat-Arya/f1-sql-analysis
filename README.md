# Formula 1 Race Analytics & SQL Performance Engineering

## Project Overview

A comprehensive **MySQL-based Formula 1 analytics project** covering **75 seasons of Formula 1 history from 1950–2024**.

Rather than treating the dataset as a collection of independent CSV files, this project builds a structured **relational database** and uses advanced SQL to transform historical race data into analytical insights.

The project covers the complete workflow from **database schema design and data ingestion to analytical querying, database programmability and query optimization**.

### What this project demonstrates

* Relational database design
* Primary & foreign key relationships
* CSV data ingestion with `LOAD DATA LOCAL INFILE`
* Data-quality validation
* Complex multi-table `JOIN`s
* Common Table Expressions (CTEs)
* Conditional aggregation
* Self-JOIN analysis
* Window functions
* `ROW_NUMBER()`
* `DENSE_RANK()`
* `LAG()`
* `UNION ALL`
* SQL Views
* Stored Procedures
* Composite indexing
* Covering-index behaviour
* Execution-plan analysis with `EXPLAIN`
* Query optimization

---

## Project Objectives

### Formula 1 Analysis

The database is used to investigate:

* Championship battles and title margins
* Driver race victories
* Constructor wins and podiums
* Pole-position conversion
* Constructor reliability
* Teammate head-to-head performance
* Championship progression
* Grid-position gains
* Pit-stop performance
* Lap-time consistency

### Database Engineering

The project also demonstrates how a relational database can be used beyond basic `SELECT` queries through:

* Reusable SQL Views
* Parameterized Stored Procedures
* Composite indexes
* Execution-plan comparison
* Query optimization
* Data integrity validation

---

# Database Architecture

The database contains **14 interconnected tables** representing different aspects of Formula 1.

| Table                   |    Rows | Description                         |
| ----------------------- | ------: | ----------------------------------- |
| `circuits`              |      77 | Circuit and location information    |
| `seasons`               |      75 | Championship seasons                |
| `status`                |     139 | Race-result status classifications  |
| `drivers`               |     861 | Driver information                  |
| `constructors`          |     212 | Constructor/team information        |
| `races`                 |   1,125 | Race calendar and event information |
| `results`               |  26,759 | Grand Prix results                  |
| `sprint_results`        |     360 | Sprint race results                 |
| `qualifying`            |  10,494 | Qualifying session results          |
| `lap_times`             | 589,081 | Driver lap-time records             |
| `pit_stops`             |  11,371 | Pit-stop records                    |
| `driver_standings`      |  34,863 | Driver championship standings       |
| `constructor_standings` |  13,391 | Constructor championship standings  |
| `constructor_results`   |  12,625 | Constructor race results            |

The core relationships connect:

**Seasons → Races → Results → Drivers / Constructors**

with additional relationships for:

* Circuits
* Qualifying
* Sprint results
* Lap times
* Pit stops
* Driver standings
* Constructor standings
* Race-result status

Primary keys and foreign keys are used to maintain relational integrity throughout the database.

---

# Dataset

The project uses historical Formula 1 data covering the **1950–2024 seasons**.

### Dataset Scale

* **75** seasons
* **1,125** races
* **861** drivers
* **212** constructors
* **77** circuits
* **26,759** race results
* **360** sprint results
* **10,494** qualifying records
* **589,081** lap-time records
* **11,371** pit stops
* **34,863** driver-standing records
* **13,391** constructor-standing records
* **12,625** constructor-result records

The original CSV files are stored inside the `f1_data/` directory.

---

# Data Validation

Before beginning the analytical phase, the database was validated against the source data.

Validation included:

* CSV-to-database row-count reconciliation
* Duplicate primary-key detection
* Foreign-key orphan detection
* NULL checks
* Literal `\N` checks
* Negative-value checks
* Character encoding validation
* Line-ending validation
* Referential-integrity checks

All **14 CSV row counts matched their corresponding MySQL table counts**.

No duplicate primary keys or orphaned relationships were found in the validation checks performed.

### Historical Scoring Rules

Historical championship points require additional context when compared with a simple sum of race-result points.

Earlier Formula 1 seasons used **dropped-score systems**, meaning only a specified number of a driver's best results could count toward the championship.

As a result, a direct sum of every race-result point is not always expected to equal the final historical championship standings.

---

# Analytical Modules

## 01 — Championship Winners & Title-Fight Closeness

The first analysis identifies the final race of every season and retrieves the final championship positions.

The query uses:

* CTEs
* `ROW_NUMBER()`
* `PARTITION BY`
* Window-function ranking
* Multi-table `JOIN`s

### Closest Championship

**1984 — Niki Lauda vs Alain Prost**

| Driver      | Points |
| ----------- | -----: |
| Niki Lauda  |     72 |
| Alain Prost |   71.5 |

**Margin: 0.5 points**

### 2021 Championship

| Driver         | Points |
| -------------- | -----: |
| Max Verstappen |  395.5 |
| Lewis Hamilton |  387.5 |

**Margin: 8 points**

### Largest Championship Margin

**2023 — Max Verstappen vs Sergio Pérez**

| Driver         | Points |
| -------------- | -----: |
| Max Verstappen |    575 |
| Sergio Pérez   |    285 |

**Margin: 290 points**

---

# 02 — All-Time Driver Wins

Driver victories were aggregated from the `results` table and ranked using `DENSE_RANK()`.

| Rank | Driver             | Wins |
| ---: | ------------------ | ---: |
|    1 | Lewis Hamilton     |  105 |
|    2 | Michael Schumacher |   91 |
|    3 | Max Verstappen     |   63 |
|    4 | Sebastian Vettel   |   53 |
|    5 | Alain Prost        |   51 |
|    6 | Ayrton Senna       |   41 |
|    7 | Fernando Alonso    |   32 |
|    8 | Nigel Mansell      |   31 |
|    9 | Jackie Stewart     |   27 |
|   10 | Niki Lauda         |   25 |
|   10 | Jim Clark          |   25 |

Using `DENSE_RANK()` preserves tied rankings without creating gaps in the ranking sequence.

---

# 03 — Constructor Wins & Podiums

Constructor performance was analysed using conditional aggregation.

The query calculates:

* Race victories
* Podium finishes
* Total result records

This analysis also exposed an important characteristic of historical Formula 1 datasets: constructor identities can be represented by separate records across different eras.

Historical constructor comparisons therefore need to account for how teams are represented in the underlying source data.

---

# 04 — Pole-to-Win Conversion

This analysis measures how effectively drivers converted **pole positions into race victories**.

The query combines:

* CTEs
* Aggregation
* `LEFT JOIN`
* `COALESCE()`
* Derived percentages

A minimum of **10 pole positions** was used to reduce the effect of extremely small samples.

The analysis demonstrates that qualifying dominance and race-winning conversion are distinct performance measures.

---

# 05 — Constructor Reliability & DNF Rate

Constructor reliability was examined by identifying result records without a finishing position.

The analysis uses:

* `CASE`
* `COUNT()`
* `GROUP BY`
* `HAVING`
* Percentage calculations

A minimum number of race entries was applied before comparing constructors.

This module also demonstrates the distinction between:

* `WHERE` — filtering rows before aggregation
* `HAVING` — filtering groups after aggregation

---

# 06 — Teammate Head-to-Head Analysis

A **self-JOIN** was used to compare teammates competing for the same constructor in the same race.

The relationship is established through:

* `raceId`
* `constructorId`

The condition:

```sql
r1.driverId < r2.driverId
```

prevents the same driver pairing from being counted twice.

The analysis calculates:

* Driver A wins
* Driver B wins
* Races contested together

This provides a practical example of using a self-JOIN to compare records within the same logical group.

---

# 07 — Championship Running Totals

The 2021 championship analysis combines Grand Prix and sprint points using:

```sql
UNION ALL
```

The combined results are grouped by race weekend and then processed using a cumulative window function.

Techniques demonstrated:

* `UNION ALL`
* CTEs
* `SUM()`
* Window functions
* `PARTITION BY`
* Ordered cumulative aggregation

### Final 2021 Championship Totals

| Driver         | Points |
| -------------- | -----: |
| Max Verstappen |  395.5 |
| Lewis Hamilton |  387.5 |

Including `sprint_results` is necessary for seasons where sprint events contribute championship points.

---

# 08 — Average Grid Positions Gained

Starting grid position was compared against finishing position using:

```text
grid - positionOrder
```

A positive value represents positions gained relative to the starting grid.

The analysis uses:

* `AVG()`
* `GROUP BY`
* `HAVING`
* Derived metrics

A minimum of **50 races** was required.

### Analytical Consideration

Large position gains do not automatically represent superior overtaking performance.

In high-attrition historical races, drivers who remain classified can move higher in the finishing order as competitors retire. This creates a potential **survivorship and attrition effect**.

---

# 09 — Pit-Stop Duration Analysis

Pit-stop records were joined back to constructors through race and driver relationships.

The initial analysis revealed extreme duration values in the raw dataset.

A diagnostic analysis examined:

* Average duration
* Minimum duration
* Maximum duration
* Number of stops

For the analytical comparison, pit-stop records of **100 seconds or more** were excluded.

After filtering, constructor averages generally fell within the **20–25 second range**.

The analysis treats the dataset's `milliseconds` measurement as pit-lane time rather than assuming that it represents only stationary tyre-change time.

---

# 10 — Lap-Time Consistency

Lap-time consistency was analysed using the `LAG()` window function.

For every driver within every race, the difference between consecutive laps was calculated.

Conceptually:

```text
Current Lap Time - Previous Lap Time
```

The resulting deltas were analysed using population standard deviation.

Techniques demonstrated:

* `LAG()`
* Window partitioning
* Window ordering
* `STDDEV_POP()`
* CTEs
* Multi-table `JOIN`s

A minimum of **40 lap-to-lap observations** was required.

---

# Views & Stored Procedures

The project extends beyond analytical queries by implementing reusable database objects.

## `driver_career_stats`

A reusable SQL View combining driver race and sprint performance.

| Metric         | Description                   |
| -------------- | ----------------------------- |
| `race_entries` | Number of race-result records |
| `wins`         | Grand Prix victories          |
| `podiums`      | Podium finishes               |
| `total_points` | Race points + sprint points   |

Example:

```sql
SELECT *
FROM driver_career_stats
ORDER BY total_points DESC
LIMIT 20;
```

---

## `GetDriverCareerStats`

A parameterized Stored Procedure that searches driver career statistics.

Example:

```sql
CALL GetDriverCareerStats('Hamilton');
```

Demonstrates:

* Input parameters
* Pattern matching
* Reusing a View
* Stored procedure logic

---

## `GetSeasonChampion`

A Stored Procedure accepting a season year and returning the champion and championship points through output parameters.

Example:

```sql
CALL GetSeasonChampion(2021, @champ, @pts);

SELECT @champ, @pts;
```

Example result:

```text
Max Verstappen | 395.50
```

Demonstrates:

* Input parameters
* Output parameters
* `SELECT ... INTO`
* Stored procedures
* Nested queries

---

# Query Performance Engineering

Performance optimization was treated as an evidence-based process.

Instead of adding indexes arbitrarily, execution plans were inspected using:

```sql
EXPLAIN
```

The workflow was:

1. Establish a baseline execution plan
2. Identify the bottleneck
3. Create a targeted index
4. Re-run the exact query
5. Compare execution plans
6. Keep the optimization only when the plan demonstrated a meaningful improvement

---

## Optimization 01 — Driver Win Count

Baseline query:

```sql
SELECT driverId, COUNT(*) AS wins
FROM results
WHERE position = 1
GROUP BY driverId;
```

### Before

```text
type: index
key: driverId
rows: 26,881
Extra: Using where
```

### Index Added

```sql
CREATE INDEX idx_results_position_driver
ON results (position, driverId);
```

### After

```text
type: ref
key: idx_results_position_driver
rows: 1,128
Extra: Using index
```

The estimated rows examined dropped from **26,881 to 1,128**, approximately a **95.8% reduction** in the optimizer's estimated row count.

The execution strategy also changed from scanning the existing `driverId` index and filtering rows to directly using the composite index on `position` and `driverId`.

---

# Optimization 02 — Teammate Self-JOIN

The teammate analysis initially relied on a single-column `raceId` lookup.

A composite index was introduced:

```sql
CREATE INDEX idx_results_race_constructor_driver
ON results (raceId, constructorId, driverId);
```

### Estimated Lookup

**Before:**

```text
23 rows
```

**After:**

```text
2 rows
```

The estimated lookup size decreased by approximately **91%**.

The composite index allows MySQL to use the race and constructor relationship before resolving the driver comparison.

---

# Optimization 03 — Lap-Time Window Function

The `lap_times` table already contains the composite primary key:

```text
PRIMARY KEY (raceId, driverId, lap)
```

A control query ordered by:

```sql
ORDER BY raceId, driverId, lap
```

was able to use the existing primary key.

However, the window-function query:

```sql
LAG(milliseconds) OVER (
    PARTITION BY raceId, driverId
    ORDER BY lap
)
```

still produced a plan containing:

```text
Using filesort
```

This provided an important database-engineering observation:

> Having an index whose column order matches a window function's partition and ordering columns does not guarantee that MySQL will use that ordering directly for the window-function execution plan.

No duplicate index was created because the required column order was already represented by the existing primary key.

---

# Key Findings

## Formula 1

* **1984** produced the closest championship margin in the dataset at **0.5 points**.
* **2021** ended with an **8-point** championship difference between Max Verstappen and Lewis Hamilton.
* **2023** produced the largest identified championship margin at **290 points**.
* Lewis Hamilton has **105 race victories** in the analysed dataset.
* Pole position does not automatically translate into race victory.
* Historical constructor identities can be fragmented across multiple constructor records.
* Sprint results need to be incorporated into cumulative championship calculations for applicable seasons.
* Historical race attrition can influence grid-position gain metrics.
* Raw pit-stop data contains extreme observations requiring analytical treatment.
* Lap-time consistency can be quantified using window functions and statistical dispersion.

## SQL & Database Engineering

* Self-JOINs can compare records belonging to the same logical group.
* `DENSE_RANK()` handles tied rankings without ranking gaps.
* `LAG()` enables row-to-row comparisons within partitions.
* `UNION ALL` can combine different result streams into a unified analytical dataset.
* CTEs make complex multi-stage analytical queries easier to structure.
* Composite indexes can significantly alter MySQL execution plans.
* `EXPLAIN` provides evidence for evaluating index effectiveness.
* Existing primary keys should be evaluated before creating additional indexes.
* Index optimization should be based on execution plans rather than assumptions.

---

# SQL Concepts Demonstrated

### Relational Querying

* `INNER JOIN`
* `LEFT JOIN`
* Self-JOIN
* Foreign-key relationships
* Multi-table aggregation

### Aggregation

* `COUNT()`
* `SUM()`
* `AVG()`
* `MIN()`
* `MAX()`
* `STDDEV_POP()`
* Conditional aggregation
* `GROUP BY`
* `HAVING`

### Advanced SQL

* Common Table Expressions
* `UNION ALL`
* `CASE`
* `COALESCE()`
* `NULLIF()`
* Derived tables
* Nested queries

### Window Functions

* `ROW_NUMBER()`
* `DENSE_RANK()`
* `LAG()`
* `PARTITION BY`
* Ordered cumulative aggregation

### Database Programmability

* SQL Views
* Stored Procedures
* Input parameters
* Output parameters
* `SELECT ... INTO`

### Performance Engineering

* Composite indexes
* Covering-index behaviour
* `EXPLAIN`
* Execution-plan comparison
* Estimated row analysis
* Index selection

---

# Repository Structure

```text
f1-sql-analysis/
│
├── README.md
│
├── f1.sql
├── f1_analysis.sql
├── f1_view_procedures.sql
├── f1_performance.sql
│
└── f1_data/
    ├── circuits.csv
    ├── constructors.csv
    ├── constructor_results.csv
    ├── constructor_standings.csv
    ├── drivers.csv
    ├── driver_standings.csv
    ├── lap_times.csv
    ├── pit_stops.csv
    ├── qualifying.csv
    ├── races.csv
    ├── results.csv
    ├── seasons.csv
    ├── sprint_results.csv
    └── status.csv
```

---

# SQL File Guide

### `f1.sql`

Creates the `f1` database, defines the relational schema, establishes primary and foreign keys, and loads the Formula 1 CSV dataset.

### `f1_analysis.sql`

Contains the ten analytical modules:

1. Championship winners & title margins
2. All-time driver wins
3. Constructor wins & podiums
4. Pole-to-win conversion
5. Constructor reliability
6. Teammate head-to-head
7. Championship running totals
8. Average positions gained
9. Pit-stop analysis
10. Lap-time consistency

### `f1_view_procedures.sql`

Contains:

* `driver_career_stats`
* `GetDriverCareerStats`
* `GetSeasonChampion`

### `f1_performance.sql`

Contains:

* Baseline `EXPLAIN` queries
* Targeted composite indexes
* Post-index execution plans
* Performance comparisons

---

# How to Run

## 1. Create the Database

Run:

```text
f1.sql
```

This creates the database, tables, relationships and CSV data imports.

The `LOAD DATA LOCAL INFILE` paths inside the SQL script should point to the local `f1_data` directory.

## 2. Run the Analysis

Run:

```text
f1_analysis.sql
```

This executes the ten Formula 1 analytical modules.

## 3. Create Views & Procedures

Run:

```text
f1_view_procedures.sql
```

This creates the reusable View and Stored Procedures.

## 4. Run Performance Analysis

Run:

```text
f1_performance.sql
```

This contains the indexing and execution-plan analysis.

---

# Technologies

* **MySQL**
* **MySQL Workbench**
* **SQL**
* **Common Table Expressions**
* **Window Functions**
* **Stored Procedures**
* **SQL Views**
* **Composite Indexing**
* **EXPLAIN Query Analysis**
* **Visual Studio Code**
* **Git**
* **GitHub**

---

# Author

## Akshat Arya

**Data Analytics • SQL • Power BI • Excel**

I build data projects focused on transforming raw datasets into structured analysis, meaningful insights and practical analytical solutions.

This project represents hands-on work across:

* Relational database design
* Advanced SQL analytics
* Data validation
* Window functions
* Database programmability
* Query optimization
* Historical data analysis

### Project Focus

**Formula 1 Data → Relational Database → Advanced SQL → Analytical Insights → Database Engineering → Performance Optimization**

---

*Built with MySQL, SQL and a lot of Formula 1 data.*
