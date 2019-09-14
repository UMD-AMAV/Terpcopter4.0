function [completionFlag,ayprCmd] = bhv_FollowCSVWaypoints(stateEstimateMsg,ayprCmd, completion,t)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    global waypoint
        if ~isempty(Temp)
            k=1;
            WaypointSatisfaction = completion.durationSec;
            toleranceMeters = 0.25;
            Temp = 1;
        end
    
    % Set Desired Waypoints
    ayprCmd.WaypointXDesiredMeters = waypoint.waypoint_x(k);
    ayprCmd.WaypointYDesiredMeters = waypoint.waypoint_y(k);
    ayprCmd.AltDesiredMeters = waypoint.waypoint_z(k);
    
    % Waypoint Completion Conditions
    WaypointXComplete = abs(ayprCmd.WaypointXDesiredMeters - stateEstimateMsg.East) <= toleranceMeters;
    WaypointYComplete = abs(ayprCmd.WaypointYDesiredMeters - stateEstimateMsg.North) <= toleranceMeters;
    WaypointZComplete = abs(ayprCmd.AltDesiredMeters - stateEstimateMsg.Up) <= toleranceMeters;
    if WaypointXComplete && WaypointYComplete && WaypointZComplete
        fprintf('Waypoint: %f has been satisfied\t', k)
        current_event_time = t; % reset time for which altitude is satisfied
    else
        disp('Waypoint is not satisfied');
        current_event_time = t;
        timestamps.behavior_satisfied_timestamp = t;
    end
 
    % Require Waypoint to be held within tolerance for specified time to advance
    elapsed_satisfied_time = current_event_time - timestamps.behavior_satisfied_timestamp;  
    if elapsed_satisfied_time >= WaypointSatisfaction
        % If this is the final waypoint of the CSV file, send Completion Flag
        if k == FinalWaypoint
            completionFlag = 1;
            return;
        end
        k=k+1;
    end  
    completionFlag = 0;
end

	
