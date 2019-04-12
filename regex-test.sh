
export PATH=/usr/local/bin:$PATH 

. /usr/local/bin/oraenv <<< c12 >/dev/null

sqlplus -s /nolog <<-EOF
connect /@js122a as sysdba
set feed off term on pagesize 0 linesize 200

select decode( mod(to_char(sysdate,'SS'),2), 1, 'PASS', 'FAIL') 
from dual;

exit
EOF
