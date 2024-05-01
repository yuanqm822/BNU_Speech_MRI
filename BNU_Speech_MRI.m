function BNU_Speech_MRI(subject, gender, age, group, set_num)
% BNU_SPEECH_MRI Function to run MRI speech experiments at BNU
% This function sets up and runs an MRI speech experiment based on the
% provided subject details and experiment block number.
% Running by PTB-3 and Audapter
% Created by Simon Yuan @ 30/04/2024

% Inputs:
%   subject - Subject ID (string)
%   gender  - Gender (1 for Male, 2 for Female)
%   age     - Age (integer)
%   group   - Group (1 for Exp, 2 for Test)
%   set_num - Experiment block number (1, 2, 3, or 4)

%% Set paths and participant's info
addpath('C:\Users\qyuan\speechres\commonmcode');
addpath('C:\Users\qyuan\speechres\audapter_matlab\mcode');
addpath('C:\Users\qyuan\speechres\audapter_mex');
cds('audapter_matlab');
which Audapter;

cd F:\OneDrive\BNU_project\Experiment_code\MRI

% Change to the Audapter directory
cd C:\Users\qyuan\speechres\audapter_matlab\mcode

subject = input('Enter subject ID: ', 's');
gender = input('Enter gender (1 for Male, 2 for Female): ');
age = input('Enter age: ');
group = input('Enter group (1 for Exp, 2 for Test): ');
set_num = input('What block is this? (1, 2, 3, & 4): ');

% Set filename based on input details
fName = [subject,'_', 'BNU_Speech_MRI','_G',num2str(gender),'_B',num2str(set_num),'_',date];

% Gender-specific settings for vocal tract
if gender == 1
    GENDER = 'male';
elseif gender == 2
    GENDER = 'female';
end

%% Audapter Configurations
audiointerface.name   = 'MOTU MicroBook ASIO';
audiointerface.fs     = 48000; % Hardware sampling rate (before downsampling)
audiointerface.down   = 4;
audiointerface.buffer = 96; % before downsampling (256) 128
audiointerface.nDelay = 3; % to reduce latency

% set parameters for audio interface and real-time processing
params = getAudapterDefaultParams(GENDER);
params.sr = audiointerface.fs / audiointerface.down;
params.downFact = audiointerface.down;
params.frameLen = audiointerface.buffer / audiointerface.down;
params.nDelay = audiointerface.nDelay;

params.f1Min = 0;
params.f1Max = 5000;
params.f2Min = 0;
params.f2Max = 5000;
params.pertF2 = linspace(0, 5000, 257);
params.pertPhi = 0 * ones(1, 257);
params.pertAmp = 0 * ones(1, 257); % no shift (default)
params.bTrack = 1;
params.bShift = 1;
params.bRatioShift = 0;
params.bMelShift = 1;
params.stereoMode = 1;
params.dScale = 2;
params.rmsThr = 0.01;

Audapter('deviceName', audiointerface.name);
Audapter('setParam', 'downFact', params.downFact);
Audapter('setParam', 'sRate', params.sr);
Audapter('setParam', 'frameLen', params.frameLen);
Audapter('setParam', 'nDelay', params.nDelay);

rng('shuffle'); % Shuffle random number generator

%% Stimuli and Alteration
% Define stimuli based on block number
if set_num == 1
    stimuli = {'dī','dē','dā'}; % vowel exploration
else
    stimuli = {'dē'};
end

stim_num = [];
shift = 110; % shift size in mel

% Define experimental block settings
if set_num == 1
    for i=1:45 % 3 stimuli x 45
        stim_num = [stim_num,randperm(3)];
    end
    PHI = 0; % shift angle
    AMP = zeros(1,45*3); % shift amount = zero
elseif set_num == 2
    for i=1:90 % 1 stimuli x 90
        stim_num = [stim_num,randperm(1)];
    end
    PHI = 0;
    AMP = zeros(1,90*1);
