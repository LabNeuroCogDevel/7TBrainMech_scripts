getld8_dcmdir(){
   d="$1"
   [ -z "$d" -o ! -d "$d" ] && echo "bad input to $FUNCNAME, expected dicom dir, got '$d'" >&2 && return 1

   exampledcm=$(find $d -iname '*IMA' -print -quit) 
   [ -z "$exampledcm" ] && echo "no IMA in $d" >&2 && return 1

   patname=$(dicom_hinfo -no_name -tag 0010,0010 $exampledcm)
   orig_pn=$patname
   [ -z "$patname" ] && echo "n2o id in $exampledcm" >&2 && return 1

   # hardcoded pass (but with details about how was run [pilot])
   [ $patname == '20171009Luna'  ] && patname="Cat_20171009"
   [ $patname == '20170929Luna'  ] && patname="David_20170929"
   
   # hardcoded fix
   [ $patname == '20180614Luna2' ] && patname="11662_20180614"  # added b/c no Luna1, throws off query DB
   #[[ $patname == '20180521Luna1' ]] && patname=xxxxx_20180521

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
   echo "$FUNCNAME: $@: ld8 '$ymd' scanno '$num'">&2;
   [ -z "$ymd" ] && return
   psql -F $'\t'  --no-align -qt  -h arnold.wpic.upmc.edu  lncddb  lncd -c "
select
   concat(id, '_', to_char(vtimestamp,'yyyymmdd')) as ld8,
   vtimestamp
   from visit_study 
   natural join visit
   natural join enroll
   where 
   vtype like 'scan' and
   study like 'BrainMechR01' and
   etype like 'LunaID' and
   to_char(vtimestamp,'yyyymmdd') like '%$ymd%'
   order by vtimestamp asc; 
   " | uniq |tee >( cat|sed 's/^/\t/' >&2) |sed -n ${num}p |cut -f1
}

getld8(){
   ld8=$(getld8_dcmdir $d) || : 
   ld8db=$(getld8_db $d) || :
   echo "ids: '$ld8' '$ld8db'" >&2
   [ -z "$ld8" -a -z "$ld8db" ] && echo "$d has no luna in dcm or db?!">&2 && return 1
   [ -z "$ld8" ] && echo "$d has no dcm luna">&2 && ld8="$ld8db"
   [ -z "$ld8db" ] && echo "$d has no db luna">&2 && ld8db="$ld8"
   [ "x$ld8db" != "x$ld8" ] && echo "db $ld8db does not match dcm $ld8, using db">&2 && ld8=$ld8db
   echo "$ld8"
   return 0
}
