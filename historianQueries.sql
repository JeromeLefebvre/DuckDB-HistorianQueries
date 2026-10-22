
create or replace function grafana_epochTotimestampz(epochStr) AS
    epoch_ms(cast (epochStr as bigint)) at time zone 'UTC';

create or replace macro t2f(ts) as (
    epoch(ts) / 86400
);

CREATE OR REPLACE MACRO nextValue(time_serie, ts_col, value_col, ts) AS (
    SELECT value_col
    FROM query_table(time_serie)
    WHERE ts_col >= ts
    ORDER BY ts_col
    LIMIT 1
);

CREATE OR REPLACE MACRO nextTs(time_serie, ts_col, ts) AS (
    SELECT ts_col
    FROM query_table(time_serie)
    WHERE ts_col >= ts
    ORDER BY ts_col
    LIMIT 1
);

CREATE OR REPLACE MACRO prevValue(time_serie, ts_col, value_col, ts) AS (
    SELECT value_col
    FROM query_table(time_serie)
    WHERE ts_col <= ts
    ORDER BY ts_col DESC
    LIMIT 1
);

CREATE OR REPLACE MACRO prevTs(time_serie, ts_col, ts) AS (
    SELECT ts_col
    FROM query_table(time_serie)
    WHERE ts_col <= ts
    ORDER BY ts_col DESC
    LIMIT 1
);

CREATE OR REPLACE MACRO interpolatedValue(time_serie, ts_col, value_col, ts) AS (
    WITH
    scalars AS (
        SELECT
            prevValue(time_serie, ts_col, value_col, ts) AS v_prev,
            nextValue(time_serie, ts_col, value_col, ts) AS v_next,
            t2f(prevTs(time_serie, ts_col, ts))         AS t_prev,
            t2f(nextTs(time_serie, ts_col, ts))         AS t_next,
            t2f(ts)                                     AS t_query
    )
    SELECT
        CASE
            WHEN v_prev IS NULL          THEN v_next
            WHEN v_next IS NULL          THEN v_prev
            WHEN t_next = t_prev         THEN v_prev
            ELSE v_prev + (v_next - v_prev)
                        * (t_query - t_prev)
                        / (t_next - t_prev)
        END AS value_col
    FROM scalars
);

CREATE OR REPLACE MACRO RecordedValues(time_serie, ts_col, value_col, starttime, endtime) AS TABLE (
    with allValues as (
        select starttime as ts_coln, interpolatedValue(time_serie, ts_col, value_col, starttime) as value_coln
        union
        select endtime as ts_coln, interpolatedValue(time_serie, ts_col, value_col, endtime) as value_coln
        union
        (
            select ts_col as ts_coln, value_col as value_coln
            from query_table(time_serie) where ts_col between starttime and endtime
        ) 
    ) select * from allValues order by ts_coln
);

CREATE or replace MACRO time_weighted_avg(tbl, end_ts, num_days) as (
    WITH organised AS (
        SELECT
            date AS t_i,
            weight AS x_i,
            LEAD(date) OVER (ORDER BY date) AS t_next,
            LEAD(weight) OVER (ORDER BY date) AS x_next
        FROM RecordedValues(tbl, date, weight, end_ts - INTERVAL (num_days) DAY, end_ts) as t(date, weight)
    )
    SELECT
        SUM((x_i + x_next) / 2 * date_diff('day', t_i, t_next)) / num_days
    FROM organised
    WHERE t_next IS NOT NULL
);