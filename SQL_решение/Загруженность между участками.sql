WITH
    'Qutab Minar' AS stop_A,
    'Chhattarpur' AS stop_B 
SELECT
    floor(arrival_time_A / 65) % 24 AS hour_of_day,
    avg(travel_time) AS avg_travel_time_minutes
FROM (
    SELECT
        t1.route_id,
        t1.arrival_time AS arrival_time_A,
        t2.arrival_time - t1.arrival_time AS travel_time
    FROM bus_stops AS t1
    JOIN bus_stops AS t2
      ON t1.route_id = t2.route_id AND t1.stop_order = t2.stop_order - 1
    WHERE t1.stop_name = stop_A AND t2.stop_name = stop_B
)
GROUP BY hour_of_day
ORDER BY hour_of_day;