#!/bin/bash



# Arch
function prepare_arch {
  pacman -S --needed --noconfirm sudo nano base-devel git wget yajl
  export EDITOR=/bin/nano

  if (id -u devinstall &>/dev/null); then
    echo "devinstall exists";
  else
    echo "Setting up devinstall user...";
    useradd -M -N --system -s /bin/bash devinstall
  fi;
  if grep -q "devinstall ALL=NOPASSWD: /usr/bin/makepkg" "/etc/sudoers"; then
    echo "sudoers file already set up";
  else
    echo "devinstall ALL=NOPASSWD: /usr/bin/makepkg" | (EDITOR="tee -a" visudo)
  fi;

  mkdir -p /tmp/devinstall
  pushd /tmp/devinstall
  git clone https://aur.archlinux.org/package-query.git
  git clone https://aur.archlinux.org/yaourt.git
  chown -R devinstall:devinstall .
  cd package-query
  su -m devinstall -c "makepkg -si"
  cd ../yaourt
  su -m devinstall -c "makepkg -si"
  cd ..
  rm -dR yaourt/ package-query/
  popd
}

prepare_arch
