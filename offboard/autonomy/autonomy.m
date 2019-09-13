%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Node: autonomy
%
% Reference: stateEstimate.msg
% float32 range
% float32 time
% float32 north
% float32 east
% float32 up
% float32 yaw
% float32 pitch
% float32 roll
%
% Reference: ayprCmd.msg
% ayprCmdMsg = rosmessage(ayprCmdPublisher);
% ayprCmdMsg.AltDesiredMeters = 0;
% ayprCmdMsg.YawDesiredDegrees = 0;
% ayprCmdMsg.PitchDesiredDegrees = 0;
% ayprCmdMsg.RollDesiredDegrees = 0;
% ayprCmdMsg.AltSwitch = 0;
% ayprCmdMsg.YawSwitch = 0;
% ayprCmdMsg.PitchSwitch = 0;
% ayprCmdMsg.RollSwitch = 0;
%
% Reference: H detection
% hDetected = 0 (no H detected) , 1 (H detected)
% hAngle = -180 to 180 (deg)
% hPixelX = -360 to 360 (pixels)
% hPixelY = -640 to 640
%
% Reference: target detection
% targetDetected = 0 (no H detected) , 1 (H detected)
% targetPixelX = -360 to 360 (pixels)
% targetPixelY = -640 to 640
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prepare workspace
clear; close all; clc; format compact;
addpath('../')
params = loadParams();

keyStrokeFlag = 0;
if ( keyStrokeFlag )
    % keystroke capture
    h_fig = figure;
    global key_roll key_pitch;
    key_roll = 0;
    key_pitch = 0;
    set(h_fig,'KeyPressFcn',@arrowToInt);
    set(gcf, 'Position',  [100, 100, 500, 500])
    title('Keystroke Capture','FontSize',16);
end
% Competition Missions
% mission = loadMission_Comp_takeoffHoverPointLand();


% Cypress Missions
% missions
% mission = loadMission_takeoffHoverLand();
% mission = loadMission_takeoffHoverDropPackageLand();
% mission = loadMission_takeoffHoverFlyForwardLand();
% mission = loadMission_takeoffHoverFlyForwardProbeLand();
% mission = loadMission_takeoffHoverPointLand();
% mission = loadMission_takeoffHoverOverHKeyLand();
% mission = loadMission_takeoffHoverOverHLand();
% mission = loadMission_takeoffHoverOverHWithRadiusLand();
% mission = loadMission_servoTest();
% mission = loadMission_takeoffHoverFlyForwardDropPackageLand();
% mission = loadMission_PitchRollTestJerrar();
% mission = loadMission_StayOverHJerrar();
% mission = loadMission_CompetitionTakeoffHoverLand();
% mission = loadMission_CompetitionTakeoffHoverPointLand();
% mission = loadMission_CompetitionTakeoffHoverPointRiverLand();
% mission = loadMission_StayOverHAlign();
% mission = loadMission_takeoffHoverWaypointLand();
mission = loadMission_takeoffHoverWaypointSquareLand();
% mission = loadMission_followCSVWaypoints();
% mission = loadMission_CSVTest()
fprintf('Launching Autonomy Node...\n');

global timestamps

% initialize ROS
if(~robotics.ros.internal.Global.isNodeActive)
    rosinit;
end

% Publishers
fprintf('Setting up ayprsCmd Publisher ...\n');
ayprCmdPublisher = rospublisher('/ayprCmd', 'terpcopter_msgs/ayprCmd');
controlStartPublisher = rospublisher('/startControl', 'std_msgs/Bool');
imuDataSubscriber = rossubscriber('/mavros/imu/data');
fprintf('Setting up servoSwitch Publisher ...\n');
servoSwitchCmdPublisher = rospublisher('/servoSwitch', 'terpcopter_msgs/servoSwitchCmd');

% initialize control off
controlStartMsg = rosmessage('std_msgs/Bool');
controlStartMsg.Data = 0;
send(controlStartPublisher, controlStartMsg);

