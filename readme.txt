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
			
	EXPORT:
		1) Set parameter file as:
			DIRECTORY=HAVI_DP_EXPORTS_DIR1
			PARALLEL=4
			FULL=Y
			CONTENT=ALL
			COMPRESSION=ALL
			LOGFILE=expdp_prdpilot_full.log
			DUMPFILE=expdp_full_prdpilot_%U.dmp
			JOB_NAME=expdp_prdpilot_full
			
			3 minutes for duspltj; 
			
		2) Copy export file(s) from hgspoelna10 to hgsdoelna04
			 scp -p expdp_full_prdpilot_0[1-2].dmp oracle@hgsdoelna04:/exports/duspltj/. 
	
	IMPORT:
		1) Set parameter file as:
			directory=HAVI_DP_EXPORTS_DIR
			job_name=impdp_duspltj_full
			cluster=N
			content=all
			parallel=4
			logfile=impdp_prdpilot_full.log
			dumpfile=expdp_full_prdpilot_%U.dmp
			TABLE_EXISTS_ACTION=SKIP
			EXCLUDE=SCHEMA:"IN(select username from all_users)"
			 
-------------------------------------------------------------------------
SHELL CREATION
-------------------------------------------------------------------------
1) Create template from Old Database
	hgsdoelna04:oracle(/home/oracle)> dbca -silent -createTemplateFromDB -sourceDB hgsdoelna04:1521:DEVPILOT -sysDBAUserName sys -sysDBAPassword ****** -templateName DEVPILOT_DB -maintainFileLocations  true

2) Create Database utilizing template
	dbca -silent -createDatabase -templateName DEVPILOT_DB -gdbName duspltj -sid duspltj -sysPassword Lunch\$11 -systemPassword Lunch\$11 -adminManaged -emConfiguration NONE -dbsnmpPassword Lunch\$11 -sysmanPassword Lunch\$11 -asmsnmpPassword Lunch\$11 -storageType ASM -asmSysPassword Lunch\$11 -diskGroupName DATA1 -nodelist hgsdoelna04 -characterSet AL32UTF8 -nationalCharacterSet AL16UTF16  -oratabLocation /etc/oratab

	<Production> dbca -silent -createDatabase -templateName $TEMPLATE_DIR/$TMPLT_NAME -gdbName ${ORACLE_SID} -sid ${ORACLE_SID} -sysPassword Lunch\$11 -systemPassword Lunch\$11 -adminManaged -emConfiguration NONE -dbsnmpPassword Lunch\$11 -sysmanPassword Lunch\$11 -asmsnmpPassword Lunch\$11 -storageType ASM -asmSysPassword Lunch\$11 -diskGroupName DATA1 -nodelist ${FIRST_HOST},${SECOND_HOST} -characterSet AL32UTF8 -nationalCharacterSet AL16UTF16  -oratabLocation /etc/oratab

3) <Production> Create/Start service for New database:

	hgspoelna11:oracle(/home/oracle)> srvctl add service -d puspltj -s puspltjoel -r "puspltj2"  -a "puspltj1" -P PRECONNECT -q TRUE -e SELECT -m BASIC  -z 10 -w 5

	hgspoelna11:oracle(/home/oracle)> srvctl status service -d puspltj
	
	hgspoelna11:oracle(/home/oracle)> srvctl start service -d puspltj
	hgspoelna11:oracle(/home/oracle)> srvctl status service -d puspltj
	
-----------------------------------------------------------------------------
MIGRATION
-----------------------------------------------------------------------------
	ROLES:
		1) Use output from one as script to run on New database as @step_2_get_roles.sql
		
	DATABASE LEVEL:
		1) Create directory for importing.
			SQL> create directory  HAVI_DP_EXPORTS_DIR as '/exports/duspltj';
	
	SECURITY:
		1) Run create_verify_func to create SYS.VERIFY_FUNCTION on New database **WAIT ON THIS DUE TO JDA RESTRICTIONS to remove alter profile <profile_name> limit password_verify_function null;

	IMPORT:
		1) Verify SID
			echo $ORACLE_SID
		
		
		2) Alter database into noarchivelog mode:
			A) Non-Production
				i) Stop database
					shutdown immediate;
				
				ii) Startup database in mount mode
					startup mount;
					
				iii) Alter database to noarchivelog mode
					alter database noarchivelog;
				
			B) Production
				i) Shutdown immediate all database instances
					srvctl stop database -d puspltj
					
				ii) Startup database in mount mode
					srvctl start database -d puspltj -o mount
					
				iii) Disable archive logging
					sqlplus / as sysdba
					sql> alter database noarchivelog;
					sql> exit;
					
				iv) Stop database
					srvctl stop database -d puspltj
					
				v) Restart all database instances
					srvctl start database -d puspltj
				
				vi) Verify
					PUSPLTJ1> archive log list;
			
		3) Import utilizing the parameter file from import preparation.
		
