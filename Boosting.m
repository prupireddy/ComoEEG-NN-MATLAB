%% Explanation
%This program takes in all of the 176 feature PSD data as an input. It then
%sets up and performs K-Fold Validation on an LDA model (no hyperparameter
%optimization or cost-sensitivity). For each fold, it calculates the TP/FP
%etc. rates. 
%% Program
tic %timer start
%Import
input_str = 'P5_FullPSD_176.mat';
load(input_str);

%number of total ictal, interictal, total observations
n_ictal = length(ictal_indices); %number total ictal
n_interictal = length(interictal_indices); %number total interictal
n_total = n_ictal+n_interictal; %number total total
prior = [n_ictal/n_total, n_interictal/n_total]; %here is a prior vector that you can use as an argument for the model

%Set up 5 fold
cv_type = 'KFold';
n_folds = 5;
%Indices for 5 fold
cvIndices = crossvalind(cv_type,n_total,n_folds);
%Setup matrix to store results of TP,FP,TN,FN respectively
ConfusionMatrix = zeros(n_folds,5);

%PCA
% n_pcomponents = floor(n_total*((n_folds-1)/n_folds))-10; %Calculate the number of principle components
% PSD_row = PSD_row - mean(PSD_row); %Substract off the mean 
% pcacomponents=pca(PSD_row); %pca components stores all of the pca components, in order of eigienvalue magnitude  
% PSD_row = PSD_row*pcacomponents(:,1:n_pcomponents); %Projects data onto PCA space defined by the the number of components from the first line in this section

for i = 1:n_folds
    test = (cvIndices == i); %Find test indices
    train = ~test; %Find train indices
    PSD_row_test = PSD_row(test,:); %Create test input matrix
    PSD_row_train = PSD_row(train,:); %Create train matrix
    State_array_train = State_array(train,:);%Create train output matrix
    [class,err,POSTERIOR,~,coeff] = classify(PSD_row_test,PSD_row_train,State_array_train, 'linear');
    State_array_test = State_array(test,:);%Create test output matrix
    n_ictal_test = nnz(State_array_test);%number of ictals in test 
    n_interictal_test = nnz(~State_array_test);%number of interictals in test
    %Calculating accuracy. In general, this finds where the positive
    %classifications were and the negative classifications were and then
    %checks the ground truth by going to those same indices (1-1
    %correspondence between the order of classifications and true order).
    %It uses this to find how many true positives etc. there are and then
    %divides these results to get the rates.
    PositiveClassificationIndices = find(class); %find positive classifications
    NegativeClassificationIndices = find(~class); %find negative classifications
    TP = nnz(State_array_test(PositiveClassificationIndices));%find number true positives by finding the number of positives in the same indices as positive classifications
    FP = nnz(~State_array_test(PositiveClassificationIndices));%fp same procedure
    FN = nnz(State_array_test(NegativeClassificationIndices));%fn same procedure
    TN = nnz(~State_array_test(NegativeClassificationIndices));%tn same procedure
    %Calculate rates
    TPR = TP/n_ictal_test;
    FPR = FP/n_interictal_test;
    TNR = TN/n_interictal_test;
    FNR = FN/n_ictal_test;
    Accuracy = (TP+TN)/(TP+TN+FN+FP);
    %Assign into the matrix for results
    ConfusionMatrix(i,:) = [TPR,FPR,TNR,FNR,Accuracy];
end 
%Mean of all results 
ConfusionMatrixMean = mean(ConfusionMatrix);
toc %timer end



