function [] = AnalyzeEEG(app)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%% Initialize directories
addpath(genpath('./Dependencies/'));
DataDir = app.DatadirectoryEditField.Value;
dataFolderDir = strsplit(DataDir,filesep);
ResultDir = [app.ResultdirectoryEditField.Value dataFolderDir{end-1} '_results/'];

if ~exist(ResultDir,'dir')
    mkdir(ResultDir);
end

% get all .set data files in the folder and process one by one
MyFolderInfo = dir(strcat(DataDir,'*.set'));

% create an empty table for generating report
if strcmp(app.GenerateReportSwitch.Value, 'Yes')
    if exist(strcat(ResultDir,'Analysis_Report.mat'))
        Report_tb = load(strcat(ResultDir,'Analysis_Report.mat'));
        Report_tb = Report_tb.Report_tb;
    else
        Report_tb = table('Size',[0 21],'VariableNames', {'File Name','NoChannel','Filter_Lo_Hi_Notch_SampRate', 'Original Duration','ASR thres','Bad Segment Boundaries','Remaining Duration','Perc_rej_dur','Kurtosis thres','Bad Channels','Perc_rej_ch','CAR','ICA Algorithm','ICA Parameters','ICA Labeling','Artifact IC','Prob_artficat','Prob_thres','IC Rejection Ratio','mean Brain IC prob','Residual Variance'},...
            'VariableTypes',{'string','double','string','double','double','string','double','double','double','string','string','string','string','string','string','string','string','double','double','double','double'});
    end
end
if isempty(MyFolderInfo)
    disp('No files found. Please check the patient name and file directory.');
