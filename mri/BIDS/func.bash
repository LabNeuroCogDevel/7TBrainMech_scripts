
## extra output if verbose is set
# set verbose to empty if not in env
env |grep -q ^VERBOSE= || VERBOSE=""
env |grep -q ^USEDB= || USEDB=""
warnifverb(){ [ -n "$VERBOSE" ] && echo -e "$@" >&2 || return 0; }
verbtee(){ [ -n "$VERBOSE" ] && tee >( cat|sed 's/^/# \t/' >&2) || cat;}

getld8_dcmdir(){
   local d="$1"
   [ -z "$d" -o ! -d "$d" ] && echo "bad input to $FUNCNAME, expected dicom dir, got '$d'" >&2 && return 1

   exampledcm=$(find -L $d -iname '*IMA' -print -quit) 
   [ -z "$exampledcm" ] && echo "$d: (dcm) cannot find IMA in $d" >&2 && return 1

   patname=$(dicom_hinfo -no_name -tag 0010,0010 "$exampledcm")
   orig_pn=$patname

   hc_patname=$(getld8_hardcoded "$patname" || echo "")
   if [ -n "$hc_patname" ]; then 
      [ -n "${VERBOSE:-}" ] && echo "$d: using hardcoded value $hc_patname (instead of $patname)" >&2
      patname=$hc_patname 
   fi
   [ -z "$patname" ] && echo "no id in $exampledcm" >&2 && return 1

   # match something like 
   # 20180426Luna_11633 or 20180514Luna2_11640
   [[  ${patname,,} =~ (2[0-9]{7})_?(luna[0-9]?[a-c]?)?_?(1[0-9]{4}) ]] && patname=${BASH_REMATCH[3]}_${BASH_REMATCH[1]}
   [[ ! $patname =~ [0-9]{5}_[0-9]{8} ]] &&
      warnifverb "$FUNCNAME: bad dcm lunadate patname ('$orig_pn' -> '$patname') from $exampledcm, correct in func.bash if db also off" >&2 &&
      return 1

   # ld8 is matched pattern
   echo "$BASH_REMATCH"

}

#DBHOST=arnold.wpic.upmc.edu
#! ping -qc1 -W1 $DBHOST && echo "$DBHOST down?" && DBHOST=10.145.64.121
DBHOST=10.145.64.121

# give me a string like yyyymmddLuna#, and i'll give you the luna_date
getld8_db(){
   read ymd num <<< $(echo "$@" | perl -lne 'print $1,"\t",$2?$2:1 if m/(\d{8})Luna([1-3])?/i')
   warnifverb "${FUNCNAME[0]}: $*: ymd '$ymd' scanno '$num'";
   [ -z "$ymd" ] && return
   [ -n "$VERBOSE" ] && set -x
   psql -F $'\t'  --no-align -qt  -h $DBHOST  lncddb  lncd -c "
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
   " | uniq | verbtee |sed -n ${num}p |cut -f1

   set +x
}

