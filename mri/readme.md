2018-10-30 - see ../runme.bash (created 10-22)
2018-10-22 - raw data pushed from linux shim at 7t 
```
# meduser@shimliunx-OptiPlex-7050:~$ crontab -l
0 5 * * 0 rsync -urhvi --size-only /twix/7t/20*Luna* rhea:/Volumes/Hera/Raw/MRprojects/7TBrainMech/ --exclude="*Problem*" --exclude='*.tar' --exclude='*.tar.gz' --exclude="*bad*/" --exclude="**DS_Store"
```
