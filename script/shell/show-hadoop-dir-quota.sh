#!/bin/bash
# 打印指定用户或当前用户的Hadoop目录配额。

# 检查hadoop命令是否可用
hadoop version > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "hadoop命令不可用，无法继续"
  exit 1
fi

# 显示提示信息
echo "你想按什么统计quota："
echo "1) 指定用户名"
echo "2) 指定HDFS路径"

# 使用 read 命令等待用户输入
read -p "> " WHAT_TO_DO
if [ -z $WHAT_TO_DO ]; then
  echo "必须选择一项"
  exit 1
fi

HDFS_PATH=  # 要查看配额的HDFS路径
case $WHAT_TO_DO in
  1)
    echo "1) 使用当前用户名：$USER"
    echo "2) 自己指定用户名"

    read -p "> " USER_NAME_TYPE
    if [ -z "$USER_NAME_TYPE" ]; then
      echo "必须选择一项"
      exit 1
    fi

    if [ $USER_NAME_TYPE -eq 1 ]; then
      HDFS_PATH=/user/$USER
    elif [ $USER_NAME_TYPE -eq 2 ]; then
      echo "请输入自己指定的用户名："
      read -p "> " INPUT_USER_NAME
      if [ -z $INPUT_USER_NAME ]; then
        echo "必须输入用户名"
        exit 1
      fi
      HDFS_PATH=/user/$INPUT_USER_NAME
    else
      echo "无效选项"
      exit 1
    fi
    ;;
  2)
    echo "输入HDFS路径："
    read -p "> " INPUT_HDFS_PATH
    if [ -z $INPUT_HDFS_PATH ]; then
      echo "必须输入HDFS路径"
      exit 1
    fi
    HDFS_PATH=$INPUT_HDFS_PATH
    ;;
  *)
    echo "无效选项"
    exit 1
    ;;
esac

echo "准备检测的HDFS目录是：$HDFS_PATH"

INFO=`hadoop fs -count -q $HDFS_PATH`
# 删除 INFO 字符串开头及结尾的空白字符
INFO=`echo $INFO | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
echo "hadoop命令输出的原样结果："
echo $INFO
echo "------------------------------------------------------------------------------------------"
QUOTA=`echo $INFO | awk '{print $1}'`  # 文件和目录的总数限制
REMAINING_QUOTA=`echo $INFO | awk '{print $2}'`  # 该用户可以创建的剩余文件和目录总数
SPACE_QUOTA=`echo $INFO | awk '{print $3}'`  # 授予该用户的空间配额，单位：字节
REMAINING_SPACE_QUOTA=`echo $INFO | awk '{print $4}'`  # 该用户剩余的空间配额，单位：字节
DIR_COUNT=`echo $INFO | awk '{print $5}'`  # 当前目录总数
FILE_COUNT=`echo $INFO | awk '{print $6}'`  # 当前文件总数
CONTENT_SIZE=`echo $INFO | awk '{print $7}'`  # 当前文件大小，单位：字节

# 把 SPACE_QUOTA(有可能是无限)、REMAINING_SPACE_QUOTA(有可能是无限)、CONTENT_SIZE 转换成GB
if [ $SPACE_QUOTA != "none" ]; then
  SPACE_QUOTA=`echo "scale=2; $SPACE_QUOTA/1024/1024/1024" | bc`
  # 如果 SPACE_QUOTA 的值 > 1024，则转换成TB
  if [ `echo "$SPACE_QUOTA > 1024" | bc` -eq 1 ]; then
    SPACE_QUOTA=`echo "scale=2; $SPACE_QUOTA/1024" | bc`
    SPACE_QUOTA="${SPACE_QUOTA} TB"
  else
    SPACE_QUOTA="${SPACE_QUOTA} GB"
  fi
fi
if [ $REMAINING_SPACE_QUOTA != "inf" ]; then
  REMAINING_SPACE_QUOTA=`echo "scale=2; $REMAINING_SPACE_QUOTA/1024/1024/1024" | bc`
  # 如果 REMAINING_SPACE_QUOTA 的值 > 1024，则转换成TB
  if [ `echo "$REMAINING_SPACE_QUOTA > 1024" | bc` -eq 1 ]; then
    REMAINING_SPACE_QUOTA=`echo "scale=2; $REMAINING_SPACE_QUOTA/1024" | bc`
    REMAINING_SPACE_QUOTA="${REMAINING_SPACE_QUOTA} TB"
  else
    REMAINING_SPACE_QUOTA="${REMAINING_SPACE_QUOTA} GB"
  fi
fi
CONTENT_SIZE=`echo "scale=2; $CONTENT_SIZE/1024/1024" | bc`  # 单位：MB

# 根据 CONTENT_SIZE 的大小，换算成合适的单位
if [ `echo "$CONTENT_SIZE > 1048576" | bc` -eq 1 ]; then
  CONTENT_SIZE=`echo "scale=2; $CONTENT_SIZE/1024/1024" | bc`
  CONTENT_SIZE="${CONTENT_SIZE} TB"
elif [ `echo "$CONTENT_SIZE > 1024" | bc` -eq 1 ]; then
  CONTENT_SIZE=`echo "scale=2; $CONTENT_SIZE/1024" | bc`
  CONTENT_SIZE="${CONTENT_SIZE} GB"
else
  CONTENT_SIZE="${CONTENT_SIZE} MB"
fi

# 没有设置配额的情况
if [ $QUOTA == "none" ]; then
  QUOTA="无限"
fi
if [ $REMAINING_QUOTA == "inf" ]; then
  REMAINING_QUOTA="无限"
fi
if [ "$SPACE_QUOTA" == "none" ]; then
  SPACE_QUOTA="无限"
fi
if [ "$REMAINING_SPACE_QUOTA" == "inf" ]; then
  REMAINING_SPACE_QUOTA="无限"
fi
echo "文件和目录的总数限制: $QUOTA"
echo "还可以创建的剩余文件和目录总数: $REMAINING_QUOTA"
echo "空间配额: $SPACE_QUOTA"
echo "剩余可用空间大小: $REMAINING_SPACE_QUOTA"
echo "当前目录总数: $DIR_COUNT"
echo "当前文件总数: $FILE_COUNT"
echo "当前数据大小: $CONTENT_SIZE"
