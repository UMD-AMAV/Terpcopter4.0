All the folders present here are packages which can be used in catkin workspace.

In order to use these packeges follow the instructions:
```
#In the home directory
mkdir ~/catkin_ws/src && cd ~/catkin_ws/src
#Move these packages in the src directory
mv <Path to these packages> ~/catkin_ws/src/
#In the src directory
cd ~/catkin_ws/src/ && catkin_init_workspace
cd ~/catkin_ws
catkin_make -DCMAKE_BUILD_TYPE=<Debug/Release>
source devel/setup.bash
roslaunch realsense2_camera rs_t265.launch serial_no:=<Serial Number of Camera>
```

In order to get the serial number of Camera we can use the following command:
```
rs-enumerate-devices | grep Serial
```

After running the launch file, we will get the following topics:
```
/camera/accel/imu_info
/camera/accel/sample
/camera/fisheye1/camera_info
/camera/fisheye1/image_raw
/camera/fisheye1/image_raw/compressed
/camera/fisheye1/image_raw/compressed/parameter_descriptions
/camera/fisheye1/image_raw/compressed/parameter_updates
/camera/fisheye1/image_raw/compressedDepth
/camera/fisheye1/image_raw/compressedDepth/parameter_descriptions
/camera/fisheye1/image_raw/compressedDepth/parameter_updates
/camera/fisheye1/image_raw/theora
/camera/fisheye1/image_raw/theora/parameter_descriptions
/camera/fisheye1/image_raw/theora/parameter_updates
/camera/fisheye2/camera_info
/camera/fisheye2/image_raw
/camera/fisheye2/image_raw/compressed
/camera/fisheye2/image_raw/compressed/parameter_descriptions
/camera/fisheye2/image_raw/compressed/parameter_updates
/camera/fisheye2/image_raw/compressedDepth
/camera/fisheye2/image_raw/compressedDepth/parameter_descriptions
/camera/fisheye2/image_raw/compressedDepth/parameter_updates
/camera/fisheye2/image_raw/theora
/camera/fisheye2/image_raw/theora/parameter_descriptions
/camera/fisheye2/image_raw/theora/parameter_updates
/camera/gyro/imu_info
/camera/gyro/sample
/camera/odom/sample
/camera/realsense2_camera_manager/bond
/camera/tracking_module/parameter_descriptions
/camera/tracking_module/parameter_updates
/diagnostics
/rosout
/rosout_agg
/tf
/tf_static
```
