################################################################################
# SPDX-FileCopyrightText: Copyright (c) 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################
USE_CPU?=0
CUDA_VER?=
ifeq ($(CUDA_VER),)
  $(error "CUDA_VER is not set")
endif

DS_VER?=
ifeq ($(DS_VER),)
  $(error "DS_VER is not set")
endif

APP:= deepstream_test_opencv_plugin

TARGET_DEVICE = $(shell gcc -dumpmachine | cut -f1 -d -)

NVDS_VERSION:=$DS_VER

LIB_INSTALL_DIR?=/opt/nvidia/deepstream/deepstream-$(DS_VER)/lib/
APP_INSTALL_DIR?=/opt/nvidia/deepstream/deepstream-$(DS_VER)/bin/

ifeq ($(TARGET_DEVICE),aarch64)
  CFLAGS:= -DPLATFORM_TEGRA
endif

ifeq ($(USE_CPU),1)
  SRCS:= deepstream_test_opencv_plugin_cpu.c
else
  SRCS:= deepstream_test_opencv_plugin_cuda.c
endif


INCS:= $(wildcard *.h)

PKGS:= gstreamer-1.0 opencv

OBJS:= $(SRCS:.c=.o)
CC := g++

CFLAGS+= -I../../../includes \
		 -I /usr/local/cuda-$(CUDA_VER)/include

CFLAGS+= $(shell pkg-config --cflags $(PKGS))

LIBS:= $(shell pkg-config --libs $(PKGS))

LIBS+= -L$(LIB_INSTALL_DIR) -lnvdsgst_meta -lnvds_meta -lgstapp-1.0 \
	   -L/usr/local/cuda-$(CUDA_VER)/lib64/ -lcudart \
	   -lnvbufsurface -lnvbufsurftransform -ldl -lpthread \
     -lcuda -Wl,-rpath,$(LIB_INSTALL_DIR)

all: $(APP)

%.o: %.c $(INCS) Makefile
	$(CC) -c -o $@ $(CFLAGS) $<

$(APP): $(OBJS) Makefile
	$(CC) -o $(APP) $(OBJS) $(LIBS)

install: $(APP)
	cp -rv $(APP) $(APP_INSTALL_DIR)

clean:
	rm -rf $(OBJS) $(APP)


