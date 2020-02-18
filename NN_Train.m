%% Metadata

% This script takes as input a cell array and target vector output by
% the script tk_deepprep. It randomly sorts this array into training and
% test data and then trains an LSTM sequence classifier on it. The trained
% neural network is both saved in a .mat file and exported to ONNX format
% for later use in TensorRT.

% MATLAB's Deep Learning Toolbox must be installed before this script will
% function properly.
%% User-Defined Parameters

in_str = 'P10_Features.mat'; % input filename
mat_str = 'P10_NN.mat'; % output filename (.mat)
onnx_str = 'P10_NN.onnx'; % output filename (ONNX network)

train_rat = 0.5; % proportion of inputs to go into the training set

numHiddenUnits = 200; % number of hidden units in the LSTM layer
% This variable controls the complexity of the neural network, I think.
% Higher numbers mean more neurons, which might increase accuracy but
% definitely increase processing time.

options = trainingOptions('adam', ...
    'ExecutionEnvironment','auto', ...
    'MaxEpochs',400, ...
    'GradientThreshold',1, ...
    'Shuffle','every-epoch', ...
    'ValidationPatience',5, ...
    'Plots','training-progress');

%% Script

% Load input variables
load(in_str);

% Trim empty observations from data
XTrain(cellfun('isempty',XTrain))=[];
YTrain = YTrain(1:length(XTrain));
XTest(cellfun('isempty',XTest))=[];
YTest = YTest(1:length(XTest));

% Categorize labels and display assignment results.
YTrain = categorical(YTrain);
YTest = categorical(YTest);
tracker_str = ['The training set contains ',num2str(tracker(1,1)),' ictal and ',num2str(tracker(1,2)),' interictal observations.',newline,'The test set contains ',num2str(tracker(2,1)),' ictal and ',num2str(tracker(2,2)),' incterictal observations.'];
disp(tracker_str);

% Define LSTM Network Architecture
inputSize = length(XTrain{1}); % input size (number of features)
numClasses = 2;

layers = [ ...
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

% Train network
net = trainNetwork(XTrain,YTrain,layers,options);

% Test network accuracy using test set
YPred = classify(net,XTest);
acc = sum(YPred == YTest)./numel(YTest)

% Export files
save(mat_str,'net','acc');
exportONNXNetwork(net,onnx_str);