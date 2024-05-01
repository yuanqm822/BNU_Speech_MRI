%% A. Vowel Scoring
% For vowel formant extraction using PRAAT
% Find FORMANT section (using PRAAT) 
% Modified by Simon Yuan @ 25/04/2024

%% House Keeping
clear;close all;clc;
warning('off','all')

% Change current folder (windows)
cd('./');

% Input subject number
sub = num2str(input('Input subject number: '));
folder = 'Raw_data/';

disp('Select/deselect the midpoint of the vowel.')
pause(.5)
disp('Press p to play the word.')
pause(.5)
disp('Press space to advance.')
pause(.5)
disp('Press b to go back.')
pause(.5)

%% Define the centre of the vowel
FS = 16000; % sampling rate

% array of NaNs the size of the largest block and the number of blocks.
vowel_centres = NaN*ones(225,4);

BLOCK = 1;
while BLOCK <= 4
    X = dir([folder, sub,'*BNU_Speech*', 'B', num2str(BLOCK), '*.mat']);
    load([folder, X.name])

    scrsz = get(0, 'ScreenSize');  % screen stuff
    fig1 = figure('position', [scrsz(3)/5 scrsz(4)/2 scrsz(3)/1.5 scrsz(3)/4]);

    TRIAL = 1;  % Initialize TRIAL before the while loop starts
    while TRIAL <= length(dataSave)
        if isempty(dataSave(TRIAL).signalIn)
            dataSave(TRIAL).signalIn = zeros(24032, 1);
            dataSave(TRIAL).signalIn(24032, 1) = 1;
        end
        analysis_window = dataSave(TRIAL).signalIn;

        subplot(2,1,1)
        plot(analysis_window);
        axis([1 length(analysis_window) min(analysis_window) max(analysis_window)]);
        hold on;

        subplot(2,1,2)
        specgram(analysis_window);
        xlabel('Samples');

        smoothed_data = smooth(abs(analysis_window), FS/8);
        [~, peak_ind] = findpeaks(smoothed_data, 'MinPeakHeight', max(smoothed_data)/4, 'MINPEAKDISTANCE', round(length(analysis_window)/4/1.5), 'NPEAKS', 1);

        if isempty(peak_ind)
            peak_ind = NaN * ones(1, 1);
        end

        subplot(2,1,1)
        linehandle = gobjects(length(peak_ind), 1);
        for k = 1:length(peak_ind)
            linehandle(k) = plot([peak_ind(k), peak_ind(k)], [min(analysis_window), max(analysis_window)], 'r', 'linewidth', 2);
        end

        index = peak_ind';
        loopcount = length(peak_ind);
        collect = 0;

        while collect == 0
            [x, ~, button] = ginput(1);

            if button == 1
                [distance, order] = sort(abs(x - index));
                if ~isempty(distance) && distance(1) <= FS/5
                    loopcount = loopcount - 1;
                    delete(linehandle(order(1)));
                    index = index(order(2:end));
                    linehandle = linehandle(order(2:end));
                else
                    loopcount = loopcount + 1;
                    linehandle(loopcount) = plot([x, x], [min(analysis_window), max(analysis_window)], 'r', 'linewidth', 2);
                    index = [index, x];
                end
            elseif button == 32
                pause(0.25);
                button = 0;
                [index, fix_ind] = sort(index);
                collect = 1;
            elseif button == 112
                p = audioplayer(analysis_window, FS);
                play(p);
            elseif button == 98 % 'b' to go back
                TRIAL = TRIAL - 2;
                display(['Trial: ', num2str(TRIAL)]);
                break;
            end
            display(['Trial: ', num2str(TRIAL)]);
        end

        clf(fig1);
        vowel_centres(TRIAL, BLOCK) = index;
        TRIAL = TRIAL + 1;  % Manually increment TRIAL
    end
    close all;
    BLOCK = BLOCK + 1;  % Manually increment BLOCK
end

close all
save(['Temp_data/',sub,'_vTEMP'],'vowel_centres', 'FS', 'sub', 'folder')

%% FIND FORMANTS - PRAAT

warning('off','all')
sub = num2str(input('Input subject number: '));
load(['Temp_data/',sub,'_vTEMP']);
keep vowel_centres sub folder FS condition

stimuli_number = []; trial_time = []; block_time = [];

