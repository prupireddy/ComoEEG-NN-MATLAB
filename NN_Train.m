%% Metadata

% This script takes as input a cell array and target vector output by
% the script tk_deepprep. It randomly sorts this array into training and
% test data and then trains an LSTM sequence classifier on it. The trained
% neural network is both saved in a .mat file and exported to ONNX format
% for later use in TensorRT.

% MATLAB's Deep Learning Toolbox must be installed before this script will
% function properly.
%% Inputs and Outputs

in_str = 'P10_BoostedPSD_2640.mat'; % input filename
mat_str = 'P10_NN.mat'; % output filename (.mat)
onnx_str = 'P10_NN.onnx'; % output filename (ONNX network)
load(in_str);

%% Script

%{
% Transpose target array (n.b. future updates to tk_dataprep may invalidate
% the necessity for this line, so comment this out if the target array is
% already vertical)
nn_targets = transpose(nn_targets);
%}

train_rat = 0.5; % proportion of inputs to go into the training set
% Separate data into training and target sets (this script does so
% randomly, with a proportion determined by the user. Make sure there are
% enough observations made by the previous scripts for this to work.
n_obs = length(nn_inputs); % fetches number of features and observations
% Array Initialization
XTrain = cell(floor(n_obs*train_rat),1);
YTrain = zeros(n_obs*train_rat,1);
XTest = cell(floor(n_obs*(1-train_rat)),1);
YTest = zeros(n_obs*(1-train_rat),1);
% These initializations are rough, so some extra memory will inevitably
% have to be reallocated to one of them due to the nature of the sorting.

n_train = 1; % number of training observations recorded (offset 1 for index reasons)
n_test = 1;

tracker = zeros(2,2); % tracks ictal/interictal observations in each set

for k = 1:n_obs % for each observation
    Q = rand; % generate random number
    disp(Q)
    if (Q < train_rat) && (n_train <= length(XTrain)) % add observation k to the training set, if there is room
        % n.b. indexing errors will occur if there are less observations
        % than there are features, due to how length() works. But you
        % should have more than 176 observations for reasons besides this
        % as well.
        XTrain{n_train} = nn_inputs{k}; % update training set
        YTrain(n_train) = nn_targets(k);
        n_train = n_train + 1;
        % update tracker information
        disp('train')
        if nn_targets(k) == 1
            tracker(1,1) = tracker(1,1) + 1;
        else
            tracker(1,2) = tracker(1,2) + 1;
        end
    else % observation is in the test set
        XTest{n_test} = nn_inputs{k}; % update test set
        YTest(n_test) = nn_targets(k);
        n_test = n_test + 1;
        % update tracker information
        disp('test')
        if nn_targets(k) == 1
            tracker(2,1) = tracker(2,1) + 1;
        else
            tracker(2,2) = tracker(2,2) + 1;
        end
    end
end

tracker_str = ['The training set contains ',num2str(tracker(1,1)),' ictal and ',num2str(tracker(1,2)),' interictal observations.',newline,'The test set contains ',num2str(tracker(2,1)),' ictal and ',num2str(tracker(2,2)),' incterictal observations.'];
disp(tracker_str);

% Trim empty observations from data
XTrain(cellfun('isempty',XTrain))=[];
YTrain = YTrain(1:length(XTrain));
XTest(cellfun('isempty',XTest))=[];
YTest = YTest(1:length(XTest));

% Categorize labels and display assignment results.
YTrain = categorical(YTrain);
YTest = categorical(YTest);

% Define LSTM Network Architecture
inputSize = length(XTrain{1}); % input size (number of features)
numClasses = 2;
% This project only distinguishes ictal and interictal data; hence the
% number of classes is locked at 2. It would be interesting to modify the
% code to accept more classes in the future, but currently there is no
% cause to do so.

numHiddenUnits = 200; % number of hidden units in the LSTM layer
% This variable controls the complexity of the neural network, I think.
% Higher numbers mean more neurons, which might increase accuracy but
% definitely increase processing time.

layers = [ ...
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

options = trainingOptions('adam', ...
    'ExecutionEnvironment','auto', ...
    'MaxEpochs',400, ...
    'GradientThreshold',1, ...
    'Shuffle','every-epoch', ...
    'ValidationPatience',5, ...
    'Plots','training-progress');

% Train network
net = trainNetwork(XTrain,YTrain,layers,options);

% Test network accuracy using test set
YPred = classify(net,XTest);

YPred = double(YPred);
YPred = YPred - 1;
YTest = double(YTest);
YTest = YTest - 1;

n_ictal_test = nnz(YTest);
n_interictal_test = nnz(~YTest); 
PositiveClassificationIndices = find(YPred);
NegativeClassificationIndices = find(~YPred);
TP = nnz(YTest(PositiveClassificationIndices));
FP = nnz(~YTest(PositiveClassificationIndices));
FN = nnz(YTest(NegativeClassificationIndices));
TN = nnz(~YTest(NegativeClassificationIndices));
TPR = TP/n_ictal_test;
FPR = FP/n_interictal_test;
TNR = TN/n_interictal_test;
FNR = FN/n_ictal_test;
Accuracy = (TP+TN)/(TP+TN+FN+FP);
ConfusionMatrix = [TPR,FPR,TNR,FNR,Accuracy];

% Export files
save(mat_str,'net');
exportONNXNetwork(net,onnx_str);