function [pitchStickCmd, velPitchControl] = pitchVelocityPID(velPitchControl, vy_d, vy)

% gains/parameters
Kp_pitch = 0.10;
Ki_pitch = 0;%0.001
Kd_pitch = 0;

% pitchStickLimit = 0.25;
% rollStickLimit = 0.25;

velPitchControl.error = vy_d - vy

if(velPitchControl.Iflag == true)
    velPitchControl.errorsum = velPitchControl.errorsum + velPitchControl.error;
else
    velPitchControl.errorsum = 0;
end

% % Rotation from inertial frame to quad body frame
% vx_error = vx_error*cosd(relativeYawDeg) + vy_error*sind(relativeYawDeg)
% vy_error = -vx_error*sind(relativeYawDeg) + vy_error*cosd(relativeYawDeg)

pitchStickCmd = Kp_pitch*velPitchControl.error...
              + Ki_pitch*velPitchControl.errorsum...
              + Kd_pitch*velPitchControl.preverror;
          
velPitchControl.preverror = velPitchControl.error;

end