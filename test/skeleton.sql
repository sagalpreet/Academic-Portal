-- Run as postgres / database manager
create database project;
\c project

\i 'Academic Portal/main.sql'
\i 'Academic Portal/helpers.sql'
\i 'Academic Portal/procedures.sql'
\i 'Academic Portal/triggers.sql'
\i 'Academic Portal/privileges.sql'
