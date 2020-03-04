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
input_str = 'P5_FullPSD_176.mat';
load(input_str);

n_ictal = length(ictal_indices);
n_interictal = length(interictal_indices);
n_total = n_ictal+n_interictal;
prior = [n_ictal/n_total, n_interictal/n_total];

cv_type = 'KFold';
n_folds = 5;
cvIndices = crossvalind(cv_type,n_total,n_folds);
ConfusionMatrix = zeros(n_folds,5);

%PCA
% n_pcomponents = floor(n_total*((n_folds-1)/n_folds))-10; %Calculate the number of principle components
% PSD_row = PSD_row - mean(PSD_row); %Substract off the mean 
% pcacomponents=pca(PSD_row); %pca components stores all of the pca components, in order of eigienvalue magnitude  
% PSD_row = PSD_row*pcacomponents(:,1:n_pcomponents); %Projects data onto PCA space defined by the the number of components from the first line in this section

for i = 1:n_folds
    test = (cvIndices == i); 
    train = ~test;
    PSD_row_test = PSD_row(test,:);
    PSD_row_train = PSD_row(train,:);
    State_array_train = State_array(train,:);
    [class,err,POSTERIOR,~,coeff] = classify(PSD_row_test,PSD_row_train,State_array_train, 'linear');
    State_array_test = State_array(test,:);
    n_ictal_test = nnz(State_array_test);
    n_interictal_test = nnz(~State_array_test); 
    %Calculating accuracy 
    PositiveClassificationIndices = find(class);
    NegativeClassificationIndices = find(~class);
    TP = nnz(State_array_test(PositiveClassificationIndices));
    FP = nnz(~State_array_test(PositiveClassificationIndices));
    FN = nnz(State_array_test(NegativeClassificationIndices));
    TN = nnz(~State_array_test(NegativeClassificationIndices));
    TPR = TP/n_ictal_test;
    FPR = FP/n_interictal_test;
    TNR = TN/n_interictal_test;
    FNR = FN/n_ictal_test;
    Accuracy = (TP+TN)/(TP+TN+FN+FP);
    ConfusionMatrix(i,:) = [TPR,FPR,TNR,FNR,Accuracy];
end 
ConfusionMatrixMean = mean(ConfusionMatrix);
toc



