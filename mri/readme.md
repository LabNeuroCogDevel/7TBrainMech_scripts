2018-10-30 - see ../runme.bash (created 10-22)
2018-10-22 - raw data pushed from linux shim at 7t 
2019-08-21 - using `BIDS/000_dcmfolder_201906fmt.bash` b/c folder structure changed

when data was on linux machine, had cronjob there
```
# meduser@shimliunx-OptiPlex-7050:~$ crontab -l
0 5 * * 0 rsync -urhvi --size-only /twix/7t/20*Luna* rhea:/Volumes/Hera/Raw/MRprojects/7TBrainMech/ --exclude="*Problem*" --exclude='*.tar' --exclude='*.tar.gz' --exclude="*bad*/" --exclude="**DS_Store"
```

20191011 - new coords
```
cd /Volumes/Hera/Projects/7TBrainMech/scripts/mri/MRSI_roi/mni_examples
./warp_to_example_subjs.bash ../mkcoords/ROI_mni_MP_20191004.nii.gz 10129_20180917 11734_20190
```
