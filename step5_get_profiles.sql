SET LONG 1000000;
SET LONGCHUNKSIZE 1000000;
SET LINESIZE 1000;
SET HEADING OFF PAGES 0 FEEDBACK OFF VERIFY OFF;
spool get_profiles_old.sql
exec dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SQLTERMINATOR',TRUE);

select  dbms_metadata.get_ddl('PROFILE' , profile) from (select distinct profile from dba_profiles ) ;
spool off