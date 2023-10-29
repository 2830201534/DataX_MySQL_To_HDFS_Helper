## 项目说明

---

基于 DataX 开发的快速同步 MySQL 数据至 HDFS 上的工具。自动获取 MySQL 中对象库的所有表，一键自动化批量配置 DataX 可执行 JSON 配置文件，自动化创建本地路径、HDFS 同结构存储路径。省去了繁琐的字段映射、配置文件编写步骤，自动化程度高，效率提升明显。

本项目基于 DataX3.0 开源项目的基础上完成 —— [DataX 官网](https://github.com/alibaba/DataX)


## Quick Start

---

### 1.安装 Python3 环境

本项目同时支持 Python3 和 Python2，请根据你的环境进行选择。

下载 Python3 连接 MySQL 的依赖库。

你可以使用 `pip3` 安装它:

```shell
pip3 install PyMySQL
```

或者：

```shell
pip install PyMySQL
```

如果你使用的是 MySQL8.x 版本，则需要进行额外的扩展下载，因为在 MySQL8.x 中需要进行连接认证，你可以通过如下命令来查询对应用户的认证规则：

```sql
SELECT host,user,plugin FROM mysql.user;
```

当认证方式为 `sha256_password` 或 `caching_sha2_password`，你需要安装额外的依赖项:

```shell
pip3 install PyMySQL[rsa]
```

或者：

```shell
pip install PyMySQL[rsa]
```

### 2.统一文件路径

**必须**将下列文件放置在同一路径下：

- 配置文件 `config.py`

- JSON 模板文件 `template.json`

- 文件创建程序 `datax_mysql_hdfs_json.py`

- 程序调度脚本 `create_json_files.sh`

### 3.编辑配置文件

按照你的需求，编辑 `config.py` 配置文件，请检查你配置的相关路径是否具有读写权限，否则程序调度时会出现异常。

> 不要更改配置文件原有结构、名称，配置内容必须使用英文双引号进行引用。

### 4.运行任务并创建 JSON 文件

运行脚本文件 `create_json_files.sh`，它会将本次执行日志信息存储在 `/tmp/run_log.txt` 文件中，如果遇到异常，请查看该文件内容。

```shell
bash create_json_files.sh
```

正常运行完成后，它将根据你在 `config.py` 配置文件中设定的信息，生成 DataX 所需的 JSON 配置文件，生成的 JSON 文件将存储在你指定的目录下。

### 5.可选项——自动批量执行 DataX 任务

自动批量执行 DataX 任务，将 MySQL 数据同步到 HDFS 上的 DataX 脚本 `run_datax.sh`，需要指定 DataX 安装路径以及存放 JSON 配置文件的路径（目录）。

开始执行前，请先启动 Hadoop 和 MySQL，确保服务能够正常执行，并且脚本拥有执行权限。

```shell
bash run_datax.sh $DATAX_HOME $JSON_FILES_HOME
```

如果你在环境变量中配置了 `$DATAX_HOME` 变量，那么会默认将该路径作为 DataX 的安装路径，只需要指定 `$JSON_FILES_HOME` 文件的存放根路径即可。

```shell
bash run_datax.sh $JSON_FILES_HOME
```

运行过程中，会打印对应提示信息，它会将本次运行日志信息存储在 `/tmp/run_datax_log.txt` 文件中，如果数据同步执行失败，会将失败的文件统计到 `/tmp/run_datax_errors.txt` 文件中，以供查看。


> 功能与限制同 DataX 开源项目保持一致，详细内容请查看：[hdfswriter](https://github.com/alibaba/DataX/blob/master/hdfswriter/doc/hdfswriter.md)


## 文件列表说明

--- 

展开对文件列表的说明。

**1.`config.py`：**
- 定义 DataX 的相关配置文件。

**2.`template.json`：**
- DataX 的 JSON 模板文件。  

**3.`datax_mysql_hdfs_json.py`：**
- 根据 `config.py` 配置文件和 `template.json` 模板文件，生成 DataX 可执行的 JSON 数据同步文件。

**4.`create_json_files.sh`：**
- 文件调度执行脚本，执行成功后，会将创建好的 JSON 数据同步文件存储到你指定的路径下，该路径由你在 `config.py` 配置文件中指定的 `save_json_path` 参数决定。

**5.`run_datax.sh`：**
- 执行 DataX 数据同步任务，需要传入两个参数： 
   - 1.DataX 安装根路径，该参数默认为环境变量中的 `$DATAX_HOME`，如果你配置了该环境变量，则可以省略该参数。
   - 2.待执行的批量 JSON 文件根路径

  检测到 HDFS 路径未创建时会自动进行创建，前提是需要相关权限。


## 配置文件参数介绍

---

展开对配置文件 `config.py` 的详细说明。

- `username`
指定 MySQL 连接账号，无默认值；


- `password`
指定 MySQL 连接密码，无默认值；


- `database`
指定 MySQL 连接库，无默认值；

  
- `host`
指定 MySQL 连接主机，默认值：`localhost`；

  
- `port`
指定 MySQL 连接端口，默认值：`3306`；


- `defaultFS`
指定 HDFS 连接地址，默认值：`hdfs://localhost:8020`；


- `fileName`
指定文件在 HDFS 上文件的存储前缀，默认值：当前操作的表名称；

  DataX 在进行数据同步时，为了避免重复路径的存在，采用了 `fileName` + 随机路径的方式实现，所以定义该值的意义并不大，在这里，直接对其做了默认化处理，也就是将正在操作的表名称作为前缀。当然，你也可以自定义名称。


- `fileType`
指定 HDFS 数据存储类型，默认值：`text` 文本类型【可选数据类型 `orc`】；


- `path`
指定 HDFS 数据存储路径，默认值：`/` 根路径；


- `template_path`
**新增参数**，指定 HDFS 中数据存储路径模板，无默认值；

  使用说明：假设要将 MySQL 库 `test` 所有的表都导入到 HDFS 上的 `/ods` 路径下的子目录 `/2023/09/19` 中，那么你将这样实现：
    - 定义 `"path": "/ods"` 存放主目录；
    - 定义`"template_path":"/2023/09/19"` 存放模板目录；
    
  系统在运行过程中会自动补全当前操作的表名称，补全后数据最终的存储路径为：`/ods/table_name/2023/09/19/`

  其中 `table_name` 会随着正在操作的表进行变化，该操作为批量执行，执行前请确认是否需要将所有表存储在相同结构的路径下。


- `writeMode`
指定文件写入形式，默认值：`append` 追加模式；
   - `append`：写入前不做任何处理，直接使用 `filename` 写入，并保证文件名不冲突。
   - `nonConflict`：如果目录下有 `fileName` 前缀的文件，直接报错。
   - `truncate`：如果目录下有 `fileName` 前缀的文件，先删除后写入。


- `fieldDelimiter`
指定数据行间隔符，默认值：`\t` 制表符；


- `compress`
指定数据压缩模式，默认值：`gzip` 压缩格式；
    - `text` 类型文件支持压缩类型：`gzip`、`bzip2`；
    - `orc` 类型文件支持压缩类型：`NONE`、`SNAPPY`（需要用户安装SnappyCodec）；
    


- `template_json_file_path`
**新增参数**，指定生成 DataX 可执行 JSON 文件的模板文件；


- `save_json_path`
**新增参数**，指定生成的 JSON 文件存储路径，默认值：`/opt`；

  该路径在执行过程中会自动进行创建（需要有创建权限）， 最终生成的文件目录为：`save_json_path/database_name/`；









