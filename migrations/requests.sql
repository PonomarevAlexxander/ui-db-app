-- SELECT 1

select count(*) from project
where date_end_real <= localtimestamp;

select count(*) from project
where date_end_real is not null;

select count(*)
from project
where date_end_real <= current_timestamp;

-- SELECT 2
select p.name as proj_name, e.id as employee_id, e.first_name as employee_f_name, e.salary as salary from project p
left join department_employee d on d.department_id = p.department_id
left join employee e on d.employee_id = e.id
order by proj_name asc;

-- SELECT 3
select p.name as proj_name, p.cost - coalesce(sum(e.salary), 0) * (extract(year from age(p.date_end, p.date_beg)) * 12 +
extract(month from age(p.date_end, p.date_beg))) as profit
from project p
left join department_employee d on d.department_id = p.department_id
left join employee e on d.employee_id = e.id
group by p.id
having p.date_end_real is null
order by proj_name asc;

-- INSERT 1
insert into employee (first_name, father_name, last_name, position, salary)
values ('Иван', 'Иванович', 'Иванов', 'Программист', 70000);

-- INSERT 2
insert into department_employee (department_id, employee_id)
values (1, 1);

-- INSERT 3
do $$
declare
    v_id int;
    v_date_beg timestamp without time zone;
    v_date_end timestamp without time zone;
    v_duration int;
begin
    insert into project (name, cost, department_id, date_beg, date_end)
    values ('Новый проект', 500000, 1, '2024-01-01 00:00:00', '2024-04-01 00:00:00')
    returning id, date_beg, date_end INTO v_id, v_date_beg, v_date_end;

    v_duration := extract(year from age(v_date_end, v_date_beg)) * 12 + extract(month from age(v_date_end, v_date_beg));

    if v_duration > 2 then
        raise notice 'Длительность проекта превышает 2 месяца. Транзакция отменена.';
        rollback;
    else
        raise notice 'Проект успешно добавлен. ID: %', v_id;
        commit;
    end if;
end $$;

-- DELETE 1
delete from department d
where (select count(*) from department_employee de where de.department_id = d.id) < 3
  and not exists (select 1 from project p where p.department_id = d.id);

-- DELETE 2
begin;

select e.*, de.department_id from employee e
join department_employee de on e.id = de.employee_id;

with min_salary_employee as (
    select e.id
    from employee e
    join department_employee d on d.department_id = 1
    order by salary asc
    limit 1
)
delete from employee
where id = (select id from min_salary_employee);

select e.*, de.department_id from employee e
join department_employee de on e.id = de.employee_id;

rollback;

-- MODIFY 1
update project
set date_end_real = '2024-10-01 00:00:00'
where name = 'Проект А';

-- MODIFY 2
begin;
update project
set name = 'Проект NEW'
where name = 'Проект А';
select * from project;
rollback; -- commit;

delete from project p
where p.name like 'А%' and p.date_beg >= '2023-01-01 00:00:00' and p.date_end_real < '2024-01-01 00:00:00';

-- views
-- num1
CREATE OR REPLACE VIEW employees_in_projects AS
SELECT e.first_name, e.last_name, d.name AS department_name, p.name AS project_name, p.date_beg, p.date_end_real
FROM employee e
JOIN department_employee de ON e.id = de.employee_id
JOIN department d ON de.department_id = d.id
JOIN project p ON p.department_id = d.id
WHERE p.date_beg IS NOT NULL AND p.date_end_real IS NOT NULL;

SELECT *
FROM employees_in_projects
WHERE date_beg >= '2022-01-01' AND (date_end_real <= '2024-12-31' OR date_end_real IS NULL);

--num2
CREATE OR REPLACE VIEW project_monthly_expenses AS
SELECT p.name AS project_name, p.cost AS project_cost, SUM(e.salary) AS monthly_expense
FROM project p
JOIN department_employee de ON p.department_id = de.department_id
JOIN employee e ON de.employee_id = e.id
GROUP BY p.id;

SELECT *
FROM project_monthly_expenses;

--procedures
--num1
CREATE OR REPLACE PROCEDURE avg_project_duration_by_department()
LANGUAGE plpgsql
AS $$
DECLARE
    department_name VARCHAR(20);
    avg_duration_days NUMERIC;
BEGIN
    FOR department_name, avg_duration_days IN
        SELECT d.name AS department_name,
               AVG(EXTRACT(DAY FROM (p.date_end_real - p.date_beg))) AS avg_duration_days
        FROM department d
        JOIN project p ON d.id = p.department_id
        WHERE p.date_end_real IS NOT NULL
        GROUP BY d.name
    LOOP
        RAISE NOTICE 'Отдел: %, Средняя длительность: % дней', department_name, avg_duration_days;
    END LOOP;
