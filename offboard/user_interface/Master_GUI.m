function varargout = Master_GUI(varargin)
% MASTER_GUI MATLAB code for Master_GUI.fig
%      MASTER_GUI, by itself, creates a new MASTER_GUI or raises the existing
%      singleton*.
%
%      H = MASTER_GUI returns the handle to a new MASTER_GUI or the handle to
%      the existing singleton*.
%
%      MASTER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MASTER_GUI.M with the given input arguments.
%
%      MASTER_GUI('Property','Value',...) creates a new MASTER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Master_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Master_GUI_OpeningxiFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Master_GUI

% Last Modified by GUIDE v2.5 21-Jul-2019 14:16:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Master_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @Master_GUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Master_GUI is made visible.
function Master_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Master_GUI (see VARARGIN)
global pathToMatlabRoot pathToGUI pathToGUIScripts
pathToGUI = '/home/amav/Terpcopter4.0/offboard/user_interface';

cd(pathToGUI)
% addpath('../');
params = loadParams();
pathToMatlabRoot = params.env.matlabRoot;
pathToGUIScripts = [params.env.matlabRoot '/user_interface/scripts'];

if(~robotics.ros.internal.Global.isNodeActive)
    rosinit('192.168.1.3');
end
% Choose default command line output for Master_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes Master_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Master_GUI_OutputFcn(hObject, eventdata, handles)


% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text2,'String','launching');
system('./scripts/px4_script.sh &');
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/mavros/imu/data');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text2,'String','active');

% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text3,'String','launching');
system('./scripts/camera_script.sh &')
% first_run = 1;
% error_flag = 0;
% while( error_flag==1 || first_run == 1 )
%     pause(0.1);
%     try
%         sub = rossubscriber('/camera/image_raw/compressed');
%         first_run = 0;
%         error_flag = 0;
%     catch error
%         disp(error.identifier)
%         error_flag = 1;
%     end
% end
% msg = receive(sub,20);
set(handles.text3,'String','active');
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text4,'String','launching');
system('./scripts/navigation_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/stateEstimate');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text4,'String','active');
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text5,'String','launching');
system('./scripts/virtual_transmitter_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    try
        sub = rossubscriber('/vtxStatus');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text5,'String','active');
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text6,'String','launching');
system('./scripts/autonomy_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/ahsCmd');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text6,'String','active');
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text7,'String','launching');
system('./scripts/control_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/stickCmd');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text7,'String','active');
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text11,'String','launched');
system('./scripts/vision_script.sh &')
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
cwd = split(pwd(),'/');
if cwd{end} ~= "GUI"
    global pathToGUI
    cd(pathToGUI)
end
set(handles.text2,'String','launching');
system('./scripts/px4_script.sh &');
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/mavros/imu/data');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text2,'String','active');

set(handles.text3,'String','launching');
system('./scripts/lidar_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/terarangerone');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text3,'String','active');

set(handles.text4,'String','launching');
system('./scripts/estimation_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/stateEstimate');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text4,'String','active');



set(handles.text5,'String','launching');
system('./scripts/virtual_transmitter_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    try
        sub = rossubscriber('/vtxStatus');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text5,'String','active');


set(handles.text6,'String','launching');
system('./scripts/autonomy_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/ahsCmd');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text6,'String','active');


set(handles.text7,'String','launching');
system('./scripts/control_script.sh &')
first_run = 1;
error_flag = 0;
while( error_flag==1 || first_run == 1 )
    pause(0.1);
    try
        sub = rossubscriber('/stickCmd');
        first_run = 0;
        error_flag = 0;
    catch error
        disp(error.identifier)
        error_flag = 1;
    end
end
msg = receive(sub,20);
set(handles.text7,'String','active');


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
rosshutdown;
close();
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% Change loadParams
global pathToMatlabRoot pathToGUI pathToGUIScripts
fid = fopen([pathToMatlabRoot '/loadParams.m'],'rt')
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='192.168.1.93';
S2='192.168.1.3';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen([pathToMatlabRoot '/loadParams.m'],'wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;

% Change autolaunch_px4
fid = fopen([pathToGUIScripts '/autolaunch_px4'],'rt') ;
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='192.168.1.93';
S2='192.168.1.3';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen([pathToGUIScripts '/autolaunch_px4'],'wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;

% Change autolaunch_px4
fid = fopen([pathToGUIScripts '/autolaunch_camera'],'rt') ;
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='192.168.1.93';
S2='192.168.1.3';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen([pathToGUIScripts '/autolaunch_camera'],'wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;

% Change bashrc
fid = fopen('~/.bashrc','rt') ;
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='ROS_MASTER_URI=http://192.168.1.93:11311';
S2='ROS_MASTER_URI=http://192.168.1.3:11311';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen('~/.bashrc','wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;


% source bashrc
PATH = getenv('PATH');
setenv('PATH', [PATH ':/usr/local/desiredpath']);
unix('source ~/.bashrc')

if(~robotics.ros.internal.Global.isNodeActive)
    rosinit('192.168.1.3');
end
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton3


% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)

% Change loadParams
global pathToMatlabRoot pathToGUI pathToGUIScripts
fid = fopen([pathToMatlabRoot '/loadParams.m'],'rt')
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='192.168.1.3';
S2='192.168.1.93';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen([pathToMatlabRoot '/loadParams.m'],'wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;

% Change autolaunch_px4
fid = fopen([pathToGUIScripts '/autolaunch_px4'],'rt') ;
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='192.168.1.3';
S2='192.168.1.93';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen([pathToGUIScripts '/autolaunch_px4'],'wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;

% Change autolaunch_px4
fid = fopen([pathToGUIScripts '/autolaunch_camera'],'rt') ;
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='192.168.1.3';
S2='192.168.1.93';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen([pathToGUIScripts '/autolaunch_camera'],'wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;

% Change bashrc
fid = fopen('~/.bashrc','rt') ;
X = fread(fid) ;
fclose(fid) ;
X = char(X.') ; 
S1='ROS_MASTER_URI=http://192.168.1.3:11311';
S2='ROS_MASTER_URI=http://192.168.1.93:11311';
Y = strrep(X, S1, S2) ;
% replace string S1 with string S2
fid2 = fopen('~/.bashrc','wt') ;
fwrite(fid2,Y) ;
fclose (fid2) ;


% source bashrc
PATH = getenv('PATH');
setenv('PATH', [PATH ':/usr/local/desiredpath']);
unix('source ~/.bashrc')

if(~robotics.ros.internal.Global.isNodeActive)
    rosinit('192.168.1.93');
end
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton4


% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% intialize ros node
% if(~robotics.ros.internal.Global.isNodeActive)
%     rosinit;
% end

persistent startMissionPublisher;
startMissionPublisher = rospublisher('/startMission', 'std_msgs/Bool');
startMissionMsg = rosmessage(startMissionPublisher);
startMissionMsg.Data = true;
send(startMissionPublisher, startMissionMsg);
