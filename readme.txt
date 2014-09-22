Definitions:
	Old - source or originating database
	New - destination database

----------------------------------------------------------------------------
PREPARATION
----------------------------------------------------------------------------
	DATABASE LEVEL:
		1) Run preparation_script.sql. 
		It will do the following:
			
			A) get_roles on Old database.
			
			SET PAGESIZE 10000;
			SET VERIFY OFF;
			SET term OFF;
			SET FEEDBACK OFF;

			exec dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SQLTERMINATOR',TRUE);


			select dbms_metadata.get_ddl('ROLE' , role) 
			from dba_roles
			where role not in ('ADM_PARALLEL_EXECUTE_TASK'
			,'APEX_ADMINISTRATOR_ROLE'
			,'AQ_ADMINISTRATOR_ROLE'
			,'AQ_USER_ROLE'
			,'AUTHENTICATEDUSER'
			,'CAPI_USER_ROLE'
			,'CONNECT'
			,'CSW_USR_ROLE'
			,'CTXAPP'
			,'CWM_USER'
			,'DATAPUMP_EXP_FULL_DATABASE'
			,'DATAPUMP_IMP_FULL_DATABASE'
			,'DBA'
			,'DBFS_ROLE'
			,'DELETE_CATALOG_ROLE'
			,'EJBCLIENT'
			,'EXECUTE_CATALOG_ROLE'
			,'EXP_FULL_DATABASE'
			,'GATHER_SYSTEM_STATISTICS'
			,'GLOBAL_AQ_USER_ROLE'
			,'HS_ADMIN_EXECUTE_ROLE'
			,'HS_ADMIN_ROLE'
			,'HS_ADMIN_SELECT_ROLE'
			,'IMP_FULL_DATABASE'
			,'JAVADEBUGPRIV'
			,'JAVAIDPRIV'
			,'JAVASYSPRIV'
			,'JAVAUSERPRIV'
			,'JAVA_ADMIN'
			,'JAVA_DEPLOY'
			,'JMXSERVER'
			,'LBAC_DBA'
			,'LOGSTDBY_ADMINISTRATOR'
			,'MGMT_USER'
			,'OEM_ADVISOR'
			,'OEM_MONITOR'
			,'OLAPI_TRACE_USER'
			,'OLAP_DBA'
			,'OLAP_USER'
			,'OLAP_XS_ADMIN'
			,'ORDADMIN'
			,'OWB$CLIENT'
			,'OWB_DESIGNCENTER_VIEW'
			,'OWB_USER'
			,'PLUSTRACE'
			,'RECOVERY_CATALOG_OWNER'
			,'RESOURCE'
			,'SCHEDULER_ADMIN'
			,'SELECT_CATALOG_ROLE'
			,'SNMPAGENT'
			,'SPATIAL_CSW_ADMIN'
			,'SPATIAL_WFS_ADMIN'		
			,'WFS_USR_ROLE'
			,'WM_ADMIN_ROLE'
			,'XDBADMIN'
			,'XDB_SET_INVOKER'
			,'XDB_WEBSERVICES'
			,'XDB_WEBSERVICES_OVER_HTTP'
			,'XDB_WEBSERVICES_WITH_PUBLIC');


			B) get_system_roles on Old database.
			
			SET FEEDBACK OFF;
			select 'grant ' || granted_role || ' to system;' from dba_role_privs where grantee = 'SYSTEM';
	
			C) Run get_directories on Old database.
			
			SET FEEDBACK OFF;
			select 'create directory ' || rpad(directory_name, 30, ' ') || ' as ' || q'<'>' || directory_path  || q'<'>' || ';' from dba_directories;

			D) Run get_synonyms on Old database.
			
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
			
			E)Run get_profiles on Old database.
			
			SET LONG 1000000;
			SET LONGCHUNKSIZE 1000000;
			SET LINESIZE 1000;
			SET HEADING OFF PAGES 0 FEEDBACK OFF VERIFY OFF;

			exec dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SQLTERMINATOR',TRUE);

			select  dbms_metadata.get_ddl('PROFILE' , profile) from (select distinct profile from dba_profiles ) ;

		
		2) Identify db links by connecting via SQL Developer
		select * from dba_db_links;
		
		no rows selected

		3) Check files
		Run database_check.sql which contains the following checks:
		
			A) Datafiles
			
			select name from v$datafile;
			
				
			B) Controlfiles
			
			select name from v$controlfile;
			
			C) Logfiles
			
			select member from v$logfile order by 1;
			
			D) Tempfiles
			
			select name from v$tempfile;
				
			E) Spfile
			
			show parameter spfile
				
			F) Check for invalid objects
			
			set linesize 300
        		set pages 1000
        		column owner format a20
		    	column object_name format a30
		    	column object_type format a25
    	    		column status format a10
			 
			select owner, object_type, object_name, status from all_objects where status = 'INVALID' order by 1, 2, 3;
						
			G) Get object count
			
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
		
			H) Check log setup
			
			select dbid,name,created,log_mode,force_logging from v$database;
			
			I) Check components
			
			col version for a15
			col comp_name for a50
			select comp_id, comp_name, version, status from dba_registry order by 1;	
                  
			J) Check domain
			
			show parameter db_domain
			
			K) <Production> Check cluster
			
			show parameter cluster
				
			L) Check undo
			
			show parameter undo
						
			M) Check listener
			
			show parameter listener
			
			N) Check name
			
			show parameter name
			
			O) Check case-sensitive settings
			
			show parameter sec_case_sensitive_logon
			
			P) Check audit file destination
			
			show parameter audit_file_dest
			
															 
	SECURITY:	
		1) Run create_verify_func to create SYS.VERIFY_FUNCTION on New database
		
		2) Run get_profiles on Old database.
		
		SET LONG 1000000;
		SET LONGCHUNKSIZE 1000000;
		SET LINESIZE 1000;
		SET HEADING OFF PAGES 0 FEEDBACK OFF VERIFY OFF;

		exec dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SQLTERMINATOR',TRUE);

		select  dbms_metadata.get_ddl('PROFILE' , profile) from (select distinct profile from dba_profiles ) ;    
			