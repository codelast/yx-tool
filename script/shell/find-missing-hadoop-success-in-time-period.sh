#!/bin/bash
# 从一个起始日期(start_date)开始，到一个结束日期(end_date)结束，找出这个时间周期内，某个Hadoop父目录下所有缺失_SUCCESS文件的日期。
# 例如，Hadoop目录 /user/hadoop/export-sample/ 下面有若干个日期子目录：/user/hadoop/export-sample/2023-10-09，...，/user/hadoop/export-sample/2023-10-13，每个子目录下都有Hadoop job生成的_SUCCESS文件，此脚本可以找出缺失_SUCCESS文件的那些日期。

if [ $# -lt 3 ]; then
  echo "Usage: <start_date> <end_date> <hdfs_dir>"
  exit 1
fi

START_DATE=$1  # 起始日期(更早的日期)，e.g. "2023-09-16"
END_DATE=$2  # 结束日期(更晚的日期)，e.g. "2023-09-20"
HDFS_DIR=$3  # Hadoop父目录，e.g. "/user/hadoop/export-sample"

echo "start date: $START_DATE, end date: $END_DATE"

# 如果 HDFS_DIR 以 "/" 结尾，则删除掉结尾的 "/"
if [ "${HDFS_DIR: -1}" == "/" ]; then
  HDFS_DIR=${HDFS_DIR:0:-1}
fi

COUNT=0  # 计数器，用于每检查了10天的数据就打印一次进度
FOUND_ONE_MISSING=0  # 至少找到了一个缺失的文件
DATE=`date -d "$START_DATE 1 day ago" +%F`  # 起始日期往前挪一天，由后面的计算方式决定
END_DATE=`date -d "$END_DATE -1 day ago" +%F`  # 结束日期往后挪一天，由后面的计算方式决定
while true; do
  DATE=`date -d "$DATE -1 day ago" +%F`  # e.g. "2022-04-21"
  # 检查是否到达结束日期
  if [ $DATE == $END_DATE ]; then
    echo "reach end date, quit"
    break
  fi

  hadoop fs -test -e $HDFS_DIR/$DATE/_SUCCESS
  if [ $? -ne 0 ]; then
    echo "+++ missing _SUCCESS file for date $DATE"
    FOUND_ONE_MISSING=1
  fi
  COUNT=$(($COUNT+1))
  if [ $COUNT -eq 10 ]; then
    echo "processed 10 days, current date: $DATE"
    COUNT=0
  fi
done

if [ $FOUND_ONE_MISSING -eq 0 ]; then
  echo "no missing file found"
fi
