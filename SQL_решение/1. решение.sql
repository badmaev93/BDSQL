WITH
    -- плотность расписания для удовл данных условию
    65.0 AS scaling_factor,

    FittedBusStops AS (
        SELECT route_id, stop_name, arrival_time / scaling_factor AS arrival_time
        FROM bus_stops
    ),


    -- "справочник расписаний для подогнанных данных
    StopSchedules AS (
        SELECT
            stop_name,
            groupArray(arrival_time) AS all_arrivals,
            groupArray(route_id) AS all_route_ids
        FROM FittedBusStops
        GROUP BY stop_name
    ),

    -- анализ
    LocalImpactReport AS (
        SELECT
            bus_on_stop.route_id AS bus_to_remove,
            bus_on_stop.stop_name,
            arrayMax(arrayConcat(
                arrayDifference(arraySort(
                    arrayFilter((t, r) -> r != bus_to_remove, schedule.all_arrivals, schedule.all_route_ids)
                )),
                [(arrayMin(arraySort(
                    arrayFilter((t, r) -> r != bus_to_remove, schedule.all_arrivals, schedule.all_route_ids)
                )) + (1440.0 / scaling_factor)) - arrayMax(arraySort(
                    arrayFilter((t, r) -> r != bus_to_remove, schedule.all_arrivals, schedule.all_route_ids)
                ))]
            )) AS new_local_interval
        FROM 
            (SELECT DISTINCT route_id, stop_name FROM FittedBusStops) AS bus_on_stop
        JOIN StopSchedules AS schedule ON bus_on_stop.stop_name = schedule.stop_name
        WHERE length(arrayFilter((t, r) -> r != bus_to_remove, schedule.all_arrivals, schedule.all_route_ids)) > 1
    ),

    -- ск-ко составит макс интервал при удалении и на какой остановке
     RankedLocalImpact AS (
        SELECT
            bus_to_remove,
            stop_name,
            new_local_interval,
              row_number() OVER (PARTITION BY bus_to_remove ORDER BY new_local_interval DESC) AS rank
        FROM LocalImpactReport
    )

-- рез-т
SELECT
    bus_to_remove AS removable_bus_id,
    round(new_local_interval, 2) AS resulting_max_local_interval,
    stop_name AS most_affected_stop
FROM RankedLocalImpact
WHERE rank = 1 
AND new_local_interval <= 5.0
ORDER BY new_local_interval ASC;