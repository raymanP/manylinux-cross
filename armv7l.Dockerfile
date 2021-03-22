FROM ubuntu:16.04

RUN apt-get update \
	&& apt-get install --no-install-recommends -y \
	automake \
	bison \
	bzip2 \
	ca-certificates \
	cmake \
	curl \
	file \
	flex \
	g++ \
	gawk \
	gdb \
	git \
	gperf \
	help2man \
	libncurses-dev \
	libssl-dev \
	libtool-bin \
	make \
	ninja-build \
	patch \
	pkg-config \
	python3 \
	sudo \
	texinfo \
	unzip \
	wget \
	xz-utils \
	libssl-dev \
	libffi-dev

# Install crosstool-ng
RUN curl -Lf https://github.com/crosstool-ng/crosstool-ng/archive/master.tar.gz | tar xzf - && \
    cd crosstool-ng-master && \
    ./bootstrap && \
    ./configure --prefix=/usr/local && \
    make -j4 && \
    make install && \
    cd .. && rm -rf crosstool-ng-master

COPY armv7l.config /tmp/toolchain.config

# Build cross compiler
RUN mkdir build && \
    cd build && \
    cp /tmp/toolchain.config .config && \
    export CT_ALLOW_BUILD_AS_ROOT_SURE=1 && \
    ct-ng build && \
    cd .. && \
    rm -rf build

ENV PATH=$PATH:/usr/armv7-unknown-linux-gnueabihf/bin

ENV CC_armv7_unknown_linux_gnueabihf=armv7-unknown-linux-gnueabihf-gcc \
    AR_armv7_unknown_linux_gnueabihf=armv7-unknown-linux-gnueabihf-ar \
    CXX_armv7_unknown_linux_gnueabihf=armv7-unknown-linux-gnueabihf-g++

ENV TARGET_CC=armv7-unknown-linux-gnueabihf-gcc \
    TARGET_AR=armv7-unknown-linux-gnueabihf-ar \
    TARGET_CXX=armv7-unknown-linux-gnueabihf-g++ \
    TARGET_SYSROOT=/usr/armv7-unknown-linux-gnueabihf/armv7-unknown-linux-gnueabihf/sysroot/ \
    TARGET_C_INCLUDE_PATH=/usr/armv7-unknown-linux-gnueabihf/armv7-unknown-linux-gnueabihf/sysroot/usr/include/

ENV CARGO_BUILD_TARGET=armv7-unknown-linux-gnueabihf
ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=armv7-unknown-linux-gnueabihf-gcc

# Target openssl & libffi
RUN export CC=$TARGET_CC && \
    echo "Building zlib" && \
    VERS=1.2.11 && \
    cd /tmp && \
    curl -sqLO https://zlib.net/zlib-$VERS.tar.gz && \
    tar xzf zlib-$VERS.tar.gz && cd zlib-$VERS && \
    ./configure --archs="-fPIC" --prefix=/usr/armv7-unknown-linux-gnueabihf/ || tail -n 500 configure.log && \
    make -j4 && make -j4 install && \
    cd .. && rm -rf zlib-$VERS.tar.gz zlib-$VERS && \
    echo "Building OpenSSL" && \
    VERS=1.1.1j && \
    curl -sqO https://www.openssl.org/source/openssl-$VERS.tar.gz && \
    tar xzf openssl-$VERS.tar.gz && cd openssl-$VERS && \
    ./Configure linux-generic32 -fPIC --prefix=/usr/armv7-unknown-linux-gnueabihf/ && \
    make -j4 && make -j4 install_sw install_ssldirs && \
    cd .. && rm -rf openssl-$VERS.tar.gz openssl-$VERS && \
    echo "Building libffi" && \
    VERS=3.3 && \
    curl -sqLO https://github.com/libffi/libffi/releases/download/v$VERS/libffi-$VERS.tar.gz && \
    tar xzf libffi-$VERS.tar.gz && cd libffi-$VERS && \
    ./configure --prefix=/usr/armv7-unknown-linux-gnueabihf/ --disable-docs --host=armv7-unknown-linux-gnueabihf --build=x86_64-linux-gnu && \
    make -j4 && make -j4 install && \
    cd .. && rm -rf libffi-$VERS.tar.gz libffi-$VERS


ENV OPENSSL_DIR=/usr/armv7-unknown-linux-gnueabihf \
    OPENSSL_INCLUDE_DIR=/usr/armv7-unknown-linux-gnueabihf/include \
    DEP_OPENSSL_INCLUDE=/usr/armv7-unknown-linux-gnueabihf/include \
    OPENSSL_LIB_DIR=/usr/armv7-unknown-linux-gnueabihf/lib

RUN apt-get install -y libz-dev libbz2-dev libexpat1-dev libncurses5-dev libreadline-dev liblzma-dev file

RUN mkdir -p /opt/python

