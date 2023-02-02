#!/usr/bin/env bash
#
# get scanlog acquisition number for HC MRSI slice
# creates txt/hc_scanlog.txt using Makefile
#
# 20221128WF - init
lncddb "
select
  enroll.id || '_' || to_char(vtimestamp,'YYYYmmdd') as ld8,
  mr.id as mrid,
  (measures->'Hc_Spectroscopy') as hcacqnum
from visit_task
natural join visit_study
natural join visit
join enroll on enroll.pid=visit.pid and enroll.etype like 'LunaID'
left join enroll as mr on
   mr.pid=visit.pid and 
   mr.id like to_char(vtimestamp,'YYYYmmdd')|| '%' and
   mr.etype like '7TMRID'
where
    study like 'BrainMe%' and
    task like 'ScanLog' and
    (measures->'Hc_Spectroscopy')::text not like 'null'
    order by vtimestamp;"
