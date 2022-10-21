close all
clear all

%% Need these folders for the audio files
addpath(genpath('1'))
addpath(genpath('2'))
addpath(genpath('3'))
addpath(genpath('4'))

%% Import the SPIN target words file
targetWordList = readtable("SPIN_test_scoresheets.xlsx","Range","A1:C401");
targetWordList.Carrier = [];


promptOrder = {'Enter the counterbalance order (separated by a space):'};
dlgtitleOrder = 'Order of Conditions';
dims = [1 35];
definputOrder = {'0 0 0 0'};
Order = inputdlg(promptOrder,dlgtitleOrder,dims,definputOrder);
conditionOrder = str2num(Order{1});

currentDir = pwd;
fileOrder = [1:25]; % This creates a randomly ordered vector of indices between 1 and size(files)
keyWord = cell(size(fileOrder,2),4);
for k = 1:4
    %% Prepare the audio files and store them to create a "playlist"
    filepath = fullfile(currentDir,num2str(conditionOrder(k)));
    files = dir(fullfile(filepath,'*.wav')); % Get the name of all folders in file

    % This will grow in size according to the number of buffers that are created
    for i = 1:length(fileOrder)
        % Read the audio files into MATLAB
        fileName = fullfile(filepath,files(fileOrder(i)).name);

        % Find and store the target word for audio file
        keyWord{i,k} = targetWord(fileName, targetWordList);
    end
end
