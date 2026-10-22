
ATTACH 'historianQueries.db' as hq (READ_ONLY);
select hq.grafana_epochTotimestampz('0');

DETACH hq;

ATTACH 'https://github.com/JeromeLefebvre/DuckDB-HistorianQueries/blob/main/historianQueries.db' AS hq;
select hq.grafana_epochTotimestampz('0');

DETACH hq;