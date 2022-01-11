FROM fedora:latest

# Installing pe-util to be able to determine the DLL
# dependencies of the executable
WORKDIR /root
RUN dnf install -y git cmake gcc-c++ boost-devel
RUN git clone https://github.com/gsauthof/pe-util
WORKDIR pe-util
RUN git submodule update --init
RUN mkdir build
WORKDIR build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release
RUN make

FROM fedora:latest
COPY --from=0 /root/pe-util/build/peldd /usr/bin/peldd

# Switching to the root user to install dependencies
USER root

# Installing packages
RUN dnf -y update; dnf clean all
RUN dnf install -y git cmake gcc-c++ boost-devel mingw64-gcc
RUN dnf install -y mingw64-freetype mingw64-cairo mingw64-harfbuzz
RUN dnf install -y mingw64-pango
RUN dnf install -y mingw64-poppler
RUN dnf install -y mingw64-gtk3
RUN dnf install -y mingw64-winpthreads-static
RUN dnf install -y mingw64-glib2-static gcc boost zip
RUN dnf clean all -y

# Creating not-root user and switching to it
RUN useradd -ms /bin/bash crosscc
USER crosscc

# Setting environment variables for pkg-config
ENV PKG_CONFIG_ALLOW_CROSS=1

ENV PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/sys-root/mingw/lib/pkgconfig/
ENV PKG_CONFIG_LIBDIR=/usr/x86_64-w64-mingw32/sys-root/mingw/lib/pkgconfig/
ENV GTK_INSTALL_PATH=/usr/x86_64-w64-mingw32/sys-root/mingw

# Setting up the project home
VOLUME /home/crosscc/src
WORKDIR /home/crosscc/src

# Compilation command that gets executed when the image is run
CMD /bin/bash package.sh

# USAGE:
#
# 1. Create image
# ===============
#
# Run this only once (and whenever changes are made to this Dockerfile) to
# create the Docker image:
#
# docker build . -t cppcc
#
# 2. Create project instance
# ==========================
#
# Run this for each project (and whenever the Dockerfile is changed). If you
# need to rerun this, you have to remove the container using `docker rm` and
# the ID. This command and the next one has tobe run in the project root.
#
# docker create -v $(pwd):/home/crosscc/src --name cppcc_gtk cppcc:latest
#
# 3. Compile the project
# ======================
#
# Run this every time the project needs to be recompiled. This command and the
# previous one need to be run in the project root.
#
# docker start -ai cppcc_gtk

