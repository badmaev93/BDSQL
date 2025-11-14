SELECT
    stop_name,
    next_stop_name,
    count() AS segment_frequency
FROM (
    SELECT
        stop_name,
        lead(stop_name, 1) OVER (PARTITION BY route_id ORDER BY stop_order) AS next_stop_name
    FROM bus_stops
)
WHERE next_stop_name IS NOT NULL
GROUP BY stop_name, next_stop_name
ORDER BY segment_frequency DESC
LIMIT 10;