USE f1;

SHOW INDEX FROM results;
SHOW INDEX FROM pit_stops;
SHOW INDEX FROM lap_times;
SHOW INDEX FROM races;


EXPLAIN
SELECT driverId, COUNT(*) AS wins
FROM results
WHERE position = 1
GROUP BY driverId;

CREATE INDEX idx_results_position_driver
ON results (position, driverId);


EXPLAIN
SELECT
  r1.driverId,
  r2.driverId,
  COUNT(*) AS races_together
FROM results r1
JOIN results r2
  ON r1.raceId = r2.raceId
  AND r1.constructorId = r2.constructorId
  AND r1.driverId < r2.driverId
GROUP BY r1.driverId, r2.driverId;

CREATE INDEX idx_results_race_constructor_driver
ON results (raceId, constructorId, driverId);


EXPLAIN
SELECT
    raceId,
    driverId,
    lap,
    milliseconds,
    LAG(milliseconds) OVER (
        PARTITION BY raceId, driverId
        ORDER BY lap
    ) AS previous_lap
FROM lap_times;


EXPLAIN
SELECT
    raceId,
    driverId,
    lap,
    milliseconds
FROM lap_times
ORDER BY raceId, driverId, lap;