elseif set_num == 3
    for i=1:180 % 1 stimuli x 180
        stim_num = [stim_num,randperm(1)];
    end
    PHI = deg2rad(0);
    AMP = shift*ones(1,180*1);
elseif set_num == 4
    for i=1:90 % 1 stimuli x 90
        stim_num = [stim_num,randperm(1)];
    end
    PHI = 0;
    AMP = zeros(1,90*1);
end

Audapter('ost', '', 0);
Audapter('pcf', '', 0);
Audapter('reset');
AudapterIO('init', params);

%% Setting jittered interval for MRI
interval_1 = repmat([0.5, 1, 1.5], 1, length(stim_num) / 3);
interval_2 = zeros(1, length(stim_num));
for i = 1:length(stim_num)
    if interval_1(i) == 0.5
        interval_2(i) = 3.5;
    elseif interval_1(i) == 1
        interval_2(i) = 3;
    elseif interval_1(i) == 1.5
        interval_2(i) = 2.5;
    end
end
rng('shuffle');
randomOrder = randperm(length(stim_num));
interval_1 = interval_1(randomOrder);
interval_2 = interval_2(randomOrder);

%% Main Experiment
% Running by PTB-3
PsychDefaultSetup(2);
screenNumber = max(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
Screen('TextSize', window, 96);
Screen('Preference', 'TextEncodingLocale', 'UTF8');
Screen('TextFont', window, 'Microsoft YaHei');
HideCursor();
DrawFormattedText(window, double('请稍候...'), 'center', 'center', white);
Screen('Flip', window);
Audapter('start');
WaitSecs(2);
Audapter('stop');
DrawFormattedText(window, double(['请用正常清楚的声音',sprintf('\r\n'),...
    '读出屏幕呈现的拼音']), 'center', 'center', white);
Screen('Flip', window);
KbWait([], 2);
Screen('Flip', window);
bstart = GetSecs;
escapeKey = KbName('ESCAPE');
counter = 0;
for TRIAL = 1:length(stim_num)
    tstart = GetSecs;
    params.fb = 1;
    params.pertPhi = PHI * ones(1, 257);
    params.pertAmp = AMP(TRIAL) * ones(1, 257);
    params.bRatioShift = 0;
    AudapterIO('init', params);
    Audapter('reset');
    if counter == 4
        WaitSecs(2);
        counter = 0;
    end
    %WaitSecs(interval_1(TRIAL));
    Audapter('start');
    DrawFormattedText(window, double(stimuli{stim_num(TRIAL)}), 'center', 'center', white);
    Screen('Flip', window);
    WaitSecs(1.5);
    Screen('Flip', window);
    Audapter('stop');
    WaitSecs(0.5);
    %WaitSecs(2 + interval_2(TRIAL));
    dataSave(TRIAL) = AudapterIO('getData');
    trial_length(TRIAL) = GetSecs - tstart;
    counter = counter + 1;
    % Check for escape key press
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(escapeKey)
            Screen('CloseAll');
            disp('Experiment terminated early.');
            return;
        end
    end
end
block_length = GetSecs - bstart;

%% Save Files
x = dir([fName,'.mat']);
if isempty(x)
    save(['F:\OneDrive\BNU_project\Experiment_code\Data_MRI\',fName],'subject','gender','age','group','set_num','stim_num','stimuli','trial_length','block_length','interval_1','interval_2','dataSave');
    disp([fName,' saved.']);
else
    disp('FILE EXISTS. SAVING WITH TIMESTAMP')
    save(['F:\OneDrive\BNU_project\Experiment_code\Data_MRI\',fName,'_',num2str(round(rem(now,1)*10000))],'subject','gender','age','group','set_num','stim_num','stimuli','trial_length','block_length','interval_1','interval_2','dataSave');
end
clear;
cd F:\OneDrive\BNU_project\Experiment_code\MRI
sca;
end
