# Git用户配置信息
GIT_USER_NAME="小HUI灰"
GIT_USER_EMAIL="21794468@qq.com"
DIFY_URL="https://ghfast.top/https://github.com/xiyanluo/dify.git"
# Pyenv环境信息
PYENV_URL="https://ghfast.top/https://github.com/pyenv/pyenv.git"
# Python环境信息
PYTHON_VERSION="3.12.6"
PYTHON_ARCHIVE="Python-$PYTHON_VERSION.tar.xz"
PYTHON_URL="http://wp.dayousoft.com/py/Python-3.12.6.tar.xz"
# node环境信息
NODE_URL="https://rpm.nodesource.com/setup_20.x"

install_git(){
  echo ">>>>>>>>> 1:正在配置Git环境 <<<<<<<<<<<"
  if ! git --version &> /dev/null; then
      echo "- Installing git..."
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
      printFail "- [Dify]拉取失败"
#      exit 1
  fi
}

install_pyenv(){
  echo ">>>>>>>>> 2:正在配置Pyenv环境 <<<<<<<<<<<"
  if [ ! -d "$HOME/.pyenv" ]; then
      echo "- Installing pyenv..."
      git clone $PYENV_URL ~/.pyenv
      if [ $? -eq 0 ]; then
          printSuccess "- [Pyenv]拉取成功"
          cd ~/.pyenv && src/configure && make -C src
          # Add pyenv to bashrc
          echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
          echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
          echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
          # Source the bashrc file
          source ~/.bashrc
          pyenv --version
      else
          printFail "- [Pyenv]拉取失败"
          exit 1
      fi
  else
      echo "- [Pyenv] 检测出已存在"
      pyenv --version
  fi
}

install_Python(){
  echo ">>>>>>>>> 3:正在配置Python环境 <<<<<<<<<<<"
  wget $PYTHON_URL
  # Create cache directory and move the downloaded file
  mkdir -p "$HOME/.pyenv/cache"
  mv $PYTHON_ARCHIVE "$HOME/.pyenv/cache/"
  # Install Python using pyenv
  pyenv install $PYTHON_VERSION
  pyenv global $PYTHON_VERSION
  # Check python version
  python3 --version
  # Install development tools and libraries
  sudo yum install -y openssl-devel zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel wget curl llvm ncurses-devel xz xz-devel libffi-devel gcc gcc-c++ python3-devel
  sudo yum groupinstall -y "Development Tools"
  # Upgrade pip and install necessary Python packages
  python3 -m pip install --upgrade pip setuptools wheel
  python3 -m pip install grpcio==1.60.0 -i https://pypi.org/simple
}

install_Poetry(){
  echo ">>>>>>>>> 3:正在配置Poetry环境 <<<<<<<<<<<"
  # 检查 poetry 是否已安装
  if ! command -v poetry &> /dev/null
  then
      echo "[poetry]现在将通过 pip 安装..."
      pip install poetry
  else
      echo "[poetry]已安装"
  fi
  poetry --version
}

install_Node(){
  echo ">>>>>>>>> 4:正在配置Node环境 <<<<<<<<<<<"
  if command -v node > /dev/null 2>&1 && command -v npm > /dev/null 2>&1; then
      echo "- Node和npm已经安装。"
      echo "- Node版本: $(node -v)"
      echo "- NPM版本: $(npm -v)"
  else
      echo "Node未安装，现在开始安装..."
      # 导入NodeSource Node.js 20.x repo
      curl -fsSL $NODE_URL | sudo bash -
      # 安装Node.js
      if sudo dnf install -y nodejs; then
          printSuccess "- [Node]安装成功."
          echo "Node版本: $(node -v)"
          echo "NPM版本: $(npm -v)"
      else
          printFail "Node安装失败。"
          exit 1
      fi
  fi
}
getStatus(){
  echo "pyenv版本: $(pyenv --version)"
  echo "python3版本: $(python3 --version)"
  echo "poetry版本: $(poetry --version)"
  echo "Node版本: $(node -v)"
  echo "NPM版本: $(npm -v)"
}
printSuccess() {
    echo -e "\033[0;32m$1\033[0m"
}
printFail() {
    echo -e "\033[31m$1\033[0m"
}
restart(){
  install_git
  install_pyenv
  install_Python
  install_Poetry
  install_Node
}
case "$1" in
  "status") #查看状态
    getStatus
    ;;
  "python")
    install_Python
    ;;
  "pyenv")
    install_pyenv
    install_Poetry
    ;;
  *)
    restart
    ;;
esac
exit 0