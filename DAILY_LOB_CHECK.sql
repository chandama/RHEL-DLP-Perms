/* Oracle SQL Stored Procedure - DAILY_LOB_CHECK

Written by: Chandler Taylor
Date: 10/14/2019

SQL Script to create a stored procedure to query the Status, Name,
    Available bytes, Free bytes, and Free% of the LOB_TABLESPACE called
    DAILY_LOB_CHECK

This procedure can be called and spooled into an output .txt file via
    Powershell/Python script to provide a daily report of the LOB_TABLSEPACE

The format of this output can be edited by editing the dbms_output.put()
    lines to your liking.

The line 'AND d.tablespace_name = 'LOB_TABLESPACE'' can be removed if you
    want to query all of the tablespaces and not just LOB_TABLESPACE.
*/
CREATE OR REPLACE PROCEDURE DAILY_LOB_CHECK
IS
    VAL CHAR(15);
    VAL2 CHAR(15);
    VAL3 CHAR(15);
    VAL4 CHAR(15);
    VAL5 CHAR(15);
BEGIN
    SELECT d.status,
        d.tablespace_name,
        TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99999990D900'),
        TO_CHAR(NVL(NVL(f.bytes, 0), 0)/1024/1024 ,'99999990D900'),
        TO_CHAR(NVL((NVL(f.bytes, 0)) / a.bytes * 100, 0), '990D00')
    INTO VAL,VAL2,VAL3,VAL4,VAL5
    FROM sys.dba_tablespaces d,
        (select tablespace_name, sum(bytes) bytes from dba_data_files group by tablespace_name) a,
        (select tablespace_name, sum(bytes) bytes from dba_free_space group by tablespace_name) f
    WHERE d.tablespace_name = a.tablespace_name(+)
        AND d.tablespace_name = f.tablespace_name(+)
        AND d.tablespace_name = 'LOB_TABLESPACE'
        AND NOT (d.extent_management like 'LOCAL'
        AND d.contents like 'TEMPORARY');
    dbms_output.new_line;
    dbms_output.put('STATUS         NAME               AVAIL MB       FREE MB      %FREE');
    dbms_output.new_line;
    dbms_output.put('------         --------------     ---------      ---------    -----');
    dbms_output.new_line;
    dbms_output.put(VAL);
    dbms_output.put(VAL2);
    dbms_output.put(VAL3);
    dbms_output.put(VAL4);
    dbms_output.put_line(VAL5);
END;
/


/*
    This code will execute the procedure via SQLPlus
    You can add SPOOL code here to write the data to an output file
*/
BEGIN
DAILY_LOB_CHECK();
END;
/
