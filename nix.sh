#!/usr/bin/env bash
profile=~/.nix-profile/etc/profile.d/nix.sh

install_source=https://nixos.org/nix/install
mirror_ustc=https://mirrors.ustc.edu.cn
mirror_bfsu=https://mirrors.bfsu.edu.cn
mirror_nju=https://mirror.nju.edu.cn
mirror_iscas=https://mirror.iscas.ac.cn
channel=nixpkgs-unstable

conn_test() {
    # test all arguments, return status code if not 200
    for arg in "$@"; do
        result=$(curl --connect-timeout 5 -o /tmp/conn-test -s -w "%{http_code}" $arg -L -I)
        if [[ -z "$result" || "$result" != "200" ]]; then
            echo "$result"
            return 0
        fi
        test_output=$(cat /tmp/conn-test | grep "We have detected enormous traffic")
        if [ ! -z "$test_output" -a "$test_output" != " " ]; then
            echo "999"
            return 0
        fi
    done
    echo "200"
    return 0
}

echo ""
echo "---Connection Status---"
ustc_code=$(conn_test $mirror_ustc/nix-channels/store)
echo "USTC: $ustc_code"
bfsu_code=$(conn_test $mirror_bfsu/nix-channels/store $mirror_bfsu/nix/latest/install)
echo "BFSU: $bfsu_code"
nju_code=$(conn_test $mirror_nju/nix-channels/ $mirror_nju/nix/latest/install)
echo "NJU: $nju_code"
iscas_code=$(conn_test $mirror_iscas/nix-channels/ $mirror_iscas/nix/latest/install)
echo "ISCAS: $iscas_code"
nix_code=$(conn_test https://nixos.org/)
echo "NIX: $nix_code"

if [[ "$nix_no_mirror" ]]; then
    echo "wont use mirror for channel"
elif [[ "$nix_mirror" ]]; then
    selected_mirror=$nix_mirror
elif [[ "$nju_code" == "200" ]]; then
    selected_mirror=$mirror_nju
elif [[ "$bfsu_code" == "200" ]]; then
    selected_mirror=$mirror_bfsu
elif [[ "$ustc_code" == "200" ]]; then
    selected_mirror=$mirror_ustc
elif [[ "$iscas_code" == "200" ]]; then
    selected_mirror=$mirror_iscas
fi

# Note: USTC mirror didn't provide install script
if [[ "$nix_install_source" ]]; then
    echo "use install source $install_source"
    install_source=$nix_install_source
elif [[ "$nix_no_mirror" ]]; then
    echo "wont use mirror for nix install script"
elif [[ "$nju_code" == "200" ]]; then
    install_source=$mirror_nju/nix/latest/install
elif [[ "$bfsu_code" == "200" ]]; then
    install_source=$mirror_bfsu/nix/latest/install
elif [[ "$iscas_code" == "200" ]]; then
    install_source=$mirror_iscas/nix/latest/install
fi

if [ -f $profile ] && ! [ -x "$(command -v nix)" ]; then
    . $profile || true
fi

set -e
PATH=$PATH:/usr/sbin

if ! [ -x "$(command -v nix)" ]; then
    echo No nix found. Installing...
    if [ -x "$(command -v apk)" ]; then
        # preserve=ownership,timestamps requested by setup-nix.sh
        # and `cp` command from busybox doesn't support this option
        apk add xz curl bash shadow coreutils
    fi
    mkdir -p -m 0755 /nix
    if ! [ -x "$(command -v groupadd)" ]; then
        echo "groupadd command was required to run this script"
        exit
    fi
    groupadd nixbld -g 30000 || true
    for i in {1..10}; do
        useradd -c "Nix build user $i" -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(which nologin)" "nixbld$i" || true
    done
    if ! [ -x "$(command -v xz)" ]; then
        if [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
            apt-get update
            apt-get install xz-utils -y
        else
            echo "xz command was required to run this script"
            exit
        fi
    fi
    if [ -f "/snap/bin/curl" ]; then # Not compatible with snap curl
        snap remove curl || true
        if [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
            apt-get update
            apt-get install curl -y
        elif ! [ -x "$(command -v wget)" ]; then
            echo "please install wget or curl, without snap."
            exit
        fi
    fi
    echo "Downloading from $install_source"
    if [[ -z "$NIX_DEBUG" ]]; then
        curl -L $install_source --output /tmp/nix-install.sh
        head /tmp/nix-install.sh
    else
        curl -L $install_source --output /tmp/nix-install.sh -v
        head /tmp/nix-install.sh
    fi
    if [[ "$NIX_USE_DAEMON" ]]; then
        sh /tmp/nix-install.sh --no-daemon --no-channel-add
    else
        sh /tmp/nix-install.sh --no-channel-add
    fi
    echo ". $profile" >>~/.bashrc
    [[ -f ~/.zshrc ]] && echo ". $profile" >>~/.zshrc
    . $profile
    mkdir -p /etc/nix
fi

if [[ -z "$nix_no_mirror" ]]; then
    echo "substituters = $mirror_bfsu/nix-channels/store $mirror_ustc/nix-channels/store $mirror_nju/nix-channels/store $mirror_iscas/nix-channels/store https://nix-bin.hydro.ac/" >/etc/nix/nix.conf    
else
    echo "substituters = https://cache.nixos.org/" >/etc/nix/nix.conf
fi
echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= hydro.ac:EytfvyReWHFwhY9MCGimCIn46KQNfmv9y8E2NqlNfxQ=" >>/etc/nix/nix.conf
echo "connect-timeout = 10" >>/etc/nix/nix.conf
echo "experimental-features = nix-command flakes" >>/etc/nix/nix.conf
if ! [ "$(nix-channel --list | grep nixpkgs)" ]; then
    if [[ -z "$selected_mirror" ]]; then
        nix-channel --add https://nixos.org/channels/$channel nixpkgs
    else
        nix-channel --add $selected_mirror/nix-channels/$channel nixpkgs
    fi
fi
nix-channel --add https://nix-channel.hydro.ac/ hydro
echo "Now unpacking channel. might take a long time."
echo "You can safely ignore the 'installing Nix as root is not supported by this script' error above."
nix-channel --update
mkdir -p ~/.config/nixpkgs

set +e
