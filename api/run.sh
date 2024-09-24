#das!/bin/bash
APP_NAME=flask
LONG_NAME=flask_log.out
# 使用ps aux和grep查找所有flask进程
flask_processes=$(ps aux | grep flask | grep -v grep)

usage(){
    echo "Usage: sh 执行脚本.sh [start|stop|restart|status]"
    exit 1
}

is_exist(){
  # 通过awk获取每个flask进程的PID
  if [ -z "$flask_processes" ]; then
   echo "没有找到正在运行的flask进程。"
   return 1
  else
   # 输出找到的flask进程
   echo "找到以下flask进程："
   echo "$flask_processes"
   # 通过awk获取每个flask进程的PID
   pids=$(echo "$flask_processes" | awk '{print $2}')
   return 0
  fi
}

stop(){
  is_exist
  if [ $? -eq "0" ]; then
    for pid in $pids; do
      echo "正在杀掉进程 $pid ..."
      kill -9 $pid
      if [ $? -eq 0 ]; then
          echo "进程 $pid 已被成功杀掉。"
      else
          echo "无法杀掉进程 $pid。"
      fi
    done
  fi
}

start(){
  is_exist -e
  if [ $? -eq "0" ]; then
    echo "${APP_NAME} is already running. pid=${pid} ."
  else
    poetry shell
    nohup $APP_NAME run --host 0.0.0.0 --port 5001 --debug > $LONG_NAME 2>&1 &
    echo ">>> start $APP_NAME successed PID=$! <<<"
	tail -fn 200 $LONG_NAME
  fi
}

log(){
  is_exist
  if [ $? -eq "0" ]; then
    tail -fn 200 $LONG_NAME
  else
    echo "${APP_NAME} is not find"
  fi  
}
restart(){
  stop
  start
}
case "$1" in
  "start")
    start
    ;;
  "stop")
    stop
    ;;
  "log")
    log
    ;;
  *)
    restart
    ;;
esac
exit 0
