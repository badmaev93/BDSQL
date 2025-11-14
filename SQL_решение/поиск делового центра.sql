WITH
    420 AS morning_rush_start, 
    600 AS morning_rush_end,  
    1020 AS evening_rush_start, 
    1200 AS evening_rush_end,  

      StopMetrics AS (
        SELECT
            s.stop_name,
            
            count(DISTINCT b.route_id) AS number_of_unique_routes,
            
            countIf(s.arrival_time BETWEEN morning_rush_start AND morning_rush_end) AS morning_rush_hour_trips,
            countIf(s.arrival_time BETWEEN evening_rush_start AND evening_rush_end) AS evening_rush_hour_trips,
            
            count() AS total_trips_per_day
            
        FROM bus_stops AS s
        JOIN buses AS b ON s.route_id = b.bus_id
        GROUP BY s.stop_name
    ),

    RankedStops AS (
        SELECT
            stop_name,
            number_of_unique_routes,
            morning_rush_hour_trips,
            evening_rush_hour_trips,
            total_trips_per_day,            
             (number_of_unique_routes * 5) + 
            (morning_rush_hour_trips * 1) + 
            (evening_rush_hour_trips * 1)   
            AS cbd_score
            
        FROM StopMetrics
    )

SELECT
    stop_name,
    round(cbd_score) AS cbd_score,
    number_of_unique_routes,
    morning_rush_hour_trips,
    evening_rush_hour_trips,
    total_trips_per_day
FROM RankedStops
ORDER BY cbd_score DESC
LIMIT 15;