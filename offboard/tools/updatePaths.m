function updatePaths()
cd ..
addpath('./utilities');
params = loadParams();
addpath(params.env.terpcopterMatlabMsgs);
addpath('./control')
addpath('./control/subroutines')
addpath('./navigation')
% addpath('./navigation/subroutines')
addpath('./autonomy')
addpath('./autonomy/subroutines')
addpath('./virtual_transmitter')
addpath('./virtual_transmitter/subroutines')
% addpath('./vision')
% % addpath('./vision/subroutines')
addpath('./utilities/geometry')
addpath('./user_interface')
addpath('./user_interface/scripts')
addpath('./tools')

% addpath('./plots')
% addpath('./plots/plotahsCmd')
% addpath('./plots/plotahsCmd/subroutines')
% addpath('./plots/plotpidSetting')
% addpath('./plots/plotpidSetting/subroutines')
% addpath('./plots/plotStateEstimate')
% addpath('./plots/plotStateEstimate/subroutines')
% addpath('./plots/plotStickCmd')
% addpath('./plots/plotStickCmd/subroutines')
% addpath('./plots/plotpidSetting')
% addpath('./plots/plotpidSetting/subroutines')
% addpath('./plots/plotTerarangerone')
% addpath('./plots/plotTerarangerone/subroutines')
% addpath('./results')
% savepath;
% %savepath([params.env.matlabHome '/pathdef.m']);
% end


