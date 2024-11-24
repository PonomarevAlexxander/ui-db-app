create table if not exists "user" (
    id text primary key,
    pass text,
    role int references "role" (id) on delete cascade
);

create table if not exists "role" (
    id serial primary key,
    name text
)

create table if not exists employee (
    id serial primary key,
    first_name character varying(20),
    last_name character varying(20),
    father_name character varying(20),
    position character varying(20),
    salary integer
);

create table if not exists department (
    id serial primary key,
    name character varying(20)
);

create table if not exists project (
    id serial primary key,
    name character varying(20),
    cost integer,
    department_id integer references department(id) on delete cascade,
    date_beg timestamp without time zone,
    date_end timestamp without time zone,
    date_end_real timestamp without time zone
);

create table if not exists department_employee (
    id serial primary key,
    employee_id integer references employee(id) on delete cascade,
    department_id integer references department(id) on delete cascade,
    unique (employee_id, department_id)
);

-- INSERT INTO employee (first_name, father_name, last_name, position, salary)
-- VALUES
-- ('Иван', 'Иванович', 'Иванов', 'Программист', 80000),
-- ('Петр', 'Петрович', 'Петров', 'Аналитик', 70000),
-- ('Алексей', 'Алексеевич', 'Алексеев', 'Дизайнер', 65000),
-- ('Мария', 'Сергеевна', 'Сергеева', 'Менеджер', 90000),
-- ('Ольга', 'Николаевна', 'Николаева', 'Бухгалтер', 75000);

-- INSERT INTO department (name)
-- VALUES
-- ('Разработка'),
-- ('Аналитика'),
-- ('Маркетинг'),
-- ('Финансы'),
-- ('Дизайн');

-- INSERT INTO project (name, cost, department_id, date_beg, date_end, date_end_real)
-- VALUES
-- ('Проект F', 500000, 1, '2000-01-01 00:00:00', '2022-07-01 00:00:00', '2023-06-25 00:00:00');
-- INSERT INTO department_employee (department_id, employee_id)
-- VALUES
-- (1, 1),
-- (2, 2),
-- (3, 3),
-- (4, 4),
-- (5, 5),
-- (1, 3),
-- (3, 1),
-- (2, 4);
