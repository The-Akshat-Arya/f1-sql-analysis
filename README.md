# F1 SQL Analytics (1950–2024), 7,01,000+ records.

## Project Overview

A MySQL analytics project built on 75 seasons of Formula 1 history — roughly 700,000 records across 14 tables. Rather than working with the raw CSVs as flat files, the project loads them into a proper relational schema and uses SQL to answer real questions about championships, drivers, constructors and race performance.

The workflow covers schema design and data ingestion, analytical querying, database programmability (views and stored procedures), and query optimization backed by `EXPLAIN`.

## Questions the Analysis Answers

- How close were the tightest championship battles, and how large was the biggest margin?
- Who has the most race wins of all time?
- Which constructors win and podium most often?
- How well do drivers convert pole positions into wins?
- Which constructors are most reliable, and where do they DNF most?
- How do teammates compare head-to-head at the same constructor?
- How are Grand Prix and sprint points combined into a running championship total?
- Do drivers who gain the most grid positions actually overtake the most?
- What does pit-stop performance look like once outliers are removed?
- How consistent are drivers' lap times within a race?

## Database Architecture

14 interconnected tables, built with primary/foreign key relationships:

| Table | Rows | Description |
|---|---:|---|
| `circuits` | 77 | Circuit and location information |
| `seasons` | 75 | Championship seasons |
| `status` | 139 | Race-result status classifications |
| `drivers` | 861 | Driver information |
| `constructors` | 212 | Constructor/team information |
| `races` | 1,125 | Race calendar and event information |
| `results` | 26,759 | Grand Prix results |
| `sprint_results` | 360 | Sprint race results |
| `qualifying` | 10,494 | Qualifying session results |
| `lap_times` | 589,081 | Driver lap-time records |
| `pit_stops` | 11,371 | Pit-stop records |
| `driver_standings` | 34,863 | Driver championship standings |
| `constructor_standings` | 13,391 | Constructor championship standings |
| `constructor_results` | 12,625 | Constructor race results |

Core relationship chain: **Seasons → Races → Results → Drivers / Constructors**, with circuits, qualifying, sprint results, lap times, pit stops and both standings tables joined in around it.

## Data Validation

Before any analysis, the database was checked against the source CSVs: row-count reconciliation, duplicate primary keys, foreign-key orphans, nulls and literal `\N` values, negative values, and encoding/line-ending issues. All 14 tables matched their CSV row counts, with no duplicate keys or orphaned relationships found.

One caveat worth flagging: early F1 seasons used dropped-score systems, where only a driver's best N results counted toward the title. A plain `SUM()` of every race result won't always match the historical standings — that's expected, not a data error.

## Analytical Modules

| # | Module | Technique | Key finding |
|---:|---|---|---|
| 1 | Championship winners & title margins | CTE, `ROW_NUMBER()`, `PARTITION BY` | 1984 (Lauda vs Prost) decided by **0.5 points** — the tightest in the dataset. 2023 (Verstappen vs Pérez) had the widest margin at **290**. |
| 2 | All-time driver wins | `DENSE_RANK()` | Hamilton leads with **105** wins, Schumacher **91**, Verstappen **63**. |
| 3 | Constructor wins & podiums | Conditional aggregation | Historical constructor identities are fragmented across multiple records for the same team in different eras. |
| 4 | Pole-to-win conversion | CTE, `LEFT JOIN`, `COALESCE()` | Pole share and win-conversion rate are clearly distinct — dominant qualifiers don't always convert. Minimum 10 poles applied to avoid small-sample noise. |
| 5 | Constructor reliability / DNF rate | `CASE`, `HAVING` | Filtering on aggregated DNF rate (`HAVING`) versus filtering raw rows (`WHERE`) — the module doubles as a working example of the difference. |
| 6 | Teammate head-to-head | Self-JOIN on `raceId` + `constructorId` | `r1.driverId < r2.driverId` avoids counting each pairing twice. |
| 7 | 2021 championship running total | `UNION ALL`, windowed `SUM()` | Combining Grand Prix and sprint points confirms Verstappen's 395.5 vs Hamilton's 387.5 — an 8-point title margin. |
| 8 | Average grid positions gained | `AVG()`, `HAVING`, min. 50 races | Big gains don't always mean better overtaking — in high-attrition races, drivers can rise simply because others retire. |
| 9 | Pit-stop duration | Aggregation, outlier filtering | Raw data has extreme outliers; excluding stops ≥100s puts most constructors in the 20–25s range. |
| 10 | Lap-time consistency | `LAG()`, `STDDEV_POP()` | Lap-to-lap deltas per driver, measured via population standard deviation, min. 40 observations. |

