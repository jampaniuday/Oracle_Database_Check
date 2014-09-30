
set feedback off

set serveroutput on
set lines 120

spool db_links_${ORACLE_SID}.sql


SET LONGCHUNKSIZE 1000000;
SET LONG 2000000
SET PAGESIZE 0

exec dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SQLTERMINATOR',TRUE);
SELECT DBMS_METADATA.GET_DDL('DB_LINK',u.DB_LINK,u.owner)
     FROM DBA_DB_LINKS u
     WHERE u.owner ='PUBLIC';

spool off
