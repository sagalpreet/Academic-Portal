--- HELPER FUNCTIONS
create or replace function get_sgpa(entry_number char(11), sem int, year int)
returns numeric(4, 2)
language plpgsql
as $$
declare
    table_name char(18);
    sgpa numeric(4, 2);
begin
    select 'credit_'||entry_number into table_name;
    execute format('select sum(n)/sum(d)
        from (
            select course.c * grade_to_number(t.grade), course.c
            from %I as t, offering, course
            where offering.id = t.offering_id and course.id = offering.course_id
            and (offering.sem_offered, offering.year_offered)=(%L, %L)
        ) x (n, d)'
        , table_name, sem, year) into sgpa;
    return sgpa;
end;
$$;

create or replace function get_cgpa(entry_number char(11), sem int, year int)
returns numeric(4, 2)
language plpgsql
as $$
declare
    table_name char(18);
    cgpa numeric(4, 2);
begin
    select 'credit_'||entry_number into table_name;
    execute format(
        'select sum(n)/sum(d)
        from (
            select course.c * grade_to_number(t.grade), course.c
            from %I as t, offering, course
            where offering.id = t.offering_id and course.id = offering.course_id
            and (
                offering.year_offered<%L
                or
                (offering.year_offered=%L and offering.sem_offered<=%L)
            )
        ) x (n, d)'
        , table_name, year, year, sem) into cgpa;
    return cpga;
end;
$$;

-----------------------------------------------------------

create or replace function get_id()
returns char(11)
language plpgsql
as $$
begin
    return (select current_user);
end;
$$;

-----------------------------------------------------------

create or replace function get_current_year() 
returns int
language plpgsql
as $$
begin
    return (select current_year from registration_status);
end;
$$;

create or replace function get_current_sem() 
returns int
language plpgsql
as $$
begin
    return (select current_sem from registration_status);
end;
$$;


create or replace function is_add_open() 
returns boolean
language plpgsql
as $$
begin
    return (select add_open from registration_status);
end;
$$;

create or replace function is_withdraw_open() 
returns boolean
language plpgsql
as $$
begin
    return (select withdraw_open from registration_status);
end;
$$;

-----------------------------------------------------------

create or replace function grade_to_number(grade credit_grade)
returns integer
language plpgsql
as $$
begin
    if grade='A' then
        return 10;
    elsif grade='A-' then
        return 9;
    elsif grade='B' then
        return 8;
    elsif grade='B-' then
        return 7;
    elsif grade='C' then
        return 6;
    elsif grade='C-' then
        return 5;
    elsif grade='D' then
        return 4;
    elsif grade='E' then
        return 2;
    elsif grade='F' then
        return 0;
    else
        return 0;
    end if;
end;
$$;

-----------------------------------------------------------

create or replace function get_gpa(entry_number char(11))
returns numeric(4, 2)
language plpgsql
as $$
declare
    table_name char(18);
    gpa numeric(4, 2);
begin
    select 'credit_'||entry_number into table_name;
    execute format(
        'select sum(n)/sum(d)
        from (
            select course.c * grade_to_number(t.grade), course.c
            from %I as t, offering, course
            where offering.id = t.offering_id and course.id = offering.course_id
        ) x (n, d)'
        , table_name) into gpa;
end;
$$;

-----------------------------------------------------------

create or replace function is_offering_offered_in_current_sem_and_year(offering_id int)
returns boolean
language plpgsql
as $$
declare
    current_year int;
    current_sem int;
begin
    return (not exists (select id from offering where offering.id=offering_id and offering.sem_offered=current_sem and offering.year_offered=current_year));
end;
$$;

create or replace function is_slot_conflicting_for_student(entry_number char(11), offering_id int)
returns boolean
language plpgsql
as $$
declare
    current_year int;
    current_sem int;
    is_conflicting boolean;
