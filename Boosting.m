%% Explanation
%This program takes in all of the PSD data as as input - either time difference and/or
%with the ictal classification. It then computes
%LDA scores for all of the data. It then finds the n interictals with the
%highest LDA scores, where n in the number of ictals. It then adds the
%interictals under the ictals to created the boostedData. It also creates a
%stateArray that stores the state of each data with the same index. Hence,
%it a series of 1s (number of ictals) followed by a series of 0's (number of interictals). 
%It also outputs the number of ictals and the number of interictals, which
%are set to be the same. 

%It takes these and creates multitaper spectrograms (it is commented out
%, but you do have the option to add in a notch filter) with 2s and 1s overlap. It does 
%this twice, the first time is to find the min and max spectral density values to create the 
%bounds on the spectrograms. The second to actually calculate the spectrograms It
%converts them down to 0 to 1 using the min and max. Each time it cuts out the 
%55-65 Hz to ignore the 60Hz noise. It then converts to TIFF format (the format that
%allows stacking) and stacks them. All of the boosted trials have a TIFF
%output - each - and all of the boosted TIFFs are sent into one filder and
%all of ictal TIFFs are sent into another folder. 
%% Program

%Import
data_str = 'P10_EEG.mat';

%Filter:
% d = designfilt('bandstopiir','FilterOrder',2, ...
%                'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
%                'DesignMethod','butter','SampleRate',256);
           
%input_str = 'P10_TFullPSD_176.mat';
%input_str = 'P10_TIFullPSD_176.mat';
input_str = 'P10_TNIFullPSD_176.mat';
load(data_str);
load(input_str);

%data = filtfilt(d,data);

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

%Parameters for the Multitaper Spectrograms
%movingwin = [2 .25]; %87.5% overlap
movingwin = [2 1]; %50% overlap
params.tapers = [4 7]; %Time-bandwidth and number of tapers
params.pad = 0; %No padding
params.Fs = 256; %Sampling Rate
params.fpass = [0 128]; %Range of frequencies
params.err = 0; %Error bars
params.trialave = 0; %No averaging over trials

mkdir spectrograms %ictal folder
fpath = strcat(pwd,'\spectrograms'); %path to the folder
baseStr = erase(data_str,"EEG.mat");
baseStr = strcat(fpath,'\',baseStr);%Used as the base for the file name
for l = 1:(n_ictals + n_high_power_interictals)%iterate over all observations
    k = l-1;
    obvStr = strcat(baseStr,num2str(k),"_"); %Complete the name
    i_psd = boostedIndices(l);%locate the index of the observation in interest
    start = 1 + (tr_pts)*(i_psd-1); %Calculate the start and end of the points
    stop = start + (tr_pts - 1);
    for c = 1:n_chan
%       [S,t,f] = mtspecgramc(diff(filtfilt(d,data(c,start:stop))),movingwin,params);filtered
        [S,t,f] = mtspecgramc(diff(data(c,start:stop)),movingwin,params);
        S = S';
        S = log(abs(S));
        f = f';
        S(111:131,:) = [];
        f(111:131) = [];
        b = c-1;
        chanStr = strcat(obvStr,num2str(b),".bin");
        fileID = fopen(chanStr,'w');
        fwrite(fileID,S,'float64');
        fclose(fileID);
    end
end   

StateStr = strcat(baseStr,"state.bin");
fileID = fopen(StateStr,'w');
fwrite(fileID,boostedStateArray,'float64');
fclose(fileID);


