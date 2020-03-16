%% Explanation
%This program takes in all of the PSD data as as input. It then computes
%LDA scores for all of the data. Then, it calculates false positive and
%true positive rates for all of the data so that the ROC curves could be
%computed. The final output is an ROC curve.

%Note: If the number of observations is less than the number of
%features, You will get an error somewhere along the lines of - the matrix needs 
%to be positive definite. You will need to perform PCA by uncommenting the
%PCA code. 

%In the future, this should also generate the x highest power interictals, where
%x is the number of ictals. 
%% Program

%Import
input_str = 'P10_FullPSD_176.mat';
out_str = 'P10_BoostedDataInfo';
load(input_str);

%Check out https://www.mathworks.com/help/stats/classify.html
[~,~,~,~,coeff] = classify(PSD_row,PSD_row,State_array);%LDA%First entry is train
%Second is test%In this case, they are the same for simplicity
proj=PSD_row*coeff(1,2).linear;

%Isolation of ictals and high power interictals
n_ictals = length(ictal_indices);
n_high_power_interictals = n_ictals;
proj_no_ictal = proj(interictal_indices);
[sortedproj,unsortedIndices] = sort(proj_no_ictal);
postextracted_high_power_indices = unsortedIndices(1:n_high_power_interictals);
high_power_indices = interictal_indices(postextracted_high_power_indices);
high_power_interictals = PSD_row(high_power_indices,:);
ictals = PSD_row(ictal_indices,:);
boostedPSD_row = zeros((n_ictals+n_high_power_interictals),176);
boostedPSD_row((1:n_ictals),:)=ictals;
boostedPSD_row(((n_ictals+1):(n_ictals+n_high_power_interictals)),:) = high_power_interictals;
boostedIndices = vertcat(ictal_indices,high_power_indices);

save(out_str,'boostedIndices','n_ictals','n_high_power_interictals','-v7.3');





