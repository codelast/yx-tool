#!/bin/bash
# 时间戳/时间字符串 互转。

echo "1) 时间戳(秒) → 时间字符串(yyyy-MM-dd HH:mm:ss)"
echo "2) 时间字符串(yyyy-MM-dd HH:mm:ss) → 时间戳(秒)"
echo "3) 打印当前时间戳(秒)"
echo "你想做什么："
read -p "> " CONVERT_TYPE
if [ -z "$CONVERT_TYPE" ]; then
  echo "必须选择一项"
  exit 1
fi

if [ $CONVERT_TYPE -eq 1 ] || [ $CONVERT_TYPE -eq 2 ]; then
  echo "输入待转内容："
  read -p "> " INPUT
  if [ -z "$INPUT" ]; then
    echo "必须输入内容"
    exit 1
  fi
fi

if [ $CONVERT_TYPE -eq 1 ]; then
  date -d @$INPUT "+%F %T"
elif [ $CONVERT_TYPE -eq 2 ]; then
  date -d "$INPUT" +%s
elif [ $CONVERT_TYPE -eq 3 ]; then
  echo "==========================================="
  echo "当前时间戳(秒)："
  date +%s
else
  echo "输入错误"
  exit 1
fi
