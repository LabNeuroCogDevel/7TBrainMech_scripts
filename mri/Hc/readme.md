# Hc MRSI 
see [`Makefile`](./Makefile)
using `MRSI_roi/gen_pdf.bash` as reference for `gen_pdf.bash`

likely need to manually `unzip -d Hpc *zip`

send_backup_mrrc.bash used HcFromLNCD/ to get MRRC data that was no longer on their servers (?, noted 20220701 created 20200521)

20221201:
see `/Volumes/Hera/Projects/7TBrainMech/raw/MRSI_BrainMechR01/HPC/` for previous (not LNCD placed) spreadsheet.csv files
* `gen_csv.R` pulls from both (saves txt/all_hc.csv)

## Row Col
Col=0==L, Col>90 == "R" (from `gen_csv.R`)
Row==0 is top?
