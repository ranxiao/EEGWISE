%% -----------------------------------------------------------------------
% DEFINE BT, and BC
%
% This script sets parameters to provide to eega_tDefBTBC to define what is
% a bat time segment (BT) and what is a bad channel (BC) on epoched data
%
% Ana Fló, December 2022
%
% ------------------------------------------------------------------------

function P =  ex2_Perp_DefBTBC

% Limits for the proportion of BT to define a BC (the last value is the final/effective one)
P.BCall.nbt         = [0.70 0.50 0.30 0.30];
P.BCep.nbt          = [0.70 0.50 0.30 0.10];   
% Limits for the proportion of BC to define a BT (the last value is the final/effective one)
P.BT.nbc            = [0.70 0.50 0.30 0.30];
% Shorter intervals between bad segments will be marked as bad
P.BT.minGoodTime    = 1.000;
% Shorter periods will not be considered as bad
P.BT.minBadTime     = 0.100;   
% Also mark as bad surronding samples within this value 
P.BT.maskTime       = 0;  

end
