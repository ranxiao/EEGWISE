function  [chan2plot]=getchanloc(chan2plot)
% removing T3 and T4 from channel labels as they cause errors
% EEGchanslabels = {'Fp1';'AF3';'F7';'F3';'FC1';'FC5';'T7(T3)';'C3';'CP1';'CP5';'P7';'P3';'Pz';'PO3';'O1';'Oz';'O2';'PO4';'P4';'P8';'CP6';'CP2';'C4';'T8(T4)';'FC6';'FC2';'F4';'F8';'AF4';'Fp2';'Fz';'Cz'};
EEGchanslabels = {'Fp1';'AF3';'F7';'F3';'FC1';'FC5';'T7';'C3';'CP1';'CP5';'P7';'P3';'Pz';'PO3';'O1';'Oz';'O2';'PO4';'P4';'P8';'CP6';'CP2';'C4';'T8';'FC6';'FC2';'F4';'F8';'AF4';'Fp2';'Fz';'Cz'};

chanidx = strcmpi(EEGchanslabels,chan2plot);
chan2plot = find(chanidx==1);

end


