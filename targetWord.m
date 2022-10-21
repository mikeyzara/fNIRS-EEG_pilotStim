function keyWord = targetWord(fileName, targetWordList)
%This function will obtain the target word of the current SPIN sentence.

% Get the list # and file # from the audio file's name
%   The list # is the number right after the word "SPIN"
%   The file # follows the list # after the underscore
%       e.g. The file 2_-_SPIN7_02_SNR-2_short_ramped.wav
%                             ^^^^    
%                             list #7, file #02
idx = strfind(fileName,"_SPIN")+5; %Find the index of the string "_SPIN" -- determine where the list# and file# are in the file name
audioFile = fileName(idx:idx+3); %This is the full list#_file# name for the audio file (e.g. '7_02')
wordIdx = find(strcmp(audioFile,targetWordList.Filename)); %This is the index of the word in targetWordList
keyWord = targetWordList.Keyword(wordIdx);
end