insert into slot values (1, 50), (2, 50), (3, 50), (4, 100), (5, 30);

insert into department values (1, 'CSE'), (2, 'EE'), (3, 'ME');

insert into batch values (1, 2019, 1), (2, 2019, 2), (3, 2019, 3), (4, 2020, 1), (5, 2020, 2), (6, 2020, 3);

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

insert into student values
('2019csb1113', 'John', '2019csb1113@iitrpr.ac.in', 1),
('2019csb1068', 'Jim', '2019csb1068@iitrpr.ac.in', 1),
('2019csb0000', 'Jonny', '2019csb0000@iitrpr.ac.in', 1),
('2019eeb1000', 'Kim', '2019eeb1000@iitrpr.ac.in', 2),
('2019eeb1001', 'Peter', '2019eeb1001@iitrpr.ac.in', 2),
('2019meb0001', 'Harry', '2019meb0001@iitrpr.ac.in', 3),
('2019meb0000', 'Neel', '2019meb0000@iitrpr.ac.in', 3),
('2020csb1113', 'Bruno', '2020csb1113@iitrpr.ac.in', 4),
('2020csb1068', 'Selena', '2020csb1068@iitrpr.ac.in', 4),
('2020csb0000', 'Justin', '2020csb0000@iitrpr.ac.in', 4),
('2020eeb1000', 'Joe', '2020eeb1000@iitrpr.ac.in', 5),
('2020eeb1001', 'Mike', '2020eeb1001@iitrpr.ac.in', 5),
('2020meb0001', 'Zayn', '2020meb0001@iitrpr.ac.in', 6),
('2020meb0000', 'Virat', '2020meb0000@iitrpr.ac.in', 6);

insert into instructor values
('2015csp0001', 'Dumbledore', 'ddore@iitrpr.ac.in', 1),
('2015csp0002', 'Snape', 'snape@iitrpr.ac.in', 1),
('2010eep0003', 'Ben', 'ben@iitrpr.ac.in', 2),
('2016eep0010', 'Jaspreet', 'bumrah@iitrpr.ac.in', 2),
('2014mep0001', 'Wasim', 'wasim@iitrpr.ac.in', 3),
('2017mep0020', 'Brett', 'brett@iitrpr.ac.in', 3);

insert into advisor values
('2015csp0001', 1),
('2015csp0001', 2),
('2010eep0003', 3),
('2015eep0010', 4),
('2014mep0001', 5),
('2017mep0020', 6);