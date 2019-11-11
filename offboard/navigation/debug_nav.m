% prepare workspace
clear all; close all; clc; format compact;
run('loadParams.m');
addpath('../');
rosshutdown;

% intialize ros node
if(~robotics.ros.internal.Global.isNodeActive)
    rosinit;
end

1;

% Publishers
stateEstimatePublisher = rospublisher('/stateEstimate2', 'terpcopter_msgs/ayprCmd');

stateMsg = rosmessage(stateEstimatePublisher)

stateMsg;

send(stateEstimatePublisher, stateMsg);