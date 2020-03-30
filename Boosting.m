%% Explanation
%This program takes in all of the PSD data as as input. It then computes
%LDA scores for all of the data. It then finds the n interictals with the
%highest LDA scores, where n in the number of ictals. It then adds the
%interictals under the ictals to created the boostedData. It also creates a
%stateArray that stores the state of each data with the same index. Hence,
%it a series of 1s (number of ictals) followed by a series of 0's (number of interictals). 
%It also outputs the number of ictals and the number of interictals, which
%are set to be the same. 
%% Program

%Import
data_str = 'P10_EEG.mat';
input_str = 'P10_TFullPSD_176.mat';
load(data_str);
load(input_str);

%Check out https://www.mathworks.com/help/stats/classify.html
[~,~,~,~,coeff] = classify(PSD_row,PSD_row,State_array);%LDA%First entry is train
%Second is test%In this case, they are the same for simplicity
proj=PSD_row*coeff(1,2).linear;

%Isolation of ictals and high power interictals
n_ictals = length(ictal_indices);
n_high_power_interictals = n_ictals;
proj_no_ictal = proj(interictal_indices);%remove ictals
[sortedproj,unsortedIndices] = sort(proj_no_ictal);%find the highest power interictals
postextracted_high_power_indices = unsortedIndices(1:n_high_power_interictals);%find the original index in the interictal only matrix
high_power_indices = interictal_indices(postextracted_high_power_indices);%find the original index in the matrix containing ictals
boostedIndices = vertcat(ictal_indices,high_power_indices);
%Create a new matrix that srores the ictals and high power interictals
high_power_interictals = PSD_row(high_power_indices,:);%high power interictials
ictals = PSD_row(ictal_indices,:);%ictals
boostedPSD_row = zeros((n_ictals+n_high_power_interictals),176);
boostedPSD_row((1:n_ictals),:)=ictals;
boostedPSD_row(((n_ictals+1):(n_ictals+n_high_power_interictals)),:) = high_power_interictals; 
%Create the State array that corresponds to each of the PSD index-by-index
boostedStateArray = zeros((n_ictals+n_high_power_interictals),1);
boostedStateArray(1:n_ictals) = 1;
% 
% params.tapers = [3 5];
% params.pad = 0;
% params.Fs = 256;
% params.fpass = [0,128];
% params.err = 1;
% params.trialave = 1;
%[S,t,f,Serr] = mtspecgramc(data(1,start:stop),[1,.25], params);


mkdir ictal
fpath = strcat(pwd,'\ictal');
for l = 1:n_ictals
    i_psd = boostedIndices(l);
    start = 1 + (tr_pts)*(i_psd-1);
    stop = start + (tr_pts - 1);
    for c = 1:n_chan
        S=spectrogram(diff(data(c,start:stop)),512,256);
        h = imagesc(log(abs(S)));
        colormap('gray')
        fileStr = erase(data_str,"EEG.mat");
        fileStr = strcat(fileStr,num2str(l),"_",num2str(c));
        saveas(h,fullfile(fpath,fileStr),'png');
    end
end

n_tr = n_ictals+n_high_power_interictals;
mkdir interictal
fpath = strcat(pwd,'\interictal');
for m = (n_ictals+1):(n_tr)
    i_psd = boostedIndices(m);
    start = 1 + (tr_pts)*(i_psd-1);
    stop = start + (tr_pts - 1);
    for d = 1:n_chan
        S=spectrogram(diff(data(d,start:stop)),512,256);
        h = imagesc(log(abs(S)));
        colormap('gray')
        fileStr = erase(data_str,"EEG.mat");
        fileStr = strcat(fileStr,num2str(m),"_",num2str(d));
        saveas(h,fullfile(fpath,fileStr),'png');
    end
end






