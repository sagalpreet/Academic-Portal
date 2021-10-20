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
    entry_number = get_entry_number();
    if is_student_eligible_for_enrollment(entry_number, offering_id) then
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
    entry_number = get_entry_number();
    if is_student_eligible_for_enrollment(entry_number char(11), offering_id) then
        execute format('insert into %I(entry_number) (%L)', 'audit_'||offering_id, entry_number); -- for the instructor
        execute format('insert into %I(offering_id) (%L)', 'audit_'||entry_number, offering_id); -- for the student
    end if;
end;
$$;

create or replace procedure withdraw(offering_id int)
language plpgsql
as $$
declare
    entry_number char(11);
begin
    entry_number = get_entry_number();
    execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, offering_id);
    execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, offering_id);
    execute format('delete from %I where student_id=%L', 'credit_'||offering_id, entry_number);
    execute format('delete from %I where student_id=%L', 'audit_'||offering_id, entry_number);
end;
$$;

---------------------------------------------

create or replace procedure add_offering(course_id char(5), inst_id int, sem_offered int, year_offered int, slot_id int)
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
    update add_status
    set add_open=true,
    set current_sem=current_sem,
    set current_year=current_year;
end;
$$;

create or replace procedure stop_add()
language plpgsql
as $$
begin
    update add_status
    set add_open=false,
    set current_sem=null,
    set current_year=null;
end;
$$;