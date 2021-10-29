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
    email char(24),
    batch_id int,
    
    primary key(entry_number),
    foreign key (batch_id) references batch(id)
);

create table instructor(
    id char(11),
    name varchar(100),
    email varchar(50),
    dept_id int,

    primary key (id),
    foreign key (dept_id) references department(id)
);

create table advisor(
    inst_id char(11),
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
    inst_id char(11),
    sem_offered int,
    year_offered int,
    slot_id int, -- single slot assumed
   
    primary key (id),
    foreign key (slot_id) references slot(id),
    foreign key (course_id) references course(id),
    foreign key (inst_id) references instructor(id)
);

create table registration_status(
    id boolean check(id=true),
    add_open boolean,
    withdraw_open boolean,
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

-- TYPES

create type credit_grade as enum ('F', 'E', 'D-', 'D', 'C-', 'C', 'B-', 'B', 'A-', 'A');
create type audit_grade as enum ('NP', 'NF');

-- MISCELLANEOUS

create table d_ticket(
    id int not null,
    entry_number char(11),
    verdict boolean,

    primary key (id, entry_number),
    foreign key (entry_number) references student(entry_number)
);

insert into registration_status(id, add_open, withdraw_open, current_sem, current_year) values(true, false, false, NULL, NULL);