END;
$$;

call avg_project_duration_by_department();

--num2
CREATE OR REPLACE PROCEDURE common_projects(employee1_id INT, employee2_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    project_name TEXT;
BEGIN
    FOR project_name IN
        SELECT p.name
        FROM project p
        WHERE p.department_id IN (
            SELECT de1.department_id
            FROM department_employee de1
            JOIN department_employee de2 ON de1.department_id = de2.department_id
            WHERE de1.employee_id = employee1_id
              AND de2.employee_id = employee2_id
        )
    LOOP
        RAISE NOTICE 'Project: %', project_name;
    END LOOP;
END;
$$;


CALL common_projects(1, 3);


--num3
CREATE OR REPLACE PROCEDURE max_project_duration(dept_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    project_name VARCHAR;
    max_duration INTERVAL;
BEGIN
    SELECT p.name, (p.date_end_real - p.date_beg) AS duration
    INTO project_name, max_duration
    FROM project p
    WHERE p.department_id = dept_id
      AND p.date_end_real IS NOT NULL
    ORDER BY duration DESC
    LIMIT 1;

    RAISE NOTICE 'Проект: %, Максимальная длительность: %', project_name, max_duration;
END;
$$;

CALL max_project_duration(1);

--triggers
--num1
CREATE OR REPLACE FUNCTION check_employee_in_department()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM department_employee
        WHERE employee_id = NEW.employee_id
          AND department_id = NEW.department_id
    ) THEN
        RAISE EXCEPTION 'Сотрудник уже работает в этом отделе';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_duplicate_employee
BEFORE INSERT OR UPDARE ON department_employee
FOR EACH ROW
EXECUTE FUNCTION check_employee_in_department();

--num2
CREATE OR REPLACE FUNCTION check_project_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.date_end < NEW.date_beg THEN
        RAISE EXCEPTION 'Дата окончания проекта не может быть раньше даты начала';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_project_end_date_update
BEFORE UPDATE OF date_end ON project
FOR EACH ROW
EXECUTE FUNCTION check_project_dates();

CREATE TRIGGER validate_project_end_date_insert
BEFORE INSERT ON project
FOR EACH ROW
EXECUTE FUNCTION check_project_dates();

--num3
CREATE OR REPLACE FUNCTION prevent_unfinished_project_deletion()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.date_end_real IS NULL THEN
        RAISE EXCEPTION 'Нельзя удалять незавершенные проекты';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_deletion_of_unfinished_project
BEFORE DELETE ON project
FOR EACH ROW
EXECUTE FUNCTION prevent_unfinished_project_deletion();


CREATE OR REPLACE FUNCTION start_date_check()
RETURNS TRIGGER AS $$
BEGIN
    IF extract(year FROM NEW.date_beg) > 2010 OR extract(year FROM NEW.date_end) < 2030 THEN
        RAISE EXCEPTION 'error: date_beg or date_end are out of the allowed range';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_date_insert
BEFORE INSERT OR UPDATE ON project
FOR EACH ROW
EXECUTE FUNCTION start_date_check();

--cursor
CREATE OR REPLACE PROCEDURE calculate_profit(start_date DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    project_cursor CURSOR FOR
        SELECT p.id, p.name, p.cost, EXTRACT(MONTH FROM (p.date_end_real - p.date_beg)) * SUM(e.salary) AS expenses
        FROM project p
        JOIN department_employee de ON p.department_id = de.department_id
        JOIN employee e ON de.employee_id = e.id
        WHERE p.date_end_real IS NOT NULL
          AND p.date_end_real > start_date
        GROUP BY p.id, p.name, p.cost, p.date_end_real, p.date_beg;

    project_id INT;
    project_name VARCHAR;
    cost NUMERIC;
    expenses NUMERIC;
    profit NUMERIC;
BEGIN
    OPEN project_cursor;

    LOOP
        FETCH project_cursor INTO project_id, project_name, cost, expenses;
        EXIT WHEN NOT FOUND;

        -- Вычисляем прибыль
        profit := cost - expenses;

        -- Выводим результат для каждого проекта
        RAISE NOTICE 'Project ID: %, Project Name: %, Profit: %', project_id, project_name, profit;
    END LOOP;

    -- Закрываем курсор
    CLOSE project_cursor;
END;
$$;


CALL calculate_profit('2020-01-01');
