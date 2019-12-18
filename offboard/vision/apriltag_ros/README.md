## Apriltag detection ros package

## Build Instructions for apriltag ros package
```
mkdir -p ~/catkin_ws_apriltag/src
cd ~/catkin_ws_apriltag/
catkin_make
source devel/setup.bash
cd src/
copy apriltag_ros package here
cd ..
catkin_make
```

Apriltag ros package requires rectified camera images and camera parameters. To publish images for depth camera, install the realsense-ros package as shown below:

## Build Instructions for Intel RealSense ROS wrapper

- Create a [catkin](http://wiki.ros.org/catkin#Installing_catkin) workspace
```bash
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src/
```
- Clone the latest Intel&reg; RealSense&trade; ROS from [here](https://github.com/intel-ros/realsense/releases) into 'catkin_ws/src/'
```bashrc
git clone https://github.com/IntelRealSense/realsense-ros.git
cd realsense-ros/
git checkout `git tag | sort -V | grep -P "^\d+\.\d+\.\d+" | tail -1`
cd ..
```
- Make sure all dependent packages are installed. You can check .travis.yml file for reference.
- Specifically, make sure that the ros package *ddynamic_reconfigure* is installed. If *ddynamic_reconfigure* cannot be installed using APT, you may clone it into your workspace 'catkin_ws/src/' from [here](https://github.com/pal-robotics/ddynamic_reconfigure/tree/kinetic-devel) (Version 0.2.0)

```bash
catkin_init_workspace
cd ..
catkin_make clean
catkin_make -DCATKIN_ENABLE_TESTING=False -DCMAKE_BUILD_TYPE=Release
catkin_make install
echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

## Publish image data

Run following command to publish rectified camera images and camera parameters
```
roslaunch realsense2_camera rs_aligned_depth.launch

```

## Launch apriltag detection 
```
cd <path to catkin_ws_apriltag>
source devel/setup.bash
roslaunch apriltag_ros continuous_detection.launch
```
This publishes data on folllowing topics:
 - /tf: relative pose between the camera frame and each detected tag's or tag bundle's frame
 - /tag_detections: the same information as provided by the /tf topic but as a custom message carrying the tag ID(s), size(s) and geometry_msgs/PoseWithCovarianceStamped pose information
 - /tag_detections_image: the same image as input by /camera/image_rect but with the detected tags highlighted.
 

