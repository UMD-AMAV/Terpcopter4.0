%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Node: estimation
%
% Purpose:
% The purpose of the estimation node is to compute an estimate of the
% quadcopters state from noisy sensor data. This may include fusing data
% from different sources (e.g., barometer and lidar for altittude),
% filtering noisy signals (e.g., low-pass filters), implementing
% state estimators (e.g., kalman filters) and navigation algorithms.
%
% Input:
%   - ROS topics: several sensor data topics
%           /mavros/imu/data
%           /terarangerone
%
%   - ROS topic: /features (generated by vision)
%
% Output:
%   - ROS topic: /stateEstimate (used by control, autonomy, vision, planning)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% prepare workspace
clear all; close all; clc; format compact;
run('loadParams.m');
addpath('../');

%run('updatePaths.m');
fprintf('Navigation Node Launching...\n');

% intialize ros node
if(~robotics.ros.internal.Global.isNodeActive)
    rosinit;
end

useLidarFlag = 0;

% Subscribers
imuDataSubscriber = rossubscriber('/mavros/imu/data');
if useLidarFlag
    lidarDataSubscriber = rossubscriber('/mavros/distance_sensor/hrlv_ez4_pub');
end
VIODataSubscriber = rossubscriber('/camera/odom/sample', 'nav_msgs/Odometry');
localPositionOdomSubscriber = rossubscriber('/mavros/local_position/odom', 'nav_msgs/Odometry');

% Publishers
stateEstimatePublisher = rospublisher('/stateEstimate', 'terpcopter_msgs/stateEstimate');

stateMsg = rosmessage(stateEstimatePublisher);
%stateMsg.Range = 0.2;

pause(2)
t0 = [];
t0_log = [];
t0_memory = [];

r = robotics.Rate(100);
reset(r);

% smoothing filter
a = 0;
b = 0;
c = 0;
d = 0;
e = 0;
f = 0;
g = 0;
h = 0;
i = 0;
j = 0;

% Receive Latest Imu and Lidar data
imuMsg = imuDataSubscriber.LatestMessage;
if useLidarFlag
    lidarMsg = lidarDataSubscriber.LatestMessage;
end
VIOMsg = VIODataSubscriber.LatestMessage;
localPositionOdomMsg = localPositionOdomSubscriber.LatestMessage;

%% Pixhawk IMU
w = imuMsg.Orientation.W;
x = imuMsg.Orientation.X;
y = imuMsg.Orientation.Y;
z = imuMsg.Orientation.Z;

euler = quat2eul([w x y z]);
%yaw measured clock wise is negative.
disp('psi:')
state.psi_inertial = rad2deg(euler(1))
state.theta = rad2deg(euler(2));
state.phi = rad2deg(euler(3));


%get relative yaw = - inertial yaw_intial - inertial yaw
inertial_yaw_initial = state.psi_inertial;

%% VIO Odometry
% VIO Time
VIOTime = VIOMsg.Header.Stamp.Sec;
% VIO Pose
% Position
VIOPositionX = VIOMsg.Pose.Pose.Position.X;
VIOPositionY = VIOMsg.Pose.Pose.Position.Y;
VIOPositionZ = VIOMsg.Pose.Pose.Position.Z;

% Orientation
VIOOrientationX = VIOMsg.Pose.Pose.Orientation.X;
VIOOrientationY = VIOMsg.Pose.Pose.Orientation.Y;
VIOOrientationZ = VIOMsg.Pose.Pose.Orientation.Z;
VIOOrientationW = VIOMsg.Pose.Pose.Orientation.W;

VIOeuler = quat2eul([VIOOrientationW VIOOrientationX VIOOrientationY VIOOrientationZ]);

VIOpsi = rad2deg(VIOeuler(1));
VIOtheta = rad2deg(VIOeuler(2));
VIOphi = rad2deg(VIOeuler(3));

