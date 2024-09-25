# Git用户配置信息
GIT_USER_NAME="小HUI灰"
GIT_USER_EMAIL="21794468@qq.com"
DIFY_URL="https://github.com/xiyanluo/dify.git"
# Pyenv与Python环境信息
Python_Version=3.10.14
Python_URL=http://wp.dayousoft.com/py/Python-3.10.14.tar.xz

install_git(){
  echo ">>>>>>>>> 1:正在配置Git环境 <<<<<<<<<<<"
  if ! git --version &> /dev/null; then
      echo "- Git is not installed. Installing git..."
      # 使用yum安装git
      sudo yum install -y git
      if [ $? -ne 0 ]; then
          echo "- Failed to install git."
          exit 1
      fi
      printSuccess "- [Git]安装成功."
  fi

  # 输出git版本
  git_version=$(git --version)
  echo "- Git version: $git_version"

  # 配置git用户信息
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  echo "- Git global user name and email configured to $GIT_USER_NAME and $GIT_USER_EMAIL."

  # 克隆指定的仓库
  echo "- 正在拉取[Dify]: $DIFY_URL"
  git clone $DIFY_URL
  if [ $? -eq 0 ]; then
      printSuccess "- [Dify]拉取成功"
  else
      printFail "- [Dify]拉取失败,请检查网络"
  fi
}


printSuccess() {
    echo -e "\033[0;32m$1\033[0m"
}
printFail() {
    echo -e "\033[31m$1\033[0m"
}