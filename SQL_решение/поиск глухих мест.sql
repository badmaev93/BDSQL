WITH
    RouteStops AS (
        SELECT DISTINCT
            b.route_id AS common_route_id,
            s.stop_name
        FROM bus_stops AS s
        JOIN buses AS b ON s.route_id = b.bus_id
    ),
    DirectConnections AS (
        SELECT DISTINCT
            r1.stop_name AS stop_A,
            r2.stop_name AS stop_B
        FROM RouteStops AS r1
        JOIN RouteStops AS r2 ON r1.common_route_id = r2.common_route_id
        WHERE r1.stop_name != r2.stop_name
    ),
    OneTransferConnections AS (
        SELECT DISTINCT d1.stop_A, d2.stop_B
        FROM DirectConnections AS d1
        JOIN DirectConnections AS d2 ON d1.stop_B = d2.stop_A 
        WHERE d1.stop_A != d2.stop_B
        EXCEPT
        SELECT stop_A, stop_B FROM DirectConnections
    ),
    
     DirectReachCounts AS (
        SELECT
            stop_A AS stop_name,
            count() AS direct_count
        FROM DirectConnections
        GROUP BY stop_A
    ),
    OneTransferReachCounts AS (
        SELECT
            stop_A AS stop_name,
            count() AS transfer_count
        FROM OneTransferConnections
        GROUP BY stop_A
    )

SELECT
    all_stops.stop_name,
    ifNull(drc.direct_count, 0) AS direct_reach_count,
    ifNull(otrc.transfer_count, 0) AS one_transfer_reach_count,
    
    direct_reach_count + one_transfer_reach_count AS total_reach_within_one_transfer,
    round(total_reach_within_one_transfer / (SELECT count(DISTINCT stop_name) FROM bus_stops), 3) AS connectivity_index
FROM 
    (SELECT DISTINCT stop_name FROM bus_stops) AS all_stops
LEFT JOIN DirectReachCounts AS drc ON all_stops.stop_name = drc.stop_name
LEFT JOIN OneTransferReachCounts AS otrc ON all_stops.stop_name = otrc.stop_name
ORDER BY total_reach_within_one_transfer ASC
LIMIT 20;