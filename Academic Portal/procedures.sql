-- PROCEDURES

---------------------------------------------------------

create or replace procedure enroll_credit(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    execute format('insert into %I(offering_id) (%L)', 'credit_'||entry_number, offering_id);
end;
$$;

create or replace procedure enroll_audit(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    execute format('insert into %I(offering_id) (%L)', 'audit_'||entry_number, offering_id);
end;
$$;

create or replace procedure drop_offering(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    execute format('insert into %I(offering_id) (%L)', 'drop_'||entry_number, offering_id);
end;
$$;

create or replace procedure withdraw_offering(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();
    execute format('insert into %I(offering_id) (%L)', 'withdraw_'||entry_number, offering_id);
end;
$$;

---------------------------------------------
create or replace procedure generate_ticket(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_id();

    execute format('insert into %I(offering_id) values (%L, %L)', 's_ticket_'||entry_number, offering_id);
end;
$$;

create or replace procedure ticket_verdict_i(ticket_id int, entry_number char(11), verdict boolean)
language plpgsql
as $$
declare
    inst_id char(11);
begin
    inst_id = get_id();
    execute format('update %I set verdit=%L where id=%L and entry_number=%L', 'i_ticket_'||inst_id, verdict, ticket_id, entry_number);
end;
$$;

create or replace procedure ticket_verdict_b(ticket_id int, entry_number char(11), verdit boolean)
language plpgsql
as $$
declare
    advisor_id char(11);
begin
    advisor_id = get_id();
    execute format('update %I set verdit=%L where id=%L and entry_number=%L', 'b_ticket_'||advisor_id, verdict, ticket_id, entry_number);
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
---------------------------------------------

create or replace procedure add_offering(course_id char(5), slot_id int)
language plpgsql
as $$
declare
    inst_id char(11);
    current_sem int;
    current_year int;
    offering_id int;
begin
    inst_id = get_id();
    current_sem = get_current_sem();
    current_year = get_current_year();

    insert into offering(course_id, inst_id, sem_offered, year_offered, slot_id) values(course_id, inst_id, current_sem, current_year, slot_id) returning id into offering_id;

    raise NOTICE 'Offering added with ID: %', offering_id;
end;
$$;

create or replace procedure add_constraints(offering_id char(5), batch_id int, min_gpa numeric(4, 2))
language plpgsql
as $$
declare
    constr_table_name varchar(100);
begin
    select 'constr_'||offering_id into constr_table_name;
    execute format('insert into %I (batch_id, min_gpa) values (%L, %L)', constr_table_name, batch_id, min_gpa);
end;
$$;

---------------------------------------------

create or replace procedure start_add(curr_sem int, curr_year int)
language plpgsql
as $$
begin
    update registration_status
    set add_open=true,
    	current_sem=curr_sem,
    	current_year=curr_year;
end;
$$;

create or replace procedure stop_add()
language plpgsql
as $$
begin
    update registration_status
    set add_open=false;
end;
$$;

create or replace procedure start_withdraw()
language plpgsql
as $$
begin
    update registration_status
    set withdraw_open=true;
end;
$$;

create or replace procedure stop_withdraw()
language plpgsql
as $$
begin
    update registration_status
    set withdraw_open=false;
end;
$$;

---------------------------------------------

create or replace procedure update_credit_grades(filepath varchar(2048), offering_id int)
language plpgsql
as $$
declare
    table_name char(50);
    temp_table_name char(50);
    no_extra_student boolean;
    some_students_left boolean;
begin
    if (not is_offering_offered_in_current_sem_and_year(get_current_sem(), get_current_year())) then
        raise EXCEPTION 'Offering has been completed';
    end if;
    
    select 'temp_credit_grades_'||offering_id into temp_table_name;
    select 'credit_'||offering_id into table_name;
    execute format('create table %I(entry_number char(11), grade credit_grade)', temp_table_name);
    execute format('revoke all on %I from public', temp_table_name);
    execute format('copy %I from %L with (format csv)', temp_table_name, filepath);

	execute format('
        not exists
        (
            (select entry_number from %I)
            except
            (select entry_number from %I)
        )
    ', temp_table_name, table_name) into no_extra_student;
    if (no_extra_student) then
        execute format('drop table %I', temp_table_name);
        raise EXCEPTION 'Some students in CSV have not credited this course';
        return;
    end if;

    execute format('
        update %I as t
        set t.grade=x.grade
        from %I as x
        where t.entry_number=x.entry_number
    ', table_name, temp_table_name);

	execute format('
        exists
        (
            select *
            from %I as t
            where t.grade=null
        )
    ', table_name) into some_students_left;

    if (some_students_left) then
        raise WARNING 'Some grades are missing';
    end if;

    execute format('drop table %I', temp_table_name);
end;
$$;

create or replace procedure update_audit_grades(filepath varchar(2048), offering_id int)
language plpgsql
as $$
declare
    table_name char(50);
    temp_table_name char(50);
    no_extra_student boolean;
    some_students_left boolean;
begin
    if (not is_offering_offered_in_current_sem_and_year(get_current_sem(), get_current_year())) then
        raise EXCEPTION 'Offering has been completed';
    end if;

    select 'temp_audit_grades_'||offering_id into temp_table_name;
    select 'audit_'||offering_id into table_name;
    execute format('create table %I(entry_number char(11), grade audit_grade)', temp_table_name);
    execute format('revoke all on %I from public', temp_table_name);
    execute format('copy %I from %L with (format csv)', temp_table_name, filepath);
    execute format('revoke all on %I from public', temp_table_name);
    execute format('grant all on %I to owner', temp_table_name);
    execute format('
        not exists
        (
            (select entry_number from %I)
            except
            (select entry_number from %I)
        )
    ', temp_table_name, table_name) into no_extra_student;
    if (no_extra_student) then
        execute format('drop table %I', temp_table_name);
        raise WARNING 'Some students in CSV have not audited this course';
        return;
    end if;

    execute format('
        update %I as t
        set t.grade=x.grade
        from %I as x
        where t.entry_number=x.entry_number
    ', table_name, temp_table_name);

	execute format('
        exists
        (
            select *
            from %I as t
            where t.grade=null
        )
    ', table_name) into some_students_left;

    if (some_students_left) then
        raise WARNING 'Some grades are missing';
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
    for offering_row in execute format('select (offering_id, grade) from %I where sem_offered=%L and year_offered=%L', 'credit_'||entry_number, sem, year)
    loop
        select * into course_info from offering, course where offering.course_id=course.id and offering.id=offering_id;
        raise INFO '% % %', course_info.id, course_info.name, offering_row.grade;
    end loop;

    raise INFO 'Courses Audited';
    for offering_row in execute format('select (offering_id, grade) from %I where sem_offered=%L and year_offered=%L', 'audit_'||entry_number, sem, year)
    loop
        select * into course_info from offering, course where offering.course_id=course.id and offering.id=offering_id;
        raise INFO '% % %', course_info.id, course_info.name, offering_row.grade;
    end loop;

    raise INFO 'Courses Withdrawn';
    for offering_row in execute format('select (offering_id) from %I where sem_offered=%L and year_offered=%L', 'withdraw_'||entry_number, sem, year)
    loop
        select * into course_info from offering, course where offering.course_id=course.id and offering.id=offering_id;
        raise INFO '% % %', course_info.id, course_info.name, 'W';
    end loop;

    raise INFO 'SGPA: %', get_sgpa(entry_number, sem, year);
    raise INFO 'CGPA: %', get_cgpa(entry_number, sem, year);
end;
$$;