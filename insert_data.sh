#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $1 == "test" ]]
then
  DB_USER="postgres"
  DB_NAME="worldcuptest"
else
  DB_USER="freecodecamp"
  DB_NAME="worldcup"
fi

psql --username="$DB_USER" --dbname="$DB_NAME" -v ON_ERROR_STOP=1 <<SQL
TRUNCATE TABLE games, teams RESTART IDENTITY CASCADE;

CREATE TEMP TABLE temp_games (
  year INT,
  round VARCHAR(50),
  winner VARCHAR(50),
  opponent VARCHAR(50),
  winner_goals INT,
  opponent_goals INT
);

\copy temp_games FROM '$SCRIPT_DIR/.freeCodeCamp/games.csv' WITH (FORMAT csv, HEADER true);

INSERT INTO teams(name)
SELECT DISTINCT team
FROM (
  SELECT winner AS team FROM temp_games
  UNION
  SELECT opponent AS team FROM temp_games
) AS all_teams
ORDER BY team;

INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT
  g.year,
  g.round,
  w.team_id,
  o.team_id,
  g.winner_goals,
  g.opponent_goals
FROM temp_games g
JOIN teams w ON w.name = g.winner
JOIN teams o ON o.name = g.opponent;
SQL
