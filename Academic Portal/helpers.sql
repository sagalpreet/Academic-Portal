--- HELPER FUNCTIONS

create or replace function get_entry_number()
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
    return (select current_year from add_status);
end;
$$;

create or replace function get_current_sem() 
returns int
language plpgsql
as $$
begin
    return (select current_sem from add_status);
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
begin
    select 'credit_'||entry_number into table_name;
    return (execute format(
        'select sum(n)/sum(d)
        from (
            select course.c * grade_to_number(t.grade), course.c
            from %I as t, offering, course
            where offering.id = t.offering_id and course.id = offering.course_id
        ) x (n, d)'
        , table_name));
end;
$$;

-----------------------------------------------------------

create or replace function is_student_eligible_for_enrollment(entry_number char(11), offering_id int)
returns boolean
language plpgsql
as $$
declare
    satisfies_offering_constraints boolean;
    satisfies_credit_constraints boolean;
    table_name char(18);
    current_year int;
    current_sem int;
    total_sems int;
begin
    current_year = get_current_year();
    current_sem = get_current_sem();

    -- Check if course if being offered in current semester

    select (
        select offering_constr.min_gpa<=get_gpa(entry_number)
        from offering_constr, student
        where offering_constr.batch_id=student.batch_id and offering_constr.offering_id=offering_id
    ) = true into satisfies_offering_constraints;

    select 'credit_'||entry_number into table_name;

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
    )
    into total_sems;

    if total_sems>=2 then
        select sum(course.credit)/2
        from %I as t, offering, course
        where t.offering_id=offering.id and offering.course_id=course.id and
        (
            (offering.year_offered=current_year and offering.sem_offered<current_sem)
            or
            (offering.year_offered=(current_year-1) and offering.sem_offered>=current_sem)
        );
    else
        
    end if;

    return (select satisfies_offering_constraints and satisfies_credit_constraints);
end;
$$;