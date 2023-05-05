# Contents of dockerfile below,
# adapted from: https://github.com/fangohr/octopus-in-docker ,
# and informed by gpu build script distributed with the source code:  https://gitlab.com/octopus-code/octopus/-/raw/main/scripts/build/build_octopus_mpcdf.sh


#Octopus-gpu with 11.7.1-devel-ubuntu20.04
FROM nvcr.io/nvidia/cuda:11.7.1-devel-ubuntu20.04

ENV CRAY_ACCEL_TARGET=nvidia80
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /opt/mpich

RUN \
    apt-get update        && \
    apt-get install --yes    \
        build-essential      \
        gfortran             \
        python3-dev          \
        python3-pip          \
        wget              && \
    apt-get clean all

ARG mpich=4.0.2
ARG mpich_prefix=mpich-$mpich

RUN \
    wget https://www.mpich.org/static/downloads/$mpich/$mpich_prefix.tar.gz && \
    tar xvzf $mpich_prefix.tar.gz                                           && \
    cd $mpich_prefix                                                        && \
    ./configure                                                             && \
    make -j 2                                                               && \
    make install                                                            && \
    make clean                                                              && \
    cd ..                                                                   && \
    rm -rf $mpich_prefix

RUN /sbin/ldconfig

#Now get debs for octopus
RUN apt-get -y update && apt-get -y install wget time nano vim emacs \
    autoconf \
    automake \
    fftw3-dev \
    g++ \
    gcc \
    gfortran \
    git \
    libatlas-base-dev \
    libblas-dev \
    libboost-dev \
    libcgal-dev \
    libelpa-dev \
    libetsf-io-dev \
    libfftw3-dev \
    libgmp-dev \
    libgsl-dev \
    liblapack-dev \
    liblapack-dev \
    libmpfr-dev \
    libnetcdff-dev \
    libnlopt-dev \
    libscalapack-mpi-dev \
    libspfft-dev \
    libtool \
    libxc-dev \
    libyaml-dev \
    openscad \
    openctm-tools \
    pkg-config \
    procps \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt
RUN wget -O oct.tar.gz https://octopus-code.org/download/12.2/octopus-12.2.tar.gz  && tar xfvz oct.tar.gz && rm oct.tar.gz

WORKDIR /opt/octopus-12.2

RUN autoreconf -i
RUN ./configure --enable-mpi --enable-openmp --enable-cuda --enable-nvtx --with-cuda-prefix='/usr/local/cuda/'

# Which optional dependencies are missing?
RUN cat config.log | grep WARN > octopus-configlog-warnings
RUN cat octopus-configlog-warnings

# all in one line to make image smaller
RUN make && make install && make clean && make distclean

# offer directory for mounting container
WORKDIR /io

CMD bash -l

