# -*- coding: utf-8 -*-

# @Time : 2023/9/17 9:26
# @Author : HJ
# @File : datax_mysql_hdfs_json.py
# @Software : PyCharm

import json
import os
import pymysql
from config import config
import re


# 读取配置文件，设置相关配置
def read_config():
    try:
        global dict_list

        # 设置配置文件
        for key, value in config.items():
            config[key] = config[key].strip(" ")
            if config[key] == "" and dict_list[key] == "":
                print("%s 配置文件有误，请检查后重试。" % key)
                exit(1)
            elif config[key] != "":
                dict_list[key] = config[key]

        # 判断 JSON 文件输入与输出路径是否正确
        for key in ['template_json_file_path', 'save_json_path']:
            if not os.path.exists(config[key]):
                print("The %s does not exist." % key)
                exit(1)

    except Exception as e:
        print(e)
        exit(1)


# 连接 MySQL，获取库下的所有表以及对应字段
def get_table_column():
    try:
        # 连接数据库
        conn = pymysql.connect(
            host=dict_list["host"],  # MySQL服务器地址
            user=dict_list["username"],  # 用户名
            password=dict_list["password"],  # 密码
            database=dict_list["database"],  # 数据库名
        )
        # 创建游标
        cursor = conn.cursor()
        # 查询该库所有表
        cursor.execute('show tables')
        # 获取该库的所有表名称
        tableName_list = cursor.fetchall()
        # 获取表对应字段
        table_info = []
        for row in tableName_list:
            cursor.execute('desc %s;' % row[0])
            result = cursor.fetchall()
            table_info.append(result)
        # 获取数据类型转换后的字段
        result_column = []
        for info in table_info:
            column = []
            type_not_support_list = ["decimal", "binary", "maps", "arrays","structs","union","date","timestamp","char","varchar","text","set","geometry"]
            for el in info:
                key, value = str(el[0]), str(el[1])
                for type in type_not_support_list:
                    # 将 MySQL 中不支持的类型都统一转换为 string
                    if type in value:
                        value = "string"
                        break

                # 特殊数据类型判断
                if value == "integer":
                    value = "int"

                column.append({"name": key, "type": value})

            result_column.append(column)
        # 添加对应表名称
        result_list = []
        for i in range(0, len(tableName_list)):
            result_list.append({tableName_list[i][0]: result_column[i]})
        # 关闭游标和连接
        cursor.close()
        conn.close()
        # 返回获取到的表名以及对应表转换后的字段列表，格式为 [{key:[value]}]
        return result_list
    except Exception as e:
        print(e)
        exit(1)


# 读取 JSON 模板文件
def read_json(filename):
    try:
        with open(filename, 'r') as file:
            data = json.load(file)
        return data
    except Exception as e:
        print(e)
        exit(1)


# 更新 JSON 模板
def update_json(json_data, table_name, column_list):
    try:
        if isinstance(json_data, dict):
            for key, value in json_data.items():
                if key in ["username", "password", "defaultFS", "fileType", "writeMode", "fieldDelimiter", "compress"]:
                    json_data[key] = dict_list[key]
                elif key == "path":
                    if dict_list["template_path"].strip() == "":
                        json_data[key] = re.sub(r'/+', '/',dict_list[key])
                    else:
                        json_data[key] = re.sub(r'/+', '/',dict_list[key] + "/" + table_name + "/" + dict_list["template_path"].strip() + "/")
                elif key == "column":
                    json_data[key] = column_list
                elif key == "fileName":
                    if dict_list[key] == "table_name":
                        json_data[key] = "%s" % table_name
                    else:
                        json_data[key] = dict_list[key]
                elif key == "querySql":
                    json_data[key] = ["select * from %s.%s;" % (dict_list['database'], table_name)]
                elif key == "jdbcUrl":
                    json_data[key] = [
                        "jdbc:mysql://%s:%s?useSSL=false&useUnicode=true&characterEncoding=utf-8&allowPublicKeyRetrieval=true" % (
                            dict_list['host'], dict_list['port'])]
                else:
                    update_json(value, table_name, column_list)
        elif isinstance(json_data, list):
            for item in json_data:
                update_json(item, table_name, column_list)
    except Exception as e:
        print(e)
        exit(1)


# 主函数
if __name__ == '__main__':
    # 定义配置参数以及部分默认值
    dict_list = {
        "username": "",
        "password": "",
        "database": "",
        "host": "localhost",
        "port": "3306",
        "defaultFS": "hdfs://127.0.0.1:8020",
        "fileName": "table_name",
        "fileType": "text",
        "path": "/",
        "template_path": "template_path",
        "writeMode": "append",
        "fieldDelimiter": "\t",
        "compress": "gzip",
        "template_json_file_path": "",
        "save_json_path": "/opt",
    }

    # 调用配置文件函数进行参数配置
    read_config()

    # 获取所有表及其字段列表
    result_list = get_table_column()

    # 读取 JSON 模板数据
    json_data = read_json(dict_list['template_json_file_path'])

    try:
        # 按照配置生成 JSON 作业数据
        for items in result_list:
            tmp_json_data = json_data
            for item in items:
                # 将配置数据写入 JSON 模板中
                table_name, column_list = item, items.get(item, [])
                update_json(tmp_json_data, table_name, column_list)
                # 将生成的 JSON 文件进行存储，将 save_json_path 作为主路径、database 库名作为子路径、表名作为 JSON 文件名称进行存储
                if not os.path.exists("%s/%s" % (dict_list['save_json_path'], dict_list['database'])):
                    os.mkdir("%s/%s" % (dict_list['save_json_path'], dict_list['database']))
                with open("%s/%s/%s.json" % (dict_list['save_json_path'], dict_list['database'], table_name),
                          'w') as file:
                    json.dump(tmp_json_data, file, indent=4)
    except Exception as e:
        print(e)
        exit(1)
