
'''
import duckdb, pytest

@pytest.fixture
def con():
    c = duckdb.connect()  # fresh in-memory DB per test
    c.execute("CREATE TABLE orders(id INT, amount DECIMAL(10,2))")
    c.execute("INSERT INTO orders VALUES (1, 10.50), (2, 20.00)")
    yield c
    c.close()

def test_total(con):
    assert con.execute("SELECT sum(amount) FROM orders").fetchone()[0] == 30.50
'''

ATTACH 'historianQueries.duckdb' as hq (READ_ONLY);
SET search_path = 'main,hq';

select hq.grafana_epochTotimestampz('0');

DETACH hq;

ATTACH 'https://raw.githubusercontent.com/JeromeLefebvre/DuckDB-HistorianQueries/main/historianQueries.duckdb' AS hq (READ_ONLY);
select hq.grafana_epochTotimestampz('0');


CREATE OR REPLACE VIEW weightOverTime AS
FROM read_parquet('~/Weight/weights.parquet') order by date asc;

from hq.RecordedValues(weightOverTime, date, weight, now() - INTERVAL 10 DAY, now());

DETACH hq;