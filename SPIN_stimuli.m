close all
clear all

%% Need these folders for the audio files
addpath(genpath('1'))
addpath(genpath('2'))
% addpath(genpath('3'))
% addpath(genpath('4'))


%% Import the SPIN target words file
targetWordList = readtable("SPIN_test_scoresheets.xlsx","Range","A1:C401");
targetWordList.Carrier = [];

%% Create a fixation cross
% Create the fixation cross
figure('color','k')
set(gcf,'Position',[-500 500 400 300],'MenuBar', 'None','WindowState','fullscreen')
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
scatter(0,0,'+','LineWidth',100,'MarkerEdgeColor','w')
set(gca, 'Color','k', 'XColor','k', 'YColor','k')
%% Initialize LSL stream to transmit markers
addpath(genpath('liblsl-Matlab-master')) % Need this folder to create LSL stream

% Load the library first so that lsl functions are available to us
lib = lsl_loadlib();

% Let's open up a stream outlet to send the markers to
% First we'll need info about the stream
%   Define the variables separately and keep the original arguments in the
%   lsl_streaminfo function for future reference
name = 'SPINMarkers';
type = 'Markers';
channelcount = 1; %Only sending markers
samplingrate = 0; %No regular sampling rate
channelformat = 'cf_string'; %We're sending strings
sourceid = '1234'; %Testing a unique source ID in case anything crashes
info = lsl_streaminfo(lib,name,type,channelcount,samplingrate,channelformat,sourceid);

%Let's open up that stream outlet
outlet = lsl_outlet(info);
%% Initialize Psychtoolbox
% Running on PTB-3? Abort otherwise.
AssertOpenGL;

%% Initialize keyboard stuff
% In this experiment, the only keyboard input that we want is from the
% spacebar
KbName('UnifyKeyNames');
responseKeys = {'space'};
KbCheckList = [KbName('space'),KbName('ESCAPE')];
for i = 1:length(responseKeys)
    KbCheckList = [KbName(responseKeys{i}),KbCheckList];
end
% this makes sure that the only 'legal' keypresses are from the space bar
% and the escape key (in case we need to force-quit)
RestrictKeysForKbCheck(KbCheckList);

%% Initialize sound stuff
% This routine loads the PsychPortAudio sound driver for high-precision,
% low-latency, multi-channel sound playback and recording.
%   Set the argument to '1' to run in low latency mode
InitializePsychSound(1)

device = []; %The default soundcard
mode = []; %Mode of operation. Default is audio playback only
reqlatencyclass = 1;  %The default is 1. Try to get the lowest latency
%that is possible under the constraint of reliable playback, freedom of choice
%for all parameters and interoperability with other applications.
freq = []; %Requested playback/capture rate in samples per second (Hz). Defaults to a value that depends on the
%requested latency mode
nrChannels = 2; %Default for stereo sound
bufferSize = []; %Best left alone -- let it default
suggestedLatency = []; %Best left alone -- let it default
pahandle = PsychPortAudio('Open', device, mode, reqlatencyclass, freq, nrChannels, bufferSize, suggestedLatency);

% Get frequency for playback:
s = PsychPortAudio('GetStatus', pahandle);
freq = s.SampleRate;

%% Take a brief pause -- need some user input from experimenters to initiate the experiment
% Ask for the PID
promptPID = {'Enter PID:'};
dlgtitlePID = 'PID';
dims = [1 35];
definputPID = {'000'};
PID = inputdlg(promptPID,dlgtitlePID,dims,definputPID);

% Ask for the counterbalance order
while (1)
    promptOrder = {'Enter the counterbalance order (separated by a space):'};
    dlgtitleOrder = 'Order of Conditions';
    dims = [1 35];
    numArgs = 2;
    definputOrder = {'0 0'};
    Order = inputdlg(promptOrder,dlgtitleOrder,dims,definputOrder);

    % Check to see if counterbalance order is correctly formatted
    % We're checking for three conditions: 1) There are 4 numbers, 2) There are
    % no repeated numbers, and 3) All numbers are between 1 and 4.
    conditionOrder = str2num(Order{1});

    %If conditions are met, continue with the code
    if length(conditionOrder) == numArgs && length(conditionOrder) == length(unique(conditionOrder))...
            && all(conditionOrder >=1 & conditionOrder <=numArgs)
        break
    else %Otherwise, let user know there was an error and ask them to input the order again
        err = errordlg('Formatting Error','Input Error'); %
        waitfor(err)
    end
