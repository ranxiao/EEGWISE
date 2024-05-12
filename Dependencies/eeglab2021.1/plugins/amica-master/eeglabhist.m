% EEGLAB history file generated on the 11-May-2024
% ------------------------------------------------
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','Activity1 - 2048Hz_export_EEG_2cameras_OPAL.set','filepath','C:\\Users\\rxiao27\\Documents\\MATLAB\\infantMotor\\Data\\Demo1_Automatic\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = pop_loadset('filename','Memorize.set','filepath','C:\\Users\\rxiao27\\Documents\\MATLAB\\infantMotor\\EEGWISE\\Dependencies\\eeglab2021.1\\plugins\\amica-master\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
pop_saveh( EEG.history, 'eeglabhist.m', 'C:\Users\rxiao27\Documents\MATLAB\infantMotor\EEGWISE\Dependencies\eeglab2021.1\plugins\amica-master\');
pop_saveh( ALLCOM, 'eeglabhist.m', 'C:\Users\rxiao27\Documents\MATLAB\infantMotor\EEGWISE\Dependencies\eeglab2021.1\plugins\amica-master\');
pop_saveh( EEG.history, 'eeglabhist.m', 'C:\Users\rxiao27\Documents\MATLAB\infantMotor\EEGWISE\Dependencies\eeglab2021.1\plugins\amica-master\');
eeglab redraw;
