#!/bin/bash
set -e

function add_user_for_docker() {
  if [ $# == 0 ]; then
    echo "need to pass the container name: $0 xxxx_container"
    exit 2
  fi
  container_name=$1
  user_name=$USER
  uid=`id -u`
  gid=`id -g`

  ifContainerUser=`docker exec -it -u root $container_name bash -c "id $user_name" | grep "no such user" | wc -l`
  if [ $ifContainerUser == 0 ]; then
    echo "user: $user_name already exists in container: $container_name"
    exit 1
  fi

  passwd_user="$user_name:x:$uid:$gid::/home/$user_name:/bin/bash"
  group_user="$user_name:x:$gid:"
  shadow_user="$user_name:*:0:99999:7:::"
  sudoers_user="%sudo ALL=(ALL) NOPASSWD:ALL"
  bash_user="alias ls=\"ls --color=auto\""

  cmd="echo $passwd_user >> /etc/passwd && \
echo $group_user >> /etc/group && \
echo $shadow_user >> /etc/shadow && \
pwconv && \
usermod -aG sudo $user_name && \
echo '$sudoers_user' >> /etc/sudoers && \
mkdir -p /home/$user_name && \
touch /home/$user_name/.bashrc && \
echo '$bash_user' >> /etc/bash.bashrc  && \
chown $user_name: /home/$user_name"

  docker exec -it -u root $container_name bash -c "$cmd"

  echo "Successfully added user for: $user_name on container: $container_name, with sudo enabled!"
  echo "With user added, you can exec docker using your own username, try this:"
  echo ""
  echo "docker exec -it -u $user_name $container_name /bin/bash"
}

add_user_for_docker $@