end

% Instruct the user to begin setting up the fNIRS equipment
message = ["Set up the fNIRS equipment."; "Don't forget to import the LSL markers titled 'SPINMarkers'.";" ";
    "Press 'OK' when setup is done."];
f = msgbox(message,'Setup Time');
waitfor(f)

%Confirm with the user that experimental setup is ready. Pressing OK wil
%begin the experiment
message = ["Experimental setup is ready. Press the 'Record' button in  OxySoft.";" ";
    "Press 'OK' when fNIRS data is being recorded."];
g = msgbox(message,'Record fNIRS');
waitfor(g)

message = ["The experiment will now begin.";" ";
    "Press 'OK' to start the experiment."];
h = msgbox(message,'Experiment Ready');
waitfor(h)
clc
%% Now for the experiment. This code will run 2 times since we have 2 conditions.
%Let's first get our current directory (the audio files for the experiments
%should be stored in 2 different folders). Make sure that these 2 folderes
%are in the same folder as this code.
currentDir = pwd;
for k = 1:numArgs
    %% Prepare the audio files and store them to create a "playlist"
    filepath = fullfile(currentDir,num2str(conditionOrder(k)));
    files = dir(fullfile(filepath,'*.wav')); % Get the name of all folders in file

    % We want to randomize the order of sentences without replacement. We'll
    % use the function 'randperm' to create a vector of indices
    fileOrder = randperm(size(files,1)); % This creates a randomly ordered vector of indices between 1 and size(files)

    buffer = [];
    keyWord = cell(size(fileOrder));
    % This will grow in size according to the number of buffers that are created
    for i = 1:length(fileOrder)
        % Read the audio files into MATLAB
        fileName = fullfile(filepath,files(fileOrder(i)).name);
        [audiodata, infreq] = psychwavread(fileName);

        % Find and store the target word for audio file
        keyWord{i} = targetWord(fileName, targetWordList);

        % Check to see if freq of audio file and freq of playback the same
        if infreq ~= freq % If they're not, do some resampling
            audiodata = resample(audiodata, freq, infreq); %Resample to 48kHz
            audiodata = audiodata';
        end

        % We want to playback in stereo, which means we need two rows of the audio
        % signal
        if size(audiodata,1) < 2
            audiodata = repmat(audiodata,2,1);
        end 

        buffer(end+1) = PsychPortAudio('CreateBuffer', [], audiodata); %Create a buffer and store the audio clip
    end

    nfiles = length(buffer);
    %% Let's start loading the files into a buffer and playing the stimuli
    % But first, define some variables to be used by PsychPortAudio
    repetitions = []; %Default is 1
    when = []; %Default to 0 (start immediately)
    waitForStart = 1; %If ‘waitForStart’ is set to non-zero value, ie if PTB should
    % wait for sound onset, then the optional return argument ‘startTime’ will contain
    % an estimate of when the first audio sample hit the speakers, i.e., the real
    % start time.

    bufferCnt = 1; % Initialize a counter for the number of buffers we're using

    disp(['sending: "Start Baseline"']);
    disp(' ')
    disp(['Upcoming Keyword: ']) %Display the upcoming target word
    disp(keyWord{bufferCnt}) %The keyword
    %% SEAN -- BASELINE TRIGGER
    outlet.push_sample({'Baseline Start'}); % Send the second trigger to the outlet
    WaitSecs(30); %30 second baseline
    disp(['sending: "Baseline End"']);
    while(bufferCnt <= nfiles) %This loop will go on until we've gone through each buffer's audio
        s = PsychPortAudio('GetStatus', pahandle);
        if s.Active == 0
            %% Fill buffers to play audio
            PsychPortAudio('FillBuffer', pahandle, buffer(bufferCnt));
            %% SEAN -- TRIGGER HERE FOR START OF SENTENCE
            % Right before the sentence begins
            disp(['sending: "Start"']);
            outlet.push_sample({['Start condition' num2str(conditionOrder(k))]}); % Send the trigger to the outlet

            %% Play the audio
            tStart = GetSecs; %Time at which audio starts to play
            PsychPortAudio('Start', pahandle, [], 0, 1);
            %% Output to command window
            disp('Audio: ');
