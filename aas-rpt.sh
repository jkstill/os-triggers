
export PATH=/usr/local/bin:$PATH 

. /usr/local/bin/oraenv <<< c12 >/dev/null

sqlplus -s /nolog <<-EOF
connect sys/grok@js122a as sysdba

set pause off
set echo off
set timing off
set trimspool on
set feed on term off echo off verify off
set line 80
set pages 24 head on

clear col
clear break
clear computes

btitle ''
ttitle ''

btitle off
ttitle off

set newpage 1

set pages 0 lines 200 feed off 

set term on

prompt begin_time,end_time,instance_number,elapsed_seconds,AAS

with data as (
	select 
		to_char(h.begin_time,'yyyy-mm-dd hh24:mi:ss') begin_time
		, to_char(h.end_time,'yyyy-mm-dd hh24:mi:ss') end_time
		, (h.end_time - h.begin_time) * 86400  elapsed_seconds
		, h.instance_number
		, round(h.value,2) aas
	from dba_hist_sysmetric_history h
	where h.metric_name = 'Average Active Sessions'
	order by h.snap_id
)
select 
	begin_time
	|| ',' || end_time
	|| ',' || instance_number
	|| ',' || elapsed_seconds
	|| ',' || aas
from data
/

exit
EOF
