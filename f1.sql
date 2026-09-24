USE f1;

DROP TABLE IF EXISTS constructor_results, constructor_standings, driver_standings,
  pit_stops, lap_times, qualifying, sprint_results, results, races,
  constructors, drivers, status, seasons, circuits;

CREATE TABLE circuits (
  circuitId INT PRIMARY KEY,
  circuitRef VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL,
  location VARCHAR(100),
  country VARCHAR(50),
  lat DECIMAL(9,6),
  lng DECIMAL(9,6),
  alt INT,
  url VARCHAR(255)
);

CREATE TABLE seasons (
  year INT PRIMARY KEY,
  url VARCHAR(255)
);

CREATE TABLE status (
  statusId INT PRIMARY KEY,
  status VARCHAR(50) NOT NULL
);

CREATE TABLE drivers (
  driverId INT PRIMARY KEY,
  driverRef VARCHAR(50) NOT NULL,
  number INT,
  code CHAR(3),
  forename VARCHAR(50) NOT NULL,
  surname VARCHAR(50) NOT NULL,
  dob DATE,
  nationality VARCHAR(50),
  url VARCHAR(255)
);

CREATE TABLE constructors (
  constructorId INT PRIMARY KEY,
  constructorRef VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL,
  nationality VARCHAR(50),
  url VARCHAR(255)
);

CREATE TABLE races (
  raceId INT PRIMARY KEY,
  year INT NOT NULL,
  round INT NOT NULL,
  circuitId INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  date DATE NOT NULL,
  time TIME,
  url VARCHAR(255),
  fp1_date DATE,
  fp1_time TIME,
  fp2_date DATE,
  fp2_time TIME,
  fp3_date DATE,
  fp3_time TIME,
  quali_date DATE,
  quali_time TIME,
  sprint_date DATE,
  sprint_time TIME,
  UNIQUE (year, round),
  FOREIGN KEY (year) REFERENCES seasons(year),
  FOREIGN KEY (circuitId) REFERENCES circuits(circuitId)
);

CREATE TABLE results (
  resultId INT PRIMARY KEY,
  raceId INT NOT NULL,
  driverId INT NOT NULL,
  constructorId INT NOT NULL,
  number INT,
  grid INT,
  position INT,
  positionText VARCHAR(5),
  positionOrder INT,
  points DECIMAL(5,2),
  laps INT,
  time VARCHAR(15),
  milliseconds INT,
  fastestLap INT,
  `rank` INT,
  fastestLapTime VARCHAR(12),
  fastestLapSpeed DECIMAL(6,3),
  statusId INT NOT NULL,
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (driverId) REFERENCES drivers(driverId),
  FOREIGN KEY (constructorId) REFERENCES constructors(constructorId),
  FOREIGN KEY (statusId) REFERENCES status(statusId)
);

CREATE TABLE sprint_results (
  resultId INT PRIMARY KEY,
  raceId INT NOT NULL,
  driverId INT NOT NULL,
  constructorId INT NOT NULL,
  number INT,
  grid INT,
  position INT,
  positionText VARCHAR(5),
  positionOrder INT,
  points DECIMAL(4,1),
  laps INT,
  time VARCHAR(15),
  milliseconds INT,
  fastestLap INT,
  fastestLapTime VARCHAR(12),
  statusId INT NOT NULL,
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (driverId) REFERENCES drivers(driverId),
  FOREIGN KEY (constructorId) REFERENCES constructors(constructorId),
  FOREIGN KEY (statusId) REFERENCES status(statusId)
);

CREATE TABLE qualifying (
  qualifyId INT PRIMARY KEY,
  raceId INT NOT NULL,
  driverId INT NOT NULL,
  constructorId INT NOT NULL,
  number INT,
  position INT,
  q1 VARCHAR(12),
  q2 VARCHAR(12),
  q3 VARCHAR(12),
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (driverId) REFERENCES drivers(driverId),
  FOREIGN KEY (constructorId) REFERENCES constructors(constructorId)
);

CREATE TABLE lap_times (
  raceId INT NOT NULL,
  driverId INT NOT NULL,
  lap INT NOT NULL,
  position INT,
  time VARCHAR(12),
  milliseconds INT,
  PRIMARY KEY (raceId, driverId, lap),
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (driverId) REFERENCES drivers(driverId)
);

CREATE TABLE pit_stops (
  raceId INT NOT NULL,
  driverId INT NOT NULL,
  stop INT NOT NULL,
  lap INT,
  time TIME,
  duration VARCHAR(12),
  milliseconds INT,
  PRIMARY KEY (raceId, driverId, stop),
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (driverId) REFERENCES drivers(driverId)
);

CREATE TABLE driver_standings (
  driverStandingsId INT PRIMARY KEY,
  raceId INT NOT NULL,
  driverId INT NOT NULL,
  points DECIMAL(6,2),
  position INT,
  positionText VARCHAR(5),
  wins INT,
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (driverId) REFERENCES drivers(driverId)
);

CREATE TABLE constructor_standings (
  constructorStandingsId INT PRIMARY KEY,
  raceId INT NOT NULL,
  constructorId INT NOT NULL,
  points DECIMAL(6,1),
  position INT,
  positionText VARCHAR(5),
  wins INT,
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (constructorId) REFERENCES constructors(constructorId)
);

CREATE TABLE constructor_results (
  constructorResultsId INT PRIMARY KEY,
  raceId INT NOT NULL,
  constructorId INT NOT NULL,
  points DECIMAL(5,1),
  status VARCHAR(5),
  FOREIGN KEY (raceId) REFERENCES races(raceId),
  FOREIGN KEY (constructorId) REFERENCES constructors(constructorId)
);

USE f1;

LOAD DATA LOCAL INFILE 'C:/f1_data/circuits.csv' INTO TABLE circuits
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/seasons.csv' INTO TABLE seasons
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/status.csv' INTO TABLE status
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/drivers.csv' INTO TABLE drivers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/constructors.csv' INTO TABLE constructors
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/races.csv' INTO TABLE races
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/results.csv' INTO TABLE results
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/sprint_results.csv' INTO TABLE sprint_results
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/qualifying.csv' INTO TABLE qualifying
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES
(qualifyId, raceId, driverId, constructorId, number, position, q1, @q2, @q3)
SET q2 = NULLIF(@q2, ''), q3 = NULLIF(@q3, '');

LOAD DATA LOCAL INFILE 'C:/f1_data/lap_times.csv' INTO TABLE lap_times
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/pit_stops.csv' INTO TABLE pit_stops
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/driver_standings.csv' INTO TABLE driver_standings
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/constructor_standings.csv' INTO TABLE constructor_standings
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/f1_data/constructor_results.csv' INTO TABLE constructor_results
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;