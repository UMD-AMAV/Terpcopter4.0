# Run Instruction:

Only run camSub.py via rosrun
Type the following in the command prompt

```
rosrun camera_package cameraSub.py
```

If cameraSub.py is not detected then we have to make it as an executable, for that write the following command

```
cd <Directory with the camSub.py file>
chmod +x camSub.py
```

## List of Publishers

In ObstacleAvoidance:
```
targetObst ---> Flag to detect  pink obstacle, return Bool when detected
```

In DropOffDetection:
```
targetPixelX ---> Float32 to detect dropoff center x  error value
targetPixelY ---> Float32 to detect dropoff center y error value
targetDetected ---> Bool to detect dropoff detected or not
```

In HBaseDetector:
```
hPixelX ---> Float32 to detect homebase center x  error value
hPixelY ---> Float32 to detect home base center y error value
hAngle ---> Float32 to detect the home base orientation
hDetected --> Bool to detect dropoff or not
```
