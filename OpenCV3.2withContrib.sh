######################################
# INSTALL OPENCV ON UBUNTU OR DEBIAN #
######################################

# Use below command to install OpenCV 3.2 with Contrib at Ubuntu or Debian on your own operating system.
# wget -O - https://gist.githubusercontent.com/syneart/3e6bb68de8b6390d2eb18bff67767dcb/raw/OpenCV3.2withContrib.sh | bash

# |            THIS SCRIPT IS TESTED CORRECTLY ON             |
# |-----------------------------------------------------------|
# | OS             | OpenCV       | CUDA | Test | Last test   |
# |----------------|--------------|------|------|-------------|
# | Ubuntu 22.04.4 | OpenCV 3.2.0 |  OK  |  OK  | 02 Mar 2024 |
# | Ubuntu 22.04.1 | OpenCV 3.2.0 |  OK  |  OK  | 17 Aug 2022 |
# | Ubuntu 20.04.4 | OpenCV 3.2.0 |   ?  |  OK  | 17 Aug 2022 |
# | Ubuntu 18.04.6 | OpenCV 3.2.0 |   ?  |  OK  | 17 Aug 2022 |
# | Ubuntu 16.04.2 | OpenCV 3.2.0 |   ?  |  OK  | 20 May 2017 |
# | Debian 8.8     | OpenCV 3.2.0 |   -  |  OK  | 20 May 2017 |
# | Debian 9.0     | OpenCV 3.2.0 |   -  |  OK  | 25 Jun 2017 |

# 1. KEEP UBUNTU OR DEBIAN UP TO DATE

sudo apt-get -y update
#sudo apt-get -y upgrade
sudo apt-get -y autoremove

export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/$(curl http://ip-api.com/line?fields=timezone) /etc/localtime
sudo apt-get install -y tzdata


# 2. INSTALL THE DEPENDENCIES

# Build tools:
sudo apt-get install -y build-essential cmake

# GUI (if you want to use GTK instead of Qt, replace 'qt5-default' with 'libgtkglext1-dev' and remove '-DWITH_QT=ON' option in CMake):
sudo apt-get install -y libgtkglext1-dev libvtk6-dev

# Media I/O:
sudo apt-get install -y zlib1g-dev libjpeg-dev libwebp-dev libpng-dev libtiff5-dev libjasper-dev libopenexr-dev libgdal-dev libgphoto2-dev

# Video I/O:
sudo apt-get install -y libdc1394-22-dev libavcodec-dev libavformat-dev libswscale-dev libtheora-dev libvorbis-dev libxvidcore-dev libx264-dev yasm libopencore-amrnb-dev libopencore-amrwb-dev libv4l-dev libxine2-dev v4l-utils

# Parallelism and linear algebra libraries:
sudo apt-get install -y libtbb-dev libeigen3-dev

# Python:
sudo apt-get install -y python-dev python-tk python-numpy python3-dev python3-tk python3-numpy

# Java:
# sudo apt-get install -y ant default-jdk

# Documentation:
# sudo apt-get install -y doxygen


# 3. INSTALL THE LIBRARY (YOU CAN CHANGE '3.2.0' FOR THE LAST STABLE VERSION)

sudo apt-get install -y unzip wget
wget https://github.com/opencv/opencv/archive/3.2.0.zip -O opencv320.zip
unzip opencv320.zip
rm opencv320.zip
mv opencv-3.2.0 OpenCV
cd OpenCV
touch OpenCV3.2withContrib

# 4. INSTALL THE OPENCV_CONTRIB LIBRARY (YOU CAN CHANGE '3.2.0' FOR THE LAST STABLE VERSION)

wget https://github.com/opencv/opencv_contrib/archive/3.2.0.zip -O opencv_contrib320.zip
unzip opencv_contrib320.zip
rm opencv_contrib320.zip
mv opencv_contrib-3.2.0 OpenCV_contrib

# 5. Build OpenCV with contrib

## Fix Flow control statements are not properly nested issue
sed -i '21,22 s/^/#/' cmake/OpenCVCompilerOptions.cmake
## Fix ffmpeg version issue
sed -i '1 i #define AV_CODEC_FLAG_GLOBAL_HEADER (1 << 22)\n#define CODEC_FLAG_GLOBAL_HEADER AV_CODEC_FLAG_GLOBAL_HEADER\n#define AVFMT_RAWPICTURE 0x0020' modules/videoio/src/cap_ffmpeg_impl.hpp
## Fix build.make:56 Error
sed -i 's/PyString_AsString(obj);/(char*)PyString_AsString(obj);/' modules/python/src2/cv2.cpp
## Requires version 10 or lower
if [[ `gcc -dumpversion` -ge 11 ]]; then
    sudo apt-get install -y gcc-10 g++-10 libtbb2-dev
    CC="gcc-10"
    CXX="g++-10"
fi
## If the system supports CUDA, and version LESS then 12 (REQUIRE)
(nvcc --version) >/dev/null 2>&1 && {
    if [[ $(echo "`nvcc --version | sed -n 's/^.*release \([0-9]\+\.[0-9]\+\).*$/\1/p'` < 12" | bc) -eq 1 ]]; then
        CUDA_LIBRARY="-DCUDA_nppicom_LIBRARY=stdc++"
        wget -O - https://gist.githubusercontent.com/syneart/3e6bb68de8b6390d2eb18bff67767dcb/raw/WITH_CUDA.patch | patch -p1
    else
	DO_CUDA_OFF="-DWITH_CUDA=OFF"
	echo "[SCRIPT] CUDA OFF # CUDA Version REQUIRE LESS then 12 # OpenCV not Support !!"
    fi
} || {
    echo "[SCRIPT] CUDA NOT FOUND !!"
}

mkdir build
cd build
CC=${CC} CXX=${CXX} cmake -DOPENCV_EXTRA_MODULES_PATH=../OpenCV_contrib/modules -DWITH_QT=OFF -DWITH_OPENGL=ON -DFORCE_VTK=ON -DWITH_TBB=ON -DINSTALL_C_EXAMPLES=OFF -DWITH_GDAL=ON -DWITH_XINE=ON -DBUILD_EXAMPLES=OFF -DENABLE_PRECOMPILED_HEADERS=OFF ${CUDA_LIBRARY} ${DO_CUDA_OFF} ..
CC=${CC} CXX=${CXX} make -j`nproc`
sudo make install
sudo ldconfig