#!/bin/bash

# 判断 DataX 路径是否有效
DATAX_PATH=$DATAX_HOME
echo "-----------------DataX PATH CHECK-----------------"
if [[ -z "$DATAX_PATH" ]]; then
	if [[ -z "$1" || ! -d "$1" ]]; then
		echo "未检测到有效 DataX 路径参数，请重新输入或配置环境变量！"
		exit
	else
		DATAX_PATH=$1
	fi
elif [[ ! -d "$DATAX_PATH" ]]; then
	echo "未检测到有效 DataX 路径参数，请重新输入或配置环境变量！"
	exit
fi


# 判断 JSON_FILES_PATH 路径是否有效
JSON_FILES_PATH=""
echo "-----------------JSON_FILES PATH CHECK-----------------"
if [[ $# -eq 1 ]]; then
	if [[ -z "$1" || ! -d "$1" ]]; then
		echo "未检测到有效 JSON_FILES 路径参数或者输入参数非目录，请重新输入！"
		exit
	else
		JSON_FILES_PATH=$1
	fi
elif [[ $# -eq 2 ]]; then
	if [[ -z "$2" || ! -d "$2" ]]; then
		echo "未检测到有效 JSON_FILES 路径参数或输入参数非目录，请重新输入！"
		exit
	else
		JSON_FILES_PATH=$2
	fi
else
	echo "未检测到有效 JSON_FILES 路径参数或输入参数非目录，请重新输入！"
	exit
fi


# 检测 JSON_FILES_PATH 路径下的 JSON 文件数量
echo "-----------------JSON_FILES NUMBER CHECK-----------------"
num=`ls $JSON_FILES_PATH/*.json | wc -l`
if [[ num -eq 0 ]]; then
	echo "路径 $JSON_FILES_PATH 未检测到有效 JSON 文件！"
	exit
fi


# 检测 HDFS 是否启动
echo "-----------------HDFS CHECK-----------------"
hadoop fs -ls / > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
	echo "未检测到 HDFS 启动或正处于安全模式，请稍后重试！"
	exit
fi

# 创建 HDFS 目录
echo "-----------------HDFS PATH CREATE-----------------"
ls $JSON_FILES_PATH/*.json | while read -r file;do
	HDFS_PATH=`cat $file | grep -oP '^[^#]+' | grep "path" -m 1 | awk -F'"' '{print $4}'`
	echo "-----------------HDFS PATH CREATE 【$HDFS_PATH】-----------------"
	hadoop fs -mkdir -p $HDFS_PATH
	if [[ $? -ne 0 ]]; then
		exit
	fi
done


# 执行 DataX 数据同步任务
index=1
good=0
rm -rf /tmp/run_datax_errors.txt /tmp/run_datax_log.txt
echo "-----------------DATAX TASK RUN-----------------"
echo "-----------------共 $num 个数据同步执行文件-----------------"
find "$JSON_FILES_PATH" -maxdepth 1 -type f -name "*.json" | while read -r file;
do
	echo ""
    if [ -f "/tmp/run_datax_index_cnt.txt" ]; then
        index=`cat /tmp/run_datax_index_cnt.txt`
    fi
	echo "正在执行第 $index 个数据同步文件【$file】"
	python $DATAX_PATH/bin/datax.py $file >> /tmp/run_datax_log.txt 2>&1
	if [[ $? -ne 0 ]]; then
		echo "ERROR:第 $index 个数据同步文件【$file】执行失败！"
		echo "ERROR_JSON_FILE:$file" >> /tmp/run_datax_errors.txt
	else
		echo "SUCCESS:第 $index 个数据同步文件【$file】执行完成！"
        if [ -f "/tmp/run_datax_good_cnt.txt" ]; then
            good=`cat /tmp/run_datax_good_cnt.txt`
        fi
		echo $(($good+1)) > /tmp/run_datax_good_cnt.txt
	fi
	echo $(($index+1)) > /tmp/run_datax_index_cnt.txt
done

if [ -f "/tmp/run_datax_good_cnt.txt" ]; then
    good=`cat /tmp/run_datax_good_cnt.txt`
fi

if [ -f "/tmp/run_datax_index_cnt.txt" ]; then
    index=`cat /tmp/run_datax_index_cnt.txt`
fi

rm -rf /tmp/run_datax_good_cnt.txt /tmp/run_datax_index_cnt.txt > /dev/null 2>&1

error_cnt=$((num-good))

echo ""
echo "共执行 $num 个数据同步执行文件，其中 $good 个文件执行成功，$error_cnt 个文件执行失败。"
echo "-----------------DATAX TASK END-----------------"

if [[ $error_cnt -ne 0 ]]; then
	echo "错误日志查看：【/tmp/run_datax_log.txt】"
	echo "错误文件查看：【/tmp/run_datax_errors.txt】" 
fi