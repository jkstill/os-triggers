
export PATH=/usr/local/bin:$PATH 

. /usr/local/bin/oraenv <<< c12 >/dev/null

sqlplus -s /nolog <<-EOF
connect jkstill/grok@p1
set feed off term on pagesize 0 linesize 200
select 100 from dual;
exit
EOF
