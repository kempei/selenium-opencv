FROM python:3.9.6-alpine3.13

ENV OPENCV_VERSION=4.5.3
ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

# update apk repo
RUN echo "http://dl-4.alpinelinux.org/alpine/v3.13/main" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/v3.13/community" >> /etc/apk/repositories

# install chromedriver
RUN apk add --update --no-cache \
        chromium chromium-chromedriver

RUN apk add --update --no-cache \
        --virtual=.build-dependencies \
        build-base \
        openblas-dev \
        unzip \
        wget \
        cmake \
        libjpeg  \
        libjpeg-turbo-dev \
        libpng-dev \
        tiff-dev \
        libwebp-dev \
        clang-dev \
        linux-headers && \
    pip install selenium numpy && \
    find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + && \
    mkdir -p /opt && cd /opt && \
    wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && \
    rm -rf ${OPENCV_VERSION}.zip && \
    mkdir -p /opt/opencv-${OPENCV_VERSION}/build && \
    cd /opt/opencv-${OPENCV_VERSION}/build && \
    cmake \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D WITH_FFMPEG=NO \
        -D WITH_IPP=NO \
        -D WITH_OPENEXR=NO \
        -D WITH_TBB=NO \
        -D BUILD_TESTS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_EXAMPLES=NO \
        -D BUILD_ANDROID_EXAMPLES=NO \
        -D INSTALL_PYTHON_EXAMPLES=NO \
        -D BUILD_DOCS=NO \
        -D BUILD_opencv_python2=NO \
        -D BUILD_opencv_python3=ON \
        -D PYTHON3_EXECUTABLE=/usr/local/bin/python \
        -D PYTHON3_INCLUDE_DIR=/usr/local/include/python3.9/ \
        -D PYTHON3_LIBRARY=/usr/local/lib/libpython3.so \
        -D PYTHON_LIBRARY=/usr/local/lib/libpython3.so \
        -D PYTHON3_PACKAGES_PATH=/usr/local/lib/python3.9/site-packages/ \
        -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.9/site-packages/numpy/core/include/ \
        .. && \
    make VERBOSE=1 && \
    make && \
    make install && \
    rm -rf /opt/opencv-${OPENCV_VERSION} && \
    rm -r /root/.cache && \
    find /usr/local/lib/python3.*/ -name 'tests' -exec rm -r '{}' + && \
    find /usr/local/lib/python3.*/site-packages/ -name '*.so' -print -exec sh -c 'file "{}" | grep -q "not stripped" && strip -s "{}"' \; && \
    apk del .build-dependencies && \
    apk add --update --no-cache openblas