%% Local Position Odometry
% Local Position Time
localPositionTime = localPositionOdomMsg.Header.Stamp.Sec;
% Local Position Pose
% Position
localPositionX = localPositionOdomMsg.Pose.Pose.Position.X;
localPositionY = localPositionOdomMsg.Pose.Pose.Position.Y;
localPositionZ = localPositionOdomMsg.Pose.Pose.Position.Z;

% Orientation
localOrientationX = localPositionOdomMsg.Pose.Pose.Orientation.X;
localOrientationY = localPositionOdomMsg.Pose.Pose.Orientation.Y;
localOrientationZ = localPositionOdomMsg.Pose.Pose.Orientation.Z;
localOrientationW = localPositionOdomMsg.Pose.Pose.Orientation.W;

localPositionEuler = quat2eul([localOrientationW localOrientationX localOrientationY localOrientationZ]);

localPositionPsi = rad2deg(localPositionEuler(1));
localPositionTheta = rad2deg(localPositionEuler(2));
localPositionPhi = rad2deg(localPositionEuler(3));

logFlag = 1;
dateString = datestr(now,'mmmm_dd_yyyy_HH_MM_SS_FFF');
VIOLog = ['/home/amav/amav/Terpcopter3.0/matlab/estimation/EstimationLogs' '/VIO_' dateString '.log'];
localPositionLog = ['/home/amav/amav/Terpcopter3.0/matlab/estimation/EstimationLogs' '/localPosition_' dateString '.log'];
if useLidarFlag
    lidarLog = ['/home/amav/amav/Terpcopter3.0/matlab/estimation/EstimationLogs' '/lidar_' dateString '.log'];
end
stateEstimateLog = ['/home/amav/amav/Terpcopter3.0/matlab/estimation/EstimationLogs' '/stateEstimate_' dateString '.log'];
WaypointLog = ['~/Terpcopter4.0/Logs/Waypoint_logs' '/WaypointLog_' dateString '.log'];
tic

%MOVE TO PARAMS
%Initialization for Waypoint Flight Log
k = 1;
t_lastWaypoint = zeros(500,1);
lastWaypointX = zeros(500,1);
lastWaypointY = zeros(500,1);
lastWaypointZ = zeros(500,1);
t = 0;
LogWaypoints = 1; % 1=on 0=off | Turns logging on or off
Discretation_log = 1; %Set to either Time=1 or Distance=0
TimeInterval = 1; %Time span between waypoint logging in seconds.
DistanceInterval = 0.5; %Distance between waypoint logging in methers.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

debugLevel = 1;

