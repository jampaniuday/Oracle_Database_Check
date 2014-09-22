spool get_directories_old.sql
SET FEEDBACK OFF;
select 'create directory ' || rpad(directory_name, 30, ' ') || ' as ' || q'<'>' || directory_path  || q'<'>' || ';' from dba_directories;
spool off