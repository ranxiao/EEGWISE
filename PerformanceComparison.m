load '../Results/month1_results/Analysis_Report.mat';


prob_art_allIC = (Report_tb.Prob_artficat);
p_art_thres = 0.9;
IC_Reject_Ratio_p9 = [];
mean_P_brain_p9 = [];
for i = 1:length(prob_art_allIC)
    prob_art_trial= str2double(split(prob_art_allIC(i)));
    IC_Reject_Ratio_p9 = [IC_Reject_Ratio_p9 sum(prob_art_trial>=p_art_thres)/length(prob_art_trial)];
    mean_P_brain_p9 = [mean_P_brain_p9 mean(1-prob_art_trial(prob_art_trial<p_art_thres))];
end

figure;
x = 1:2;
data = [mean(mean_P_brain_p9) mean(Report_tb.("mean Brain IC prob")) ]';
errhigh = [std(mean_P_brain_p9) std(Report_tb.("mean Brain IC prob")) ];
errlow  = errhigh;
bar(x,data)                
hold on
er = errorbar(x,data,errlow,errhigh);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
hold off
xticklabels({'Default threshold (0.9)','EEGWISE'})
ax = gca;
ax.XGrid = 'off';
ax.YGrid = 'on';
ylabel('Mean Brain IC Probability (mBICP)');

[h,p]=ttest2(mean_P_brain_p9,Report_tb.("mean Brain IC prob")); 

figure;
bar(Report_tb.("mean Brain IC prob"));
hold on;
yline(mean(Report_tb.("mean Brain IC prob")),'r-','mean');
yline(mean(Report_tb.("mean Brain IC prob"))-std(Report_tb.("mean Brain IC prob")),'r--','std');
hold off;
xlabel('Individual trials');
ylabel('Mean Brain IC Probability (mBICP)');

figure;
bar(Report_tb.Prob_thres);
hold on;
yline(0.9,'r-','Default threshold');
hold off;
xlabel('Individual trials');
ylabel('Artifact probability threshold');