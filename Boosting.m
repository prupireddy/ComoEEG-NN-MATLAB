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
input_str = 'P10_FullPSD.mat';
load(input_str);

n_ictal = length(ictal_indices);
n_interictal = length(interictal_indices);
n_total = n_ictal+n_interictal;

%PCA
% n_pcomponents = n_total-10; %Calculate the number of principle components
% PSD_row = PSD_row - mean(PSD_row); %Substract off the mean 
% pcacomponents=pca(PSD_row); %pca components stores all of the pca components, in order of eigienvalue magnitude  
% PSD_row = PSD_row*pcacomponents(:,1:n_pcomponents); %Projects data onto PCA space defined by the the number of components from the first line in this section


%Commented out prior vector - to be used with commented out prior vector
%LDA code below
%prior = [n_ictal/n_total, n_interictal/n_total];
%prior = char(prior);


cv_type = 'KFold';
n_folds = 5;

cvIndices = crossvalind(cv_type,n_total,n_folds);
for i = 1:n_folds
    test = (indices == i); 
    train = ~test;
    PSD_row_test = PSD_row(test,:);
    PSD_row_train = PSD_row(train,:);
    State_array_train = State_array(train,:);
    %First is without prior vector. Second is with prior vector. 
    [~,~,~,~,coeff] = classify(PSD_row_test,PSD_row_train,State_array_train);%LDA%First entry is test
    %Second is train. Third is labels for training set. 
    %[~,~,~,~,coeff] = classify(PSD_row_test,PSD_row_train,State_array_train,'linear',prior);%LDA%First entry is test
    %Second is train. Third is labels for training set. This allows you to put in the prior vector. 
    proj=PSD_row*coeff(1,2).linear;%Creates 1 dimensional score for likelihood into
    %class 2 (ictal). Normally, when you add on the constant term for the boundary
    %line (the linear term is the slope), if your final
    %result is positive, it is class 1 (interical). If it negative, you get class 2 
    %(ictal). This is matrix multipication - you are projecting the data on the
    %one dimensional line defined by coeff. The reason we don't really care about the true value when added
    %by X is because we care about the relative positions of the LDA
    %transformed points - as this will be used to generate thresholds for ROC
    %analysis. 

    %This sections sorts the LDA results in descending fashion. The program will then
    %iterate over each of the LDA scores, in descending, using each as a
    %threshold. For each threshold, it will iterate over each point again,
    %wherein the points under the threshold are ictal and the points over are interictal.  Whenever it encounters 
    %a positive point, it counts it as either a false positive or false
    %negative. Once it goes through comparing all points, it calculates false
    %positive and true positive rates. Once you go through all of the
    %thresholds, you calculate an ROC curve based on the false positive and
    %true positive rates at each threshold. 

    [thresholds,original]=sort(proj,'descend'); %sort projections in a descending fashion to make them thresholds
    roc=zeros(length(proj),2); %to store fpr and tpr rates, in order
    for k=1:length(proj) %iterating over each of the thresholds
        countTP=0;
        countFP=0;
        currentLabels=zeros(length(proj),1);
        for i=1:length(proj) %over all points for that threshold 
            if proj(i)<=thresholds(k)%if the point passes as ictal
                currentLabels(i)=1;%set label as ictal - default is 0 - interictal
                if State_array(i) == 1 %if true state is positive, add 1 to true count
                    countTP = countTP + 1;
                elseif State_array(i) == 0 %if true state is negative, add 1 to false positive count
                    countFP = countFP + 1;
                end
            end
        end
        roc(k,1)=countFP/(length(interictal_indices)); %Calculate false positive rate after going through all points
        roc(k,2)=countTP/(length(ictal_indices)); % ditto for true positive rate
    end
end


%% Plot ROC curve
figure
plot(roc(:,1),roc(:,2)) %plot roc curve with x values as false positives and y values as true positives
xlabel('False Positive Rate')
ylabel('True Positive Rate')
title('ROC Curve of All Data Projected After LDA')
hold on
plot(linspace(0,1,length(State_array)),linspace(0,1,length(State_array))) %plot naive classifier
%% Determine indices of Data that passes the Threshold Set by the LDA 
%  projection ROC

% bestThreshold=thresholds(16380);
% 
% count=0;
% for i = 1:length(proj)
%     if proj(i)>bestThreshold
%         count=count+1;
%     end
% end
% 
% postLDAind=zeros(count,1);
% for i = 1:length(proj)
%     if proj(i)<bestThreshold
%         postLDAind(i)=i;
%     end
% end
% postLDAind=find(postLDAind);
% 
% %% Create Data and Label Arrays for Observations that passed the threshold
% 
% postLdaData=zeros(length(postLDAind),128);
% for i = 1:length(postLDAind)
%     postLdaData(i,:)=allData(postLDAind(i),:);
% end
% 
% postLdaLabels=zeros(length(postLDAind),1);
% for i=1:105
%     if postLDAind(i)<=105
%         postLdaLabels(i)=1;
%     end
% end




