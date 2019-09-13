function mission = loadMission_followCSVWaypoints()

global timestamps
global waypoint

%Mission Configurations
mission.config.firstLoop = 1;
mission.config.firstIteration = 1;
mission.config.H_detector = 0;
mission.config.R_detector = 0;
mission.config.target_detector = 0;
mission.config.flowProbe = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Select Path to File and enter it
pathToWaypointLogs = '/home/amav/amav/Terpcopter3.0/matlab/estimation/WaypointLogs';
cd(pathToWaypointLogs)

% Select File
[file1,path1] = uigetfile('*.log'); %Enter File name here

% Read in CSV
file1
filepath1 = [path1 file1];
data1 = csvread(filepath1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i = 1;
% Behavior 1: Follow CSV Waypoints
mission.bhv{i}.name = 'bhv_followCSVWaypoints';
mission.bhv{i}.ayprCmd = default_aypr_msg();
mission.bhv{i}.ayprCmd.AltSwitch = 1;
mission.bhv{i}.ayprCmd.WaypointSwitch = 1;
% Initialize
mission.bhv{i}.ayprCmd.WaypointXDesiredMeters = 0;
mission.bhv{i}.ayprCmd.WaypointYDesiredMeters = 0;
mission.bhv{i}.ayprCmd.AltDesiredMeters = 0;
mission.bhv{i}.completion.durationSec = 3; % 3 seconds
mission.bhv{i}.completion.status = false; % completion flag
% Parse out waypoint data
waypoint.waypoint_time = data1(:,1);
waypoint.waypoint_time = waypoint.waypoint_time - waypoint.waypoint_time(1); %Duration since start
waypoint.waypoint_x = data1(:,2);
waypoint.waypoint_y = data1(:,3);
waypoint.waypoint_z = data1(:,4);
waypoint.FinalWaypoint = length(waypoint.waypoint_time);

% i = i + 1;
% % Behavior 2: Land
% mission.bhv{i}.name = 'bhv_land';
% mission.bhv{i}.ayprCmd = default_aypr_msg();
% mission.bhv{i}.ayprCmd.AltSwitch = 1;
% mission.bhv{i}.ayprCmd.AltDesiredMeters = 0.0;
% mission.bhv{i}.completion.durationSec = 10*60; % make this very long so vehicle hovers above ground before manual takeover
% mission.bhv{i}.completion.status = false;     % completion flag

end

