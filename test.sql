
ATTACH 'historianQueries.duckdb' as hq (READ_ONLY);
select hq.grafana_epochTotimestampz('0');

DETACH hq;

ATTACH 'https://raw.githubusercontent.com/JeromeLefebvre/DuckDB-HistorianQueries/main/historianQueries.duckdb' AS hq (READ_ONLY);
select hq.grafana_epochTotimestampz('0');

DETACH hq;