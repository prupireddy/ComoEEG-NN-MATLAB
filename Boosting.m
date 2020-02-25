%Import
input_str = 'P10_PSD.mat';
load(input_str);

%Check out https://www.mathworks.com/help/stats/classify.html
[~,~,~,~,coeff] = classify(PSD_row,PSD_row,State_array);%LDA%First entry is train
%Second is test%In this case, they are the same for simplicity
proj=PSD_row*coeff(1,2).linear;%Creates 1 dimensional score for likelihood into
%class 2 (ictal). Basically, when you add on the constant term for the boundary
%line (the linear term is the slope), if your final
%result is positive, it is class 1 (interical). If it negative, you get class 2 
%(ictal). You are 
%more or less taking the dot product and seeing on which side the result falls
%You can also think of it a regression. In this case, we have not added on
%the constant term, so if something is below X, it is ictal. Above,
%interical. The reason we don't really care about the true value when added
%by X is because we care about the relative positions of the LDA
%transformed points - as this will be used to generate thresholds for ROC
%analysis. 

[thresholds,original]=sort(proj,'descend');
roc=zeros(length(proj),2); %to store fpr and tpr rates, in order
for k=1:length(proj)
    countTP=0;
    countFP=0;
    currentLabels=zeros(length(proj),1);
    for i=1:length(proj)
        %determine label based on threshold (check each value against threshold
        %and determine if it passes for classification or not
        if proj(i)<=thresholds(k)
            currentLabels(i)=1;
            if State_array(i) == 1
                countTP = countTP + 1;
            elseif State_array(i) == 0
                countFP = countFP + 1;
            end
        end
    end
    roc(k,1)=countFP/(length(interictal_indices));
    roc(k,2)=countTP/(length(ictal_indices));
end
%% Plot ROC curve
figure
plot(roc(:,1),roc(:,2))
xlabel('False Positive Rate')
ylabel('True Positive Rate')
title('ROC Curve of All Data Projected After LDA')
hold on
plot(linspace(0,1,length(State_array)),linspace(0,1,length(State_array)))
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




