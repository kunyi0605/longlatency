#!/bin/bash
# change all files to 777
find ./ -type f -exec chmod 777 {} \;

echo "Set device to test: TARGETDEVICE"
target=$1
declare -u size      #Convert to Upper Case
echo "Set device capacity to test: ex.CAPACITY"
size=$2
LOOPCNT=$3

size=${size/G}                #Delete G
size="$(((size*3)/2))G"       #Size * 1.5 + G 
echo "Read test device capacity $size"

filepath="/usr/lib/libaio.so.1"

if [ -e $filepath ];then
     echo $filepath exists
else
     cp libaio.so.1 /usr/lib/
fi

# Move *.csv files to Tmp folder before test start.
ls *.log > /dev/null
if [ "$?" -eq "0" ] 
then  
cur_time=`date +%Y-%m-%d-%H-%M-%S`
result_dir="./result_${cur_time}-Tmp"
rm -rf $result_dir
mkdir -p $result_dir         

find . -maxdepth 1 -type f -iname '*.log' -exec mv -t ./$result_dir/ {} \+
find . -maxdepth 1 -type f -iname '*.csv' -exec mv -t ./$result_dir/ {} \+
else
    echo "There is no *.log file exist"
fi

# Create result folder.
cur_time=`date +%Y-%m-%d-%H-%M-%S`
result_dir="./result_${cur_time}"
rm -rf $result_dir
mkdir -p $result_dir

# start test
echo "Test at least need: 0 Day 12 Hour 10 Min 0 Sec"
echo "Name=Pre_Condition, BlockSize=131072Bytes, Sequential=100%, Read=0%, Write=100%, QD=32, NumJobs=1, Target=$target, Size=$size, Loop=1"
echo "Name,Read_IOPS,Write_IOPS,Total_IOPS,Read_BW(KB),Write_BW(KB),Total_BW(KB),Read_lantency(us),Write_lantency(us),Total_lantency(us)" >> Pre_Condition.csv
./fio --filename=/dev/$target --rw=write --bs=131072 --iodepth=32 --numjobs=1 --size=$size --name=Pre_Condition --norandommap --direct=1 --refill_buffers --ioengine=libaio --minimal>>Pre_Condition.log
tail -n1 Pre_Condition.log| awk -F ";" '{printf "%s,%d,%d,%d,%d,%d,%d,%d,%d,%d\n","'Pre_Condition'",$8,$49,$8+$49,$7,$48,$7+$48,$40,$81,$40+$81}' >> Pre_Condition.csv
echo "Name=Random_Write_1M_QD32, BlockSize=1048576Bytes, Sequential=0%, Read=0%, Write=100%, QD=32, NumJobs=1, Target=$target, RunTime=1 Secs, Loop=$LOOPCNT"
echo "Name,Read_IOPS,Write_IOPS,Total_IOPS,Read_BW(KB),Write_BW(KB),Total_BW(KB),Read_lantency(us),Write_lantency(us),Total_lantency(us)" >> Random_Write_1M_QD32.csv
for((i=1;i<=$LOOPCNT;i=i+1))
do
./fio --filename=/dev/$target --rw=randwrite --bs=1048576 --iodepth=32 --numjobs=1 --runtime=1 --name=Random_Write_1M_QD32 --norandommap --direct=1 --refill_buffers --ioengine=libaio --time_based --minimal>>Random_Write_1M_QD32.log
tail -n1 Random_Write_1M_QD32.log| awk -F ";" '{printf "%s,%d,%d,%d,%d,%d,%d,%d,%d,%d\n","'Random_Write_1M_QD32'",$8,$49,$8+$49,$7,$48,$7+$48,$40,$81,$40+$81}' >> Random_Write_1M_QD32.csv
done
find . -maxdepth 1 -type f -iname '*.log' -exec mv -t ./$result_dir/ {} \+
find . -maxdepth 1 -type f -iname '*.csv' -exec mv -t ./$result_dir/ {} \+

