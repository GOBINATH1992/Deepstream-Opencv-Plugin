<!--
 * @Author: Gobinath
 * @Date: 2024-07-26 13:00:00
 * @Description: Deepstream Opencv plugin
 * @LastEditors:  Gobinath
 * @LastEditTime: 2024-07-26 13:00:00
-->
# Deepstream Openv Plugin
This a custom Deepstream plugin which uses Opencv with CUDA accleration to  read video stream and fed them into deepstream pipeline.
## Requirements
+ Deepstream 6.0+
+ Opencv 4.8

## Notice
1. Currently this plugin is only supported on X86. 
2. Only support CUDA UNIFIED Memory  so set memtype field in plugin to 3 
3. Only output RGBA buffers others format are not supported
   
## Feature
1. Build and Install Opencv with CUDA Accelerated Video Decoding 
2. Build Custom Deepstream Plugin which uses Opencv to read stream and fed data into deepstream pipeline directly 

## Usage

1. Change file permission
```
chmod a+x install.sh
```
2. set Deepstream version,  in install.sh
```
DS_VER=6.0
```
3. set appropriate SM_COMPUTE value in install.sh . Refer https://developer.nvidia.com/cuda-gpus
```
SM_COMPUTE=8.6
```
4. To disable cuda acclerated decoding in plugin set USE_CPU to false. By default this is enabled
```
USE_CPU=0
```
5. Run
```
./install.sh
```
NOTE: To compile the sources, run make with "sudo" or root permission.

6. Post installation run 
```
nano ~/.bashrc
Add follwing lines at end 'PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.8/site-packages'
export PYTHONPATH
```


## TODO
+ Support for other Cuda memory type, video format
