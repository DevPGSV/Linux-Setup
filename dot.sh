#!/bin/bash

DEV_userinstall="devinstall"


# Debian
function prepare_debian {
  export DEBIAN_FRONTEND=noninteractive
  apt-get -yq install jq
}

# Arch
function prepare_arch {
  pacman -S --needed --noconfirm sudo nano base-devel git wget yajl jq
  export EDITOR=/bin/nano

  if (id -u $DEV_userinstall &>/dev/null); then
    echo "$DEV_userinstall exists";
  else
    echo "Setting up $DEV_userinstall user...";
    useradd -M -N --system -s /bin/bash $DEV_userinstall
  fi;
  if grep -q "$DEV_userinstall ALL=NOPASSWD: /usr/bin/makepkg, /usr/bin/pacman" "/etc/sudoers"; then
    echo "sudoers file already set up";
  else
    echo "$DEV_userinstall ALL=NOPASSWD: /usr/bin/makepkg" | (EDITOR="tee -a" visudo)
  fi;

  if (yaourt --help &>/dev/null); then
    echo "Yaourt already installed";
  else
    mkdir -p /tmp/$DEV_userinstall
    pushd /tmp/$DEV_userinstall
    git clone https://aur.archlinux.org/package-query.git
    git clone https://aur.archlinux.org/yaourt.git
    chown -R $DEV_userinstall .
    cd package-query
    su -m $DEV_userinstall -c "makepkg -si --noconfirm"
    cd ../yaourt
    su -m $DEV_userinstall -c "makepkg -si --noconfirm"
    cd ..
    rm -dR yaourt/ package-query/
    popd
  fi;
}


function installPackage {
  # echo $1 $2
  from=`echo "$2" | jq -r ".from"`
  name=`echo "$2" | jq -r ".name"`
  echo $1 FROM $from NAME $name
  case $from in
    'pacman')
      pacman -S --needed --noconfirm $name
      ;;
    'apt')
      apt-get -yq install $name
      ;;
    'aur')
      su -m $DEV_userinstall -c "yaourt -S --noconfirm --force --needed $name"
      ;;
    'function')
      $name
      ;;
    'package')
      distro=`echo "$2" | jq -r ".distro"`
      pdata=`jq -cr ".packages.$name.$distro" config.json`
      echo $pdata;
      installPackage $1 $pdata
      ;;
  esac
}



distro="arch"
prepare_arch


for p in `jq -r ".packages | keys[]" config.json`; do
  echo -e "\n"
  read -p "Install $p. Press enter to continue"
  pdata=`jq -cr ".packages.$p.$distro" config.json`
  installPackage $p $pdata
  echo -e "\n"
done




























function debian-telegram-cli-git {
  if [ ! -d "/opt/telegram-cli" ]; then
    apt-get -yq install libreadline-dev libconfig-dev libssl-dev lua5.2 liblua5.2-dev libevent-dev libjansson-dev libpython-dev make gcc
    mkdir -p "/opt/telegram-cli"
    pushd "/opt/telegram-cli"
    git clone --recursive https://github.com/vysheng/tg.git .
    ./configure
    make
    popd
  fi;
  if [ ! -f "/usr/local/bin/telegram" ]; then
    cat << EOF > "/usr/local/bin/telegram"
    #!/bin/bash
    "/opt/telegram-cli/bin/telegram-cli" -k "/opt/telegram-cli/tg-server.pub" \$@
    EOF
    chmod a+x "/usr/local/bin/telegram"
  fi;
}

function common-eclipse {
  if [ ! -d "/opt/eclipse" ]; then
    wget -O "/tmp/eclipse-java-neon-3-linux-gtk-x86_64.tar.gz" "http://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/neon/3/eclipse-java-neon-3-linux-gtk-x86_64.tar.gz&r=1"
    mkdir -p "/tmp/eclipse"
    tar -zxvf "/tmp/eclipse-java-neon-3-linux-gtk-x86_64.tar.gz" -C "/tmp/eclipse"
    mv "/tmp/eclipse/eclipse" "/opt"
    rm -Rf /tmp/eclipse
    pushd "/opt/eclipse"

    eclipseFeaturesList=""
    eclipseRepo="http://download.eclipse.org/releases/neon"
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.cdt.feature.group; fi; # c/c++
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.jdt.feature.group,org.eclipse.linuxtools.javadocs.feature.feature.group; fi; # java
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.wst.jsdt.feature.feature.group,org.eclipse.wst.jsdt.chromium.debug.feature.feature.group; fi; # javascript
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.ldt.feature.group,org.eclipse.ldt.source.feature.group; fi; # lua
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.php.feature.group; fi; # php
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.photran.feature.group; fi; # fortran
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.egit.feature.group; fi; # git
    if true; then eclipseFeaturesList=$eclipseFeaturesList,org.eclipse.wst.web_ui.feature.feature.group; fi; # web
    if [ ! -z "$eclipseFeaturesList" ]; then
      eclipseFeaturesList=${eclipseFeaturesList:1:${#eclipseFeaturesList}-1}
      ./eclipse -clean -purgeHistory -application org.eclipse.equinox.p2.director -noSplash -repository "$eclipseRepo" -installIUs $eclipseFeaturesList
    fi;

    # http://download.eclipse.org/releases/neon
    # c/c++: org.eclipse.cdt.feature.group
    # java: org.eclipse.jdt.feature.group,org.eclipse.linuxtools.javadocs.feature.feature.group
    # javascript: org.eclipse.wst.jsdt.feature.feature.group,org.eclipse.wst.jsdt.chromium.debug.feature.feature.group
    # lua: org.eclipse.ldt.feature.group,org.eclipse.ldt.source.feature.group
    # php: org.eclipse.php.feature.group
    # fortran: org.eclipse.photran.feature.group
    # git: org.eclipse.egit.feature.group
    # web: org.eclipse.wst.web_ui.feature.feature.group
    popd
  fi;
}
