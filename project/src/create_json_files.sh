#!/bin/bash

# 判断运行文件是否存在同一目录下
echo "-----------------FILE PATH CHECK-----------------"
if [[ ! -f "./template.json" ]]; then
	echo "当前路径下不存在 template.json 模板文件！！！"
	exit
fi

if [[ ! -f "./config.py" ]]; then
	echo "当前路径下不存在 config.py 配置文件！！！"
	exit
fi

if [[ ! -f "./datax_mysql_hdfs_json.py" ]]; then
	echo "当前路径下不存在执行 datax_mysql_hdfs_json.py 文件！！！"
	exit
fi


echo "-----------------PYTHON ENV CHECK-----------------"
python3 -c "import pymysql" > /tmp/run_log.txt 2>&1
if [[ $? -ne 0 ]]; then
  echo "-----------------Python3 环境调用失败，正在尝试使用 Python2-----------------"
  python -c "import pymysql" >> /tmp/run_log.txt 2>&1
  if [[ $? -ne 0 ]]; then
    cat /tmp/run_log.txt
    exit
  fi
fi


echo "-----------------JSON SAVE PATH CHECK-----------------"
JSON_SAVE_PATH=`cat config.py | grep -oP '^[^#]+' | grep "save_json_path" | awk -F'"' '{print $4}'`
if [[ ! -d $JSON_SAVE_PATH ]]; then
	echo "本地不存在 $JSON_SAVE_PATH 路径！"
	echo "-----------------正在尝试创建-----------------"
	mkdir -p $JSON_SAVE_PATH
	if [[ $? -ne 0 ]]; then
		exit
	fi
	exit
fi

echo "-----------------JSON FILE CREATE START-----------------"
python3 datax_mysql_hdfs_json.py > /tmp/run_log.txt 2>&1
if [[ $? -ne 0 ]]; then
  echo "-----------------Python3 环境执行失败，正在尝试使用 Python2 执行-----------------"
  python datax_mysql_hdfs_json.py >> /tmp/run_log.txt 2>&1
  if [[ $? -ne 0 ]]; then
    cat /tmp/run_log.txt
    exit
  fi
fi


echo "-----------------JSON FILE CREATE END-----------------"

DATABASE_NAME=`cat config.py | grep -oP '^[^#]+' | grep "database" | awk -F'"' '{print $4}'`

echo ""

echo "JSON FILE SAVE PATH: $JSON_SAVE_PATH"

echo ""

ls $JSON_SAVE_PATH/$DATABASE_NAME/*.json -l