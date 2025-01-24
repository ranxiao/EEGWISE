   % Prepare data by converting into .set format from EEGLab as the input
% format for the toolbox
% Ran Xiao, Emory University, 2/12/2023
% revise for trial stitching across different trial conditions 2/8/2024
% added SATCO condition, and improve file structure 05.2024

%% Initialize directories
addpath(genpath('./Dependencies/'));

% this is where is data are on your computer
DataDir = 'C:/Users/rxiao27/OneDrive - Emory/DataBackup/Infant Development/Reach_R01/';
trialInfo = readtable(strcat(DataDir,'TrialNote_EEGreachingStudy.xlsx'));

% modify the participant and visit session for analysis
Pat = 'TD06';

% List all files and folders in the directory
PatDir = dir(fullfile(DataDir, Pat)); % Using fullfile for safer path handling
% Remove "." and ".." entries (ignore hidden folders)
PatDir = PatDir(~ismember({PatDir.name}, {'.', '..'}));

if isempty(PatDir)
    print('No monthly folders found for the patient. Please check the patient name and file directory.');
else
    for i = 1:size(PatDir,1) % loop through each Monthly folder for the participant
        SessionDir = dir(strcat(PatDir(i).folder,'\',PatDir(i).name,'\*.txt'));

        if isempty(SessionDir)
            print('No files found. Please check the patient name and file directory.');
            continue;
        else
            % get trial indices in SessionDir
            Sess_trialIdx = cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')),{SessionDir.name},'UniformOutput',false);
            Sess_trialIdx = cell2mat(Sess_trialIdx);
        
            % reorder session files in the file directory, in some systems trial10 might rank higher than trial 2, 3, etc. 
            [~,ind_asc] = sort(Sess_trialIdx);
            SessionDir_asc = SessionDir(ind_asc);
        
            % find rows in trialInfo that match the patient and visit
            ind = find(strcmp(trialInfo.ParticipantID,Pat) & (trialInfo.Month==str2num(PatDir(i).name(end))));
            % get the trial info for the patient and visit
            Sess_trialInfo = trialInfo(ind,[4 5]);
            [~,ind_asc2] = sort(Sess_trialInfo.Activity);% making sure Sess_trialInfo from excel file is ordered in ascending order
            Sess_trialInfo = Sess_trialInfo(ind_asc2,:);
        
            % get trial types for trialInd that match trialType.Activity, 
            Sess_trialType = Sess_trialInfo.TrialType(ismember(Sess_trialIdx,Sess_trialInfo.Activity));
        
            % uncomment trial type of interest
        
        %     trial_type = 'Baseline';
        %     extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);
        % 
        %     trial_type = 'reach';
        %     extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);
        % 
            trial_type = 'Baseline & reach';
            extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);
        % 
        % 
        %     trial_type = 'SATCO';
        %     extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);
        % 
        %     trial_type = 'all';
        %     extractEEG_biosemi(SessionDir_asc,Sess_trialType,trial_type);
        end
    end
end
close all;
% clc;
disp('Done!');

