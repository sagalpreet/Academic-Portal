-- triggers

-- enroll_credit


---------------------------------------------------------

create or replace function add_offering_trigger_function()
returns trigger
language plpgsql
security definer
as $$
begin
    execute format('create table %I (entry_number char(11) primary key, grade credit_grade, foreign key (entry_number) references student(entry_number) on update cascade);', 'credit_'||NEW.id);
    execute format('create table %I (entry_number char(11) primary key, grade audit_grade, foreign key (entry_number) references student(entry_number) on update cascade);', 'audit_'||NEW.id);
    execute format('create table %I (entry_number char(11) primary key, foreign key (entry_number) references student(entry_number) on update cascade);', 'drop_'||NEW.id);
    execute format('create table %I (entry_number char(11) primary key, foreign key (entry_number) references student(entry_number) on update cascade);', 'withdraw_'||NEW.id);

    execute format('create table %I (batch_id int primary key, min_gpa numeric(4, 2) check (min_gpa<=10 and min_gpa>=0), foreign key (batch_id) references batch(id))', 'constr_'||NEW.id);
    execute format($constr_update_str$
        create or replace function %I()
        returns trigger
        language plpgsql
        as $trigger_func$
        begin
            if (NEW.batch_id <> OLD.batch_id) then
                raise EXCEPTION 'Cannot change batch';
            end if;
            if (NEW.min_gpa>OLD.min_gpa) then
                raise EXCEPTION 'Cannot tighten GPA constraint';
            end if;
            return NEW;
        end;
        $trigger_func$;

        create trigger %I
        before update on %I
        for each row
        execute function %I();
    $constr_update_str$, 'constr_update_func_'||NEW.id, 'constr_update_'||NEW.id, 'constr_'||NEW.id, 'constr_update_func_'||NEW.id);
    return NEW;

    execute format('revoke all on table %I from public', 'credit_'||NEW.id);
    execute format('grant select, update on table %I to %I', 'credit_'||NEW.id, NEW.inst_id);
    execute format('revoke all on table %I from public', 'audit_'||NEW.id);
    execute format('grant select, update on table %I to %I', 'audit_'||NEW.id, NEW.inst_id);
    execute format('revoke all on table %I from public', 'drop_'||NEW.id);
    execute format('grant select, update on table %I to %I', 'drop_'||NEW.id, NEW.inst_id);
    execute format('revoke all on table %I from public', 'withdraw_'||NEW.id);
    execute format('grant select, update on table %I to %I', 'withdraw_'||NEW.id, NEW.inst_id);

    execute format('revoke all on function %I from public', 'constr_update_func_'||NEW.id);
end;
$$;

create trigger add_offering
after insert on offering
for each row
execute function add_offering_trigger_function();

create or replace function add_offering_security_check()
returns trigger
language plpgsql
security invoker
as $$
begin
    if (NEW.inst_id <> get_id()) then
        raise EXCEPTION 'Illegal action';
    end if;
    return NEW;
end;
$$;

create trigger add_offering_security_check
before insert on offering
for each row
execute function add_offering_security_check();

---------------------------------------------------------

create or replace function add_s_ticket_trigger_function()
returns trigger
language plpgsql
security definer
as $$
declare
    entry_number char(11);
    inst_id char(11);
begin
    entry_number = get_id();
    if (NEW.i_verdict <> NULL or NEW.b_verdict <> NULL or NEW.d_verdict <> NULL) then
        raise EXCEPTION 'Illegal ticket insertion';
    end if;
    if (not is_offering_offered_in_current_sem_and_year(NEW.offering_id)) then
        raise EXCEPTION 'Offering unavailable for this semester';
    end if;

    select instructor.id into inst_id
    from offering, instructor
    where offering.inst_id = instructor.id and offering.id=NEW.offering_id;

    execute format('insert into %I(id, entry_number) values(%L, %L)', 'i_ticket_'||inst_id, NEW.id, entry_number);
end;
$$;

