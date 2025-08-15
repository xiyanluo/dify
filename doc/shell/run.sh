#das!/bin/bash
flask_name=flask
flask_log=flask_log.out
flask_processes=$(ps aux | grep flask | grep -v grep)
celery_log=celery_log.out
celery_processes=$(ps aux | grep celery | grep -v grep)
# 定义变量
SOURCE_URL="https://pypi.tuna.tsinghua.edu.cn/simple/"
SOURCE_NAME="mirrors"
usage(){
    echo "Usage: sh 执行脚本.sh [start|stop|restart|status]"
    exit 1
}
#-----------[flask] API服务---------------
is_exist_flask(){
  # 通过awk获取每个flask进程的PID
  if [ -z "$flask_processes" ]; then
   echo "[${flask_name}]没有找到进程。"
   return 1
  else
   # 输出找到的flask进程
   echo "[${flask_name}]找到以下进程："
   echo "$flask_processes"
   # 通过awk获取每个flask进程的PID
   pids=$(echo "$flask_processes" | awk '{print $2}')
   return 0
  fi
}
stop_flask(){
  is_exist_flask
  if [ $? -eq "0" ]; then
    for pid in $pids; do
      kill -9 $pid
      if [ $? -eq 0 ]; then
          echo "[${flask_name}]进程 $pid 已被成功杀掉。"
      else
          echo "[${flask_name}]无法杀掉进程 $pid。"
      fi
    done
  fi
}

start_flask(){
  cd api
  nohup uv run $flask_name run --host 0.0.0.0 --port 5001 --debug > $flask_log 2>&1 &
  echo ">>> 启动 $flask_name 成功 PID=$! <<<"
	tail -fn 200 $flask_log
}

log_flask(){
  cd api
  tail -fn 200 $flask_log
}
restart_flask(){
  stop_flask
  start_flask
}
#-------------[celery] Worker服务----------
is_exist_celery(){
  # 通过awk获取每个celery进程的PID
  if [ -z "$celery_processes" ]; then
   echo "[celery]没有找到进程。"
   return 1
  else
   # 输出找到的celery进程
   echo "[celery]找到以下进程："
   echo "$celery_processes"
   # 通过awk获取每个celery进程的PID
   cids=$(echo "$celery_processes" | awk '{print $2}')
   return 0
  fi
}

stop_celery(){
  is_exist_celery
  if [ $? -eq "0" ]; then
    for pid in $cids; do
      kill -9 $pid
      if [ $? -eq 0 ]; then
          echo "[celery]进程 $pid 已被成功杀掉。"
      else
          echo "[celery]无法杀掉进程 $pid。"
      fi
    done
  fi
}

start_celery(){
  cd api
  nohup uv run celery -A app.celery worker -P gevent -c 1 -Q dataset,generation,mail,ops_trace --loglevel INFO > $celery_log 2>&1 & disown
  echo ">>> 启动 celery 成功 PID=$! <<<"
  sleep 2; echo "$celery_processes"
}

log_celery(){
  cd api
  tail -fn 200 $celery_log
}

restart_celery(){
  stop_celery
  start_celery
}

updateGit(){
  git reset --hard
  git pull
}
updateLib(){
  # 进入 API 目录
  cd api
  export UV_HTTP_TIMEOUT=240
  uv sync

# cd api && poetry env use 3.12 && poetry install
}
installWeb(){
  cd web
#  npm cache clean --force
#  npm config set registry https://registry.npmmirror.com
#  npm install
#  npm run build
  # 检查 pnpm 是否已安装
  if ! command -v pnpm &> /dev/null; then
      echo "pnpm 未安装，正在安装..."
      npm install -g pnpm
  else
      echo "pnpm 已安装，版本: $(pnpm --version)"
  fi
  # 清理 pnpm 缓存
  pnpm cache clean
  pnpm config set registry https://registry.npmmirror.com
  pnpm install
  NODE_OPTIONS="--max-old-space-size=4096" pnpm run build
}

startDocker(){
  cd docker
  docker-compose -f docker-compose.middleware.yaml up -d
}

updateDb(){
  cd api && uv run flask db upgrade
}
updateVdb(){
  cd api && uv run flask vdb-migrate
}

getStatus(){
  echo "----------正在查询[Flask]进程-----------"
  if [ -n "$flask_processes" ]; then
    echo "找到以下进程:"
    echo "$flask_processes"
  else
    echo -e "\033[31mNot found\033[0m"
  fi
  echo "----------正在查询[Celery]进程-----------"
  if [ -n "$celery_processes" ]; then
    echo "找到以下进程:"
    echo "$celery_processes"
  else
    echo -e "\033[31mNot found\033[0m"
  fi
  echo "----------正在查询Docker服务-----------"
  echo "找到以下Docker服务:"
  cd docker && docker-compose ps
}
doInstall(){
  startDocker
  updateLib
  updateDb
#  updateVdb
  installWeb
}

case "$1" in
  "stop")
    stop_flask
    ;;
  "log")
    log_flask
    ;;
  "stop2")
    stop_celery
    ;;
  "log2") #打印celery worker日志
    log_celery
    ;;
  "worker") #启动worker
    restart_celery
    ;;
  "git") #git pull
    updateGit
    ;;
  "lib") #更新py依赖包
    updateLib
    ;;
  "web") #编译web包
    installWeb
    ;;
  "status") #查看状态
    getStatus
    ;;
  "docker") #启动docker服务
    startDocker
    ;;
   "db") #pgsql数据库迁移
    updateDb
    ;;
   "vdb") #其它向量数据库更新
    updateVdb
    ;;
  *)
    restart_flask
    ;;
esac
exit 0
