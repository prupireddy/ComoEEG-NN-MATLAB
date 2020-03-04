%% Explanation
%This program takes in all of the 176 feature PSD data as an input. It then
%sets up trains a hyperparameter optimized (Bayesian optimized and K-Fold 
%validated), Parallel Processing-sped up LDA. 
%% Program
tic %start timer
%Import
input_str = 'P10_FullPSD_176.mat';
load(input_str);

%So the arguments in LDA occur in pairs. The first is the name, the second
%is the value. The first pair is input output. The second pair tells us to
%optimize the auto hyperparameters - delta and gamma - the third pair tells us how to
%optimize them with subpairs in struct: using Bayesian optimization, 5-fold validation
%and parallel processing, in that order.
LDA = fitcdiscr(PSD_row,State_array, 'OptimizeHyperparameters', 'auto',... 
    'HyperparameterOptimizationOptions',...
    struct('AcquisitionFunctionName','expected-improvement-plus','KFold',5,...
    'UseParallel',true));

disp(1-loss(LDA,PSD_row,State_array)); %validation accuracy
toc %end timer




