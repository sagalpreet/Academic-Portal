-- TABLES

create role student;
create role instructor;
create role advisor;
create role dean_acad with login password 'iitrpr';

revoke all on all tables in schema public from public;
grant references on all tables in schema public to public;
revoke all on all functions in schema public from public;
revoke all on all procedures in schema public from public;


grant select, references on table department, slot, batch, course, student, instructor, advisor, offering, prereq, registration_status to student, instructor, advisor;
grant all on table department, slot, batch, course, student, instructor, advisor, prereq, registration_status to dean_acad;
grant insert on table offering to instructor;
grant select on table offering to dean_acad;
grant select, update on table registration_status, d_ticket to dean_acad;
grant pg_read_server_files to instructor;

grant usage on sequence offering_id_seq to instructor;

-- PROCEDURES

grant execute on procedure enroll_credit to student;
grant execute on procedure enroll_audit to student;
grant execute on procedure drop_offering to student;
grant execute on procedure withdraw_offering to student;
grant execute on procedure generate_ticket to student;

grant execute on procedure ticket_verdict_i to instructor;
grant execute on procedure ticket_verdict_b to advisor;
grant execute on procedure ticket_verdict_d to dean_acad;

grant execute on procedure add_offering to instructor;
grant execute on procedure add_constraints to instructor;

grant execute on procedure start_add to dean_acad;
grant execute on procedure stop_add to dean_acad;
grant execute on procedure start_withdraw to dean_acad;
grant execute on procedure stop_withdraw to dean_acad;

grant execute on procedure update_credit_grades to instructor;
grant execute on procedure update_audit_grades to instructor;

grant execute on procedure generate_transcript to dean_acad;

-- HELPER FUNCTIONS
grant execute on function get_id, grade_to_number to student, instructor, advisor, dean_acad;
grant execute on function get_current_sem, get_current_year to student, instructor, advisor, dean_acad;
grant execute on function is_offering_offered_in_current_sem_and_year to student, instructor, advisor, dean_acad;
grant execute on function is_add_open, is_withdraw_open to student, instructor, advisor, dean_acad;

grant execute on function is_slot_conflicting_for_instructor to instructor;
grant execute on function get_cgpa, get_sgpa to dean_acad, student;

-- TRIGGER FUNCTIONS

revoke all on function add_offering_trigger_function from public;
revoke all on function add_student_trigger_function from public;
revoke all on function add_instructor_trigger_function from public;
revoke all on function add_advisor_trigger_function from public;
revoke all on function d_ticket_verdict_func from public;
