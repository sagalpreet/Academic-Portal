-- TRIGGERS

---------------------------------------------------------

create or replace function add_offering_trigger_function()
returns trigger
language plpgsql
as $$
begin
    execute format('create table %I (entry_number char(11) primary key, grade credit_grade, foreign key (entry_number) references student(entry_number) on update cascade);', 'credit_'||NEW.id);
    execute format('create table %I (entry_number char(11) primary key, grade audit_grade, foreign key (entry_number) references student(entry_number) on update cascade);', 'audit_'||NEW.id);
    execute format('create table %I (entry_number char(11) primary key, foreign key (entry_number) references student(entry_number) on update cascade);', 'withdraw_'||NEW.id);
    return NEW;
end;
$$;

create trigger add_offering
after insert on offering
for each row
execute function add_offering_trigger_function();

---------------------------------------------------------

create or replace function add_s_ticket_trigger_function()
returns trigger
language plpgsql
as $$
declare
    entry_number char(11);
    inst_id char(11);
begin
    entry_number = get_id();

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
    execute format('create table %I (offering_id int primary key, grade credit_grade, foreign key (offering_id) references offering(id));', 'credit_'||NEW.entry_number);
    execute format('create table %I (offering_id int primary key, grade audit_grade, foreign key (offering_id) references offering(id));', 'audit_'||NEW.entry_number);
    execute format('create table %I (offering_id int primary key, foreign key (offering_id) references offering(id));', 'withdraw_'||NEW.entry_number);
    execute format('create table %I (id serial primary key, offering_id int);', 's_ticket_'||NEW.entry_number);
    execute format('create trigger %I
    after insert on %I
    for each row
    execute function add_s_ticket_trigger_function()', 'add_s_ticket_'||NEW.entry_number, 's_ticket_'||NEW.entry_number);
    return NEW;
end;
$$;

create trigger add_student
after insert on student
for each row 
execute function add_student_trigger_function();

---------------------------------------------------------

create or replace function add_instructor_trigger_function()
returns trigger
language plpgsql
as $$
begin
    execute format('create table %I (id int not null, entry_number char(11) not null, verdict boolean, primary key (id, entry_number), foreign key (entry_number) references student(entry_number));', 'i_ticket_'||NEW.id);
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
    execute format('create table %I (id int not null, entry_number char(11) not null, verdict boolean, primary key (id, entry_number), foreign key (entry_number) references student(entry_number));', 'b_ticket_'||NEW.inst_id);
    return NEW;
end;
$$;

create trigger add_advisor
after insert on advisor
for each row 
execute function add_advisor_trigger_function();

---------------------------------------------------------