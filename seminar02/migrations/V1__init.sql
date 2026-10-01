-- =====================================================================
--  V1 — первая версия схемы вашего проекта.
--  Применить:  make migrate        Снести и применить заново:  make migrate-reset
--  После применения V1 НЕ редактируется — изменения идут в V2, V3, ...
-- =====================================================================
create schema if not exists project;
set search_path = project;

-- Справочник отделений (Ward)
create table ward (
    id int generated always as identity primary key,
    code text not null unique,
    name text not null,
    profile text
);
comment on table ward is 'Больничные отделения';

-- Пациенты (Patient)
create table patient (
    id int generated always as identity primary key,
    insurance_num text not null unique,
    ward_id int not null references ward(id),
    full_name text not null,
    birth_date date
);
comment on table patient is 'Зарегистрированные пациенты';

-- Датчики оборудования (Sensor)
create table sensor (
    id int generated always as identity primary key,
    serial_num text not null unique,
    kind text not null check (kind in ('pulse', 'oxygen', 'pressure'))
);
comment on table sensor is 'Медицинские датчики';

-- Таблица связи многие-ко-многим (история назначений датчиков)
create table patient_sensor (
    patient_id int not null references patient(id),
    sensor_id int not null references sensor(id),
    valid_from timestamptz not null default now(),
    valid_to timestamptz,
    primary key (patient_id, sensor_id, valid_from),
    check (valid_to is null or valid_from < valid_to)
);
comment on table patient_sensor is 'История привязки датчиков к пациентам';

-- Телеметрия (показания)
create table telemetry (
    id int generated always as identity primary key,
    sensor_id int not null references sensor(id),
    ts timestamptz not null default now(),
    value numeric not null check (value > 0)
);

-- События (аномалии)
create table event (
    id int generated always as identity primary key,
    patient_id int not null references patient(id),
    ts timestamptz not null default now(),
    severity text not null check (severity in ('info', 'warning', 'critical')),
    description text not null
);

-- Врачи (Doctor)
create table doctor (
    id int generated always as identity primary key,
    tab_no text not null unique,
    full_name text not null,
    specialty text not null
);

-- Осмотры/Процедуры (Treatment)
create table treatment (
    id int generated always as identity primary key,
    patient_id int not null references patient(id),
    doctor_id int not null references doctor(id),
    performed_at timestamptz not null default now(),
    diagnosis text not null
);

-- Документы (Document)
create table document (
    id int generated always as identity primary key,
    patient_id int not null references patient(id),
    doc_number text not null unique,
    doc_type text not null,
    file_url text not null
);

-- Тестовые данные (INSERT) для проверки схемы
insert into ward (code, name, profile) values 
    ('W-01', 'Кардиология', 'Сердечно-сосудистые'), 
    ('W-02', 'Реанимация', 'Интенсивная терапия');

insert into patient (insurance_num, ward_id, full_name, birth_date) values 
    ('111-222', 1, 'Иванов И.И.', '1980-05-15'), 
    ('333-444', 2, 'Петров П.П.', '1992-11-20');

insert into sensor (serial_num, kind) values 
    ('SN-900', 'pulse'), 
    ('SN-901', 'oxygen');

insert into doctor (tab_no, full_name, specialty) values 
    ('DOC-01', 'Смирнов А.А.', 'Кардиолог');

insert into patient_sensor (patient_id, sensor_id, valid_from) values 
    (1, 1, '2026-10-01 10:00:00+00');

insert into telemetry (sensor_id, ts, value) values 
    (1, '2026-10-01 10:05:00+00', 75);
