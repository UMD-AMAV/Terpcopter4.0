function [yawStickCmd, uStickCmd, vStickCmd, wStickCmd] = waypoint3Dcontroller(curTime, yawDeg, x_d, x, y_d, y, z_d, z)
% Will think of a better name for this soon. Essentially we are
% implementing a controller that utilizes x,y,z and normalizes
% velocity vector to a sphere of constant velocity. 

% gains/parameters
Kp_u = 0.10;
Kp_v = 0.10;
Kp_w = 0.10;

attitudeDeadbandMeters = 0.25;
altitudeDeadbandMeters = 0.25;
relativeYawDeg = yawDeg - 90;  % This yaw is relative to the initial yaw when quad is turned on (90 Degrees)

% calculate attitude error in inertial frame
x_error = x_d - x;
y_error = y_d - y;
z_error = z_d - z;

% Rotation from inertial frame to quad body frame
x_error_body = -x_error*sind(relativeYawDeg) + y_error*cosd(relativeYawDeg); %Double check on these lol @zach
y_error_body = -x_error*cosd(relativeYawDeg) + y_error*sind(relativeYawDeg);
z_error_body = -z_error; %Believe this would just be inverse of z error (hence flipping it)
%x_error_body = x_error*cosd(relativeYawDeg) + y_error*sind(relativeYawDeg);
%y_error_body = -x_error*sind(relativeYawDeg) + y_error*cosd(relativeYawDeg);

attitudeErrorMeters = sqrt(x_error_body^2 + y_error_body^2);
distanceErrorMeters = sqrt(x_error_body^2 + y_error_body^2 + z_error_body^2); 

% proportional control scaled to unit vector
uStickCmd = Kp_u*(x_error_body/distanceErrorMeters); %Double check these as well
vStickCmd = Kp_v*(y_error_body/distanceErrorMeters);
wStickCmd = Kp_w*(z_error_body/distanceErrorMeters);
%uStickCmd = Kp_u*(y_error_body/distanceErrorMeters);
%vStickCmd = -Kp_v*(x_error_body/distanceErrorMeters);
% zStickCmd

yawStickCmd = 0;

if (abs(distanceErrorMeters) <= attitudeDeadbandMeters)
    uStickCmd = 0;
    vStickCmd = 0;
    yawStickCmd = 0;
    wStickCmd = 0;
end
% if (abs(z_error) <= altitudeDeadbandMeters)
%     wStickCmd = 0;
% end
end