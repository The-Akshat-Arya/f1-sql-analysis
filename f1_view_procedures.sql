USE f1;

CREATE OR REPLACE VIEW driver_career_stats AS
SELECT
  d.driverId,
  CONCAT(d.forename, ' ', d.surname) AS driver_name,
  COUNT(r.resultId) AS race_entries,
  SUM(CASE WHEN r.position = 1 THEN 1 ELSE 0 END) AS wins,
  SUM(CASE WHEN r.position <= 3 THEN 1 ELSE 0 END) AS podiums,
  COALESCE(SUM(r.points), 0) + COALESCE(MAX(sp.sprint_points), 0) AS total_points
FROM drivers d
LEFT JOIN results r ON r.driverId = d.driverId
LEFT JOIN (
  SELECT driverId, SUM(points) AS sprint_points
  FROM sprint_results
  GROUP BY driverId
) sp ON sp.driverId = d.driverId
GROUP BY d.driverId, driver_name;

SELECT *
FROM driver_career_stats
ORDER BY total_points DESC
LIMIT 20;

DELIMITER $$

CREATE PROCEDURE GetDriverCareerStats(IN p_search VARCHAR(50))
BEGIN
  SELECT *
  FROM driver_career_stats
  WHERE driver_name LIKE CONCAT('%', p_search, '%')
  ORDER BY wins DESC;
END$$

DELIMITER ;

CALL GetDriverCareerStats('Hamilton');



DELIMITER $$

CREATE PROCEDURE GetSeasonChampion(
  IN p_year INT,
  OUT p_champion VARCHAR(100),
  OUT p_points DECIMAL(6,2)
)
BEGIN
  SELECT CONCAT(d.forename, ' ', d.surname), ds.points
  INTO p_champion, p_points
  FROM driver_standings ds
  JOIN races r ON r.raceId = ds.raceId
  JOIN drivers d ON d.driverId = ds.driverId
  WHERE r.year = p_year
    AND r.round = (SELECT MAX(round) FROM races WHERE year = p_year)
    AND ds.position = 1;
END$$

DELIMITER ;


CALL GetSeasonChampion(2021, @champ, @pts);
SELECT @champ, @pts;