while(1)
    tic
    % Receive Latest Imu and Lidar data
    imuMsg = imuDataSubscriber.LatestMessage;
    if useLidarFlag
        lidarMsg = lidarDataSubscriber.LatestMessage;
    end
    VIOMsg = VIODataSubscriber.LatestMessage;
    localPositionOdomMsg = localPositionOdomSubscriber.LatestMessage;
    
    
    %% Pixhawk IMU
    if isempty(imuMsg)
        state = NaN;
        disp('No imu data\n');
        return;
    end
    w = imuMsg.Orientation.W;
    x = imuMsg.Orientation.X;
    y = imuMsg.Orientation.Y;
    z = imuMsg.Orientation.Z;
    
    euler = quat2eul([w x y z]);
    %yaw measured clock wise is negative.
    state.psi_inertial = mod(90-rad2deg(euler(1)),360);
    state.theta = -rad2deg(euler(2));
    state.phi = rad2deg(euler(3));
    
    %state.psi_inertial = round(state.psi_inertial,1);
    
    %get relative yaw = - inertial yaw_intial - inertial yaw
    if isempty(inertial_yaw_initial), inertial_yaw_initial = state.psi_inertial; end
    state.psi_relative = -state.psi_inertial + inertial_yaw_initial;
    
    %rounding off angles to 1 decimal place
    %state.psi_inertial = round(state.psi_inertial,1);
    state.psi_relative = round(state.psi_relative,1);
    state.theta = round(state.theta,1);
    state.phi = round(state.phi,1);
    
    %yaw lies between [-180 +180];
    if state.psi_relative> 180, state.psi_relative = state.psi_relative-360;
    elseif state.psi_relative<-180, state.psi_relative = 360+state.psi_relative;end
    
    if useLidarFlag
        
        % condition lidar reading
        if isempty(lidarMsg) || lidarMsg.Range_ <= 0.2
            disp('no lidar data');
            %get min range from lidar msg
            stateMsg.Range = 0.2;
        else
            % moving average filter
            i = j;
            h = i;
            g = h;
            f = g;
            e = f;
            d = e;
            c = d;
            b = c;
            a = b;
            j = lidarMsg.Range_;
            smoothed_range = (a+b+c+d+e+f+g+h+i+j)/10;
            
            stateMsg.Range = smoothed_range;
        end
    else
        stateMsg.Range = VIOPositionZ;
    end
    %lidar data is in imu frame; convert to inertial frame
    % phi and theta are in deg. so use cosd to calculate the compensated range
    stateMsg.Range = cosd(state.phi)*cosd(state.theta)*stateMsg.Range;
    stateMsg.Range = round(stateMsg.Range,2);
    %change Up to the estimated output from the filter instead of from the
    %range
    %     stateMsg.Up = stateMsg.Range;  %%%%%Changing to VIO Alt to Test CSV
    %disp(stateMsg.Up);
    %stateMsg.Yaw = state.psi_inertial;
    stateMsg.Yaw = state.psi_relative;
    stateMsg.Roll = state.phi;
    stateMsg.Pitch = state.theta;
    
    %% VIO Odometry
    % VIO Time
    VIOTime = VIOMsg.Header.Stamp.Nsec;
    % VIO Pose
    % Position
    VIOPositionX = VIOMsg.Pose.Pose.Position.X;
    VIOPositionY = VIOMsg.Pose.Pose.Position.Y;
    VIOPositionZ = VIOMsg.Pose.Pose.Position.Z;
    
    % Orientation
    VIOOrientationX = VIOMsg.Pose.Pose.Orientation.X;
    VIOOrientationY = VIOMsg.Pose.Pose.Orientation.Y;
    VIOOrientationZ = VIOMsg.Pose.Pose.Orientation.Z;
    VIOOrientationW = VIOMsg.Pose.Pose.Orientation.W;
    
    VIOeuler = quat2eul([VIOOrientationW VIOOrientationX VIOOrientationY VIOOrientationZ]);
    
    VIOpsi = rad2deg(VIOeuler(1));
    VIOtheta = rad2deg(VIOeuler(2));
    VIOphi = rad2deg(VIOeuler(3));
    
    % VIO Twist
    VIOTwistLinearVelocityX = VIOMsg.Twist.Twist.Linear.X;
    VIOTwistLinearVelocityY = VIOMsg.Twist.Twist.Linear.Y;
    VIOTwistLinearVelocityZ = VIOMsg.Twist.Twist.Linear.Z;
    
    VIOTwistAngularVelocityX = VIOMsg.Twist.Twist.Angular.X;
    VIOTwistAngularVelocityY = VIOMsg.Twist.Twist.Angular.Y;
    VIOTwistAngularVelocityZ = VIOMsg.Twist.Twist.Angular.Z;
    
    %% Local Position Odometry
    % Local Position Time
    localPositionTime = localPositionOdomMsg.Header.Stamp.Sec;
    % Local Position Pose
    % Position
    localPositionX = localPositionOdomMsg.Pose.Pose.Position.X;
    localPositionY = localPositionOdomMsg.Pose.Pose.Position.Y;
    localPositionZ = localPositionOdomMsg.Pose.Pose.Position.Z;
    stateMsg.East = localPositionX;
    stateMsg.North = localPositionY;
    stateMsg.Up = localPositionZ;
    
    % Orientation
    localOrientationX = localPositionOdomMsg.Pose.Pose.Orientation.X;
    localOrientationY = localPositionOdomMsg.Pose.Pose.Orientation.Y;
    localOrientationZ = localPositionOdomMsg.Pose.Pose.Orientation.Z;
    localOrientationW = localPositionOdomMsg.Pose.Pose.Orientation.W;
    
    localPositionEuler = quat2eul([localOrientationW localOrientationX localOrientationY localOrientationZ]);
    
    localPositionPsi = rad2deg(localPositionEuler(1));
    localPositionTheta = rad2deg(localPositionEuler(2));
    localPositionPhi = rad2deg(localPositionEuler(3));
    
    % VIO Twist
    localPositionTwistLinearVelocityX = localPositionOdomMsg.Twist.Twist.Linear.X;
    localPositionTwistLinearVelocityY = localPositionOdomMsg.Twist.Twist.Linear.Y;
    localPositionTwistLinearVelocityZ = localPositionOdomMsg.Twist.Twist.Linear.Z;
    
    %     stateMsg.xVelocity = localPositionTwistLinearVelocityX;
    %     stateMsg.yVelocity = localPositionTwistLinearVelocityY;
    %     stateMsg.zVelocity = localPositionTwistLinearVelocityZ;
    
    localPositionTwistAngularVelocityX = localPositionOdomMsg.Twist.Twist.Angular.X;
    localPositionTwistAngularVelocityY = localPositionOdomMsg.Twist.Twist.Angular.Y;
    localPositionTwistAngularVelocityZ = localPositionOdomMsg.Twist.Twist.Angular.Z;
    
    pFile5 = fopen(WaypointLog, 'a');
    
    if ( logFlag )
        pFile2 = fopen(VIOLog, 'a');
        pFile1 = fopen(localPositionLog, 'a');
        if useLidarFlag
            pFile3 = fopen(lidarLog, 'a');
        end
        pFile4 = fopen(stateEstimateLog, 'a');
        
        % write csv file Local Position
        fprintf(pFile1,'%6.6f,',localPositionTime);
        
        fprintf(pFile1,'%6.6f,',localPositionX);
        fprintf(pFile1,'%6.6f,',localPositionY);
        fprintf(pFile1,'%6.6f,',localPositionZ);
        fprintf(pFile1,'%6.6f,',localPositionPhi);
        fprintf(pFile1,'%6.6f,',localPositionTheta);
        fprintf(pFile1,'%6.6f,',localPositionPsi);
        
        fprintf(pFile1,'%6.6f,',localPositionTwistLinearVelocityX);
        fprintf(pFile1,'%6.6f,',localPositionTwistLinearVelocityY);
        fprintf(pFile1,'%6.6f,',localPositionTwistLinearVelocityZ);
        fprintf(pFile1,'%6.6f,',localPositionTwistAngularVelocityX);
        fprintf(pFile1,'%6.6f,',localPositionTwistAngularVelocityY);
        fprintf(pFile1,'%6.6f\n',localPositionTwistAngularVelocityZ);
        
        
        
        % write csv file Realsense VIO
        fprintf(pFile2,'%6.6f,',VIOTime);
        
        fprintf(pFile2,'%6.6f,',VIOPositionX);
        fprintf(pFile2,'%6.6f,',VIOPositionY);
        fprintf(pFile2,'%6.6f,',VIOPositionZ);
        fprintf(pFile2,'%6.6f,',VIOphi);
        fprintf(pFile2,'%6.6f,',VIOtheta);
        fprintf(pFile2,'%6.6f,',VIOpsi);
        
        fprintf(pFile2,'%6.6f,',VIOTwistLinearVelocityX);
        fprintf(pFile2,'%6.6f,',VIOTwistLinearVelocityY);
        fprintf(pFile2,'%6.6f,',VIOTwistLinearVelocityZ);
        fprintf(pFile2,'%6.6f,',VIOTwistAngularVelocityX);
        fprintf(pFile2,'%6.6f,',VIOTwistAngularVelocityY);
        fprintf(pFile2,'%6.6f\n',VIOTwistAngularVelocityZ);
        
        if useLidarFlag
            % write csv file lidar
            fprintf(pFile3,'%6.6f\n', lidarMsg.Range_);
        end
        
        % write csv file stateEstimate
        fprintf(pFile4,'%6.6f,',stateMsg.Yaw);
        fprintf(pFile4,'%6.6f,',stateMsg.Pitch);
        fprintf(pFile4,'%6.6f,',stateMsg.Roll);
        fprintf(pFile4,'%6.6f,',stateMsg.East);        % X axis
        fprintf(pFile4,'%6.6f,',stateMsg.North);       % Y axis
        fprintf(pFile4,'%6.6f\n',stateMsg.Up);         % Z axis
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Write CSV File for Waypoint Log
        if LogWaypoints == 1
            if Discretation_log==1 % Time Discretation
                if t > (t_lastWaypoint(k) + TimeInterval)
                    k = k+1;
                    fprintf(pFile5,'%6.6f,',localPositionX);
                    fprintf(pFile5,'%6.6f,',localPositionY);
                    fprintf(pFile5,'%6.6f,',localPositionZ);
                    fprintf(pFile5,'%6.6f\n',t);
                    if ~isempty(t_lastWaypoint(k))
                        t_lastWaypoint(k) = t;
                    end
                    % Useful for Debugging
                    %                     fprintf('Time Elapsed: %6.6f\n',t)
                    %                     fprintf('Time Last: %6.6f\n',t_lastWaypoint(k))
                end
            end
            if Discretation_log==0 % Distance Discretation
                DistanceTraveled=sqrt((localPositionX-lastWaypointX(k))^2+(localPositionY-lastWaypointY(k))^2+(localPositionZ-lastWaypointZ(k))^2);
                if DistanceTraveled > DistanceInterval
                    k=k+1;
                    fprintf(pFile5,'%6.6f,',localPositionX);
                    fprintf(pFile5,'%6.6f,',localPositionY);
                    fprintf(pFile5,'%6.6f,',localPositionZ);
                    fprintf(pFile5,'%6.6f\n',t);
                    if ~isempty(lastWaypointX(k))
                        lastWaypointX(k) = localPositionX;
                    end
                    if ~isempty(lastWaypointY(k))
                        lastWaypointY(k) = localPositionY;
                    end
                    if ~isempty(lastWaypointZ(k))
                        lastWaypointZ(k) = localPositionZ;
                    end
                    fprintf('Distance Traveled: %6.6f\n',DistanceTraveled)
                    fprintf('Current Waypoint: %6.6f\n',k)
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        fclose(pFile1);
        fclose(pFile2);
        if useLidarFlag
            fclose(pFile3);
        end
        fclose(pFile4);
        fclose(pFile5);
    end
    
    % timestamp
    ti= rostime('now');
    abs_t = eval([int2str(ti.Sec) '.' ...
        int2str(ti.Nsec)]);
    
    if isempty(t0), t0 = abs_t; end
    t = abs_t-t0;
    t1 = abs_t-t0;
    stateMsg.Time = t;
    % fixed loop pause
    waitfor(r);
    
    fprintf('Yaw :   %03.01f\n',stateMsg.Yaw);
    fprintf('Pitch : %03.01f\n',stateMsg.Pitch);
    fprintf('Roll :  %03.01f\n',stateMsg.Roll);
    fprintf('East (X) :  %03.01f\n',stateMsg.East);
    fprintf('North (Y) :  %03.01f\n',stateMsg.North);
    fprintf('Altitude (Z) :  %03.01f\n',stateMsg.Up);
    fprintf('Altitude (Z) :  %03.01f\n',stateMsg.Range);
    fprintf('LoopRate Hz: %03d\n',round(1/toc) )
    
    
    
    
    % publish stateEstimate
    send(stateEstimatePublisher, stateMsg);
    disp('Sending stateMsg:')
    stateMsg
end

