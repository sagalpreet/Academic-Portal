-- TRIGGERS

---------------------------------------------------------

create or replace function add_offering_trigger_function()
returns trigger
language plpgsql
as $$
begin
    execute format('create table %I (entry_number int primary key, grade credit_grade, foreign key (entry_number) references student(entry_number) on update cascade);', 'credit_'||NEW.id);
    execute format('create table %I (entry_number int primary key, grade audit_grade, foreign key (entry_number) references student(entry_number) on update cascade);', 'audit_'||NEW.id);
    return NEW;
end;
$$;

create trigger add_offering
after insert on offering
for each row
execute function add_offering_trigger_function();

---------------------------------------------------------

create or replace function add_student_trigger_function()
returns trigger
language plpgsql
as $$
begin
    execute format('create table %I (offering_id int primary key, grade credit_grade, foreign key (offering_id) references offering(id));', 'credit_'||NEW.entry_number);
    execute format('create table %I (offering_id int primary key, grade audit_grade, foreign key (offering_id) references offering(id));', 'audit_'||NEW.entry_number);
    return NEW;
end;
$$;

create trigger add_student
after insert on student
for each row 
execute function add_student_trigger_function();

---------------------------------------------------------

