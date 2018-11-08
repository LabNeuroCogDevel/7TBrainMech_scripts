getld8_dcmdir(){
   d="$1"
   [ -z "$d" -o ! -d "$d" ] && echo "bad input to $FUNCNAME, expected dicom dir, got '$d'" >&2 && return 1

   exampledcm=$(find $d -iname '*IMA' -print -quit) 
   [ -z "$exampledcm" ] && echo "no IMA in $d" >&2 && return 1

   patname=$(dicom_hinfo -no_name -tag 0010,0010 $exampledcm)
   orig_pn=$patname
   [ -z "$patname" ] && echo "no id in $exampledcm" >&2 && return 1

   # hardcoded pass (but with details about how was run [pilot])
   [ $patname == '20171009Luna' ] && patname="Cat_20171009"
   [ $patname == '20170929Luna' ] && patname="David_20170929"
   
   # hardcoded fix
   [[ $patname == '20180521Luna1' ]] && patname=xxxxx_20180521

   # match something like 
   # 20180426Luna_11633 or 20180514Luna2_11640
   [[  $patname =~ (2[0-9]{7})_?(Luna[0-9]?[A-Ca-c]?)?_?(1[0-9]{4}) ]] && patname=${BASH_REMATCH[3]}_${BASH_REMATCH[1]}
   [[ ! $patname =~ [0-9]{5}_[0-9]{8} ]] && echo "bad lunadate patname ('$orig_pn' -> '$patname') from $exampledcm, correct in func.bash" >&2 && return 1

   # ld8 is matched pattern
   echo "$BASH_REMATCH"

}

# give me a string like yyyymmddLuna#, and i'll give you the luna_date
getld8_db(){
   read ymd num <<< $(echo $@ | perl -lne 'print $1,"\t",$2?$2:1 if m/(\d{8})Luna([1-3])?/i')
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
   " | uniq |tee >(echo "looking at: $@: $ymd $num">&2; cat|sed 's/^/\t/' >&2) |sed -n ${num}p
}
