#!/bin/bash
###
 # @Author: Gobinath
 # @Date: 2024-07-26 13:00:00
 # @Description: 
 # @LastEditors: Gobinath
 # @LastEditTime: 2024-07-26 13:00:00
### 
set -eE 
red='\033[0;31m'
clear='\033[0m'
# Color variables
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
# Clear the color after that
clear='\033[0m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
#trap 'if [[ $? -eq 139 ]]; then echo "segfault !"; fi' CHLD

log() {
    local message="$1"
    local clr="$2"
    current_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "$clr${BOLD}[${current_time}] $message ${clear}"
}

check_symbolic_link() {
        local l1="$1"
        local l2="$2"
	if [ -L ${l2} ] ; then
	   if [ -e ${l2} ] ; then
	      log "[INFO] symbolic link $l2 already exist" $yellow
	   else
	      ln -s $l1 $l2
	      log "[INFO] symbolic link $l2 created" $green
	   fi
	elif [ -e ${l2} ] ; then
	   ln -s $l1 $l2
	else
	   echo ln -s $l1 $l2
	   log "[INFO] symbolic link $l2 created" $green
	fi

}

test_plugin() {
	log "[INFO]Testing Opencv Plugin " $green
	cd /opt/nvidia/deepstream/deepstream-$DS_VER/sources/apps/sample_apps/deepstream_opencv_plugin_test
	make
	./deepstream_test_opencv_plugin /opt/nvidia/deepstream/deepstream/samples/streams/sample_720p.mp4 1280 720 30 RGBA

}


CUR_DIR=$PWD
DS_VER=6.3
NTHREAD=4
dir=$PWD
cuda_version=$(nvcc --version | grep -oP 'V\K\d+\.\d+')
log "[INFO]CUDA Version: $cuda_version" $green


export CUDA_VER=$cuda_version
export DS_VER=$DS_VER
export SM_COMPUTE=8.9

apt-get install -y build-essential cmake pkg-config unzip yasm git checkinstall
apt-get install -y cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev 
apt-get install  -y python3-dev python3-numpy python3-pip
apt install -y python3-testresources
apt-get install -y libjpeg-dev libpng-dev libtiff-dev
apt install -y libavcodec-dev libavformat-dev libswscale-dev libavresample-dev
apt install  -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
apt install -y libxvidcore-dev x264 libx264-dev libfaac-dev libmp3lame-dev libtheora-dev 
apt install -y libfaac-dev libmp3lame-dev libvorbis-dev	
apt install  -y libopencore-amrnb-dev libopencore-amrwb-dev
apt-get install  -y libdc1394-22 libdc1394-22-dev libxine2-dev libv4l-dev v4l-utils zip
cd /usr/include/linux
ln -s -f ../libv4l1-videodev.h videodev.h

check_symbolic_link "/usr/lib/x86_64-linux-gnu/libnvcuvid.so.1" "/usr/lib/x86_64-linux-gnu/libnvcuvid.so"
check_symbolic_link "/usr/lib/x86_64-linux-gnu/libnvidia-encode.so.1" "/usr/lib/x86_64-linux-gnu/libnvidia-encode.so"
ldconfig
cd $dir
if [ ! -d "$CUR_DIR/opencv" ]; then
    log "[INFO]pulling opencv from github" $green
    wget  -O opencv.zip https://github.com/opencv/opencv/archive/4.8.0.zip
    wget  -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.8.0.zip
    unzip opencv.zip
    unzip opencv_contrib.zip
    mv opencv-4.8.0 opencv  # rename
    mv opencv_contrib-4.8.0 opencv_contrib
fi
if [ -d "$CUR_DIR/build" ]; then
    log "[INFO]buid directory already exists" $yellow
else
    mkdir build  
fi

cp Video_Codec_SDK_11.1.5/Interface/*   /usr/local/cuda/include
cd build   
cmake -D CMAKE_BUILD_TYPE=Release \
-D CMAKE_INSTALL_PREFIX=/usr/local \
-D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules/ \
-D PYTHON3_EXECUTABLE=/usr/bin/python3 \
-D PYTHON3_INCLUDE_DIR=/usr/include/python3.8/ \
-D PYTHON3_INCLUDE_DIR2=/usr/include/x86_64-linux-gnu/python3.8/ \
-D PYTHON3_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.8.so \
-D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/lib/python3/dist-packages/numpy/core/include/ \
-D OPENCV_GENERATE_PKGCONFIG=ON \
-D OPENCV_PC_FILE_NAME=opencv.pc \
-D WITH_FFMPEG=ON \
-D WITH_CUDA=ON \
-D WITH_CUDNN=ON \
-D WITH_OPENGL=ON \
-D WITH_NVCUVID=ON \
-D WITH_GSTREAMER=OFF \
-D OPENCV_GENERATE_PKGCONFIG=ON \
-D OPENCV_DNN_CUDA=ON \
-D CUDA_ARCH_BIN=$SM_COMPUTE \
-D CUDA_ARCH_PTX=$SM_COMPUTE  \
-D ENABLE_FAST_MATH=ON \
-D CUDA_FAST_MATH=ON \
-D WITH_CUFFT=ON \
-D WITH_CUBLAS=ON \
-D WITH_V4L=ON \
-D WITH_OPENCL=ON \
-D WITH_OPENGL=ON \
-D WITH_GSTREAMER=OFF \
-D BUILD_opencv_cudacodec=ON \
-D WITH_TBB=ON \
 ../opencv
make -j $NTHREAD
make install 
/bin/bash -c 'echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf'
ldconfig
echo "PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.8/site-packages" >> /etc/profile 
echo "export PYTHONPATH" >> /etc/profile 

export USE_CPU=0
if [ "$USE_CPU" == 1 ]; then
    log "[WARN] Cuda Acclerated Decoding disbaled in Opencv Plugin " $red
else
    cd $CUR_DIR/opencv_test
    g++ test.cpp `pkg-config opencv --cflags --libs` -o test
    ./test /opt/nvidia/deepstream/deepstream-$DS_VER/samples/streams/sample_720p.mp4
fi
cd  $CUR_DIR
if [ ! -d "/opt/nvidia/deepstream/deepstream-$DS_VER/sources/gst-plugins/deepstream_opencv_plugin" ]; then
    rm -rf /opt/nvidia/deepstream/deepstream-$DS_VER/sources/gst-plugins/deepstream_opencv_plugin
fi
if [ ! -d "/opt/nvidia/deepstream/deepstream-$DS_VER/sources/apps/sample_apps/deepstream_opencv_plugin_test" ]; then
    rm -rf /opt/nvidia/deepstream/deepstream-$DS_VER/sources/apps/sample_apps/deepstream_opencv_plugin_test
fi
cp -r  $CUR_DIR/deepstream_opencv_plugin /opt/nvidia/deepstream/deepstream-$DS_VER/sources/gst-plugins
cp -r  $CUR_DIR/deepstream_opencv_plugin_test /opt/nvidia/deepstream/deepstream-$DS_VER/sources/apps/sample_apps
log "[INFO]Buiding Opencv Plugin " $green
cd /opt/nvidia/deepstream/deepstream-$DS_VER/sources/gst-plugins/deepstream_opencv_plugin
make
make install
set +eE 
test_plugin  

log "[INFO]Build Sucesss " $green

   