create or replace function add_student_trigger_function()
returns trigger
language plpgsql
as $$
begin
    execute format('create role %I with login password %L', NEW.entry_number, 'iitrpr');
    execute format('grant student to %I', NEW.entry_number);
    
    execute format('create table %I (offering_id int primary key, grade credit_grade, foreign key (offering_id) references offering(id));', 'credit_'||NEW.entry_number);
    execute format('create table %I (offering_id int primary key, grade audit_grade, foreign key (offering_id) references offering(id));', 'audit_'||NEW.entry_number);
    execute format('create table %I (offering_id int primary key, foreign key (offering_id) references offering(id));', 'drop_'||NEW.entry_number);
    execute format('create table %I (offering_id int primary key, foreign key (offering_id) references offering(id));', 'withdraw_'||NEW.entry_number);
    execute format('create table %I (id serial primary key, offering_id int, i_verdict boolean, b_verdict boolean, d_verdict boolean, foreign key (offering_id) references offering(id));', 's_ticket_'||NEW.entry_number);

    execute format('revoke all on %I, %I, %I, %I, %I from public', 'credit_'||NEW.entry_number, 'audit_'||NEW.entry_number, 'drop_'||NEW.entry_number, 'withdraw_'||NEW.entry_number, 's_ticket_'||NEW.entry_number);
    execute format('grant insert on %I, %I, %I, %I, %I to %I', 'credit_'||NEW.entry_number, 'audit_'||NEW.entry_number, 'drop_'||NEW.entry_number, 'withdraw_'||NEW.entry_number, 's_ticket_'||NEW.entry_number, NEW.entry_number);

    execute format('create trigger %I
    after insert on %I
    for each row
    execute function add_s_ticket_trigger_function()', 'add_s_ticket_'||NEW.entry_number, 's_ticket_'||NEW.entry_number);
    
    execute format($enroll_credit_trigger_func$
        create or replace function %I()
        returns trigger
        language plpgsql
        security definer
        as $trigger_func$
        declare
            entry_number char(11);
        begin
            if not (is_student_eligible_for_credit(entry_number, NEW.offering_id) and is_add_open()) then
                raise EXCEPTION 'Not eligible to credit this course';
            end if
            
            entry_number = %L;
            
            execute format('delete from %I where entry_number=%L', 'audit_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, NEW.offering_id);
            execute format('delete from %I where entry_number=%L', 'drop_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'drop_'||entry_number, NEW.offering_id);

            execute format('insert into %I(entry_number) (%L)', 'credit_'||NEW.offering_id, entry_number);

            return NEW;
        end;
        $trigger_func$;

        create trigger %I
        before insert on %I
        for each row
        execute function %I();
    $enroll_credit_trigger_func$, 'enroll_credit_func_'||NEW.entry_number, NEW.entry_number, 'enroll_credit_'||NEW.entry_number, 'credit_'||NEW.entry_number, 'enroll_credit_func_'||NEW.entry_number);

    execute format($enroll_audit_trigger_func$
        create or replace function %I()
        returns trigger
        language plpgsql
        security definer
        as $trigger_func$
        declare
            entry_number char(11);
        begin
            if not (is_student_eligible_for_audit(entry_number, NEW.offering_id) and is_add_open()) then
                raise EXCEPTION 'Not eligible to credit this course';
            end if
            
            entry_number = %L;
            
            execute format('delete from %I where entry_number=%L', 'credit_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, NEW.offering_id);
            execute format('delete from %I where entry_number=%L', 'drop_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'drop_'||entry_number, NEW.offering_id);

            execute format('insert into %I(entry_number) (%L)', 'audit_'||NEW.offering_id, entry_number);

            return NEW;
        end;
        $trigger_func$;

        create trigger %I
        before insert on %I
        for each row
        execute function %I();
    $enroll_audit_trigger_func$, 'enroll_audit_func_'||NEW.entry_number, NEW.entry_number, 'enroll_audit_'||NEW.entry_number, 'audit_'||NEW.entry_number, 'enroll_audit_func_'||NEW.entry_number);

    execute format($drop_trigger_func$
        create or replace function %I()
        returns trigger
        language plpgsql
        security definer
        as $trigger_func$
        declare
            entry_number char(11);
            has_taken_course int;
        begin
            if (not is_offering_offered_in_current_sem_and_year(NEW.offering_id)) then
                raise EXCEPTION 'Offering is from previous semester and year';
                return;
            end if;
            if not is_add_open() then
                raise EXCEPTION 'Drop window is not open';
                return;
            end if;
            
            entry_number = %L;

            execute format('
                select count(*)
                from (%I union %I) as x
                where x.offering_id = NEW.offering_id
            ', 'credit_'||NEW.offering_id, 'audit_'||NEW.offering_id) into has_taken_course;

            if (has_taken_course=0) then
                raise EXCEPTION 'Course has not been added';
            end if;
            
            execute format('delete from %I where entry_number=%L', 'credit_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, NEW.offering_id);
            execute format('delete from %I where entry_number=%L', 'audit_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, NEW.offering_id);

            execute format('insert into %I(entry_number) (%L)', 'drop_'||NEW.offering_id, entry_number);

            return NEW;
        end;
        $trigger_func$;

        create trigger %I
        before insert on %I
        for each row
        execute function %I();
    $drop_trigger_func$, 'enroll_drop_func_'||NEW.entry_number, NEW.entry_number, 'enroll_drop_'||NEW.entry_number, 'drop_'||NEW.entry_number, 'enroll_drop_func_'||NEW.entry_number);
    

    execute format($withdraw_trigger_func$
        create or replace function %I()
        returns trigger
        language plpgsql
        security definer
        as $trigger_func$
        declare
            entry_number char(11);
            has_taken_course int;
        begin
            if (not is_offering_offered_in_current_sem_and_year(NEW.offering_id)) then
                raise EXCEPTION 'Offering is from previous semester and year';
                return;
            end if;
            if not is_withdraw_open() then
                raise EXCEPTION 'Withdraw window is not open';
                return;
            end if;
            
            entry_number = %L;

            execute format('
                select count(*)
                from (%I union %I) as x
                where x.offering_id = NEW.offering_id
            ', 'credit_'||NEW.offering_id, 'audit_'||NEW.offering_id) into has_taken_course;

            if (has_taken_course=0) then
                raise EXCEPTION 'Course has not been added';
            end if;
            
            execute format('delete from %I where entry_number=%L', 'credit_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'credit_'||entry_number, NEW.offering_id);
            execute format('delete from %I where entry_number=%L', 'audit_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'audit_'||entry_number, NEW.offering_id);
            execute format('delete from %I where entry_number=%L', 'drop_'||NEW.offering_id, entry_number);
            execute format('delete from %I where offering_id=%L', 'drop_'||entry_number, NEW.offering_id);

            execute format('insert into %I(entry_number) (%L)', 'drop_'||NEW.offering_id, entry_number);

            return NEW;
        end;
        $trigger_func$;

        create trigger %I
        before insert on %I
        for each row
        execute function %I();
    $withdraw_trigger_func$, 'enroll_withdraw_func_'||NEW.entry_number, NEW.entry_number, 'enroll_withdraw_'||NEW.entry_number, 'withdraw_'||NEW.entry_number, 'enroll_withdraw_func_'||NEW.entry_number);

    execute format('revoke all on function %I, %I, %I, %I from public', 'enroll_credit_func_'||NEW.entry_number, 'enroll_audit_func_'||NEW.entry_number, 'enroll_drop_func_'||NEW.entry_number, 'enroll_withdraw_func_'||NEW.entry_number);

    return NEW;
end;
$$;

create trigger add_student
before insert on student
for each row 
execute function add_student_trigger_function();

---------------------------------------------------------

create or replace function add_instructor_trigger_function()
returns trigger
language plpgsql
as $$
declare
begin
    execute format('create role %I with login password %L', NEW.id, 'iitrpr');
    execute format('grant instructor to %I', NEW.id);

    execute format('create table %I (id int not null, entry_number char(11) not null, verdict boolean, primary key (id, entry_number), foreign key (entry_number) references student(entry_number));', 'i_ticket_'||NEW.id);

    execute format('revoke all on table %I from public', 'i_ticket_'||NEW.id);
    execute format('grant select, update on table %I to %I', 'i_ticket_'||NEW.id, NEW.id);

    execute format($i_ticket_verdict_trigger_func$
        create or replace function %I()
        returns trigger
        language plpgsql
        security definer
        as $trigger_func$
        declare
            advisor_id char(11);
        begin
            if (OLD.verdict <> NULL) then
                raise EXCEPTION 'Verdict already given';
            end if;
            advisor_id = (select advisor.id from student, advisor where student.batch_id=advisor.batch_id and student.entry_number=OLD.entry_number);

            execute format('insert into %I(id, entry_number) values (%L, %L, %L)', 'b_ticket_'||advisor_id, OLD.ticket_id, OLD.entry_number);
            execute format('update %I set i_verdit=%L where id=%L', 's_ticket_'||OLD.entry_number, NEW.verdict, OLD.ticked_id);

            return NEW;
        end;
        $trigger_func$;

        create trigger %I
        before update on %I
        for each row
        execute function %I();
    $i_ticket_verdict_trigger_func$, 'i_ticket_verdict_func_'||NEW.id, 'i_ticket_verdict_'||NEW.id, 'i_ticket_'||NEW.id, 'i_ticket_verdict_func_'||NEW.id);

    execute format('revoke all on function %I from public', 'i_ticket_verdict_func_'||NEW.id);

    return NEW;
end;
$$;

create trigger add_instructor
after insert on instructor
for each row 
execute function add_instructor_trigger_function();

---------------------------------------------------------

create or replace function add_advisor_trigger_function()
returns trigger
language plpgsql
as $$
begin
    execute format('grant advisor to %I', NEW.inst_id);

    execute format('create table %I (id int not null, entry_number char(11) not null, verdict boolean, primary key (id, entry_number), foreign key (entry_number) references student(entry_number));', 'b_ticket_'||NEW.inst_id);

    execute format('revoke all on table %I from public', 'b_ticket_'||NEW.inst_id);
    execute format('grant select, update on table %I to %I', 'b_ticket_'||NEW.id, NEW.inst_id);
    
    execute format($b_ticket_verdict_trigger_func$
        create or replace function %I()
        returns trigger
        language plpgsql
        security definer
        as $trigger_func$
        declare
        begin
            if (OLD.verdict <> NULL) then
                raise EXCEPTION 'Verdict already given';
            end if;

            execute format('insert into %I(id, entry_number) values (%L, %L, %L)', 'd_ticket_', OLD.ticket_id, OLD.entry_number);
            execute format('update %I set b_verdit=%L where id=%L', 's_ticket_'||OLD.entry_number, NEW.verdict, OLD.ticked_id);

            return NEW;
        end;
        $trigger_func$;

        create trigger %I
        before update on %I
        for each row
        execute function %I();
    $b_ticket_verdict_trigger_func$, 'b_ticket_verdict_func_'||NEW.id, 'b_ticket_verdict_'||NEW.id, 'b_ticket_'||NEW.inst_id, 'b_ticket_verdict_func_'||NEW.id);

    execute format('revoke all on function %I from public', 'b_ticket_verdict_func_'||NEW.inst_id);
    return NEW;
end;
$$;

create trigger add_advisor
after insert on advisor
for each row 
execute function add_advisor_trigger_function();

---------------------------------------------------------

create or replace function d_ticket_verdict_func()
returns trigger
language plpgsql
security definer
as $$
declare
    offering_id int;
begin
    if (OLD.verdict <> NULL) then
        raise EXCEPTION 'Verdict already given';
    end if;

    execute format('update %I set d_verdit=%L where id=%L', 's_ticket_'||OLD.entry_number, NEW.verdict, OLD.ticked_id);

    if (NEW.verdict=true) then
        execute format('select offering_id from %I where id=%L', 's_ticket_'||NEW.entry_number, NEW.ticket_id) into offering_id;
        raise NOTICE 'Student % can now enroll in offering (id: %)', NEW.entry_number, offering_id;
    end if;

    return NEW;
end;
$$;

create trigger d_ticket_verdict
before update on d_ticket
for each row
execute function d_ticket_verdict_func();