getld8_hardcoded(){
   patname="$1"
   ld8=""
   # hardcoded pass (but with details about how was run [pilot])
   [ $patname == '20171009Luna'  ] && ld8="Cat_20171009"
   [ $patname == '20170929Luna'  ] && ld8="David_20170929"
   [ $patname == '20190506Luna1'  ] && ld8="incompleteNoReturn_20190506"
   [ $patname == '20201030Luna1'  ] && ld8="11818_20201030"
   
   # hardcoded fix
   [ $patname == '20180614Luna1' ] && ld8="11659_20180614"  # was later dropped
   [ $patname == '20180614Luna2' ] && ld8="11662_20180614"  # (3pm) added b/c no Luna1, throws off query DB
   # Dropped: 11667_20180629 noshowed
   [ $patname == '20181112Luna1' ] && ld8="11708_20181112"  # added 20181219, no info in dicom
   [ $patname == '20180628Luna1' ] && ld8="11665_20180628"  # added 20181219, no info in dicom
   [ $patname == '20180921Luna1' ] && ld8="11681_20180921"  # came in twice 09-21 and 10-12
   [ $patname == '20190719Luna1' ] && ld8="11735_20190719"  # ERROR had set to Luna2 but is Luna1! (corrected 20200714)
   [ $patname == '20190719Luna2' ] && ld8="11772_20190719"  # added to correct error above (20200714)
   [ $patname == '20190401Luna1' ] && ld8="11748_20190401"  # has 2 lunaids 11748 (7T ID) or 11515 (PET ID)

   # luna1 noshowed, script cannot find causes error
   [ $patname == '20191119Luna2' ] && ld8="11711_20181119"  # came in twice 09-21 and 10-12
   [ $patname == '20181001Luna2' ] && ld8="11693_20181001"  # no luna1?
   [ $patname == '20190222Luna2' ] && ld8="11651_20190222"  # no luna1 was dropped -- did half protocol
   [ $patname == '20190712Luna'  ] && ld8="11776_20190712"  # luna1 cancelled last minute

   # SWAPPED
   [ $patname == "20190906Luna1" ] && ld8="11802_20190906"  # 1 THESE WERE SWAPPED ORIGINALLY
   [ $patname == "20190906Luna2" ] && ld8="11784_20190906"  # 2 THESE WERE SWAPPED ORIGINALLY
   [ $patname == "20190906Luna_2" ] && ld8="11784_20190906" # 2 THESE WERE SWAPPED ORIGINALLY

   [ $patname == "20191004Luna2" ] && ld8="11805_20191004"  # no luna1
   [ $patname == '20190506Luna1' ] && ld8="11763_20190506"  # nolonger interested, didn't show up in normal spot on sheet->db
   # impatiant mosaic test, should eventuall be in db
   [ $patname == '20191219Luna1' ] && ld8="11813_20191219"
   # ISSUES/TODO
   [ $patname == "20190715Luna"  ] && ld8="11788_TECHISSUE"  # not rescheduled yet (as of 20190823, 20191023)
   [ $patname == "20190510Luna2" ] && ld8="11768_20190510" # 20190510Luna2 will come back 20190913
   [ $patname == "20190913Luna2" ] && ld8="11768_20190913" # 20190510Luna2 will come back 20190913
   
   [ $patname == "20200103Luna11" ] && ld8="11675_20200103"
   [ $patname == "20200103Luna2"  ] && ld8="10202_20200103" # 10202 tp1
   [ $patname == "20200731Luna1"  ] && ld8="11681_20200731" # 10202 tp1

   # 20210301: 11700_20201113 and  11753_20201009 incorrectly assigned as Luna1!
   [ $patname == "20201009Luna1"  ] && ld8="11707_20201009" # incomplete
   [ $patname == "20201009Luna2"  ] && ld8="11753_20201009" # 15:30
   [ $patname == "20201023Luna1"  ] && ld8="11750_20201023" # 10:30
   [ $patname == "20201023Luna2"  ] && ld8="11718_20201023" # 15:30
   [ $patname == "20201113_LUNA1" ] && ld8="11707_20201113" # finished 10-09
   [ $patname == "20201113Luna2"  ] && ld8="11700_20201113" # 15:30
   [ $patname == "20210220Luna1"  ] && ld8="11864_20210220" # no dob in sheet
   [ $patname == "20210419Luna"   ] && ld8="11668_20210419" # dirname is Luna2, but only visit for day

   [ $patname == "20210426Luna"   ] && ld8="11793_20210426" # dirname is Luna2, but only visit for day

   # 20230113 ZBW 
   [ $patname == "20210410Luna1"   ] && ld8="11845_20210410"
   # 20230117 - finding missing calendar days
   [ $patname == "20220716Luna1"   ] && ld8="11865_20220716"
   [ $patname == "20211203Luna1"   ] && ld8="11738_20211203"
   [ $patname == "20220819Luna1"   ] && ld8="11686_20220819" # flow has 20220829. no cal then
   
   
   
   #[[ $patname == '20180521Luna1' ]] && patname=xxxxx_20180521

   [ -z "$ld8" ] && return 1
   echo $ld8
   return 0


}

getld8(){
   local d="$1"
   ld8=$(getld8_dcmdir $d) || : 
   ld8db=$(getld8_db $d) || :
   [ -n "${VERBOSE:-}" ] && echo "# INFO:  dcmid '$ld8' vs. dbid '$ld8db' (only need 1 valid)" >&2
   if [ -z "$ld8" -a -z "$ld8db" ]; then
      echo "$0:${FUNCNAME}:ERROR: $d has no luna in dcm or db?! run again with VERBOSE=1">&2
      #local dt=$(basename $(dirname $d))
      [[ $d =~ [0-9]{8}Luna ]] && search=${BASH_REMATCH:0:8} || search="??" 
      #echo $dt >&2;
      echo -e "psql -h $DBHOST lncddb lncd -c \"select id,vtype,study,vtimestamp from visit natural join person natural join visit_study natural join enroll where to_char(vtimestamp,'YYYYmmdd') like '$search%' and etype like 'LunaID'\"" >&2
      return 1
   fi
   [ -z "$ld8" ]   &&   ld8="$ld8db"  && warnifverb "#   $d: no dcm luna (maybe okay)"
   [ -z "$ld8db" ] && ld8db="$ld8"  && warnifverb "#   $d: no db luna: update pull_from_sheets (maybe okay)"
   if [ "x$ld8db" != "x$ld8" ]; then 
      echo "# WARNING: db $ld8db does not match dcm $ld8" >&2
      [ -z "$ld8" ] && should_usedb=1 || should_usedb=""
      [ -n "$USEDB" -o -n "$should_usedb" ] && ld8=$ld8db
      echo "using $ld8 (run again with export VERBOSE=1, set USEDB to force db)">&2
   fi
   echo "$ld8"
   return 0
}
