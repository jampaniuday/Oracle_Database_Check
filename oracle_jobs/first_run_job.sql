set long 1000000000 pagesize 0 trimspool on

select replace(replace(replace(dbms_metadata.get_ddl ('PROCOBJ',JOB_NAME,owner),'(''"','('''||owner||'.'),'"'')',''')'),'"','')||'/'
from dba_scheduler_jobs
where JOB_TYPE is not null;