% Subscribers
fprintf('Subscribing to stateEstimate ...\n');
stateEstimateSubscriber = rossubscriber('/stateEstimate');

% vision-based subscribers depend on mission
if ( mission.config.R_detector )
    fprintf('Subscribing to River detector topics ...\n');
    % R detection
    rDetectedSub = rossubscriber('/RDetected');
    rLeftSub = rossubscriber('/RYleft');
    rRightSub = rossubscriber('/RYright');
end
if ( mission.config.H_detector )
    fprintf('Subscribing to H detector topics ...\n');
    % H detection
    hDetectedSub = rossubscriber('/hDetected');
    hAngleSub = rossubscriber('/hAngle');
    hPixelXSub = rossubscriber('/hPixelX');
    hPixelYSub = rossubscriber('/hPixelY');
    % Obstacle
%     targetObstSub = rossubscriber('/targetObst'); % binary
%     % Bullseye
%     targetPixelXSub = rossubscriber('/targetPixelX');
%     targetPixelYSub = rossubscriber('/targetPixelY');
%     targetDetectedSub = rossubscriber('/targetDetected');
end
if ( mission.config.flowProbe )
    fprintf('Subscribing to flowprobe ...\n');
    flowProbeDataSubscriber = rossubscriber('/terpcopter_flow_probe_node/flowProbe');
end




pause(0.1)

% Unpacking Initial ROS Messages
[ayprCmdMsg] = default_aypr_msg();
% servo switch 'false' = closed servo
servoSwitchMsg = rosmessage(servoSwitchCmdPublisher);
servoSwitchMsg.Servo = -1;

% initial variables
stick_thrust = -1;
servoCmd = -1; % default

r = robotics.Rate(25);
reset(r);

% for logging
currentBehavior = 1;
logFlag = 1;
dateString = datestr(now,'mmmm_dd_yyyy_HH_MM_SS_FFF');
autonomyLog = [params.env.matlabRoot '/autonomy_' dateString '.log'];
hfilterLog = [params.env.matlabRoot '/hFilter_' dateString '.log'];
bhvLog = [params.env.matlabRoot '/bhv_' dateString '.log'];
riverLog = [params.env.matlabRoot '/river_' dateString '.log'];


timeForPlot = tic;
numBhvs = length( mission.bhv );

