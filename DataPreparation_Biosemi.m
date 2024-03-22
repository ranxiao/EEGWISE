   % Prepare data by converting into .set format from EEGLab as the input
% format for the toolbox
% Ran Xiao, Emory University, 2/12/2023
% revise for trial stitching across different trial conditions 2/8/2024
%% Initialize directories
addpath(genpath('./Dependencies/'));

% this is where is data are on your computer
DataDir = '../Data/ReachStudy2024/';
trialInfo = readtable(strcat(DataDir,'TrialNote_EEGreachingStudy.xlsx'));

% modify the participant and visit session for analysis
Pat = 'TD08'; Visit = 'month 1';

% get all data files of the participants and process one by one
SessionDir = dir(strcat(DataDir,Pat,'/',Visit,'/*.txt'));

if isempty(SessionDir)
    print('No files found. Please check the patient name and file directory.');
else
    % get trial indices in SessionDir
    Sess_trialIdx = cellfun(@(x) str2num(x(9:strfind(x,' ')-1)),{SessionDir.name},'UniformOutput',false);
    Sess_trialIdx = cell2mat(Sess_trialIdx);

    % find rows in trialInfo that match the patient and visit
    ind = find(strcmp(trialInfo.ParticipantID,Pat) & (trialInfo.Month==str2num(Visit(end))));
    % get the trial info for the patient and visit
    Sess_trialInfo = trialInfo(ind,[4 5]);

    % get trial types for trialInd that match trialType.Activity
    Sess_trialType = Sess_trialInfo.TrialType(ismember(Sess_trialInfo.Activity,Sess_trialIdx));

    trial_type = 'baseline';
    extractEEG_biosemi(SessionDir,Sess_trialType,trial_type);

    trial_type = 'reach';
    extractEEG_biosemi(SessionDir,Sess_trialType,trial_type);

    trial_type = 'all';
    extractEEG_biosemi(SessionDir,Sess_trialType,trial_type);
end

close all;
clc;
disp('Done!');