RUN cd /tmp && \
    VERS=3.6.12 && PREFIX=/opt/python/cp36-cp36m && \
    curl -LO https://www.python.org/ftp/python/$VERS/Python-$VERS.tgz && \
    tar xzf Python-$VERS.tgz && cd Python-$VERS && \
    ./configure --with-ensurepip=install && make -j4 && make -j4 install && make clean && \
    python3.6 -m pip install --no-cache-dir wheel && \
    ./configure CC=$TARGET_CC AR=$TARGET_AR --host=armv7-unknown-linux-gnueabihf --target=armv7-unknown-linux-gnueabihf --prefix=$PREFIX --disable-shared --with-ensurepip=no --with-openssl=$OPENSSL_DIR --build=x86_64-linux-gnu --disable-ipv6 ac_cv_have_long_long_format=yes ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no && \
    make -j4 && make -j4 install && \
    rm -rf Python-$VERS.tgz Python-$VERS ${PREFIX}/share && \
    # we don't need libpython*.a, and they're many megabytes
    find ${PREFIX} -name '*.a' -print0 | xargs -0 rm -f && \
    # We do not need the Python test suites
    find ${PREFIX} -depth \( -type d -a -name test -o -name tests \) | xargs rm -rf && \
    # We do not need precompiled .pyc and .pyo files.
    find ${PREFIX} -type f -a \( -name '*.pyc' -o -name '*.pyo' \) -delete

RUN cd /tmp && \
    VERS=3.7.10 && PREFIX=/opt/python/cp37-cp37m && \
    curl -LO https://www.python.org/ftp/python/$VERS/Python-$VERS.tgz && \
    tar xzf Python-$VERS.tgz && cd Python-$VERS && \
    ./configure --with-ensurepip=install && make -j4 && make -j4 install && make clean && \
    python3.7 -m pip install --no-cache-dir wheel && \
    ./configure CC=$TARGET_CC AR=$TARGET_AR --host=armv7-unknown-linux-gnueabihf --target=armv7-unknown-linux-gnueabihf --prefix=$PREFIX --disable-shared --with-ensurepip=no --with-openssl=$OPENSSL_DIR --build=x86_64-linux-gnu --disable-ipv6 ac_cv_have_long_long_format=yes ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no && \
    make -j4 && make -j4 install && \
    rm -rf Python-$VERS.tgz Python-$VERS ${PREFIX}/share && \
    # we don't need libpython*.a, and they're many megabytes
    find ${PREFIX} -name '*.a' -print0 | xargs -0 rm -f && \
    # We do not need the Python test suites
    find ${PREFIX} -depth \( -type d -a -name test -o -name tests \) | xargs rm -rf && \
    # We do not need precompiled .pyc and .pyo files.
    find ${PREFIX} -type f -a \( -name '*.pyc' -o -name '*.pyo' \) -delete

RUN cd /tmp && \
    VERS=3.8.8 && PREFIX=/opt/python/cp38-cp38 && \
    curl -LO https://www.python.org/ftp/python/$VERS/Python-$VERS.tgz && \
    tar xzf Python-$VERS.tgz && cd Python-$VERS && \
    ./configure --with-ensurepip=install && make -j4 && make -j4 install && make clean && \
    python3.8 -m pip install --no-cache-dir wheel && \
    ./configure CC=$TARGET_CC AR=$TARGET_AR --host=armv7-unknown-linux-gnueabihf --target=armv7-unknown-linux-gnueabihf --prefix=$PREFIX --disable-shared --with-ensurepip=no --with-openssl=$OPENSSL_DIR --build=x86_64-linux-gnu --disable-ipv6 ac_cv_have_long_long_format=yes ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no && \
    make -j4 && make -j4 install && \
    rm -rf Python-$VERS.tgz Python-$VERS ${PREFIX}/share && \
    # we don't need libpython*.a, and they're many megabytes
    find ${PREFIX} -name '*.a' -print0 | xargs -0 rm -f && \
    # We do not need the Python test suites
    find ${PREFIX} -depth \( -type d -a -name test -o -name tests \) | xargs rm -rf && \
    # We do not need precompiled .pyc and .pyo files.
    find ${PREFIX} -type f -a \( -name '*.pyc' -o -name '*.pyo' \) -delete

RUN cd /tmp && \
    VERS=3.9.2 && PREFIX=/opt/python/cp39-cp39 && \
    curl -LO https://www.python.org/ftp/python/$VERS/Python-$VERS.tgz && \
    tar xzf Python-$VERS.tgz && cd Python-$VERS && \
    ./configure --with-ensurepip=install && make -j4 && make -j4 install && make clean && \
    python3.9 -m pip install --no-cache-dir wheel auditwheel && \
    ./configure CC=$TARGET_CC AR=$TARGET_AR --host=armv7-unknown-linux-gnueabihf --target=armv7-unknown-linux-gnueabihf --prefix=$PREFIX --disable-shared --with-ensurepip=no --with-openssl=$OPENSSL_DIR --build=x86_64-linux-gnu --disable-ipv6 ac_cv_have_long_long_format=yes ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no && \
    make -j4 && make -j4 install && \
    rm -rf Python-$VERS.tgz Python-$VERS ${PREFIX}/share && \
    # we don't need libpython*.a, and they're many megabytes
    find ${PREFIX} -name '*.a' -print0 | xargs -0 rm -f && \
    # We do not need the Python test suites
    find ${PREFIX} -depth \( -type d -a -name test -o -name tests \) | xargs rm -rf && \
    # We do not need precompiled .pyc and .pyo files.
    find ${PREFIX} -type f -a \( -name '*.pyc' -o -name '*.pyo' \) -delete

RUN curl -L https://github.com/PyO3/maturin/releases/download/v0.10.0-beta.5/maturin-x86_64-unknown-linux-musl.tar.gz | tar -C /usr/local/bin -xz
RUN curl -L https://github.com/messense/auditwheel-symbols/releases/download/v0.1.5/auditwheel-symbols-x86_64-unknown-linux-musl.tar.gz | tar -C /usr/local/bin -xz
