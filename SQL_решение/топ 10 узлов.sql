SELECT
    s.stop_name,
    count(DISTINCT b.route_id) AS number_of_unique_routes,
    count() AS total_trips_per_day
FROM bus_stops AS s
JOIN buses AS b ON s.route_id = b.bus_id
GROUP BY s.stop_name
ORDER BY number_of_unique_routes DESC
LIMIT 10;