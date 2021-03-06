
export PATH=/usr/local/bin:$PATH 

. /usr/local/bin/oraenv <<< c12 >/dev/null

sqlplus -s /nolog <<-EOF
connect /@js122a as sysdba
set feed off term on pagesize 0 linesize 200

-- test query
--select 100 from dual;

-- the real query
select trunc(value) value
from v\$sysmetric  
where metric_name = 'Average Active Sessions'
and intsize_csec > 5000;

exit
EOF
