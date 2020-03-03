%% Metadata

% This script takes as input the Train and Testing sets from the Power
% Spectral Density.It trains the LSTM classifier on the Training Set and on
% the Testing set. It then converts the test set's predictions into a 3/5
% analyzed prediction (post processed) and compares that with the Test Label. The neural network is both saved in a .mat file and exported to ONNX format
% for later use in TensorRT.

% MATLAB's Deep Learning Toolbox must be installed before this script will
% function properly.
%% User-Defined Parameters

in_str = 'P8_Train_and_Test.mat'; % input filename
mat_str = 'P8_NN.mat'; % output filename (.mat)
onnx_str = 'P8_NN.onnx'; % output filename (ONNX network)

load(in_str);

%Restate n and m
n = 3;
m = 5;

%Calculate the number of postprocessed predictions
n_m_predictions = length(YTest);

%Preallocate the PostProcessed predictions array
YTruePred = zeros(n_m_predictions,1);

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

% Categorize labels - puts this into 1s and 2s - meant for the classifier
YTrain = categorical(YTrain);

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

% Create Predictions on the Test Input
YPred = classify(net,XTest);

%Convert Predictions back into 0s and 1s for quantitative analysis
YPred = double(YPred);
YPred = YPred - 1;

%Tracker for where we are in the n/m analysis 
StartIndex = 1;

for k = 1:n_m_predictions
    %This calculates the ratio of positive and negative for a set of 5
    %consecutive points in the Original Predictions
    predweight = mean(YPred(StartIndex:(StartIndex+(m-1)))); 
    %If over the ratio, classify as positive
    if predweight >= (n/m)
        YTruePred(k)= 1;
    else
    %If under the ratio, classify as negative
        YTruePred(k)= 0;
    end
    %Reset the Start index for n/m analysis to the next set of 5 points
    StartIndex = StartIndex + m;
end

%Calculate the accuracy of the N/m analysis by comparing to the True Class
acc = sum(YTruePred == YTest)./numel(YTest);
disp(acc);

% Export files
save(mat_str,'net','acc');
exportONNXNetwork(net,onnx_str);