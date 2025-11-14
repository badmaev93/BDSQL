DROP TABLE IF EXISTS bus_stops;
DROP TABLE IF EXISTS buses;
DROP TABLE IF EXISTS bus_routes;


CREATE TABLE bus_stops
(
    stop_id      UInt32,
    route_id     UInt32, 
    stop_name    String,
    arrival_time Float32,
    stop_order   UInt16
) ENGINE = MergeTree()
ORDER BY (stop_name, arrival_time);

CREATE TABLE buses
(
    bus_id   UInt32,
    route_id UInt32 
) ENGINE = MergeTree()
ORDER BY bus_id;

CREATE TABLE bus_routes
(
    route_id       UInt32, 
    bus_id         UInt32, 
    route_name     String,
    departure_time Float32
) ENGINE = MergeTree()
ORDER BY route_id;

INSERT INTO bus_stops
SELECT *
FROM url('https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/GTFS_routrs_study/bus_stops.csv', 'CSVWithNames');

INSERT INTO bus_routes
SELECT *
FROM url('https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/GTFS_routrs_study/bus_routes.csv', 'CSVWithNames');

INSERT INTO buses
SELECT *
FROM url('https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/GTFS_routrs_study/buses.csv', 'CSVWithNames');
