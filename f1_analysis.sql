use f1;
WITH final_races AS (
  SELECT year, round, raceId,
         ROW_NUMBER() OVER (PARTITION BY year ORDER BY round DESC) AS rn
  FROM races
),
season_final AS (
  SELECT year, raceId
  FROM final_races
  WHERE rn = 1
),
standings_ranked AS (
  SELECT sf.year, ds.driverId, ds.points,
         ROW_NUMBER() OVER (PARTITION BY sf.year ORDER BY ds.points DESC) AS finish_rank
  FROM season_final sf
  JOIN driver_standings ds ON ds.raceId = sf.raceId
)
SELECT
  sr1.year,
  CONCAT(d1.forename, ' ', d1.surname) AS champion,
  sr1.points AS champion_points,
  CONCAT(d2.forename, ' ', d2.surname) AS runner_up,
  sr2.points AS runner_up_points,
  sr1.points - sr2.points AS margin
FROM standings_ranked sr1
JOIN standings_ranked sr2 ON sr1.year = sr2.year AND sr2.finish_rank = 2
JOIN drivers d1 ON d1.driverId = sr1.driverId
JOIN drivers d2 ON d2.driverId = sr2.driverId
WHERE sr1.finish_rank = 1
ORDER BY margin ASC;



WITH win_counts AS (
  SELECT driverId, COUNT(*) AS wins
  FROM results
  WHERE position = 1
  GROUP BY driverId
)
SELECT
  DENSE_RANK() OVER (ORDER BY wins DESC) AS rnk,
  CONCAT(d.forename, ' ', d.surname) AS driver,
  wins
FROM win_counts wc
JOIN drivers d ON d.driverId = wc.driverId
ORDER BY wins DESC
LIMIT 20;



SELECT
  c.name AS constructor,
  COUNT(CASE WHEN r.position = 1 THEN 1 END) AS wins,
  COUNT(CASE WHEN r.position <= 3 THEN 1 END) AS podiums
FROM results r
JOIN constructors c ON c.constructorId = r.constructorId
GROUP BY c.constructorId, c.name
ORDER BY wins DESC
LIMIT 20;



WITH poles AS (
  SELECT driverId, COUNT(*) AS pole_count
  FROM results WHERE grid = 1
  GROUP BY driverId
),
pole_wins AS (
  SELECT driverId, COUNT(*) AS pole_win_count
  FROM results WHERE grid = 1 AND position = 1
  GROUP BY driverId
)
SELECT
  CONCAT(d.forename, ' ', d.surname) AS driver,
  p.pole_count,
  COALESCE(pw.pole_win_count, 0) AS converted_to_win,
  ROUND(COALESCE(pw.pole_win_count, 0) / p.pole_count * 100, 1) AS conversion_pct
FROM poles p
LEFT JOIN pole_wins pw ON pw.driverId = p.driverId
JOIN drivers d ON d.driverId = p.driverId
WHERE p.pole_count >= 10
ORDER BY conversion_pct DESC;




SELECT
  c.name AS constructor,
  COUNT(*) AS total_entries,
  COUNT(CASE WHEN r.position IS NULL THEN 1 END) AS dnfs,
  ROUND(COUNT(CASE WHEN r.position IS NULL THEN 1 END) / COUNT(*) * 100, 1) AS dnf_pct
FROM results r
JOIN constructors c ON c.constructorId = r.constructorId
GROUP BY c.constructorId, c.name
HAVING COUNT(*) >= 100
ORDER BY dnf_pct DESC
LIMIT 20;




SELECT
  CONCAT(d1.forename, ' ', d1.surname) AS driver_a,
  CONCAT(d2.forename, ' ', d2.surname) AS driver_b,
  COUNT(CASE WHEN r1.positionOrder < r2.positionOrder THEN 1 END) AS a_wins,
  COUNT(CASE WHEN r2.positionOrder < r1.positionOrder THEN 1 END) AS b_wins,
  COUNT(*) AS races_together
FROM results r1
JOIN results r2
  ON r1.raceId = r2.raceId
  AND r1.constructorId = r2.constructorId
  AND r1.driverId < r2.driverId
JOIN drivers d1 ON d1.driverId = r1.driverId
JOIN drivers d2 ON d2.driverId = r2.driverId
GROUP BY r1.driverId, r2.driverId, driver_a, driver_b
HAVING COUNT(*) >= 20
ORDER BY races_together DESC
LIMIT 20;


WITH all_points AS (
  SELECT raceId, driverId, points FROM results
  UNION ALL
  SELECT raceId, driverId, points FROM sprint_results
)
SELECT
  ra.round,
  CONCAT(d.forename, ' ', d.surname) AS driver,
  SUM(ap.points) AS weekend_points,
  SUM(SUM(ap.points)) OVER (PARTITION BY ap.driverId ORDER BY ra.round) AS running_total
FROM all_points ap
JOIN races ra ON ra.raceId = ap.raceId
JOIN drivers d ON d.driverId = ap.driverId
WHERE ra.year = 2021 AND d.surname IN ('Verstappen','Hamilton')
GROUP BY ra.round, ap.driverId, driver
ORDER BY ra.round, driver;



SELECT
  CONCAT(d.forename, ' ', d.surname) AS driver,
  COUNT(*) AS races,
  ROUND(AVG(r.grid - r.positionOrder), 2) AS avg_positions_gained
FROM results r
JOIN drivers d ON d.driverId = r.driverId
WHERE r.grid > 0
GROUP BY r.driverId, driver
HAVING COUNT(*) >= 50
ORDER BY avg_positions_gained DESC
LIMIT 20;



SELECT
  c.name AS constructor,
  COUNT(*) AS stops_counted,
  ROUND(AVG(ps.milliseconds)/1000, 2) AS avg_stop_seconds
FROM pit_stops ps
JOIN results r
  ON r.raceId = ps.raceId
  AND r.driverId = ps.driverId
JOIN constructors c
  ON c.constructorId = r.constructorId
WHERE ps.milliseconds < 100000
GROUP BY c.constructorId, c.name
HAVING COUNT(*) >= 50
ORDER BY avg_stop_seconds ASC
LIMIT 15;



WITH lap_deltas AS (
  SELECT l.raceId, l.driverId, l.lap, l.milliseconds,
         l.milliseconds - LAG(l.milliseconds) OVER (PARTITION BY l.raceId, l.driverId ORDER BY l.lap) AS delta
  FROM lap_times l
)
SELECT
  ra.year, ra.name AS race,
  CONCAT(d.forename, ' ', d.surname) AS driver,
  ROUND(STDDEV_POP(delta)/1000, 3) AS lap_consistency_sec
FROM lap_deltas ld
JOIN races ra ON ra.raceId = ld.raceId
JOIN drivers d ON d.driverId = ld.driverId
WHERE delta IS NOT NULL
GROUP BY ld.raceId, ld.driverId, ra.year, ra.name, driver
HAVING COUNT(*) >= 40
ORDER BY lap_consistency_sec ASC
LIMIT 20;




