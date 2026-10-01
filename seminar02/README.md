# Семинар 2 · Схема нашего проекта

Задание — [seminar02.pdf](seminar02.pdf). Пример диаграммы из лекции — [example/schema.mmd](example/schema.mmd).

## Команда и предметная область

- Команда: Щёголев А.А. ИУ1-72Б
- Объект: Медицинская система мониторинга пациентов

## Сущности (часть 1)

| Сущность | Естественный ключ | Атрибуты | Примечание |
|---|---|---|---|
| Отделение (`ward`) | Код палаты (`code`) | Название, профиль | Иерархия / Размещение |
| Пациент (`patient`) | Полис ОМС (`insurance_num`) | ФИО, дата рождения | Объект наблюдения |
| Датчик (`sensor`) | Серийный номер (`serial_num`) | Тип датчика | Источник сигналов |
| Врач (`doctor`) | Табельный номер (`tab_no`) | ФИО, специальность | Исполнитель |
| Телеметрия (`telemetry`) | — | Время (`ts`), значение (`value`) | Измерения |
| Событие/Тревога (`event`) | — | Время, критичность, описание | Аномалии |
| Осмотр (`treatment`) | — | Время, диагноз | Воздействие |
| Документ (`document`) | Номер документа (`doc_number`) | Тип документа, ссылка на файл | Справки, выписки |

## Связи

| A — B | Кардинальность | Обязательна? | Атрибуты связи |
|---|---|---|---|
| Отделение — Пациент | 1:N | Да | — |
| Пациент — Датчик | M:N | Нет | Дата установки (`valid_from`), дата снятия (`valid_to`) |
| Датчик — Телеметрия | 1:N | Да | — |
| Пациент — Событие | 1:N | Нет | — |
| Пациент — Осмотр | 1:N | Нет | — |
| Врач — Осмотр | 1:N | Да | — |
| Пациент — Документ | 1:N | Нет | — |

## Что меняется во времени

История назначения датчиков: Один датчик в разное время может быть закреплен за разными пациентами. Это фиксируется в таблице связи `patient_sensor` с помощью временных меток `valid_from` (когда надели) и `valid_to` (когда сняли, `NULL` = носит сейчас).

## диаграмма «сущность — связь» (часть 2)

```mermaid
erDiagram
    ward ||--o{ patient : "содержит"
    patient ||--o{ patient_sensor : "носит"
    sensor ||--o{ patient_sensor : "назначается"
    sensor ||--o{ telemetry : "измеряет"
    patient ||--o{ event : "генерирует"
    patient ||--o{ treatment : "проходит"
    doctor ||--o{ treatment : "проводит"
    patient ||--o{ document : "имеет"

    ward {
        int id PK
        text code UK "Код палаты"
        text name
        text profile
    }
    patient {
        int id PK
        text insurance_num UK "Полис ОМС"
        int ward_id FK
        text full_name
        date birth_date
    }
    sensor {
        int id PK
        text serial_num UK
        text kind "pulse | oxygen | pressure"
    }
    patient_sensor {
        int patient_id PK, FK
        int sensor_id PK, FK
        timestamptz valid_from PK
        timestamptz valid_to "NULL = носит сейчас"
    }
    telemetry {
        int id PK
        int sensor_id FK
        timestamptz ts
        numeric value "check value > 0"
    }
    event {
        int id PK
        int patient_id FK
        timestamptz ts
        text severity "info | warning | critical"
        text description
    }
    doctor {
        int id PK
        text tab_no UK
        text full_name
        text specialty
    }
    treatment {
        int id PK
        int patient_id FK
        int doctor_id FK
        timestamptz performed_at
        text diagnosis
    }
    document {
        int id PK
        int patient_id FK
        text doc_number UK
        text doc_type
        text file_url
    }