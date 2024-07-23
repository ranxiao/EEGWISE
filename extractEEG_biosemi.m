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
elseif strcmp(trial_type, 'Baseline & reach')
    trial_idx = find(contains(Sess_trialType,{'Baseline','reach'},'IgnoreCase',true));
else
    trial_idx = find(contains(Sess_trialType,trial_type,'IgnoreCase',true));
end
% disp(trial_idx);

if ~isempty(trial_idx)
    
    EEG_raw = [];
    timing_info = table();
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

        %construction original time table for later reference
        timing_info.type{i} = Sess_trialType{trial_idx(i)};
        timing_info.fid(i) = trial_idx(i);% the index of files
        
        % Open the file
        fileID = fopen(FilePath, 'r');
        % Read the file contents
        fileContents = fread(fileID, '*char')';
        fclose(fileID);
        
        % Define the regular expression pattern to match the date and time stamp
        patternDate = '\d{1,2}-\d{1,2}-\d{4}'; % Pattern for date in the format 'D-M-YYYY' or 'DD-MM-YYYY'
        patternTime = '\d{2}:\d{2}:\d{2}:\d{3}'; % Pattern for time in the format 'HH:MM:SS:FFF'
        
        % Extract the date and time using the defined patterns
        dateMatch = regexp(fileContents, patternDate, 'match');
        timeMatch = regexp(fileContents, patternTime, 'match');
        
        % Combine the date and time into a single datetime string
        datetimeString = sprintf('%s %s', dateMatch{1}, timeMatch{1});
        
        % Convert the datetime string to a MATLAB datetime object
        dateTime = datetime(datetimeString, 'InputFormat', 'd-M-yyyy HH:mm:ss:SSS');

        timing_info.startDT(i) = dateTime;
        if i == 1
            timing_info.sid_start(i) = 1;% the starting index of samples
            timing_info.sid_end(i) = size(EEGdata,2);% the starting index of samples
        else
            timing_info.sid_start(i) = timing_info.sid_end(i-1)+1;% the starting index of samples
            timing_info.sid_end(i) = timing_info.sid_end(i-1)+size(EEGdata,2);% the starting index of samples
        end

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
    % save the timing info, including the original trial type, trial id,
    % and the sample start and end sample index for each trial (2048 hz)
    save(fullfile('C:\Users\rxiao27\Documents\GitHub\EEGWISE\SampleData\TD40\Mon5',[matches{1},'_', matches{2},'_', trial_type, '_ori_timing_info.mat']),'timing_info');
end
end