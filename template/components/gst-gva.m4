dnl BSD 3-Clause License
dnl
dnl Copyright (c) 2020, Intel Corporation
dnl All rights reserved.
dnl
dnl Redistribution and use in source and binary forms, with or without
dnl modification, are permitted provided that the following conditions are met:
dnl
dnl * Redistributions of source code must retain the above copyright notice, this
dnl   list of conditions and the following disclaimer.
dnl
dnl * Redistributions in binary form must reproduce the above copyright notice,
dnl   this list of conditions and the following disclaimer in the documentation
dnl   and/or other materials provided with the distribution.
dnl
dnl * Neither the name of the copyright holder nor the names of its
dnl   contributors may be used to endorse or promote products derived from
dnl   this software without specific prior written permission.
dnl
dnl THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
dnl AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
dnl IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
dnl DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
dnl FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
dnl DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
dnl SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
dnl CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
dnl OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
dnl OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
dnl
include(begin.m4)

DECLARE(`GVA_VER',v1.3)

DECLARE(`GVA_WITH_DRM',yes)
DECLARE(`GVA_WITH_X11',no)
DECLARE(`GVA_WITH_GLX',no)
DECLARE(`GVA_WITH_WAYLAND',no)
DECLARE(`GVA_WITH_EGL',no)

DECLARE(`GVA_ENABLE_PAHO_INST',OFF)
DECLARE(`GVA_ENABLE_RDKAFKA_INST',OFF)

include(dldt-ie.m4)
include(gst-plugins-base.m4)
ifdef(`ENABLE_INTEL_GFX_REPO',,`include(libva2.m4)')

ifelse(OS_NAME,ubuntu,`
define(`GVA_BUILD_DEPS',ifdef(`BUILD_CMAKE',,cmake) git ocl-icd-opencl-dev opencl-headers pkg-config ifdef(`ENABLE_INTEL_GFX_REPO',libva-dev))
define(`GVA_INSTALL_DEPS',ocl-icd-libopencl1 ifdef(`ENABLE_INTEL_GFX_REPO',libva2 ifelse(GVA_WITH_DRM,yes,libva-drm2)))
')

ifelse(OS_NAME,centos,`
define(`GVA_BUILD_DEPS',ifdef(`BUILD_CMAKE',,cmake3) git ocl-icd-devel opencl-headers pkg-config ifdef(`ENABLE_INTEL_GFX_REPO',libva-devel))
define(`GVA_INSTALL_DEPS',ocl-icd ifdef(`ENABLE_INTEL_GFX_REPO',libva2 ifelse(GVA_WITH_DRM,yes,libva-drm2)))
')

define(`BUILD_GVA',
# formerly https://github.com/opencv/gst-video-analytics
ARG GVA_REPO=https://github.com/openvinotoolkit/dlstreamer_gst.git
# TODO: This is a workaround for a bug in dlstreamer_gst
ENV LIBRARY_PATH=BUILD_LIBDIR
RUN git clone -b GVA_VER --depth 1 $GVA_REPO BUILD_HOME/gst-video-analytics && \
    cd BUILD_HOME/gst-video-analytics && \
    git submodule update --init && \
    sed -i ``"195s/) {/||g_strrstr(name, \"image\")) {/"'' gst/elements/gvapython/python_callback.cpp && \
    mkdir -p build && cd build && \
    CFLAGS="-std=gnu99 -Wno-missing-field-initializers" \
    CXXFLAGS="-std=c++11 -Wno-missing-field-initializers" \
    ifdef(`BUILD_CMAKE',cmake,ifelse(OS_NAME,centos,cmake3,cmake)) \
        -DVERSION_PATCH="$(git rev-list --count --first-parent HEAD)" \
        -DGIT_INFO=git_"$(git rev-parse --short HEAD)" \
        -DCMAKE_INSTALL_PREFIX=BUILD_PREFIX \
        -DCMAKE_BUILD_TYPE=Release \
        -DDISABLE_SAMPLES=ON \
        -DENABLE_PAHO_INSTALLATION=GVA_ENABLE_PAHO_INST \
        -DENABLE_RDKAFKA_INSTALLATION=GVA_ENABLE_RDKAFKA_INST \
        -DENABLE_VAAPI=ON \
        -DENABLE_VAS_TRACKER=OFF \
        -Dwith_drm=GVA_WITH_DRM \
        -Dwith_x11=GVA_WITH_X11 \
        -Dwith_glx=GVA_WITH_GLX \
        -Dwith_wayland=GVA_WITH_WAYLAND \
        -Dwith_egl=GVA_WITH_EGL \
        -DMQTT=ifelse(GVA_ENABLE_PAHO_INST,ON,1,0) \
        -DKAFKA=ifelse(GVA_ENABLE_RDKAFKA_INST,ON,1,0) \
        .. \
    && make -j $(nproc) \
    && make install \
    && make install DESTDIR=BUILD_DESTDIR
)

REG(GVA)

include(end.m4)