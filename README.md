# Terpcopter4.0

## Using the tracking and depth camera together
Here are some instructions for using the depth and tracking camera together.
- Follow the instructions mentioned [here](https://github.com/IntelRealSense/librealsense/blob/master/doc/distribution_linux.md) to install the dependencies required to build the librealsense sdk.
- Once the dependencies are installed, clone the librealsense repository 
```
git clone https://github.com/IntelRealSense/librealsense
```
- Then use the following commands to build the realsense examples:
```
cd librealsense/
mkdir build && cd build/
cmake ..
make
```
This step will take some time(~20mins). Once the build finishes connect the 2 cameras(t265 and d435i) and run 
```
cd examples/tracking-and-depth/
sudo chmod u+x H_t265_d400.cfg
``` 
This is to give permissions to the .cfg file which contains the transformation matrix between the t265 and d435. Now, run the code using:
```
./rs-tracking-and-depth
```
