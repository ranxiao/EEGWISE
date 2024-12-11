   % Prepare data by converting into .set format from EEGLab as the input
% format for the toolbox
% Ran Xiao, Emory University, 2/12/2023
% revise for trial stitching across different trial conditions 2/8/2024
% added SATCO condition, and improve file structure 05.2024

%% Initialize directories
addpath(genpath('./Dependencies/'));

% this is where is data are on your computer
DataDir = 'C:/Users/rxiao27/OneDrive - Emory/DataBackup/NeuroDevelopment/Reach_R01/';
trialInfo = readtable(strcat(DataDir,'TrialNote_EEGreachingStudy.xlsx'));

% modify the participant and visit session for analysis
Pat = 'TD51'; Visit = 'Month 5';

% get all data files of the participants and process one by one
SessionDir = dir(strcat(DataDir,Pat,'/',Visit,'/*.txt'));
% SessionDir = dir(strcat(DataDir,'td40m5error/*.txt'));

if isempty(SessionDir)
    print('No files found. Please check the patient name and file directory.');
else
    % get trial indices in SessionDir
%     Sess_trialIdx = cellfun(@(x) str2num(x(9:strfind(x,' ')-1)),{SessionDir.name},'UniformOutput',false);
    Sess_trialIdx = cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')),{SessionDir.name},'UniformOutput',false);
    Sess_trialIdx = cell2mat(Sess_trialIdx);

    % reorder session files in the file directory, in some systems trial10 might rank higher than trial 2, 3, etc. 
    [~,ind_asc] = sort(Sess_trialIdx);
    SessionDir_asc = SessionDir(ind_asc);

    % find rows in trialInfo that match the patient and visit
    ind = find(strcmp(trialInfo.ParticipantID,Pat) & (trialInfo.Month==str2num(Visit(end))));
    % get the trial info for the patient and visit
    Sess_trialInfo = trialInfo(ind,[4 5]);
    [~,ind_asc2] = sort(Sess_trialInfo.Activity);% making sure Sess_trialInfo from excel file is ordered in ascending order
    Sess_trialInfo = Sess_trialInfo(ind_asc2,:);

    % get trial types for trialInd that match trialType.Activity, 
    Sess_trialType = Sess_trialInfo.TrialType(ismember(Sess_trialIdx,Sess_trialInfo.Activity));

    trial_type = 'Baseline';
    extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);

    trial_type = 'reach';
    extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);

    trial_type = 'Baseline & reach';
    extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);


    trial_type = 'SATCO';
    extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);

    trial_type = 'all';
    extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);
end

close all;
% clc;
disp('Done!');