%             disp(fileOrder(bufferCnt));
            disp(keyWord{bufferCnt})
            %% Now we wait for a keypress from the user and send a trigger. We also want to see their response time.
            while 1
                WaitSecs(2); %Wait 2 seconds before the participant can answer
                KbWait([],2); %Wait for the participant to press the spacebar
                [keyIsDown,secs,keyCode,deltaSecs] = KbCheck; %Check the keypress

                % continue to next trial if space is pressed
                if keyCode(KbName('space'))==1
%                     tResponse(bufferCnt) = secs; % Get the time at which the spacebar was pressed
                    tResponse = secs;
                    disp(['sending: "Response"']);
                    %% SEAN -- TRIGGER HERE FOR KEYBOARD PRESS
                    outlet.push_sample({'Response'} ); % Send the 'Response' trigger to the outlet
                    WaitSecs(5.5-(tResponse-tStart)); %Let the audio finish playing before moving on
                    if bufferCnt == nfiles
                        disp('Done');
                        Jitter_Times(end+1) = 0;
                    else
                        %% This is where we incorporate the jitter (between 6-9 sec)
                        disp(' ')
                        disp('Moving on to the next audio clip..');
                        disp(['Upcoming Keyword: ']) %Display the upcoming target word
                        disp(keyWord{bufferCnt+1}) %The keyword
                        Jitter_Times(bufferCnt) = randi([20, 25],1,1);
                        disp(['JitterTime: ', num2str(Jitter_Times(bufferCnt)), 'sec']);
                        disp(' ')
                        %% SEAN -- TRIGGER HERE FOR JITTER START/END
                        outlet.push_sample({'JitterStart'});
                        WaitSecs(Jitter_Times(bufferCnt));
                        outlet.push_sample({'JitterEnd'});
                    end
                    break
                    % ESC key quits the experiment
                elseif keyCode(KbName('ESCAPE')) == 1
                    clear all
                    close all
                    sca
                    return;
                end
            end
            %% Time to move on to the next audio file
            bufferCnt = bufferCnt + 1;
        end
    end
    summary(k).Audio_Order = fileOrder';
    summary(k).Target_Word = keyWord';
%     summary(k).Response_Time = tResponse'-tStart';
    summary(k).Jitter_Times = Jitter_Times;
    clear Jitter_Times
end
% Close the audio device:
PsychPortAudio('Close', pahandle);

%% Stimuli is done. Let's summarize some information in an excel file
% Put the PID and counterbalance order at the very top.
% We'll also include the following information for each condition:
% 1) The audio stimuli order
% 2) The participant's response time
% 3) The jitter times between each stimuli
% outputName = ['PID_' PID{1} '_summary.xlsx'];
% headerInfo = {'PID:' str2num(PID{1}); 'Counterbalance Order:' Order{1}};
% writecell(headerInfo, outputName);
% 
% excelRanges = {'A' 'E' 'I' 'M'};
% for j = 1:numArgs
%     tableInfo = {'Condition:' conditionOrder(j)};
%     writecell(tableInfo, outputName, 'Range', strcat(excelRanges{j},num2str(4)));
%     Audio_Order = summary(j).Audio_Order;
% %     Response_Time = summary(j).Response_Time;
%     Target_Word = summary(j).Target_Word;
%     Jitter_Time = summary(j).Jitter_Times';
%     T = table(Audio_Order, Target_Word, Jitter_Time);
%     writetable(T,outputName,'Range',strcat(excelRanges{j},num2str(5)));
% end
