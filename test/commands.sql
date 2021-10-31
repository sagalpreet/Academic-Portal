-- prepare for new batch

insert into batch values (1, 2021, 1), (2, 2021, 2), (3, 2021, 3);

insert into student values
('2021csb1113', 'John', '2021csb1113@iitrpr.ac.in', 1),
('2021csb1068', 'Jim', '2021csb1068@iitrpr.ac.in', 1),
('2021csb0000', 'Jonny', '2021csb0000@iitrpr.ac.in', 1),
('2021eeb1000', 'Kim', '2021eeb1000@iitrpr.ac.in', 2),
('2021eeb1001', 'Peter', '2021eeb1001@iitrpr.ac.in', 2),
('2021meb0001', 'Harry', '2021meb0001@iitrpr.ac.in', 3),
('2021meb0000', 'Neel', '2021meb0000@iitrpr.ac.in', 3);

insert into advisor values
('2015csp0001', 1),
('2015csp0002', 2),
('2010eep0003', 3);

-- new semester begins
call start_add(1, 2021);

call add_offering('CS101', 1); -- run by 2015csp0001
call add_constraints(1, 1, 7);

call add_offering('EE101', 1); -- run by 2010eep0003
call add_constraints(2, 2, 7);

call add_offering('ME101', 1); -- run by 2014mep0001
call add_constraints(3, 3, 7);


call enroll_credit(1); -- run as 2021csb1113
call enroll_credit(2); -- run as 2021eeb1000
call enroll_credit(3); -- run as 2021meb0001

call stop_add(); -- run as dean_acad

call start_withdraw(); -- run as dean_acad

call stop_withdraw(); -- run as dean_acad

call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_1_1.csv', 1); -- run by 2015csp0001
call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_1_2.csv', 2); -- run by 2010eep0003
call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_1_3.csv', 3); -- run by 2014mep0001

-- run as dean_acad
call generate_transcript('2021csb1113', 1, 2021);

-- prepare for new batch
insert into batch values (4, 2022, 1), (5, 2022, 2), (6, 2022, 3);

insert into student values
('2022csb1113', 'Bruno', '2022csb1113@iitrpr.ac.in', 4),
('2022csb1068', 'Selena', '2022csb1068@iitrpr.ac.in', 4),
('2022csb0000', 'Justin', '2022csb0000@iitrpr.ac.in', 4),
('2022eeb1000', 'Joe', '2022eeb1000@iitrpr.ac.in', 5),
('2022eeb1001', 'Mike', '2022eeb1001@iitrpr.ac.in', 5),
('2022meb0001', 'Zayn', '2022meb0001@iitrpr.ac.in', 6),
('2022meb0000', 'Virat', '2022meb0000@iitrpr.ac.in', 6);

insert into advisor values
('2016eep0010', 4),
('2014mep0001', 5),
('2017mep0020', 6);

-- new semester begins
call start_add(2, 2021);

call add_offering('CS101', 1); -- run by 2015csp0001
call add_constraints(4, 1, 7);
call add_constraints(4, 2, 7);
call add_constraints(4, 3, 7);
call add_constraints(4, 4, 7);

call add_offering('CS201', 2); 
call add_constraints(5, 1, 7);

call add_offering('EE101', 1); -- run by 2010eep0003
call add_constraints(6, 1, 7);
call add_constraints(6, 2, 7);
call add_constraints(6, 3, 7);
call add_constraints(6, 5, 7);

call add_offering('EE201', 2);
call add_constraints(7, 2, 7);

call add_offering('ME101', 1); -- run by 2014mep0001
call add_constraints(8, 1, 7);
call add_constraints(8, 2, 7);
call add_constraints(8, 3, 7);
call add_constraints(8, 6, 7);

call add_offering('ME201', 2);
call add_constraints(9, 3, 7);


call enroll_credit(5); -- run as 2021csb1113
call enroll_credit(7); -- run as 2021eeb1000
call enroll_credit(4); 
call enroll_credit(9); -- run as 2021meb0001
call enroll_audit(4); 
call generate_ticket(4);
call ticket_verdict_i(1, '2021meb0001', false); -- run as 2015csp0001
call ticket_verdict_b(1, '2021meb0001', true); -- run as 2010eep0003
call ticket_verdict_d(1, '2021meb0001', true); -- run as dean_acad
call enroll_audit(4); -- run as 2021meb0001

call enroll_credit(4); -- run as 2022csb1113
call enroll_credit(6); -- run as 2022eeb1000
call enroll_credit(8); -- run as 2022meb0001

call stop_add(); -- run as dean_acad

call start_withdraw(); -- run as dean_acad

call withdraw_offering(4); -- run as 2021meb0001

call stop_withdraw(); -- run as dean_acad

call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_2_4.csv', 4); -- 2015csp0001
call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_2_5.csv', 5); -- 2015csp0001
call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_2_6.csv', 6); -- 2010eep0003
call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_2_7.csv', 7); -- 2010eep0003
call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_2_8.csv', 8); -- 2014mep0001
call update_credit_grades('/home/aman/Documents/btech/cs301/project/Academic-Portal/grades/2021_2_9.csv', 9); -- 2014mep0001