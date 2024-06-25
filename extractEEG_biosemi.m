function extractEEG_biosemi(SessionDir, Sess_trialType,trial_type)
% stitch EEG of specifified trial_types, convert to EEGLAB .set file,
% and save to file directory
% Input, SessionDir icnluding file directories
%        Sess_trialType, the trial types for each trial in the session
%       trial_type, the specific trial type to extract EEG, 'reach',
%       'Baseline', 'SATCO', or 'all' which stiches all trials including SACCO ones
% Output: EEGLAB .set structure with trials of the specific types
% stitched together
% Ran Xiao, Emory University, 2/2024
% rev. 05.2024, added SATCO condition.

if strcmp(trial_type, 'all')
    trial_idx = 1:length(SessionDir);
else
    trial_idx = find(contains(Sess_trialType,trial_type,'IgnoreCase',true));
end
disp(trial_idx);

if ~isempty(trial_idx)

    EEG_raw = [];
    for i = 1:length(trial_idx)

        % Construct full path to the data file
        FilePath = fullfile(SessionDir(trial_idx(i)).folder, SessionDir(trial_idx(i)).name);

        % Read the table data from the file
        data = readtable(FilePath);

        % Select 32 channel EEG data, assuming a sample rate (srate) of 2048
        EEGdata = table2array(data(:, 2:33))';

        % Remove timepoints at the end of data showing all NaNs
        indNaN = find(isnan(sum(EEGdata, 1)));
        if ~isempty(indNaN)
            EEGdata(:, indNaN) = [];
        end
        EEG_raw = [EEG_raw EEGdata];
    end

    % Load necessary libraries or toolboxes
    eeglab nogui; % Start EEGLAB if it's not already running

    % Load data into EEGLAB
    EEG = pop_importdata('dataformat', 'array', 'nbchan', 32, 'data', EEG_raw, 'srate', 2048, 'pnts', 0, 'xmin', 0);
    EEG = eeg_checkset(EEG);

    % Load channel file
    EEG = pop_chanedit(EEG, 'lookup', './Dependencies/BioSemi_32Ch.ced', 'load', {'./Dependencies/BioSemi_32Ch.ced', 'filetype', 'autodetect'});
    EEG = eeg_checkset(EEG);

    % Re-reference to T7-T8
    EEG = pop_reref(EEG, [7, 24], 'keepref', 'on');
    EEG = eeg_checkset(EEG);
    
    % Define the regular expression for extracting patterns like TD08 or Mon4
    pattern = 'TD\d+|Mon\d+';
    
    % Use regexp to find matches to get the participant name and session
    % month
    matches = regexp(SessionDir(trial_idx(i)).folder, pattern, 'match');

    % save data into EEGLab .set format
    EEG = pop_saveset( EEG, 'filename',[matches{1},'_', matches{2},'_', trial_type, '.set'],'filepath',SessionDir(trial_idx(i)).folder);
end
end