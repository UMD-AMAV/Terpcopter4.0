function [yawStickCmd, yawControl] = yawController(yawControl, curTime, yawDeg, yawDesDeg)

% Note: clockwise is negative stick cmd

% gains/parameters
yawFiltTimeConstant = 0.2; %sec
kp = 3/180; % estimate : 10 deg error gives 0.1 stick cmd with kp = 0.1/10;
yawStickLimit = 0.45;
deadbandDeg = 0.5;

% unpack states
prevYawDeg = yawControl.prevVal;
lastTime = yawControl.lastTime;

% time elapsed since last control
dt = curTime - lastTime;

% low-pass filter
alpha = dt / ( yawFiltTimeConstant + dt);
yawFiltDeg = (1-alpha)*prevYawDeg + alpha*yawDeg;

% altitude error
yawErrorDeg = 180/pi*signedAngularDist( yawFiltDeg*pi/180,yawDesDeg*pi/180 )

% proportional control
yawStickCmd = kp*yawErrorDeg; 

% saturate
yawStickCmd = max(-yawStickLimit,min(yawStickCmd,yawStickLimit));

% deadband
if ( abs(yawErrorDeg) <= deadbandDeg )
   yawStickCmd = 0; 
end

% pack up structure
yawControl.lastTime = curTime;
yawControl.prevVal = yawDeg;

displayFlag = 1;
if ( displayFlag )
    
    pFile = fopen( yawControl.log ,'a');
    
    % write csv file
    fprintf(pFile,'%6.6f,',curTime);
    fprintf(pFile,'%6.6f,',dt);
    fprintf(pFile,'%6.6f,',yawDesDeg);
    fprintf(pFile,'%6.6f,',yawDeg);
    fprintf(pFile,'%6.6f,',yawFiltDeg);
    fprintf(pFile,'%6.6f,',yawErrorDeg);
    fprintf(pFile,'%6.6f,',yawStickCmd);
    
    
    % constant parameters
    fprintf(pFile,'%6.6f,',yawFiltTimeConstant);
    fprintf(pFile,'%6.6f,',kp);
    fprintf(pFile,'%6.6f,\n',yawStickLimit);

    fclose(pFile);
    
end
end