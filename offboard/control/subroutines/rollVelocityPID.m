function [rollStickCmd, velRollControl] = rollVelocityPID(velRollControl, vx_d, vx)

% gains/parameters
Kp_roll = 0.10;
Ki_roll = 0;%0.001
Kd_roll = 0;

% pitchStickLimit = 0.25;
% rollStickLimit = 0.25;

% calculate attitude error in inertial frame
velRollControl.error = vx_d - vx

if(velRollControl.Iflag == true)
    velRollControl.errorsum = velRollControl.errorsum + velRollControl.error;
else
    velRollControl.errorsum = 0;
end

% % Rotation from inertial frame to quad body frame
% vx_error = vx_error*cosd(relativeYawDeg) + vy_error*sind(relativeYawDeg)
% vy_error = -vx_error*sind(relativeYawDeg) + vy_error*cosd(relativeYawDeg)

% proportional control scaled to unit vector
rollStickCmd = Kp_roll*velRollControl.error...
              + Ki_roll*velRollControl.errorsum...
              + Kd_roll*velRollControl.preverror;
          
velRollControl.preverror = velRollControl.error;

end