# example. should run by hand
echo "zips no longer used. for old, run unzip by hand!. see raw_zipdir/"
exit 1

# written Jun 10  2020; 20250519 note:
# zip files are artifact of pre-open source LCModel
# at the time, MRRC (Victor) ran placments and LCModel for us
#   ls raw_zipdir/20200413_13MP20200207specs_processed/10173_20180802-20180802Luna2/spectrum.105.114.dir
#   csi.coord  csi.ps  spreadsheet.cs
cd raw_zipdir/
unzip -d HPC/ ProcessedHc_20200605_OldHc060120.zip 
make
