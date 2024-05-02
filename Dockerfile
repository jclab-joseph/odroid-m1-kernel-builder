FROM debian:bullseye as builder

RUN apt-get update -y && \
    apt-get install -y \
    git lzop build-essential gcc bc libncurses5-dev libc6-i386 lib32stdc++6 zlib1g \
    wget python3 python-is-python3 \
    flex bison bc fakeroot devscripts \
    kmod cpio libelf-dev libssl-dev

RUN update-alternatives --install ~/python python /usr/bin/python3 1

RUN cd /tmp && \
    mkdir -p /opt/toolchains && \
    wget https://releases.linaro.org/components/toolchain/binaries/7.4-2019.02/aarch64-linux-gnu/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz && \
    tar xvf gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz -C /opt/toolchains && \
    rm gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz

RUN useradd -m -s /bin/bash build

USER build

RUN cd /home/build && \
    git clone --depth 1 https://github.com/hardkernel/linux.git -b odroidm1-5.10.y

COPY [ "prepare.sh", "/tmp/prepare.sh" ]
RUN cat /tmp/prepare.sh >> ~/.bashrc

WORKDIR /home/build/linux

RUN env | grep -E 'ARCH|CROSS_COMPILE|PATH'

COPY ["config", "/home/build/linux/.config"]

ARG EXTRAVERSION=-odroid-arm64
RUN . /tmp/prepare.sh && \
    make EXTRAVERSION=${EXTRAVERSION} -j`nproc` bindeb-pkg

FROM scratch

COPY --from=builder ["/home/build/linux-*", "/"]



