#!/bin/bash
# 从一个起始日期(start_date)开始，到一个结束日期(end_date)结束，检查这个时间周期内，某个Hadoop父目录下所有日期子目录的数据完整性。
# 检查逻辑：(1)各目录下应存在 _SUCCESS 文件；(2)各目录大小不应为0

if [ $# -lt 3 ]; then
  echo "Usage: <start_date> <end_date> <hdfs_dir>"
  exit 1
fi

INPUT_START_DATE=$1  # 起始日期(更早的日期)，e.g. "2023-09-16"
INPUT_END_DATE=$2  # 结束日期(更晚的日期)，e.g. "2023-09-20"
HDFS_DIR=$3  # Hadoop父目录，e.g. "/user/hadoop/export-sample"

echo "start date: $INPUT_START_DATE, end date: $INPUT_END_DATE"

convert_size() {
    local size=$1  # 输入大小(字节)
    local unit=("B" "KB" "MB" "GB" "TB")
    local i=0

    # 将字节转换为更大的单位
    while (( size >= 1024 && i < ${#unit[@]} - 1 )); do
        size=$(( size / 1024 ))
        i=$(( i + 1 ))
    done
    echo "$size ${unit[i]}"
}

# 如果 HDFS_DIR 以 "/" 结尾，则删除掉结尾的 "/"
if [ "${HDFS_DIR: -1}" == "/" ]; then
  HDFS_DIR=${HDFS_DIR:0:-1}
fi

declare -A DATE_TO_DIR_SIZE_MAP  # 存放 日期->目录大小 的映射
COUNT=0  # 计数器，用于每检查了10天的数据就打印一次进度
FOUND_ONE_MISSING=0  # 至少找到了一个缺失的文件
DATE=`date -d "$INPUT_START_DATE 1 day ago" +%F`  # 起始日期往前挪一天，由后面的计算方式决定
END_DATE=`date -d "$INPUT_END_DATE -1 day ago" +%F`  # 结束日期往后挪一天，由后面的计算方式决定
while true; do
  DATE=`date -d "$DATE -1 day ago" +%F`  # e.g. "2022-04-21"
  # 检查是否到达结束日期
  if [ $DATE == $END_DATE ]; then
    echo "reach end date, quit"
    break
  fi

  HDFS_DATE_DIR=$HDFS_DIR/$DATE
  hadoop fs -test -e $HDFS_DATE_DIR/_SUCCESS
  if [ $? -ne 0 ]; then
    echo "+++ missing _SUCCESS file for date $DATE"
    FOUND_ONE_MISSING=1
  fi

  # 获取目录大小
  hadoop fs -test -e $HDFS_DATE_DIR
  if [ $? -eq 0 ]; then
    DIR_SIZE=$(hadoop fs -du -s $HDFS_DATE_DIR | awk '{print $1}')  # 单位：字节
    DATE_TO_DIR_SIZE_MAP[$DATE]=$DIR_SIZE
    # 如果目录大小为0，则打印警告信息
    if [ $DIR_SIZE -eq 0 ]; then
      echo "+++ warning: size for date $DATE is 0"
    fi
  else
    DATE_TO_DIR_SIZE_MAP[$DATE]=目录不存在
  fi

  # 每10天打印一次进度
  COUNT=$(($COUNT+1))
  if [ $COUNT -eq 10 ]; then
    echo "processed 10 days, current date: $DATE"
    COUNT=0
  fi
done

if [ $FOUND_ONE_MISSING -eq 0 ]; then
  echo "no missing _SUCCESS file found"
fi

# 打印出各目录大小
echo "==================================="
echo "HDFS dir size："
DATES=("${!DATE_TO_DIR_SIZE_MAP[@]}")  # 存储map的所有键到一个数组
SORTED_DATES=$(printf "%s\n" "${DATES[@]}" | sort)  # 对键进行排序

for DATE in $SORTED_DATES; do
  DIR_SIZE=${DATE_TO_DIR_SIZE_MAP[$DATE]}  # value，即目录大小
  # 把目录大小(字节)转换为易读的格式，就像 ls -lh 命令输出的大小那样
  if [ $DIR_SIZE == 目录不存在 ]; then
    SIZE="目录不存在"
  else
    SIZE=$(convert_size $DIR_SIZE)
  fi
  echo "$DATE: $SIZE"
done