if ( strcmp(params.auto.mode,'auto'))
    send(ayprCmdPublisher, ayprCmdMsg);
    send(servoSwitchCmdPublisher, servoSwitchMsg);
    fprintf('Press any key to begin mission.\n');
    pause
    fprintf('Entering loop ...\n');
    % run control once start button is pressed
    controlStartMsg.Data = 1;
    send(controlStartPublisher , controlStartMsg);
    while(1)
        
        % get latest messages
        stateEstimateMsg = stateEstimateSubscriber.LatestMessage;
        imuMsg = imuDataSubscriber.LatestMessage;
        if ( mission.config.R_detector )
            try
                rDetected = rDetectedSub.LatestMessage.Data
                yLeft = rLeftSub.LatestMessage.Data
                yRight = rRightSub.LatestMessage.Data
                if ( yLeft == -10000 || yRight == -10000 )
                    disp('Bad River message');
                    rDetected  = 0;
                end
            catch
                disp('No River message');
                rDetected = 0;                
                yLeft = 0;
                yRight = 0;
            end
        end
        if ( mission.config.H_detector )
            try
                hDetected = hDetectedSub.LatestMessage.Data
                hAngle = hAngleSub.LatestMessage.Data
                hPixelX = hPixelXSub.LatestMessage.Data
                hPixelY= hPixelYSub.LatestMessage.Data
                % TODO: make one message?
                if ( hPixelX == -10000 || hPixelY == -10000 || hAngle == -10000 )
                    disp('Bad H message');
                    hDetected  = 0;
                end
            catch
                disp('No H message');
                hDetected = 0;
                hAngle = 0;
                hPixelX = 0;
                hPixelY = 0;
            end
            
            %             targetObstSub.LatestMessage.Data
            %             % Bullseye
            %             targetX = targetPixelXSub.LatestMessage.Data
            %             targetY = targetPixelYSub.LatestMessage.Data
            %             targetDet = targetDetectedSub.LatestMessage.Data
        end
        if ( mission.config.flowProbe )
            fpMsg = flowProbeDataSubscriber.LatestMessage;
        end
        
        % unpack statestimate
        %t = stateEstimateMsg.Time;
        t = toc( timeForPlot );
        
        z = stateEstimateMsg.Up;
        fprintf('Received Msg, Quad Alttiude is : %3.3f m\n', z );
        
        
        % initialize and time-stamps on first-loop iteration
        if mission.config.firstLoop == 1
            disp('Behavior Manager Started')
            % initialize time variables
            timestamps.initial_event_time = t;
            timestamps.behavior_switched_timestamp = t;
            timestamps.behavior_satisfied_timestamp = t;
            mission.config.firstLoop = false; % ends the first loop
        end
        
        name = mission.bhv{1}.name;
        flag = mission.bhv{1}.completion.status;
        ayprCmd = mission.bhv{1}.ayprCmd;
        completion = mission.bhv{1}.completion;
        
        totalTime = t - timestamps.initial_event_time
        bhvTime = t - timestamps.behavior_switched_timestamp
        
        fprintf('Current Behavior: %s\tTime Spent in Behavior: %f\t Total Time of Mission: %f \n\n',name,bhvTime,totalTime);
        
        % if behavior completes pop behavior
        if flag == true
            [mission.bhv] = pop(mission.bhv, t);
            currentBehavior = currentBehavior + 1;
            disp('*************************')
            disp('**** Popped Behavior ****');
            disp('*************************')
        else
            % check status of remaining behavior
            %Set Handles within each behavior
            switch name
                % basic behaviors
                case 'bhv_takeoff'
                    completionFlag = bhv_takeoff( stateEstimateMsg , ayprCmd );
                case 'bhv_hover'
                    completionFlag = bhv_hover(stateEstimateMsg, ayprCmd, completion, t);
                case 'bhv_hover_fixed_orient'
                    completionFlag = bhv_hover_fixed_orient(stateEstimateMsg, ayprCmd, completion, t);
                case 'bhv_hover_over_H'
                    % this function is only for testing/logging data and
                    % does not currently affect hover_over_h behavior
                    %[hPixelFilt, yPixelFilt] = Hfilter(stateEstimateMsg, imuMsg, bhvTime, hDetected, hAngle, hPixelX, hPixelY, hfilterLog);
                    % behavior
                    [completionFlag, ayprCmd] = bhv_hover_over_H(stateEstimateMsg, ayprCmd, completion, bhvTime, hDetected, hAngle, hPixelX, hPixelY, bhvLog);
                    %[completionFlag, ayprCmd] = bhv_hover_over_H_impulse_bound(stateEstimateMsg, ayprCmd, completion, bhvTime, hDetected, hAngle, hPixelX, hPixelY)
                    %[completionFlag, ayprCmd] = bhv_hover_over_H_continuous_bound(stateEstimateMsg, ayprCmd, completion, bhvTime, hDetected, hAngle, hPixelX, hPixelY)
                    mission.bhv{1}.ayprCmd = ayprCmd; % vision actively controls yaw (for now, later pitch/roll)
                case 'bhv_hover_over_H_key'
                    [completionFlag, ayprCmd] = bhv_hover_over_H_key(stateEstimateMsg, ayprCmd, completion, bhvTime, hDetected, hAngle, hPixelX, hPixelY);
                    mission.bhv{1}.ayprCmd = ayprCmd; % vision actively controls yaw (for now, later pitch/roll)
                case 'bhv_hover_over_H_align'
                   [completionFlag, ayprCmd] = bhv_hover_over_H_align(stateEstimateMsg, ayprCmd, completion, bhvTime, hDetected, hAngle, hPixelX, hPixelY, bhvLog);                    
                   mission.bhv{1}.ayprCmd = ayprCmd; % vision actively controls yaw (for now, later pitch/roll)                        
                case 'bhv_hover_over_River_align'
                    [completionFlag, ayprCmd] = bhv_hover_over_River_align(stateEstimateMsg, ayprCmd, completion, bhvTime, rDetected, yLeft, yRight, riverLog);
                    mission.bhv{1}.ayprCmd = ayprCmd; % vision actively controls yaw (for now, later pitch/roll)                        
                case 'bhv_hover_drop'
                    [completionFlag, servoCmd] = bhv_hover_drop(completion, bhvTime );
                case 'bhv_point_to_direction'
                    completionFlag = bhv_point_to_direction(stateEstimateMsg, ayprCmd, completion, t);
                case 'bhv_fly_forward'
                    completionFlag = bhv_fly_forward(completion, bhvTime);
                case 'bhv_fly_forward_until_target'
                    completionFlag = bhv_fly_forward_until_target(completion, bhvTime, targetDet);
                case 'bhv_waypoint'
                    completionFlag = bhv_waypoint(stateEstimateMsg, ayprCmd, completion, t);
                case 'bhv_land'
                    completionFlag = bhv_land(completion, bhvTime);
                case 'bhv_FollowCSVWaypoints'
                    [completionFlag,ayprCmd] = bhv_FollowCSVWaypoints(stateEstimateMsg,ayprCmd,completion,t);
                case 'bhv_CSVTest'
                    [completionFlag, ayprCmd] = bhv_CSVTest(stateEstimateMsg, ayprCmd, completion, t);
                otherwise
            end
            mission.bhv{1}.completion.status = completionFlag;
        end
        
        % publish
        if ( currentBehavior > numBhvs )
            disp('=====================================');
            disp('          Mission Complete');
            disp('=====================================');
        else
            ayprCmdMsg = mission.bhv{1}.ayprCmd;
            send(ayprCmdPublisher, ayprCmdMsg);
            servoSwitchMsg.Servo = servoCmd;
            send(servoSwitchCmdPublisher, servoSwitchMsg);
            fprintf('Published Ahs Cmd. Alt : %3.3f \t Yaw: %3.3f\n', ayprCmdMsg.AltDesiredMeters, ayprCmdMsg.YawDesiredDegrees);
        end
        
        if ( logFlag )
            pFile = fopen( autonomyLog ,'a');
            
            % write csv file
            fprintf(pFile,'%6.6f,',toc(timeForPlot));
            fprintf(pFile,'%d,',currentBehavior);
            
            fprintf(pFile,'%6.6f,',ayprCmdMsg.WaypointXDesiredMeters);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.WaypointYDesiredMeters);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.AltDesiredMeters);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.YawDesiredDegrees);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.PitchDesiredDegrees);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.RollDesiredDegrees);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.AltSwitch);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.YawSwitch);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.PitchSwitch);
            fprintf(pFile,'%6.6f,',ayprCmdMsg.RollSwitch);
            
            fprintf(pFile,'%6.6f,',stateEstimateMsg.Range);
            fprintf(pFile,'%6.6f,',stateEstimateMsg.Time);
            fprintf(pFile,'%6.6f,',stateEstimateMsg.North);
            fprintf(pFile,'%6.6f,',stateEstimateMsg.East);
            fprintf(pFile,'%6.6f,',stateEstimateMsg.Up);
            fprintf(pFile,'%6.6f,',stateEstimateMsg.Yaw);
            fprintf(pFile,'%6.6f,',stateEstimateMsg.Pitch);          
            if ( mission.config.H_detector )
                fprintf(pFile,'%6.6f,',stateEstimateMsg.Roll);
                fprintf(pFile,'%6.6f,',hDetected);
                fprintf(pFile,'%6.6f,',hPixelX);
                fprintf(pFile,'%6.6f,',hPixelY);
                fprintf(pFile,'%6.6f\n',hAngle);
            else
                fprintf(pFile,'%6.6f\n',stateEstimateMsg.Roll);
            end
            
            
            fclose(pFile);
        end
        waitfor(r);
    end
end
fprintf('Autonomy node complete.\n');
