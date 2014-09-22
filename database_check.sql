--======================================================
--
-- Title: database_check.sql
-- Description: To display all the database information
-- via preparation scripts that can be run separately.
--
-- Usage/Notes:
--
-- Author: Nicole Harrington
-- Date: 18 September 2014
--
-- Version: 1.00
--
-- Amendment:
-- History
--
--======================================================

-- This will run a check against the database.

spool database_check.log

set term off
set head off
set timing off
set feedback off
col user for a15
col systimestamp for a40
select user, systimestamp from dual;

col instance_number heading '#' format 9
col name for a15
col host_name for a15
col version for a20
col created for a25
col log_mode for a10
col open_mode for a10
select a.instance_number, b.name, a.host_name, a.version, b.created, b.open_mode, b.log_mode
from v$instance a
full outer join v$database b
on a.instance_name = b.name;

Prompt
Prompt Datafiles
col name for a100
select name from v$datafile order by name;

Prompt  
Prompt Controlfiles
col name for a100
select name from v$controlfile order by name;

Prompt 
Prompt Logfiles
col name for a100
select member from v$logfile order by 1;

Prompt 
Prompt Tempfiles
col name for a100
select name from v$tempfile order by name;

Prompt 
Prompt spfile
set linesize 500
show parameter spfile

Prompt 
Prompt Invalid Objects
set linesize 300
set pages 1000
column owner format a20
column object_name format a30
column object_type format a25
column status format a10
select owner, object_type, object_name, status from all_objects where status = 'INVALID' order by 1, 2, 3;

Prompt
Prompt Object Count
with q1 as 
(
	select  username 
	from	dba_users 
	where	default_tablespace NOT in ('SYSTEM' ,'SYSAUX')
	and	username not in ('APEX_PUBLIC_USER',
	'DIP',
	'FLOWS_30000',
	'FLOWS_FILES',
	'MDDATA',
	'ORACLE_OCM',
	'SPATIAL_CSW_ADMIN_USR',
	'SPATIAL_WFS_ADMIN_USR',
	'XS$NULL')
	order by username
)
select t1.owner, count(*) from dba_objects t1, q1
where t1.owner = q1.username
group by t1.owner
order by 2, 1;

Prompt
Prompt Log Setup
col name for a30
select dbid,name,created,log_mode,force_logging from v$database;

Prompt
Prompt Check Components
col version for a15
col comp_name for a50
select comp_id, comp_name, version, status from dba_registry order by 1;	
			
Prompt
Prompt Check Domain
show parameter db_domain

Prompt
Prompt Check Cluster
show parameter cluster

Prompt
Prompt Undo Check
show parameter undo

Prompt
Prompt Listener Check
show parameter listener

Prompt
Prompt Name Check
show parameter name

Prompt
Prompt Check case-sensitive settings
show parameter sec_case_sensitive_logon

Prompt
Prompt Audit File Destination
show parameter audit_file_dest

spool off
