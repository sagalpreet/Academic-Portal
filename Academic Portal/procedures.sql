-- PROCEDURES

create or replace procedure update_entry_number(entry_number_old char(11), entry_number_new char(11))
language plpgsql
as $$
declare
begin
    -- Verify that the entry_number_new is not taken
    execute format('alter table %I rename to %I', 'credit_'||entry_number_old, 'credit_'||entry_number_new);
    execute format('alter table %I rename to %I', 'audit_'||entry_number_old, 'audit_'||entry_number_new);
    execute format('alter role %I rename to %I', entry_number_old, entry_number_new);
    update student set entry_number=entry_number_new where entry_number=entry_number_old;
end;
$$;

---------------------------------------------------------

create or replace procedure enroll_credit(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    if is_student_eligible_for_credit(entry_number, offering_id) and is_add_open() then
        execute format('delete from %I where entry_number=%L', 'audit_'||offering_id, entry_number);
        execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, offering_id);

        execute format('insert into %I(entry_number) (%L)', 'credit_'||offering_id, entry_number); -- for the instructor
        execute format('insert into %I(offering_id) (%L)', 'credit_'||entry_number, offering_id); -- for the student
    end if;
end;
$$;

create or replace procedure enroll_audit(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    if is_student_eligible_for_audit(entry_number char(11), offering_id) and is_add_open() then
        execute format('delete from %I where entry_number=%L', 'credit_'||offering_id, entry_number);
        execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, offering_id);

        execute format('insert into %I(entry_number) (%L)', 'audit_'||offering_id, entry_number); -- for the instructor
        execute format('insert into %I(offering_id) (%L)', 'audit_'||entry_number, offering_id); -- for the student
    end if;
end;
$$;

create or replace procedure drop_offering(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    if not is_offering_offered_in_current_sem_and_year(offering_id) then
        raise ERROR "This offering is not being offered this semester";
        return;
    end if;
    if not is_add_open() then
        raise ERROR "Drop window is not open";
        return;
    end if;
    execute format('delete from %I where entry_number=%L', 'credit_'||offering_id, entry_number);
    execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, offering_id);
    execute format('delete from %I where entry_number=%L', 'audit_'||offering_id, entry_number);
    execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, offering_id);
end;
$$;

create or replace procedure withdraw_offering(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    if not is_offering_offered_in_current_sem_and_year(offering_id) then
        raise ERROR "This offering is not being offered this semester";
        return;
    end if;
    if not is_withdraw_open() then
        raise ERROR "Withdraw is not open";
        return;
    end if;

    execute format('delete from %I where entry_number=%L', 'audit_'||offering_id, entry_number);
    execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, offering_id);
    execute format('delete from %I where entry_number=%L', 'credit_'||offering_id, entry_number);
    execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, offering_id);

    execute format('insert into %I(offering_id) (%L)', 'withdraw_'||entry_number, offering_id);
    execute format('insert into %I(entry_number) (%L)', 'withdraw_'||offering_id, entry_number);
end;
$$;

create or replace procedure drop_offering(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    if (not is_offering_open(offering_id) then
        raise EXCEPTION "Offering is not open"
        return;
    end if;
    execute format('delete from %I where entry_number=%L', 'audit_'||offering_id, entry_number);
    execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, offering_id);
    execute format('delete from %I where entry_number=%L', 'credit_'||offering_id, entry_number);
    execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, offering_id);
end;
$$;

