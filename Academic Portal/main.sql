-- ENTITIES

create table department(
    id int,
    name varchar(30),

    primary key (id)
);

create table batch(
    id int,
    year int,    
    dept_id int,

    primary key (id),
    foreign key (dept_id) references department(id)
);

create table course(
    id char(5),
    name varchar(30),
    l int,
    t int,
    p int,
    s numeric(3, 1),
    c numeric(2, 1),
    dept_id int,

    primary key (id),
    foreign key (dept_id) references department(id)
);

create table student(
    entry_number char(11),
    name varchar(100),
    email char(18),
    batch_id int,
    
    primary key(entry_number),
    foreign key (batch_id) references batch(id)
);

create table instructor(
    id int,
    name varchar(100),
    email varchar(50),
    dept_id int,

    primary key (id),
    foreign key (dept_id) references department(id)
);

create table advisor(
    inst_id int,
    batch_id int,

    primary key (inst_id, batch_id),
    foreign key (inst_id) references instructor(id),
    foreign key (batch_id) references batch(id)
);

create table slot(
    id int,
    duration int,

    primary key (id)
);

create table offering(
    id serial,
    course_id char(5),
    inst_id int,
    sem_offered int,
    year_offered int,
    slot_id int, -- single slot assumed
   
    primary key (id),
    foreign key (slot_id) references slot(id),
    foreign key (course_id) references course(id),
    foreign key (inst_id) references instructor(id)
);

create table add_status(
    id boolean check(value=true),
    add_open boolean,
    current_sem int, 
    current_year int,

    primary key (id)
);

-- RELATIONS

create table prereq(
    course_id char(5),
    prereq_id char(5),

    primary key (course_id, prereq_id),
    foreign key (course_id) references course(id),
    foreign key (prereq_id) references course(id)
);

create table offering_constr(
    offering_id int,
    batch_id int,
    min_gpa numeric(3, 2),
    
    primary key (offering_id, batch_id),
    foreign key (batch_id) references batch(id),
    foreign key (offering_id) references offering(id)
);

-- TYPES

create type credit_grade as enum ('F', 'E', 'D-', 'D', 'C-', 'C', 'B-', 'B', 'A-', 'A');
create type audit_grade as enum ('NP', 'NF');


-- PRIVILEGES

create role student;
create role instructor;
create role advisor;
create role dean_acad with login;

grant select on course, offering, department, batch, instructor, slot to student;

grant select on course, offering, department, batch, instructor, slot to instructor;

-- grant select on all tables in schema public to dean_acad;
grant select on course, offering, department, batch, instructor, slot to dean_acad;
grant insert on course, offering, slot, department, batch, instructor to dean_acad;

revoke all on department from student;

create role 2019csb1113 with login inherit; -- Can login, and inherits privileges
grant student to 2019csb1113; -- All student permissions inherited by 2019csb1113
-- can privilege be granted using triggers?




-- PROCEDURES

create or replace procedure generate_transcript(entry_number char(11), semester int, year int)
language plpgsql
as $$
declare
begin
end;
$$; 