begin
    current_sem = get_current_sem();
    current_year = get_current_year();
    execute format('
    (select slot_id from offering where offering=offering_id)
    in
    (
        (select slot_id from offering, %I as t where offering.id=t.offering_id)
        union
        (select slot_id from offering, %I as t where offering.id=t.offering_id)
    )', 'credit_'||entry_number, 'audit_'||entry_number) into is_conflicting;
    return is_conflicting;
end;
$$;

create or replace function does_student_satisfy_prereq(entry_number char(11), offering_id int)
returns boolean
language plpgsql
as $$
declare
    course_id char(5);
    satisfies boolean;
begin
    select offering.course_id into course_id from offering where offering.id=offering_id;

    execute format('
        select
        (select prereq.prereq_id from prereq where prereq.course_id=%L)
        all in
        (
        (select course_id from %I where grade not in (\'F\', \'E\'))
        union
        (select course_id from %I where grade not in (\'NF\'))
        )
    )', course_id, 'credit_'||entry_number, 'audit_'||entry_number) into satisfies;

    return satisfies;
end;
$$;

create or replace function is_student_eligible_for_credit(entry_number char(11), offering_id int)
returns boolean
language plpgsql
as $$
declare
    satisfies_offering_constraints boolean;
    satisfies_credit_constraints boolean;
    is_dean_approved boolean;
    table_name char(18);
    avg_credit numeric(4, 2);
    this_sem_credits numeric(4, 2);
    current_year int;
    current_sem int;
    total_sems int;
begin
    current_year = get_current_year();
    current_sem = get_current_sem();

    if (not is_offering_offered_in_current_sem_and_year(offering_id)) then
        return false;
    end if;

    if (is_slot_conflicting_for_student(entry_number, offering_id)) then
        return false;
    end if;

    execute format('(select (
        select constr.min_gpa<=get_gpa(entry_number)
        from %I constr, student
        where constr.batch_id=student.batch_id and constr.offering_id=offering_id
    ) = true)', 'constr_'||NEW.id) into satisfies_offering_constraints;

    select 'credit_'||entry_number into table_name;

	execute format('
    select count(*)
    from (
        select distinct offering.sem_offered, offering.year_offered
        from %I as t, offering, course
        where t.offering_id=offering.id and offering.course_id=course.id and
        (
            (offering.year_offered=current_year and offering.sem_offered<current_sem)
            or
            (offering.year_offered=(current_year-1))
        )
    )', table_name)
    into total_sems;

    if total_sems>=2 then
    execute format('select sum(course.credit)/2
        from %I as t, offering, course
        where t.offering_id=offering.id and offering.course_id=course.id and
        (
            (offering.year_offered=current_year and offering.sem_offered<current_sem)
            or
            (offering.year_offered=(current_year-1) and offering.sem_offered>=current_sem)
        )', table_name) into avg_credit;
    else
        avg_credit=0;
    end if;

    execute format('select sum(course.credit)
        from %I as t, offering, course
        where t.offering_id=offering.id and offering.course_id=course.id and
        offering.sem_offered=%L and offering.year_offered=%L
    ', table_name, current_sem, current_year) into this_sem_credits;

    select (this_sem_credits)<(1.25*avg_credit) into satisfies_credit_constraints;

    execute format('select (true in (select d_verdict from %I where offering_id=%L))', 's_ticket_'||entry_number, offering_id) into is_dean_approved;

    return ((satisfies_offering_constraints and satisfies_credit_constraints and does_student_satisfy_prereq(entry_number, offering_id)) or (is_dean_approved));
end;
$$;

create or replace function is_student_eligible_for_audit(entry_number char(11), offering_id int)
returns boolean
language plpgsql
as $$
declare
    satisfies_offering_constraints boolean;
    is_dean_approved boolean;
    table_name char(18);
    current_year int;
    current_sem int;
    total_sems int;
begin
    current_year = get_current_year();
    current_sem = get_current_sem();

    if (not is_offering_offered_in_current_sem_and_year(offering_id)) then
        return false;
    end if;

    if (is_slot_conflicting_for_student(entry_number, offering_id)) then
        return false;
    end if;

    execute format('(select (
        select constr.min_gpa<=get_gpa(entry_number)
        from %I constr, student
        where constr.batch_id=student.batch_id and constr.offering_id=offering_id
    ) = true)', 'constr_'||NEW.id) into satisfies_offering_constraints;

    execute format('select (true in (select d_verdict from %I where offering_id=%L))', 's_ticket_'||entry_number, offering_id) into is_dean_approved;

    return ((satisfies_offering_constraints  and does_student_satisfy_prereq(entry_number, offering_id)) or is_dean_approved);
end;
$$;