%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Node: control
%
% Purpose:  
% The purpose of the control node is to regulate the quadcopter to desired
% setpoints of [altitude, heading, forward speed, crab speed]. We refer to
% this as a 'ahsCmd' which is generated by a behavior in the autonomy node.
% The control node determines the appropriate 'stickCmd' [yaw, pitch, roll,
% thrust] to send to the virtual_transmitter.
%
% Input:
%   - ROS topic: /stateEstimate (generated by estimation)
%   - ROS topic: /ahsCmd (generated by autonomy)
%   
% Output:
%   - ROS topic: /stickCmd (used by virtual_transmitter)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prepare workspace
clear; close all; clc; format compact;
addpath('../')
params = loadParams();

global controlParams
controlParams = params.ctrl;
fprintf('Control Node Launching...\n');

% declare global variables
% Determine usage in other scripts - change to local if no other usage
global altitudeErrorHistory forwardErrorHistory;

forwardErrorHistory.lastVal = 0;
forwardErrorHistory.lastSum = 0;
forwardErrorHistory.lastTime = 0;


% initialize ROS
if(~robotics.ros.internal.Global.isNodeActive)
    rosinit;
end

controlNode = robotics.ros.Node('/controlspeed');

flowProbeDataSubscriber = robotics.ros.Subscriber(estimationNode,'/flowProbe','std_msgs/Float32',@flowProbeCallback,"BufferSize",1);
fpMsg = receive(flowProbeDataSubscriber,20);

if isempty(fpMsg)
        state = NaN;
        disp('No flow probe data\n');
        return;
end

stateEstimateMsg = receive(stateEstimateSubscriber,5);

% timestamp
t0 = []; 
timeMatrix=[];
ti= rostime('now');
%abs_t = eval([int2str(ti.Sec) '.' ...
    %int2str(ti.Nsec)]);

abs_t = double(ti.Sec)+double(ti.Nsec)*10^-9;

if isempty(t0), t0 = abs_t; end


forwardErrorHistory.lastTime = 0; %stateEstimateMsg.Time;
forwardErrorHistory.lastVal = ahsCmdMsg.ForwardSpeedMps;
forwardErrorHistory.lastSum = 0;
u_t_forward = 0;

disp('initialize loop');

r = robotics.Rate(10);
reset(r);

send(stickCmdPublisher, stickCmdMsg);
% flag = true;

while(1)
    
     % timestamp
    ti= rostime('now');
    abs_t = double(ti.Sec)+double(ti.Nsec)*10^-9;
    t = abs_t-t0;
    %timeMatrix = [timeMatrix;t];
    %if isempty(t0), t0 = abs_t; end
   
    fprintf("t %6.4f",t);

    % unpack statestimate
    %t = stateEstimateMsg.Time;
    z = stateEstimateMsg.Range;
    yaw = stateEstimateMsg.Yaw;
    fprintf('Current Quad Alttiude is : %3.3f m\n', z );e

    u = stateEstimateMsg.forwardVelocity;

    % get setpoint
    z_d = ahsCmdMsg.AltitudeMeters;
    yaw_d = ahsCmdMsg.HeadingRad;
%     u_d = ahsCmdMsg.ForwardSpeedMps;
    
    if(t < 2.0)
        u_d = 0.4;
    else
        u_d = 0;
    end
   
    % update errors
    altError = z_d - z;
    forwardError = u_d - u;

    % compute controls
    % FF_PID(gains, error, newTime, newErrVal)
    [u_t_forward, forwardErrorHistory] = forwardcontroller_PID(controlParams.forwardGains , forwardErrorHistory, t, forwardError);
    disp('pid loop');
    
    %calculate net throttle input
    thr_trim = 0;
    u_stick_thr_net = (u_stick_cmd(1)*controlParams.stick_lim(1) + thr_trim*controlParams.trim_lim(1))...
                            /(controlParams.stick_lim(1)+controlParams.trim_lim(1));
    %get slope                    
    slope = controlParams.m_net * controlParams.g/( u_stick_thr_net+1);
    
    %get max allowed thrust in horizontal plane
    T_XY_max = slope * sqrt(4 - (u_stick_thr_net+1)*(u_stick_thr_net+1)) -1;
    T_XY_max_tilt = slope*(u_stick_thr_net+1)*cos(stateEstimateMsg.Roll)*cos(stateEstimateMsg.Pitch)*tan(controlParams.tilt_max);
    T_XY_max = min(T_XY_max,T_XY_max_tilt);
    
    %saturate horizontal thrust setpoints
    mag = sqrt(u_t_forward*u_t_forward + thr_sp_crab*thr_sp_crab);
    if mag > T_XY_max
        u_t_forward = u_t_forward * T_XY_max/mag;
%         thr_sp_crab = thr_sp_crab * T_XY_max/mag;
    end
    
    u_t_pitch = u_t_forward;
    
    % compute controls
%     [u_t_yaw, yawError] = PID(controlParams.yawGains, yawError, t, yawSetpointError);
%     disp('pid loop');
%     disp(controlParams.yawGains)
    

    % publish
    stickCmdMsg = rosmessage('terpcopter_msgs/stickCmd');
%     stickCmdMsg.Thrust = 2*max(min(1,u_t_alt),0)-1;
    stickCmdMsg.Pitch = max(min(1,u_t_pitch),-1);
    send(stickCmdPublisher, stickCmdMsg);
    fprintf('Published Stick Cmd., Thrust : %3.3f, Altitude : %3.3f, Altitude_SP : %3.3f, Error : %3.3f \n', stickCmdMsg.Thrust , stateEstimateMsg.Up, z_d, ( z - z_d ) );

    time = r.TotalElapsedTime;
	fprintf('Iteration: %d - Time Elapsed: %f\n',i,time)
	waitfor(r);
 end