for BLOCK = 1:4
    X = dir([folder, sub,'*BNU_Speech*', 'B',num2str(BLOCK),'*.mat']);
    load([folder, X.name])

    count=0;

    index = vowel_centres(~isnan(vowel_centres(:,BLOCK)),BLOCK);

    for WORD=1:length(index)
        if isempty(dataSave(WORD).signalIn) == 1
            dataSave(WORD).signalIn = zeros(24032, 1);
            dataSave(WORD).signalIn(24032, 1) = 1;
        end
        count=count+1;
        display(['Trial: ' num2str(count)]);
        if length(dataSave(WORD).signalIn) < (index(WORD)+200)
            audiowrite('temp.wav',dataSave(WORD).signalIn(index(WORD)-200:length(dataSave(WORD).signalIn)),FS);
        elseif index(WORD)-200 < 1
            audiowrite('temp.wav',dataSave(WORD).signalIn(1:index(WORD)+200),FS);
        else
            audiowrite('temp.wav',dataSave(WORD).signalIn(index(WORD)-200:index(WORD)+200),FS);
        end
        
        OS = computer;
        if OS == 'PCWIN64'
            eval('delete rm ./temp*.Table')
            eval('!E:/Praat/Praat.exe --run "extract_formants.praat"')
        elseif OS == 'MACI64'
            eval('!rm ./temp*.Table')
            eval('!/Applications/Praat.app/Contents/MacOS/Praat --run "extract_formants.praat"')
        end
        
        % parse Praat output file
        X(1).table = textread('temp1.Table','%s');
        X(2).table = textread('temp2.Table','%s');
        X(3).table = textread('temp3.Table','%s');
        X(4).table = textread('temp4.Table','%s');
        X(5).table = textread('temp5.Table','%s');
        X(6).table = textread('temp6.Table','%s');
        X(7).table = textread('temp7.Table','%s');
        X(8).table = textread('temp8.Table','%s');
        X(9).table = textread('temp9.Table','%s');
        X(10).table = textread('temp10.Table','%s');
        X(11).table = textread('temp11.Table','%s');
        X(12).table = textread('temp12.Table','%s');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % find number of formants
        for P = 1:length(X)
            tempX = X(P).table;
            isFmt = [];
            for j = 1:length(tempX)
                isFmt(j) = contains(cell2mat(tempX(j)),'(Hz)');
            end
            nFormants = sum(isFmt);
            startIndex = max(find(isFmt))+1;                    % start index after the last formant label
            numS = str2num(cell2mat(tempX(startIndex)));        % number of samples
            numSkip = str2num(cell2mat(tempX(startIndex+1)));   % number of table values per sample (F0, F1, F2, etc...)

            clear X2 X3
            for j = (startIndex+1):length(tempX)
                temp = cell2mat(tempX(j));
                if ~isempty(temp)
                    if strcmp(temp,'"--undefined--"')
                        X2(j) = NaN;
                    elseif strcmp(temp(1),'"')
                        X2(j) = str2num(temp(2:end-1));
                    else
                        X2(j) = str2num(temp);
                    end
                end
            end

            X3 = reshape(X2(startIndex+1:end),numSkip+1,numS)';
            fmtPraat_allLPC{BLOCK}(count,:,P) = X3(3:4);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end

    stimuli_number = [stimuli_number; stim_num'];
    trial_time = [trial_time; trial_length'];
    block_time = [block_time; block_length'];

end

% pick the best LPC order based on the baseline block
%%% LPC picker
figure('Position',[1219 411 770 902])

BLOCK = 2; % baseline block
mstim = stimuli_number(136:195) == 2;
LPC_plot = fmtPraat_allLPC{BLOCK};
LPC_plot(mstim, :, :) = NaN;

for P = 1:12 % assumes 12 LPC orders (new version)
    subplot(4,3,P)
    cla
    plot(LPC_plot(:,:,P))
    hold on
    plot(LPC_plot(:,:,P),'.','markersize',10)
    title(['LPC ',num2str(P)])
end

keeper = input('WHICH LPC? ');
close all

% kill obvious outliers
fmtKeepHz = [];
fmtKeepMel = [];

for BLOCK = 1:4

    temp = killspike_F1F2(fmtPraat_allLPC{BLOCK}(:,:,keeper));

    fmtKeepHz = [fmtKeepHz; temp];
    fmtKeepMel = [fmtKeepMel; hz2mel(temp)];

end

%% save individual subject data (vowels scored and sorted)
if group == 1
    G = 'm';
elseif group == 2
    G = 'c';
else
    G = 'b';
end
eval('delete rm ./temp*.Table')
save(['Scored_data/',G,'_',sub,'_vSCORED'],'fmtPraat_allLPC','keeper','fmtKeepHz', 'fmtKeepMel','vowel_centres', 'stimuli_number','gender', 'group', 'condition', 'trial_time', 'block_time')

disp([sub,'_vSCORED file saved.'])

%% End