## Views & Stored Procedures

**`driver_career_stats`** — a view combining race and sprint points, wins and podiums per driver.
```sql
SELECT * FROM driver_career_stats ORDER BY total_points DESC LIMIT 20;
```

**`GetDriverCareerStats(name)`** — pattern-matches a driver name against the view above.
```sql
CALL GetDriverCareerStats('Hamilton');
```

**`GetSeasonChampion(year, OUT champion, OUT points)`** — returns a season's champion via output parameters.
```sql
CALL GetSeasonChampion(2021, @champ, @pts);
SELECT @champ, @pts;
-- Max Verstappen | 395.50
```

## Query Performance & Indexing

Every optimization followed the same process: baseline `EXPLAIN`, identify the bottleneck, add a targeted index, re-run, compare — and only keep the index if the plan actually improved.

| Query | Before | After | Change |
|---|---|---|---|
| Driver win count (`position = 1`) | 26,881 rows scanned on the `driverId` index | 1,128 rows, using a new composite index on `(position, driverId)` | ~96% fewer rows scanned |
| Teammate self-join | ~23-row estimated lookup | ~2-row estimated lookup, using a composite index on `(raceId, constructorId, driverId)` | ~91% smaller lookup |
| Lap-time `LAG()` window | `ORDER BY raceId, driverId, lap` already uses the primary key | Still shows `Using filesort` for the window function | No index added — see note below |

The lap-time case is worth calling out on its own: `lap_times` already has a primary key of `(raceId, driverId, lap)`, matching the window function's partition and order columns exactly — but MySQL still filesorts for the window function itself. Matching column order in an index doesn't guarantee it gets used for window-function execution, so no redundant index was added here.

## Key Insights

- 1984 is the closest title fight in the dataset (0.5 points); 2023 is the widest (290 points).
- Hamilton's 105 wins are the most of any driver in the dataset, ahead of Schumacher's 91.
- Pole position and race wins are related but distinct — conversion rate varies a lot between drivers.
- Constructor identity isn't always a single clean key across F1 history, which affects any "all-time constructor" comparison.
- Grid-position gains need to be read alongside attrition, not as a pure overtaking metric.
- Composite indexes cut estimated row counts by 90%+ on two of the three queries tested — but an index only helps when the engine can actually use it for the specific operation, as the lap-time case shows.

## Repository Structure

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

- **`f1.sql`** — creates the database and schema, sets up keys, loads all 14 CSVs via `LOAD DATA LOCAL INFILE`.
- **`f1_analysis.sql`** — the ten analytical modules above, in order.
- **`f1_view_procedures.sql`** — `driver_career_stats`, `GetDriverCareerStats`, `GetSeasonChampion`.
- **`f1_performance.sql`** — baseline and post-index `EXPLAIN` output for all three optimizations.

## How to Run

1. Run `f1.sql` to create the database and load the data. Update the `LOAD DATA LOCAL INFILE` paths to point at your local `f1_data/` folder.
2. Run `f1_analysis.sql` for the ten analytical modules.
3. Run `f1_view_procedures.sql` to create the view and stored procedures.
4. Run `f1_performance.sql` to reproduce the indexing and `EXPLAIN` comparisons.

## Technologies

MySQL, MySQL Workbench, SQL (CTEs, window functions, stored procedures, views, composite indexing, `EXPLAIN`), Visual Studio Code, Git, GitHub.

## Author

**Akshat Arya**

Data analytics learner developing skills in Python, SQL, Excel, Power BI and business analysis.
