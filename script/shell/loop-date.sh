#!/bin/bash
# 从一个起始日期(start_date)开始，到一个结束日期(end_date)结束，每次向后推进一天，依次执行某个程序。执行方法可以使用串行方式或并行方式，如果使用并行方式，将使用nohup来跑。

if [ $# -lt 2 ]; then
  echo "Usage: <start_date> <end_date> [bin_to_exec] [parallel]"
  exit 1
fi

START_DATE=$1  # 起始日期(更早的日期)，e.g. "2023-09-16"
END_DATE=$2  # 结束日期(更晚的日期)，e.g. "2023-09-20"

BIN_TO_EXEC=  # 待执行的程序，此程序接受一个日期参数(e.g. "2023-09-16")
if [ $# -ge 3 ]; then
  BIN_TO_EXEC=$3
fi

PARALLEL=1  # 是否并行执行指定的程序，1：并行，0：串行
if [ $# -ge 4 ]; then
  PARALLEL=$4
fi

echo "start date: $START_DATE, end date: $END_DATE, bin to exec: $BIN_TO_EXEC, parallel: $PARALLEL"

DATE=`date -d "$START_DATE 1 day ago" +%F`  # 起始日期往前挪一天，由后面的计算方式决定
END_DATE=`date -d "$END_DATE -1 day ago" +%F`  # 结束日期往后挪一天，由后面的计算方式决定
while true; do
  DATE=`date -d "$DATE -1 day ago" +%F`  # e.g. "2022-04-21"
  # 检查是否到达结束日期
  if [ $DATE == $END_DATE ]; then
    echo "reach end date, quit"
    break
  fi

  echo "start to run job @ $DATE"
  if [ -z $BIN_TO_EXEC ]; then  # 如果没有指定待执行的程序，则跳过
    continue
  fi
  if [ $PARALLEL -eq 0 ]; then  # 串行执行
    $BIN_TO_EXEC $DATE
  else
    nohup $BIN_TO_EXEC $DATE &  # 并行执行
  fi
done