---------------------------------------------
create or replace procedure generate_ticket(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
    inst_id char(11);
begin
    entry_number = get_id();
    select offering.inst_id into inst_id from offering where offering.id=offering_id;

    execute format('insert into %I(offering_id) values (%L, %L)', 's_ticket_'||entry_number, offering_id);
end;
$$;

create or replace procedure ticket_verdict_i(ticket_id int, entry_number char(11), verdict boolean)
language plpgsql
as $$
declare
    inst_id char(11);
    advisor_id char(11);
begin
    inst_id = get_id();
    advisor_id = (select from student, advisor where student.batch_id=advisor.batch_id);
    execute format('update %I set verdit=%L where id=%L and entry_number=%L', 'i_ticket_'||inst_id, verdict, ticket_id, entry_number);
    execute format('insert into %I(id, entry_number, offering_id) values (%L, %L, %L)', 'b_ticket_'||advisor_id, ticket_id, entry_number, offering_id);
end;
$$;

create or replace procedure ticket_verdict_b(ticket_id int, entry_number char(11), verdit boolean)
language plpgsql
as $$
    advisor_id char(11);
begin
    advisor_id = get_id();
    execute format('update %I set verdit=%L where id=%L and entry_number=%L', 'b_ticket_'||advisor_id, verdict, ticket_id, entry_number);
    execute format('insert into %I(id, entry_number, offering_id) values (%L, %L, %L)', 'd_ticket', entry_number, offering_id);
end;
$$;

create or replace procedure ticket_verdict_d(ticket_id int, verdict boolean)
language plpgsql
as $$
declare
begin
    execute format('update %I set verdit=%L where id=%L and entry_number=%L', 'd_ticket', verdict, ticket_id, entry_number);
end;
$$;

create or replace function get_ticket_verdict_i(ticket_id int, entry_number char(11))
returns boolean
language plpgsql
as $$
declare
    inst_id char(11);
    offering_id int;
begin
    execute format('select offering_id from %I where id=%L', 's_ticket_'||entry_number, ticked_id) into offering_id;

    select instructor.id into inst_id
    from offering, instructor
    where offering.inst_id =instructor.id and offering.id=offering_id;

    return (execute format('select verdict from %I where id=%L and entry_number=%L', 'i_ticket_'||inst_id, ticked_id, entry_number));
end;
$$;

create or replace function get_ticket_verdict_b(ticket_id int, entry_number char(11))
returns boolean
language plpgsql
as $$
declare
    advisor_id char(11);
begin
    select advisor.inst_id into advisor_id
    from student, advisor
    where student.batch_id = advisor.batch_id and student.entry_number = entry_number;
    
    return (execute format('select verdict from %I where id=%L and entry_number=%L', 'b_ticket_'||id, ticket_id, entry_number));
end;
$$;

create or replace function get_ticket_verdict_d(ticket_id int, entry_number char(11))
returns boolean
language plpgsql
as $$
begin
    return (select d_ticket.verdict from d_ticket where d_ticket.id = ticked_id and d_ticket.entry_number = entry_number);
end;
$$;
---------------------------------------------

create or replace procedure add_offering(course_id char(5), inst_id char(11), sem_offered int, year_offered int, slot_id int)
language plpgsql
as $$
begin
    insert into offering(course_id, inst_id, sem_offered, year_offered, slot_id) values(course_id, inst_id, sem_offered, year_offered, slot_id);
end;
$$;

---------------------------------------------

create or replace procedure start_add(current_year int, current_sem int)
language plpgsql
as $$
begin
    update registration_status
    set add_open=true,
    set current_sem=current_sem,
    set current_year=current_year;
end;
$$;

create or replace procedure stop_add()
language plpgsql
as $$
begin
    update registration_status
    set add_open=false,
end;
$$;

create or replace procedure start_withdraw()
language plpgsql
as $$
begin
    update registration_status
    set withdraw_open=true,
end;
$$;

create or replace procedure stop_withdraw()
language plpgsql
as $$
begin
    update registration_status
    set withdraw_open=false,
end;
$$;

---------------------------------------------

create or replace procedure update_credit_grades(filepath varchar(2048), offering_id)
language plpgsql
as $$
declare
    table_name char(50);
    temp_table_name char(50);
begin
    -- COPY zip_codes FROM '/path/to/csv/ZIP_CODES.txt' WITH (FORMAT csv);
    select 'temp_credit_grades_'||offering_id into temp_table_name;
    select 'credit_'||offering_id into table_name;
    execute format('create table %I(entry_number char(11), grade credit_grade)', temp_table_name);
    execute format('copy %I from %L with (format csv)', temp_table_name, filepath);

    if (execute format('
        exists
        (
            (select entry_number from %I)
            except
            (select entry_number from %I)
        )
    ', temp_table_name, table_name)) then
        execute format('drop table %I', temp_table_name);
        raise WARNING "Some students in CSV have not credited this course";
        return;
    end if;

    execute format('
        update %I as t
        set t.grade=x.grade
        from %I as x
        where t.entry_number=x.entry_number
    ', table_name, temp_table_name);

    if (execute format('
        exists
        (
            select *
            from %I as t
            where t.grade=null
        )
    ', table_name)) then
        raise WARNING "Some grades are missing";
    end if;

    execute format('drop table %I', temp_table_name);
end;
$$;

create or replace procedure update_audit_grades(filepath varchar(2048), offering_id)
language plpgsql
as $$
declare
    table_name char(50);
    temp_table_name char(50);
begin
    -- COPY zip_codes FROM '/path/to/csv/ZIP_CODES.txt' WITH (FORMAT csv);
    select 'temp_audit_grades_'||offering_id into temp_table_name;
    select 'audit_'||offering_id into table_name;
    execute format('create table %I(entry_number char(11), grade audit_grade)', temp_table_name);
    execute format('copy %I from %L with (format csv)', temp_table_name, filepath);

    if (execute format('
        exists
        (
            (select entry_number from %I)
            except
            (select entry_number from %I)
        )
    ', temp_table_name, table_name)) then
        execute format('drop table %I', temp_table_name);
        raise WARNING "Some students in CSV have not audited this course";
        return;
    end if;

    execute format('
        update %I as t
        set t.grade=x.grade
        from %I as x
        where t.entry_number=x.entry_number
    ', table_name, temp_table_name);

    if (execute format('
        exists
        (
            select *
            from %I as t
            where t.grade=null
        )
    ', table_name)) then
        raise WARNING "Some grades are missing";
    end if;

    execute format('drop table %I', temp_table_name);
end;
$$;

-----------------------------------------------------
create or replace procedure generate_transcript(entry_number char(11), sem int, year int)
language plpgsql
as $$
declare
    offering_row record;
    course_info record;
begin
    raise INFO 'Entry number: %', entry_number;
    raise INFO 'Name: %', (select name from student where entry_number=entry_number);
    raise INFO 'Year: %', year;
    raise INFO 'Semester: %', sem;

    raise INFO 'Courses Credited';
    for offering_row in (execute format('select (offering_id, grade) from %I where sem_offered=%L and year_offered=%L', 'credit_'||entry_number, sem, year))
    loop
        select * into course_info from offering, course where offering.course_id=course.id and offering.id=offering_id;
        raise INFO '% % %', course_info.id, course_info.name, offering_row.grade;
    end loop;

    raise INFO 'Courses Audited';
    for offering_row in (execute format('select (offering_id, grade) from %I where sem_offered=%L and year_offered=%L', 'audit_'||entry_number, sem, year))
    loop
        select * into course_info from offering, course where offering.course_id=course.id and offering.id=offering_id;
        raise INFO '% % %', course_info.id, course_info.name, offering_row.grade;
    end loop;

    raise INFO 'Courses Withdrawn';
    for offering_row in (execute format('select (offering_id) from %I where sem_offered=%L and year_offered=%L', 'withdraw_'||entry_number, sem, year))
    loop
        select * into course_info from offering, course where offering.course_id=course.id and offering.id=offering_id;
        raise INFO '% % %', course_info.id, course_info.name, 'W';
    end loop;

    raise INFO 'SGPA: %', get_sgpa(entry_number, sem, year);
    raise INFO 'CGPA: %', get_cgpa(entry_number, sem, year);
end;
$$;