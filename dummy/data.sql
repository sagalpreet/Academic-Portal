
-- Run as dean acad

insert into slot values (1, 50), (2, 50), (3, 50), (4, 100), (5, 30);
insert into department values (1, 'CSE'), (2, 'EE'), (3, 'ME');

insert into course values
('CS201', 'Discrete Maths', 3, 1, 2, 3.5, 3, 1),
('CS202', 'Programming Paradigms', 3, 1, 2, 3.5, 4, 1),
('CS203', 'Digital Logic', 3, 1, 2, 3.5, 3, 1),
('CS301', 'Databases', 3, 1, 2, 3.5, 3, 1),
('CS302', 'Design of Algorithms', 3, 1, 2, 1.5, 3, 1),
('CS303', 'Operating Systems', 3, 1, 2, 3.5, 3, 1);

insert into prereq values
('CS301', 'CS201'),
('CS302', 'CS202'),
('CS303', 'CS203');

insert into instructor values
('2015csp0001', 'Dumbledore', 'ddore@iitrpr.ac.in', 1),
('2015csp0002', 'Snape', 'snape@iitrpr.ac.in', 1),
('2010eep0003', 'Ben', 'ben@iitrpr.ac.in', 2),
('2016eep0010', 'Jaspreet', 'bumrah@iitrpr.ac.in', 2),
('2014mep0001', 'Wasim', 'wasim@iitrpr.ac.in', 3),
('2017mep0020', 'Brett', 'brett@iitrpr.ac.in', 3);
