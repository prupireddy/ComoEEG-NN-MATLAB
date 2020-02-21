%Import
input_str = 'P10_PSD.mat';
load(input_str);

[~,~,~,~,coeff] = classify(PSD_array,PSD_array,State_array);
proj=PSD_array*coeff(1,2).linear;
thresholds=sort(proj,'descend');
roc=zeros(length(proj),2);
for k=1:length(proj)
   currentLabels=zeros(length(proj),1);
for i=1:length(proj)
    %determine label based on threshold (check each value against threshold
    %and determine if it passes for classification or not
    if proj(i)<=thresholds(k)
        currentLabels(i)=1;
    end
end
    %calculate false positve
    countFP=0;
    for j =106:length(proj)
        if currentLabels(j)==1
            countFP=countFP+1;
        end
    end
    %calculate true positive
    countTP=0;
    for j = 1:105
        if currentLabels(j)==1
        countTP = countTP+1;
        end
    end
    roc(k,1)=countFP/(length(proj)-105);
    roc(k,2)=countTP/105;
end
%% Plot ROC curve
figure
plot(roc(:,1),roc(:,2))
xlabel('False Positive Rate')
ylabel('True Positive Rate')
title('ROC Curve of All Data Projected After LDA')
hold on
plot(linspace(0,1,length(allData)),linspace(0,1,length(allData)))
%% Determine indices of Data that passes the Threshold Set by the LDA 
%  projection ROC
bestThreshold=thresholds(16380);

count=0;
for i = 1:length(proj)
    if proj(i)>bestThreshold
        count=count+1;
    end
end

postLDAind=zeros(count,1);
for i = 1:length(proj)
    if proj(i)<bestThreshold
        postLDAind(i)=i;
    end
end
postLDAind=find(postLDAind);

%% Create Data and Label Arrays for Observations that passed the threshold

postLdaData=zeros(length(postLDAind),128);
for i = 1:length(postLDAind)
    postLdaData(i,:)=allData(postLDAind(i),:);
end

postLdaLabels=zeros(length(postLDAind),1);
for i=1:105
    if postLDAind(i)<=105
        postLdaLabels(i)=1;
    end
end




