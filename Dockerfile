FROM ubuntu:24.04

USER root

# 安装必要的依赖
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    sudo \
    bash \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 安装 Nix
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

# 配置 Nix 环境变量并安装 Hydro
ENV PATH="/root/.nix-profile/bin:${PATH}"
RUN echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /root/.bashrc

# 配置 Nix 使用国内镜像源
RUN mkdir -p /root/.config/nix && \
    echo 'substituters = https://mirrors.bfsu.edu.cn/nix-channels/store https://cache.nixos.org/' > /root/.config/nix/nix.conf && \
    echo 'trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' >> /root/.config/nix/nix.conf

# 下载并运行 Hydro 安装脚本
RUN curl -fsSL --max-time 60 --retry 3 https://hydro.ac/setup.sh -o /tmp/hydro-setup.sh && \
    chmod +x /tmp/hydro-setup.sh && \
    LANG=zh bash /tmp/hydro-setup.sh --no-caddy && \
    rm -f /tmp/hydro-setup.sh

RUN pm2 ls

RUN yarn -v
RUN yarn config set registry https://registry.npmmirror.com
