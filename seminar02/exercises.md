# Семинар 2 · Упражнения по нормализации (дома)

Не оцениваются. Разберём на семинаре 3; похожие будут в письменной работе на неделе 8.
Ответы пишите прямо здесь.

## 1. Рейсы

Таблица `flight(flight_no, date, aircraft, aircraft_seats, captain, captain_licence, route_from, route_to, route_distance)`.

а) Выпишите функциональные зависимости.
б) Найдите ключ (или возможные ключи).
в) Какие аномалии возникнут при: замене самолёта на рейсе; изменении номера лицензии командира; отмене всех рейсов по маршруту?
г) Приведите к 3NF: перечислите таблицы с ключами.

Ответ:
а) Функциональные зависимости:
- `flight_no` -> `route_from`, `route_to`, `route_distance`
- `aircraft` -> `aircraft_seats`
- `captain` -> `captain_licence`
- `flight_no, date` -> `aircraft`, `captain`
б) Ключ: составной `(flight_no, date)`.
в) Аномалии:
- Замена самолета / Изменение лицензии (аномалия обновления): придется искать и обновлять атрибуты `aircraft_seats` или `captain_licence` во всех исторических строках.
- Отмена рейсов (аномалия удаления): при удалении рейсов сотрется информация о расстоянии между городами (`route_distance`) для данного номера рейса.
г) 3NF (таблицы и ключи):
1. `route` (**flight_no** PK, route_from, route_to, route_distance)
2. `aircraft` (**aircraft** PK, aircraft_seats)
3. `captain` (**captain** PK, captain_licence)
4. `flight_schedule` (**flight_no** PK/FK, **date** PK, aircraft FK, captain FK)

## 2. Телеметрия «плоско»

Таблица `reading(sensor_tag, unit_code, station_name, ts, value, unit_of_measure)` — 10⁹ строк, только вставки.

а) Какие аномалии возникнут, когда агрегат перевезут на другую площадку? Когда датчик перекалибруют в другие единицы?
б) Что нужно вынести в отдельные таблицы?
в) Какую денормализацию вы бы всё же оставили ради скорости чтения и почему? Как будете её синхронизировать?

Ответ:
а) Возникнет аномалия обновления. Команда UPDATE для изменения площадки или единиц измерения затронет миллионы строк, что вызовет блокировки, исчерпание места на диске и искажение исторической правды (мы потеряем данные о том, где агрегат находился до переезда).
б) Вынести в отдельные таблицы:
- `station` (station_name PK)
- `unit` (unit_code PK, station_name FK)
- `sensor` (sensor_tag PK, unit_code FK, unit_of_measure)
В таблице `reading` оставить только: `sensor_tag` FK, `ts`, `value`.
в) Денормализация ради скорости: я бы оставил колонку `unit_code` в таблице `reading`. Это избавит от необходимости делать JOIN огромной таблицы со справочником при фильтрации метрик по конкретному агрегату.
Синхронизация: не требуется. Значение `unit_code` записывается только при вставке (INSERT) как неизменяемый исторический факт и никогда не обновляется.

## 3. Пороги во времени

Спроектируйте хранение **порогов срабатывания** (warning / alarm) для датчиков так, чтобы можно было ответить:
«какой порог действовал для TE-302 12 марта 2025?» и «кто и когда его изменил?».

Напишите DDL с ограничением на непересечение интервалов (`exclude using gist`; понадобится `create extension if not exists btree_gist`) и запрос на первый вопрос.

Ответ:
```sql
create extension if not exists btree_gist;

create table sensor_threshold (
    id int generated always as identity primary key,
    sensor_tag text not null,
    warning_limit numeric not null,
    alarm_limit numeric not null,
    changed_by text not null,
    valid_from timestamptz not null default now(),
    valid_to timestamptz,
    
    check (valid_to is null or valid_from < valid_to),
    -- Ограничение: интервалы действия для одного датчика не могут пересекаться
    exclude using gist (
        sensor_tag with =,
        tstzrange(valid_from, coalesce(valid_to, 'infinity'::timestamptz), '[)') with &&
    )
);

-- Запрос на поиск действовавшего порога:
select warning_limit, alarm_limit, changed_by, valid_from
from sensor_threshold
where sensor_tag = 'TE-302'
  and tstzrange(valid_from, coalesce(valid_to, 'infinity'::timestamptz), '[)')
      @> '2025-03-12 00:00:00+00'::timestamptz;