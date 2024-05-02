#!/bin/bash
usage(){
  cat << END_HELP
gitup: git with automation
Usage:
  -i                          initialize git repo
  -u                          updat repo in git local tree
  -ru                         update repo in git local & remote tree
  --config                    set basic git configurations
  -c <git repo link>          clone git repo
END_HELP
}

configCheck(){
  echo -ne "[+] checking for configurations"
  echo -ne "\n[+] checking for git username"
  git config user.name > /dev/null
  local ecodegitusername=$?
  if [ $ecodegitusername -ne 0 ]; then
    echo -ne "\n[-] git username is not set"
  fi
  echo -ne "\n[+] checking for git email"
  git config user.email > /dev/null
  local ecodegitemail=$?
  if [ $ecodegitemail -ne 0 ]; then
    echo -ne "\n[-] git email is not set"
  fi
  if [ $ecodegitemail -ne 0 ] || [ $ecodegitusername -ne 0 ]; then
    exit 1
  fi
  exit 0
}

localCommit(){
  if [ -d ".git" ]; then
    if [ "$PWD" = "$(git rev-parse --show-toplevel)" ]; then
      if [ -z "$(git status --porcelain)" ]; then
        echo -ne "[+] nothing to commit in local tree\n"
        exit 0
      fi
      git add .
      if [ $? -eq 0 ]; then
        echo -ne "[+] all files added to commit"
        echo -ne "\n[+] git status\n"
        git status
        read -p "commit message: " commitmsg
        git commit -m "$commitmsg";
        if [ $? -eq 0 ]; then
          echo -ne "\n[+] updates done in your local tree\n"
        fi
      fi
    else
      echo -ne "[-] Error: currently you are not in git top directory"
      echo -ne "\n[+] change to $(git rev-parse --show-toplevel) to commit changes \n"
      exit 1
    fi
  else
    echo -ne "[-] Error: No version control history found"
    echo -ne "\n[+] gitup: Use -i flag to initialize git in current directory \n"
    echo -ne "\n"
    usage
    exit 1
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    -c)
      shift
      if [ -z "$1" ]; then
        echo "Error: Git repo link not provided"
        usage
        exit 1
      else
        git clone $1
        exit 0
      fi
      ;;
    -i)
      checkconfig=$(configCheck)
      if [ "$?" -eq 0 ]; then
        echo -ne "[+] config is all set"
        echo -ne "\n[+] initializing git in current directory...\n"
        git init
        exit 0
      else
        echo -ne "[-] Error: git basic configurations are not set up"
        echo -ne "\n[*] gitup: gitup --config to set up your git configurations first"
        usage
        exit 1
      fi
      exit 0
      ;;
    --config)
      checkconfig=$(configCheck)
      if [ $? -ne 0 ]; then
        echo -ne "[-] Error: Git basic configuration is not set properly"
        echo -ne "\n[?] Set up your git configuration?[y/n] "
        read -n 1 configans
        if [ "$configans" == "y" ]; then
          echo -e "\n[+] setting up git config..."
          echo -ne "Your git username: "
          read configusername
          echo "[+] setting up your username"
          git config --global user.name "$configusername"
          echo -ne "Your git email: "
          read configemail
          echo "[+] setting up your email"
          git config --global user.email "$configemail"
          echo -ne "\n[+] Git email: $(git config user.email)"
          echo -ne "\n[+] Git username: $(git config user.name)\n"
          echo -e "\n[+] basic configurations is all set"
          exit 0
        else
          echo -e "\n[-] need basic configurations to operate git"
          exit 1
        fi
      else
        echo "[+] git configurations is all set"
        exit 0
      fi
      ;;
    -u)
      checkconfig=$(configCheck)
      if [ $? -eq 0 ]; then
        localCommit
        exit 0
      fi
      ;;
    -ru)
      checkconfig=$(configCheck)
      if [ $? -eq 0 ]; then
        localCommit
        if [ $? -eq 0 ]; then
          git config remote.origin.url > /dev/null
          if [ $? -ne 0 ]; then
            echo -ne "\n[?] remote repo url: "
            read remoterepo
            git remote add origin "$remoterepo"
            echo -ne "\n[+] remote repo added"
          fi
          echo -ne "\n[?] branch to push: "
          read branch
          git branch -M "$branch"
          echo -ne "\n[+] pushing your commits to remote on $branch branch"
          echo -ne "\n[+] remote repo: $(git status remote.origin.url)"
          git push -u origin "$branch"
          echo -ne "\n"
          exit 0
        fi
      fi
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

localCommit
