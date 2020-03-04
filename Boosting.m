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
tic
%Import
input_str = 'P10_FullPSD_176.mat';
load(input_str);

LDA = fitcdiscr(PSD_row,State_array, 'OptimizeHyperparameters', 'auto',...
    'HyperparameterOptimizationOptions',...
    struct('AcquisitionFunctionName','expected-improvement-plus','KFold',5,...
    'UseParallel',true));
disp(1-loss(LDA,PSD_row,State_array));
toc




