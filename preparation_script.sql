--======================================================
--
-- Title: preparation_script.sql
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

-- This will run the preparation scripts

spool preparation_script_out.log

set term off
set head off
set timing off
col user for a15
col systimestamp for a40
select user, systimestamp from dual;

set lines 180 pages 1000 echo off
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

@step1_get_roles.sql 
spool preparation_script_out.log append
@step2_get_system_roles.sql
spool preparation_script_out.log append
@step3_get_directories.sql
spool preparation_script_out.log append
@step4_get_synonyms.sql
spool preparation_script_out.log append
@step5_get_profiles.sql
spool preparation_script_out.log append

select * from dba_db_links;

spool off

