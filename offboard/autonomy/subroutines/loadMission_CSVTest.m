function mission = loadMission_CSVTest()
global waypoint

mission.config.Liveplot_toggle = 1; %1=on , 0=off

mission.config.H_detector = 0;
mission.config.R_detector = 0;
mission.config.target_detector = 0;
mission.config.flowProbe = 0;

mission.config.Liveplot_firstloop = 1;
waypoint.ToleranceMeters = 0.25;
mission.config.toleranceMeters = waypoint.ToleranceMeters;

mission.config.firstLoop = 1;
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

% Parse out waypoint data
waypoint.waypoint_time = data1(:,4);
waypoint.waypoint_time = waypoint.waypoint_time - waypoint.waypoint_time(1); %Duration since start
waypoint.waypoint_x = data1(:,1);
waypoint.waypoint_y = data1(:,2);
waypoint.waypoint_z = data1(:,3);
waypoint.FinalWaypoint = length(waypoint.waypoint_time);
mission.config.FinalWaypoint = waypoint.FinalWaypoint;
mission.config.waypoint_x = waypoint.waypoint_x;
mission.config.waypoint_y = waypoint.waypoint_y;
mission.config.waypoint_z = waypoint.waypoint_z;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i = 1;
% Behavior 1: Follow CSV Waypoints
mission.bhv{i}.name = 'bhv_CSVTest';
mission.bhv{i}.ayprCmd = default_aypr_msg();
mission.bhv{i}.ayprCmd.AltSwitch = 1; 
mission.bhv{i}.ayprCmd.WaypointSwitch = 1;
mission.bhv{i}.ayprCmd.AltDesiredMeters = 0;
mission.bhv{i}.ayprCmd.WaypointXDesiredMeters = 0;
mission.bhv{i}.ayprCmd.WaypointYDesiredMeters = 0;
mission.bhv{i}.completion.durationSec = 1; % 10 seconds
mission.bhv{i}.completion.status = false;     % completion flag

end