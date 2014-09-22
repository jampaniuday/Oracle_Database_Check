spool get_system_roles_old.sql
SET FEEDBACK OFF;
select 'grant ' || granted_role || ' to system;' from dba_role_privs where grantee = 'SYSTEM';
spool off