else
    for i_file = 1:size(MyFolderInfo,1)
        % load .set data
        FileName = MyFolderInfo(i_file).name;
        EEG = pop_loadset('filename',FileName,'filepath',DataDir);

        %% Step 1. Filtering
        % resample to a preset sampling rate
        EEG = pop_resample( EEG, app.ResampingHzEditField.Value);
        EEG = eeg_checkset( EEG );

        % bandpass filtering
        EEG = pop_eegfiltnew(EEG, 'locutoff',app.LowcutofffreqHzEditField.Value,'hicutoff',app.HighcutofffreqHzEditField.Value);
        EEG = eeg_checkset( EEG );

        % notch filtering
        if app.NotchHzDropDown.Value <= app.HighcutofffreqHzEditField.Value
            EEG = pop_eegfiltnew(EEG, 'locutoff',app.NotchHzDropDown.Value-1,'hicutoff',app.NotchHzDropDown.Value+1,'revfilt',1);
            EEG = eeg_checkset( EEG );
        end

        % plot EEG after the step
        pop_eegplot( EEG, 1, 1, 1);
        saveas(gcf,strcat(ResultDir,[FileName(1:end-4) '_Step1.jpg']));
        eeglab redraw;

        % Save checkpoint set after each step
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',[FileName(1:end-4) '_Step1.set'],'filepath',ResultDir);
        EEG = eeg_checkset( EEG );
        close all;
        % update report
        if strcmp(app.GenerateReportSwitch.Value, 'Yes')
            Report_tb.("File Name"){i_file} =  FileName(1:end-4);
            Report_tb.("NoChannel")(i_file) =  (EEG.nbchan);
            Report_tb.("Filter_Lo_Hi_Notch_SampRate"){i_file} = strcat(num2str(app.LowcutofffreqHzEditField.Value),', ', num2str(app.HighcutofffreqHzEditField.Value), ', ', num2str(app.NotchHzDropDown.Value), ', ', num2str(app.ResampingHzEditField.Value));
            Report_tb.("Original Duration")(i_file) = (EEG.xmax);
        end

        %% Step 2. Bad EEG segment rejection
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',num2str(app.ThresholdEditField_3.Value),'WindowCriterion','off','BurstRejection','on','Distance','Euclidian');
        eeglab redraw;
        BadSeg_bound = EEG.event;
        BadSeg_bound_dur = sum([BadSeg_bound.duration;])/EEG.srate;

        if app.AutomaticVisualButton_2.Value==1
            pop_eegplot( EEG, 1, 1, 1);
            f = msgbox("Select bad segments by dragging, then hit any key in the Command Window in MATLAB to continue");
            pause;

            %% Mark and reject segments with large fluctuations
            % (GUI operation needed: 1. Mark segments; 2. Run code block; 3. Click reject button)
            % Tip: Set window length as 20 sec to select bad segments
            g = get(gcf, 'userdata');
            try
                BadSeg_manu = int64(g.winrej(:,[1 2]));
            catch
                BadSeg_manu = [];
            end

            if ~isempty(BadSeg_manu)
                BadSeg_manu_cell = [];
                for i_manu = 1:size(BadSeg_manu,1)
                    BadSeg_manu_cell= [BadSeg_manu_cell; {'Boundary_manual',BadSeg_manu(i_manu,1),BadSeg_manu(i_manu,2)-BadSeg_manu(i_manu,1)}];
                    EEG.data(:,BadSeg_manu(i_manu,1):BadSeg_manu(i_manu,2)) = [];
                end
                BadSeg_manu_struct = cell2struct(BadSeg_manu_cell, fieldnames(BadSeg_bound)', 2)';
                BadSeg_bound = [BadSeg_bound BadSeg_manu_struct];
                BadSeg_bound_dur = sum([BadSeg_bound.duration;])/EEG.srate;

                EEG = eeg_checkset( EEG );
                eeglab redraw;
            end
        end

        % plot EEG after the step
        pop_eegplot( EEG, 1, 1, 1);
        saveas(gcf,strcat(ResultDir,[FileName(1:end-4) '_Step2.jpg']));
        eeglab redraw;
        close all;

        % Save checkpoint set after each step
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',[FileName(1:end-4) '_Step2.set'],'filepath',ResultDir);
        EEG = eeg_checkset( EEG );

        % update report
        if strcmp(app.GenerateReportSwitch.Value, 'Yes')
            Report_tb.("ASR thres")(i_file) =  (app.ThresholdEditField_3.Value);
            Report_tb.("Bad Segment Boundaries"){i_file} =  jsonencode(BadSeg_bound, "PrettyPrint", true);
            Report_tb.("Remaining Duration")(i_file) =  (EEG.xmax);
            Report_tb.("Perc_rej_dur")(i_file) =  (Report_tb.("Original Duration")(i_file)-Report_tb.("Remaining Duration")(i_file))/Report_tb.("Original Duration")(i_file);

        end

        %% Step 3. Bad channel rejection and interpolation
        % 1. Channel rejection by calculating Kurtosis index and reject if exceeding 5
        chanlocs = EEG.chanlocs; % will need to use the channel location to interpolate back to original channel number
        EEG = pop_rejchan(EEG ,'threshold',app.ThresholdEditField.Value,'norm','on','measure','kurt');
        EEG = eeg_checkset( EEG );
        if ~isempty(EEG.chaninfo.removedchans)
            BadCh = [EEG.chaninfo.removedchans.urchan;];
        else
            BadCh = [];
        end
        % 2. Interpolate bad channels by surrounding channels
        EEG = pop_interp(EEG, chanlocs, 'spherical');
        EEG = eeg_checkset( EEG );

        % comparing across channel, remove those presenting large
        % fluctuations with variance outside of 3STD of all channels
        data_var = var(EEG.data,[],2);
        [BadCh_STD,~] = find(data_var>(mean(data_var)+std(data_var)*3)|data_var<(mean(data_var)-std(data_var)*3)|data_var ==0);
        if ~isempty(BadCh_STD)
            EEG = pop_interp(EEG, BadCh_STD, 'spherical');
            BadCh = unique([BadCh BadCh_STD']);
        end


        if app.AutomaticVisualButton.Value==1
            pop_eegplot( EEG, 1, 1, 1);
            f = msgbox("Type in bad channel indices (or leave it blank) in the textbox, then hit any key in the Command Window to continue. ");
            pause;

            % (OPTIONAL)Visual inspection as a secondary approach to identify addional ones
            % Caution: Use Channel Number, instead of channel labels!
            prompt = {'Enter indices for bad channels'};
            dlg_title = 'Visual selection';
            Inputs = inputdlg(prompt,dlg_title,[1 32]);
            BadCh_Visual= str2num(Inputs{:});
            EEG = pop_interp(EEG, BadCh_Visual, 'spherical');
            EEG = eeg_checkset( EEG );
            BadCh = unique([BadCh BadCh_Visual]);

        end

        % Spatial filtering through common average reference
        if strcmp(app.Switch_3.Value, 'Yes')
            EEG = pop_reref( EEG, []);
            EEG = eeg_checkset( EEG );
        end

        % plot EEG after the step
        pop_eegplot( EEG, 1, 1, 1);
        saveas(gcf,strcat(ResultDir,[FileName(1:end-4) '_Step3.jpg']));
        eeglab redraw;
        close all;

        % Save checkpoint set after each step
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',[FileName(1:end-4) '_Step3.set'],'filepath',ResultDir);
        EEG = eeg_checkset( EEG );

        % update report
        if strcmp(app.GenerateReportSwitch.Value, 'Yes')
            Report_tb.("Kurtosis thres")(i_file) =  (app.ThresholdEditField.Value);
            Report_tb.("Bad Channels"){i_file} =  num2str(BadCh);
            Report_tb.("Perc_rej_ch")(i_file) =  (length(BadCh)/EEG.nbchan);
            Report_tb.("CAR"){i_file} =  app.Switch_3.Value;
        end
        %% Step 4. Independent component analysis
        % 1. Run ICA with PCA to tackle lost rank
        dataRank = rank(EEG.data);
        EEG = eeg_checkset( EEG );

        ICA_method = app.ICADropDown.Value;
        switch ICA_method
            case 'RUNICA'
%                 EEG = pop_runica_rx(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','pca',dataRank, 'lrate', app.LREditField.Value,'maxsteps',app.MaxStepsEditField.Value);
                EEG = pop_runica_rx(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','pca',dataRank, 'lrate',app.RunicaSettings.lrate,'maxsteps',app.RunicaSettings.maxSteps);
                
            case 'AMICA'
%                 EEG = pop_runamica(EEG, 'maxiter', 10, 'max_threads', 4);
                EEG = pop_runamica(EEG, 'lrate',app.AmicaSettings.lrate , 'maxiter', app.AmicaSettings.maxiter,...
                    'num_models', app.AmicaSettings.num_models, 'num_mix_comps', app.AmicaSettings.num_mix_comps, 'numprocs',app.AmicaSettings.numprocs,'max_threads', app.AmicaSettings.max_threads);

        end

        EEG = eeg_checkset( EEG );

        % calcualte IC variance of the components
        IC_meanvar = sum(EEG.icawinv.^2).*sum(transpose((EEG.icaweights *  EEG.icasphere)*EEG.data(EEG.icachansind,:)).^2)/((length(EEG.icachansind)*EEG.pnts)-1);

        % label ICs with probability of artefacts.
        ICA_labeling_method = app.DropDown.Value;
        switch ICA_labeling_method
            case 'MARA'
                [artcomps, info] = MARA(EEG);
                p_art = info.posterior_artefactprob;
            case 'iMARA' % based on iMara description " if probability of comoponent being artefact is greater than 0.9 then
                % the classfier marks as neural if less than 0.9 marks as artefact
                % other studies may wish to change these
                % cutoffs", info.posterior_artefactprob is the probability of being
                % neural component, so p_art = 1-info.posterior_artefactprob;
                [artcomps,info] = iMARA(EEG);
                p_art = info.posterior_artefactprob;
            case 'ICLabels'
                % run automatic IC labeling
                EEG = pop_iclabel(EEG, 'default');
                p_art = EEG.etc.ic_classification.ICLabel.classifications(:,1);
        end
        

        IC_Reject_Ratio = [];
        mean_P_brain = [];

        if app.ProbThresholdforArtICEditField.Value ==0

            % ROC analysis by calculating IC rejection ratio (ICRR) and mean IC
            % brain probability (mBCP)
            p_art_thre_range = 0:0.01:1;
            for i_thres = 0:0.01:1%min(p_art):0.001:max(p_art)
                IC_Reject_Ratio = [IC_Reject_Ratio sum(p_art>=i_thres)/length(p_art)];
                if isempty(p_art(p_art<i_thres))
                    mean_P_brain = [mean_P_brain 1]; % if all ICs are rejected, which is extreme case, then remaining IC is considered as 1
                else
                    mean_P_brain = [mean_P_brain mean(1-p_art(p_art<i_thres))];
                end
            end
    
            % rescale both variables to find optimal P_art threshold and find optimal threshold
            IC_Reject_Ratio_rs = normalize(IC_Reject_Ratio,'range');
            mean_P_brain_rs = normalize(mean_P_brain,'range');
            % caculate eclidean dist between points from each threshold and top
            % left corner, shortest one corresponds to optimal operating point
            edist = zeros(length(IC_Reject_Ratio_rs),1);
            for i_thres = 1: length(IC_Reject_Ratio_rs)
                edist(i_thres) = pdist([[IC_Reject_Ratio_rs(i_thres) mean_P_brain_rs(i_thres)];[0 1]],'euclidean');
            end
            [minDist,OPind]= min(edist);
   
            % set a floor for minimal artifact threshold should be based on the minimal mean_P_brain of 0.8, the
            % smaller of the p_art threshold, the stricter algorithm
            % select brain IC, and the better signal quality of remaining
            % brain ICs
            if mean_P_brain(OPind)<0.8
                ind_temp = find(mean_P_brain>=0.8);
                OPind = ind_temp(end);                
            end

            p_thres= p_art_thre_range(OPind);
        else
            p_thres = app.ProbThresholdforArtICEditField.Value;
        end

        % bad IC criteria: non-brain pattern with probability over p_thres
        BadIC = find(p_art>=p_thres);

        figure;
        subplot(1,2,1);
        plot(edist);
        hold on;
        plot(OPind,edist(OPind),'r*');
        text(OPind,edist(OPind),['artifact prob threshold is ' num2str(p_thres)]);
        hold off;
        xlabel('Operating point selection based on shortest distance');
        ylabel('Distance to optima (shorter the better)');

        subplot(1,2,2);
        plot(IC_Reject_Ratio,mean_P_brain,'-o');
        xlabel('IC rejection ratio (ICRR)');
        ylabel('Mean Brain Component Probability (mBCP)');
        hold on;
        plot(IC_Reject_Ratio(OPind),mean_P_brain(OPind),'r*');
        text(IC_Reject_Ratio(OPind),mean_P_brain(OPind),['ICRR is ',num2str(IC_Reject_Ratio(OPind)), ', and mBCP is ',num2str(mean_P_brain(OPind))]);
        hold off;
        set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.

        saveas(gcf,strcat(ResultDir,[FileName(1:end-4) '_Step4_OptimalThres.jpg']));
        close all;

        % plot IC topography and save figure and data before ICA
        pop_topoplot(EEG, 0, [1:size(EEG.icaweights,1)]);
        saveas(gcf,strcat(ResultDir,[FileName(1:end-4) '_Step4_ICATopo.jpg']));
        close all;

        % pop_selectcomps(EEG, [1:dataRank] );
        % 2. Save ICA results and EEG data before rejection for later reference
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',[FileName '_Step4_BeforeICARej.set'],'filepath',ResultDir);

        % hybrid mode with visual artifactual IC selection
        if app.AutomaticVisualButton_3.Value==1
            f = msgbox("Type in artifact IC indices (or leave it blank) in the textbox, then hit any key in the Command Window to continue. ");
            pause;

            prompt = {'Enter indices for '};
            dlg_title = 'Visual selection';
            Inputs = inputdlg(prompt,dlg_title,[1 32]);
            BadIC_Visual= str2num(Inputs{:});
            BadIC = unique([BadIC BadIC_Visual]);
        end

        % remove bad ICs and save data
        EEG = pop_subcomp( EEG, BadIC, 0);
        EEG = eeg_checkset( EEG );
        pop_eegplot( EEG, 1, 1, 1);
        saveas(gcf,strcat(ResultDir,[FileName(1:end-4) '_Step4_AfterICARej.jpg']));
        close all;

        % Save EEG data after bad IC rejection
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',[FileName '_Step4_AfterICARej.set'],'filepath',ResultDir);
        EEG = eeg_checkset( EEG );

        % update report
        if strcmp(app.GenerateReportSwitch.Value, 'Yes')
            Report_tb.("ICA Algorithm"){i_file} = ICA_method;
            Report_tb.("ICA Parameters"){i_file} = jsonencode(app.CurrentICASettings);            
            Report_tb.("ICA Labeling"){i_file} =  app.DropDown.Value;
            Report_tb.("Artifact IC"){i_file} =  num2str(BadIC);
            Report_tb.("Prob_artficat"){i_file} =  num2str(p_art);
            Report_tb.("Prob_thres")(i_file) =  p_thres;
            Report_tb.("IC Rejection Ratio")(i_file) =  IC_Reject_Ratio(OPind);
            Report_tb.("mean Brain IC prob")(i_file) =  mean_P_brain(OPind);
            Report_tb.("Residual Variance")(i_file) =  (sum(IC_meanvar)-sum(IC_meanvar(BadIC)))/sum(IC_meanvar);
        end

        %% Perform Spectral analysis
        if strcmp(app.Switch_4.Value, 'Yes')
            Data = EEG.data;
            ChanLabel = {EEG.chanlocs.labels;};

            % Calculate spectral powers using Pwelch
            Sampling = EEG.srate;
            Win = 2;
            Nfft = Win*Sampling;
            Overlap = 0.5*Nfft;
            NoCh = size(Data,1);
            Power = zeros(NoCh, Sampling/2*Win+1);
            RelPower = zeros(NoCh, Sampling/2*Win+1);
            for i_ch = 1:1:NoCh
                [pxx,f] = pwelch(Data(i_ch,:),hann(Nfft),Overlap,Nfft,Sampling);
                Power(i_ch,:) = pxx;
                RelPower(i_ch,:)=pxx/sum(pxx(1:find(f==30)));
            end
            save(strcat(ResultDir,FileName,'_Step4_Pw.mat'), 'Power','f');
            save(strcat(ResultDir,FileName,'_Step4_RelPw.mat'),'RelPower','f');

            figure;
            h=plot(f,RelPower');
            xlim([0 30]);
            ylim([0 0.1]);
            xlabel('Frequency');
            ylabel('Relative Power');
            title([FileName(1:end-4) ' Relative Power'],'Interpreter','none');
            set(h, {'color'}, num2cell(jet(NoCh), 2));
            legend(ChanLabel{:});
            set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
            saveas(gcf,[ResultDir FileName '_Step4_RelPower' '.jpg']);
            close all;

        end

        % backup report table after each file in case error occurs
        if strcmp(app.GenerateReportSwitch.Value, 'Yes')
            save(strcat(ResultDir,'Analysis_Report.mat'),'Report_tb')
        end

        close all; clc;
        clear ALLCOM ALLEEG EEGdata EEG;
    end
end

% save analysis report
if strcmp(app.GenerateReportSwitch.Value, 'Yes')
    writetable(Report_tb,strcat(ResultDir,'Analysis_Report.csv'));
end
disp('Calculation done!')
end