-----------------------------------------------------------------------------
POST-MIGRATION
-----------------------------------------------------------------------------		
	DATABASE LEVEL:
		1) Alter Database in archivelog mode:
			A) Non-Production
				i) Stop database
					shutdown immediate;
				
				ii) Startup database in mount mode
					startup mount;
					
				iii) Alter database to archivelog mode
					alter database archivelog;
				
			B) Production
				i) Shutdown immediate all database instances
					srvctl stop database -d puspltj
					
				ii) Startup database in mount mode
					srvctl start database -d puspltj -o mount
					
				iii) Enable archive logging
					sqlplus / as sysdba
					sql> alter database archivelog;
					sql> exit;
					
				iv) Stop database
					srvctl stop database -d puspltj
					
				v) Restart all database instances
					srvctl start database -d puspltj
				
				vi) Verify on both nodes
					PUSPLTJ1> archive log list;
					PUSPLTJ1> alter system switch logfile;
					PUSPLTJ2> archive log list;
					
		2) As SYS do the following:
			SQL> grant select, delete on aud$ to OPS$ORACLE;
			SQL> alter procedure OPS$ORACLE.AUDIT_PROC compile;
			
			
		3) Verify users and grants
		
		4) Verify synonyms
		
		5) Verify db links
		
		6) Verify directories
		
		7) Check files
			
					
	BACKUPS [RMAN]:
		1) Configure rman backup in $OC/oratabbkp
			
			New Database:/oracle/orabase/product/11.2.0.3:N:Y
				
			duspltj:/oracle/orabase/product/11.2.0.3:N:Y
			
		   Configure rman backup in  /etc/oratab on hgspolena11: <for production RAC>

			xxxxxxxx:/oracle/orabase/product/11.2.0.3:N:Y

		2) Configure rman:
			RMAN> connect target as SYSTEM
			RMAN> CONFIGURE RETENTION POLICY TO REDUNDANCY 1;
				CONFIGURE BACKUP OPTIMIZATION ON;
				CONFIGURE DEFAULT DEVICE TYPE TO DISK;
				CONFIGURE CONTROLFILE AUTOBACKUP ON;
				CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/rman/duspltj/rman_bkup/%F';
				CONFIGURE DEVICE TYPE DISK BACKUP TYPE TO COMPRESSED BACKUPSET PARALLELISM 4;
				CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
				CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
				CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT   '/rman/duspltj/rman_bkup/%U';
				CONFIGURE MAXSETSIZE TO 50 G;
				CONFIGURE ENCRYPTION FOR DATABASE OFF;
				CONFIGURE ENCRYPTION ALGORITHM 'AES128';
				CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
				CONFIGURE ARCHIVELOG DELETION POLICY TO NONE;
				CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/rman/duspltj/rman_bkup/snapcf_duspltj.f';
			
		3) Test RMAN backup:

			RMAN> backup database plus archivelog delete input;
			
				Starting backup at 21-AUG-14
				current log archived
				allocated channel: ORA_DISK_1
				channel ORA_DISK_1: SID=260 device type=DISK
				allocated channel: ORA_DISK_2
				channel ORA_DISK_2: SID=14 device type=DISK
				allocated channel: ORA_DISK_3
				channel ORA_DISK_3: SID=268 device type=DISK
				allocated channel: ORA_DISK_4
				channel ORA_DISK_4: SID=515 device type=DISK
				channel ORA_DISK_1: starting compressed archived log backup set
				channel ORA_DISK_1: specifying archived log(s) in backup set
				input archived log thread=1 sequence=1 RECID=1 STAMP=855680432
				channel ORA_DISK_1: starting piece 1 at 21-AUG-14
				channel ORA_DISK_2: starting compressed archived log backup set
				channel ORA_DISK_2: specifying archived log(s) in backup set
				input archived log thread=1 sequence=2 RECID=2 STAMP=856076465
				channel ORA_DISK_2: starting piece 1 at 21-AUG-14
				channel ORA_DISK_3: starting compressed archived log backup set
				channel ORA_DISK_3: specifying archived log(s) in backup set
				input archived log thread=1 sequence=3 RECID=3 STAMP=856179097
				channel ORA_DISK_3: starting piece 1 at 21-AUG-14
				channel ORA_DISK_3: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/03pgggcr_1_1 tag=TAG20140821T113138 comment=NONE
				channel ORA_DISK_3: backup set complete, elapsed time: 00:00:07
				channel ORA_DISK_3: deleting archived log(s)
				archived log file name=/arch/duspltj/PLT_1_3_855677804.dbf RECID=3 STAMP=856179097
				channel ORA_DISK_2: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/02pgggcr_1_1 tag=TAG20140821T113138 comment=NONE
				channel ORA_DISK_2: backup set complete, elapsed time: 00:01:45
				channel ORA_DISK_2: deleting archived log(s)
				archived log file name=/arch/duspltj/PLT_1_2_855677804.dbf RECID=2 STAMP=856076465
				channel ORA_DISK_1: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/01pgggcr_1_1 tag=TAG20140821T113138 comment=NONE
				channel ORA_DISK_1: backup set complete, elapsed time: 00:02:25
				channel ORA_DISK_1: deleting archived log(s)
				archived log file name=/arch/duspltj/PLT_1_1_855677804.dbf RECID=1 STAMP=855680432
				Finished backup at 21-AUG-14

				Starting backup at 21-AUG-14
				using channel ORA_DISK_1
				using channel ORA_DISK_2
				using channel ORA_DISK_3
				using channel ORA_DISK_4
				channel ORA_DISK_1: starting compressed full datafile backup set
				channel ORA_DISK_1: specifying datafile(s) in backup set
				input datafile file number=00007 name=+DATA1/duspltj/datafile/tmdata.932.855680089
				input datafile file number=00011 name=+DATA1/duspltj/datafile/audit.926.855680095
				input datafile file number=00008 name=+DATA1/duspltj/datafile/igpdata.930.855680093
				channel ORA_DISK_1: starting piece 1 at 21-AUG-14
				channel ORA_DISK_2: starting compressed full datafile backup set
				channel ORA_DISK_2: specifying datafile(s) in backup set
				input datafile file number=00005 name=+DATA1/duspltj/datafile/wwfdata.934.855680073
				input datafile file number=00010 name=+DATA1/duspltj/datafile/audit_lob.927.855680093
				input datafile file number=00004 name=+DATA1/duspltj/datafile/users.936.855677865
				channel ORA_DISK_2: starting piece 1 at 21-AUG-14
				channel ORA_DISK_3: starting compressed full datafile backup set
				channel ORA_DISK_3: specifying datafile(s) in backup set
				input datafile file number=00002 name=+DATA1/duspltj/datafile/sysaux.929.855677851
				input datafile file number=00003 name=+DATA1/duspltj/datafile/undotbs.938.855677855
				channel ORA_DISK_3: starting piece 1 at 21-AUG-14
				channel ORA_DISK_4: starting compressed full datafile backup set
				channel ORA_DISK_4: specifying datafile(s) in backup set
				input datafile file number=00001 name=+DATA1/duspltj/datafile/system.931.855677845
				input datafile file number=00006 name=+DATA1/duspltj/datafile/tmindex.933.855680087
				channel ORA_DISK_4: starting piece 1 at 21-AUG-14
				channel ORA_DISK_2: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/05pggghd_1_1 tag=TAG20140821T113405 comment=NONE
				channel ORA_DISK_2: backup set complete, elapsed time: 00:00:16
				channel ORA_DISK_2: starting compressed full datafile backup set
				channel ORA_DISK_2: specifying datafile(s) in backup set
				input datafile file number=00009 name=+DATA1/duspltj/datafile/dbatools.928.855680093
				channel ORA_DISK_2: starting piece 1 at 21-AUG-14
				channel ORA_DISK_2: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/08pggght_1_1 tag=TAG20140821T113405 comment=NONE
				channel ORA_DISK_2: backup set complete, elapsed time: 00:00:03
				channel ORA_DISK_3: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/06pggghd_1_1 tag=TAG20140821T113405 comment=NONE
				channel ORA_DISK_3: backup set complete, elapsed time: 00:00:23
				channel ORA_DISK_1: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/04pggghd_1_1 tag=TAG20140821T113405 comment=NONE
				channel ORA_DISK_1: backup set complete, elapsed time: 00:00:31
				channel ORA_DISK_4: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/07pggghd_1_1 tag=TAG20140821T113405 comment=NONE
				channel ORA_DISK_4: backup set complete, elapsed time: 00:00:30
				Finished backup at 21-AUG-14

				Starting backup at 21-AUG-14
				current log archived
				using channel ORA_DISK_1
				using channel ORA_DISK_2
				using channel ORA_DISK_3
				using channel ORA_DISK_4
				channel ORA_DISK_1: starting compressed archived log backup set
				channel ORA_DISK_1: specifying archived log(s) in backup set
				input archived log thread=1 sequence=4 RECID=4 STAMP=856179276
				channel ORA_DISK_1: starting piece 1 at 21-AUG-14
				channel ORA_DISK_1: finished piece 1 at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/09pgggid_1_1 tag=TAG20140821T113436 comment=NONE
				channel ORA_DISK_1: backup set complete, elapsed time: 00:00:01
				channel ORA_DISK_1: deleting archived log(s)
				archived log file name=/arch/duspltj/PLT_1_4_855677804.dbf RECID=4 STAMP=856179276
				Finished backup at 21-AUG-14

				Starting Control File and SPFILE Autobackup at 21-AUG-14
				piece handle=/rman/duspltj/rman_bkup/c-1827110124-20140821-00 comment=NONE
				Finished Control File and SPFILE Autobackup at 21-AUG-14

				RMAN> exit
