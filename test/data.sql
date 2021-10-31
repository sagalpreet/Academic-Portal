-- Run as dean acad

insert into slot values (1, 50), (2, 50), (3, 50), (4, 100), (5, 30);
insert into department values (1, 'CSE'), (2, 'EE'), (3, 'ME');

insert into course values
('CS101', 'Discrete Maths', 3, 1, 2, 3.5, 3, 1),
('CS201', 'Data Structures', 3, 1, 2, 3.5, 4, 1),
('EE101', 'Electrical Introduction', 3, 1, 2, 3.5, 3, 2),
('EE201', 'Signals', 3, 1, 2, 3.5, 3, 2),
('ME101', 'Engineering Drawing', 3, 1, 2, 3.5, 3, 3),
('ME201', 'Materials', 3, 1, 2, 3.5, 3, 3);

insert into prereq values
('CS201', 'CS101'),
('EE201', 'EE101'),
('ME201', 'ME101');

insert into instructor values
('2015csp0001', 'Dumbledore', 'ddore@iitrpr.ac.in', 1),
('2015csp0002', 'Snape', 'snape@iitrpr.ac.in', 1),
('2010eep0003', 'Ben', 'ben@iitrpr.ac.in', 2),
('2016eep0010', 'Jaspreet', 'bumrah@iitrpr.ac.in', 2),
('2014mep0001', 'Wasim', 'wasim@iitrpr.ac.in', 3),
('2017mep0020', 'Brett', 'brett@iitrpr.ac.in', 3);
