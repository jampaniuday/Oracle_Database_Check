spool get_synonyms_old.sql
SET FEEDBACK OFF;
with q1 as 
			(
				select username 
				from dba_users 
				where default_tablespace NOT in ('SYSTEM' ,'SYSAUX')
				and username not in	('SYS','SYSTEM','OUTLN','SCOTT','ADAMS','JONES','CLARK','BLAKE','HR','OE','SH',
				'DEMO','ANONYMOUS','AURORA$ORB$UNAUTHENTICATED','AWR_STAGE','CSMIG','CTXSYS','DBSNMP','DIP','DMSYS','DSSYS',
				'EXFSYS','LBACSYS','MDSYS','ORACLE_OCM','ORDPLUGINS','ORDSYS','PERFSTAT','TRACESVR','TSMSYS','XDB','APEX_PUBLIC_USER',
				'FLOWS_30000','FLOWS_FILES','MDDATA','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','XS$NULL','MGMT_VIEW','OLAPSYS',
				'OWBSYS','SI_INFORMTN_SCHEMA','SYSMAN','WK_TEST','WKSYS','WKPROXY','WMSYS')
			)
			select 'create synonym ' || owner || '.' || synonym_name || ' for ' || table_owner || '.' || table_name || ';'
			from dba_synonyms t1, q1
			where t1.table_owner = q1.username
			and t1.owner <> 'PUBLIC' union all 
			select 'create public synonym '  || synonym_name || ' for ' || table_owner || '.' || table_name  || ';'
			from dba_synonyms t1, q1
			where t1.table_owner = q1.username
			and t1.owner =  'PUBLIC';
spool off