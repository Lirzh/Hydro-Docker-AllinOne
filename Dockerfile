FROM nixos/nix:latest

USER root

# 创建兼容的 os-release 文件,让安装脚本能识别系统类型
RUN echo 'NAME=NixOS' > /etc/os-release && \
    echo 'ID=nixos' >> /etc/os-release && \
    echo 'VERSION="24.11 (Tapir)"' >> /etc/os-release && \
    echo 'VERSION_ID=24.11' >> /etc/os-release && \
    echo 'PRETTY_NAME="NixOS 24.11 (Tapir)"' >> /etc/os-release && \
    echo 'BUILD_ID=24.11' >> /etc/os-release && \
    echo 'ANSI_COLOR="38;2;77;156;212"' >> /etc/os-release && \
    echo 'HOME_URL="https://nixos.org/"' >> /etc/os-release && \
    echo 'DOCUMENTATION_URL="https://nixos.org/learn.html"' >> /etc/os-release && \
    echo 'SUPPORT_URL="https://nixos.org/community.html"' >> /etc/os-release && \
    echo 'BUG_REPORT_URL="https://github.com/NixOS/nixpkgs/issues"' >> /etc/os-release && \
    echo 'LOGO=nixos' >> /etc/os-release

# 创建必要的目录结构,确保与标准 Linux 发行版兼容
RUN mkdir -p /usr/local/bin /usr/local/lib /usr/local/etc

# 使用 Hydro 提供的 Nix 配置脚本进行环境初始化
RUN curl -fsSL --max-time 60 --retry 3 https://hydro.ac/nix.sh -o /tmp/hydro-nix.sh && \
    chmod +x /tmp/hydro-nix.sh && \
    bash /tmp/hydro-nix.sh && \
    rm -f /tmp/hydro-nix.sh

# 下载并执行 Hydro 安装脚本,显式加载 Nix 环境变量
RUN curl -fsSL --max-time 60 --retry 3 https://hydro.ac/setup.sh -o /tmp/hydro-setup.sh && \
    chmod +x /tmp/hydro-setup.sh && \
    export PATH="/root/.nix-profile/bin:$PATH" && \
    LANG=zh bash /tmp/hydro-setup.sh --no-caddy && \
    rm -f /tmp/hydro-setup.sh

RUN pm2 ls

RUN yarn -v
RUN yarn config set registry https://registry.npmmirror.com
