Все задачи были решены с помощью SQL-запросов в СУБД ClickHouse.
Использован датасет https://www.kaggle.com/datasets/lyxbash/bus-transit-data

---
### 1. Подготовка данных

**Скрипт:** 0. Создание таблиц.sql

Созданы таблицы bus_stops, buses и bus_routes. Для загрузки использовалась функция url()
```
INSERT INTO bus_stops SELECT * FROM url('https://.../bus_stops.csv',  'CSVWithNames')  
```
---

### 2. Задача 1

> **ссылка**
[https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/SQL_%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5/1.%20%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5.sql]()

Так как интервалы движения в датасете были гораздо больше 5 мин и не соответствовали условиям задания, временные метки были уменьшены делением на 65. Также, отфильтрована "зашумляющая" информация о ночных перерывах, о рейсах на тех остановках, по которым автобус не курсирует.

- С целью оптимизации, для каждой остановки все времена прибытия и ID рейсов были "свернуты" в массивы с помощью groupArray() .
- Выполнена симуляция "что если"с помощью arrayFilter(), arraySort(), arrayDifference(). При гипотетическом  удалении рейса пересчитывался новый максимальный интервал на остановке.
- Остановка, которая пострадает сильнее всего, находилась с помощью оконных функций (row_number() OVER ...).
- Результат представлен в порядке от наиболее безболезненных к удалению автобусов.
---
### 3. Задача 2

**а) Поиск транспортных узлов и коридоров:**

> **топ 10 узлов**: https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/SQL_%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5/%D1%82%D0%BE%D0%BF%2010%20%D1%83%D0%B7%D0%BB%D0%BE%D0%B2.sql
```
SELECT
    s.stop_name,
    count(DISTINCT b.route_id) AS number_of_unique_routes,
    count() AS total_trips_per_day
FROM bus_stops AS s
JOIN buses AS b ON s.route_id = b.bus_id
GROUP BY s.stop_name
ORDER BY number_of_unique_routes DESC
LIMIT 10;
```
- использовалась простая группировка GROUP BY stop_name с агрегацией count(DISTINCT b.route_id) для подсчета уникальных маршрутов.

>**топ 10 коридоров:** https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/SQL_%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5/%D1%82%D0%BE%D0%BF%20%D0%BA%D0%BE%D1%80%D0%B8%D0%B4%D0%BE%D1%80%D0%BE%D0%B2.sql
```
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
```
- применена оконная функция lead() OVER (PARTITION BY route_id ORDER BY stop_order) для нахождения пар последовательных остановок на каждом маршруте.

**б) Определение центрального делового района**

>**Скрипт** https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/SQL_%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5/%D0%BF%D0%BE%D0%B8%D1%81%D0%BA%20%D0%B4%D0%B5%D0%BB%D0%BE%D0%B2%D0%BE%D0%B3%D0%BE%20%D1%86%D0%B5%D0%BD%D1%82%D1%80%D0%B0.sql
    
- использован countIf(arrival_time BETWEEN ...) для измерения частоты перемещений в утренние и вечерние часы пик.

**в) Оценка загруженности**

>**Скрипт** https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/SQL_%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5/%D0%97%D0%B0%D0%B3%D1%80%D1%83%D0%B6%D0%B5%D0%BD%D0%BD%D0%BE%D1%81%D1%82%D1%8C%20%D0%BC%D0%B5%D0%B6%D0%B4%D1%83%20%D1%83%D1%87%D0%B0%D1%81%D1%82%D0%BA%D0%B0%D0%BC%D0%B8.sql
    
- Сравнивалось время в пути между двумя остановками в разное время суток. Использовались JOIN таблицы bus_stops саму на себя по условию t1.route_id = t2.route_id AND t1.stop_order = t2.stop_order - 1.

**г) Поиск наименее досягаемых мест

>**Скрипт https://raw.githubusercontent.com/badmaev93/BDSQL/refs/heads/main/SQL_%D1%80%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5/%D0%BF%D0%BE%D0%B8%D1%81%D0%BA%20%D0%B3%D0%BB%D1%83%D1%85%D0%B8%D1%85%20%D0%BC%D0%B5%D1%81%D1%82.sql
    
- применялись
    
    - множественные JOIN использовались для нахождения всех остановок, доступных с 0 и 1 пересадкой.
    - Оператор EXCEPT, отфильтровывающий уже известные прямые связи при поиске связей с 1 пересадкой.
    - Предварительная агрегация (GROUP BY) с последующим LEFT JOIN для объединения результатов, чтобы не было медленных коррелированных подзапросов.
