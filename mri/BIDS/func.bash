getld8_dcmdir(){
   local d="$1"
   [ -z "$d" -o ! -d "$d" ] && echo "bad input to $FUNCNAME, expected dicom dir, got '$d'" >&2 && return 1

   exampledcm=$(find $d -iname '*IMA' -print -quit) 
   [ -z "$exampledcm" ] && echo "$d: (dcm) cannot find IMA in $d" >&2 && return 1

   patname=$(dicom_hinfo -no_name -tag 0010,0010 $exampledcm)
   orig_pn=$patname

   hc_patname=$(getld8_hardcoded $patname || echo "")
   [ -n "$hc_patname" ] && echo "$d: using hardcoded value $hc_patname (instead of $patname)" >&2  && patname=$hc_patname 
   [ -z "$patname" ] && echo "no id in $exampledcm" >&2 && return 1

   # match something like 
   # 20180426Luna_11633 or 20180514Luna2_11640
   [[  $patname =~ (2[0-9]{7})_?(Luna[0-9]?[A-Ca-c]?)?_?(1[0-9]{4}) ]] && patname=${BASH_REMATCH[3]}_${BASH_REMATCH[1]}
   [[ ! $patname =~ [0-9]{5}_[0-9]{8} ]] && echo "$FUNCNAME: bad dcm lunadate patname ('$orig_pn' -> '$patname') from $exampledcm, correct in func.bash if db also off" >&2 && return 1

   # ld8 is matched pattern
   echo "$BASH_REMATCH"

}

# give me a string like yyyymmddLuna#, and i'll give you the luna_date
getld8_db(){
   read ymd num <<< $(echo $@ | perl -lne 'print $1,"\t",$2?$2:1 if m/(\d{8})Luna([1-3])?/i')
   echo "$FUNCNAME: $@: ymd '$ymd' scanno '$num'">&2;
   [ -z "$ymd" ] && return
   set -x
   psql -F $'\t'  --no-align -qt  -h arnold.wpic.upmc.edu  lncddb  lncd -c "
select
   concat(id, '_', to_char(vtimestamp,'yyyymmdd')) as ld8,
   vtimestamp
   from visit_study 
   natural join visit
   natural join enroll
   where 
   vtype ilike 'scan' and
   study like 'BrainMechR01' and
   etype like 'LunaID' and
   to_char(vtimestamp,'YYYYmmdd') like '%$ymd%'
   order by vtimestamp asc; 
   " | uniq |tee >( cat|sed 's/^/\t/' >&2) |sed -n ${num}p |cut -f1

   set +x
}

getld8_hardcoded(){
   patname="$1"
   ld8=""
   # hardcoded pass (but with details about how was run [pilot])
   [ $patname == '20171009Luna'  ] && ld8="Cat_20171009"
   [ $patname == '20170929Luna'  ] && ld8="David_20170929"
   
   # hardcoded fix
   [ $patname == '20180614Luna1' ] && ld8="11659_20180614"  # was later dropped
   [ $patname == '20180614Luna2' ] && ld8="11662_20180614"  # (3pm) added b/c no Luna1, throws off query DB
   [ $patname == '20181112Luna1' ] && ld8="11708_20181112"  # added 20181219, no info in dicom
   [ $patname == '20180628Luna1' ] && ld8="11665_20180628"  # added 20181219, no info in dicom
   [ $patname == '20180921Luna1' ] && ld8="11681_20180921"  # came in twice 09-21 and 10-12
   # luna1 noshowed, script cannot find causes error
   [ $patname == '20191119Luna2' ] && ld8="11711_20181119"  # came in twice 09-21 and 10-12
   [ $patname == '20181001Luna2' ] && ld8="11693_20181001"  # no luna1?
   [ $patname == '20190222Luna2' ] && ld8="11651_20190222"  # no luna1 was dropped -- did half protocol
   
   #[[ $patname == '20180521Luna1' ]] && patname=xxxxx_20180521

   [ -z "$ld8" ] && return 1
   echo $ld8
   return 0


}

getld8(){
   local d="$1"
   ld8=$(getld8_dcmdir $d) || : 
   ld8db=$(getld8_db $d) || :
   echo "ids: '$ld8' '$ld8db'" >&2
   if [ -z "$ld8" -a -z "$ld8db" ]; then
      echo "$d has no luna in dcm or db?!">&2
      local dt=$(basename $(dirname $d))
      #echo $dt >&2;
      echo -e "psql -h arnold.wpic.upmc.edu lncddb lncd -c \"select id,vtype,study,vtimestamp from visit natural join person natural join visit_study natural join enroll where to_char(vtimestamp,'YYYYmmdd') like '${dt:0:8}%' and etype like 'LunaID'\"" >&2
      return 1
   fi
   [ -z "$ld8" ] && echo "$d: no dcm luna">&2 && ld8="$ld8db"
   [ -z "$ld8db" ] && echo "$d: no db luna: update pull_from_sheets">&2 && ld8db="$ld8"
   [ "x$ld8db" != "x$ld8" ] && echo "db $ld8db does not match dcm $ld8, using db">&2 && ld8=$ld8db
   echo "$ld8"
   return 0
}
