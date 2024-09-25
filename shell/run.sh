#das!/bin/bash
flask_name=flask
flask_log=flask_log.out
flask_processes=$(ps aux | grep flask | grep -v grep)
celery_log=celery_log.out
celery_processes=$(ps aux | grep celery | grep -v grep)

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
  nohup poetry run $flask_name run --host 0.0.0.0 --port 5001 --debug > $flask_log 2>&1 &
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
  nohup poetry run celery -A app.celery worker -P gevent -c 1 -Q dataset,generation,mail,ops_trace --loglevel INFO > $celery_log 2>&1 & disown
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
  git pull
}
updateLib(){
  cd api && poetry env use 3.10 && poetry install
}
installWeb(){
  cd web
  npm install
}

startDocker(){
  cd docker
  docker-compose -f docker-compose.middleware.yaml up -d
}

getStatus(){
  echo "----------正在查询 Flask-----------"
  if [ -n "$flask_processes" ]; then
    echo "找到以下进程:"
    echo "$flask_processes"
  else
    echo -e "\033[31mNot found\033[0m"
  fi
  echo "----------正在查询 Celery-----------"
  if [ -n "$celery_processes" ]; then
    echo "找到以下进程:"
    echo "$celery_processes"
  else
    echo -e "\033[31mNot found\033[0m"
  fi
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
  "log2")
    log_celery
    ;;
  "worker")
    restart_celery
    ;;
  "git") #git pull
    updateGit
    ;;
  "lib") #更新工程依赖包
    updateLib
    ;;
  "web")
    installWeb
    ;;
  "status")
    getStatus
    ;;
  "docker")
    startDocker
    ;;
  *)
    restart_flask
    ;;
esac
exit 0
