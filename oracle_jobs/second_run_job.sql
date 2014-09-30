select schedule_name, schedule_type, start_date, repeat_interval 
from dba_scheduler_schedules;

select *
from dba_scheduler_jobs;

desc dba_scheduler_jobs

select 'BEGIN'|| chr(10) ||' SYS.DBMS_SCHEDULER.CREATE_JOB'|| chr(10) ||
'('||chr(10) ||
'job_name => '''||job_name||''''|| chr(10) ||
',job_type => '''||job_type||''''|| chr(10) ||
',schedule_name => '''||schedule_name||''''|| chr(10) ||
',program_name => '''||program_name||''''|| chr(10) ||
 ',comments => '''||comments||''')'||chr(10)||
 'END;' from dba_scheduler_jobs;