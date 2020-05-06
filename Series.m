%% Overview

% This takes in as an input the locations of the high power interictals, number of ictals and interictals (high power) and outputs the
% full power spectral density, 2640 features, to be inputted into the LSTM NN. 
% This was necessary because the LSTM is used to taking in as an input a series, and this turns
% the 176 feature PSD into a series. 
% 
% This program works like the normal power spectral density, just with the exception that instead of targetting
% all of the 20s segments, it targets the 20s segments where there is boosted data. It does this with a 
% little equation that converts the index retrieved from the Boosting program to the precise time steps 
% of the 20s window. It iterates over all indices. 
% 
% As an output, it generates the 2640 PSD as well as a state array that tells whether each PSD is ictal 
% or interictal. The first half of all the states are ictal and the second
% half are interictal. Therefore, the both are arrays with dimensions of
% number ictal plus number of high power interictal by 1. Each cell in the
% cell array for inputs has 2640 features and each number in the state
% array is 0 (second half) or 1 (first half). 

%% Program
data_str = 'P4_EEG.mat'; % EEG input filename
boostedDataInfo = 'P4_BoostedDataInfo'; %Indices of ictal or interictal
%out_str = 'P10_FullPSD_176.mat'; % output filename
out_str = 'P4_BoostedPSD_2640.mat';
% Input and output filenames. Use full path names or move MATLAB's working
% directory to the correct location beforehand. Output extension should be
% .mat.

tr_len = 20; % trial length (s) (recommended: 20).

pwr_mode = 'abs'; % spectral power modality
% MATLAB's Deep Learning Toolbox does not support the complex output of a
% spectrogram, so this variable indicates the desired method of processing.
% Available and planned modalities are:
% 'abs' - The absolute value of the power
% 'real' - The real component of the power
% 'imag' - The imaginary component of the power
% 'double' - Stores both components separately. Doubles the size of the
%            input matrix, requiring a separate initialization. Not yet
%            implemented.

n_bands = 8; % number of frequency bands to separate spectral data into. Recommended: 8.

% Spectrogram Parameters (leave blank for MATLAB defaults)
window = 640; % window length (samples)
noverlap = []; % window overlap (samples)
nfft = []; % number of frequency samples
% Lower window sizes and higher overlap percentages increase the number of
% points in the time domain per spectrograph. This impacts the eventual
% computation time in the neural net.

tomare = 60; % time at which while loop forcibly terminates (sec)

%% Script

% load input data
load(data_str);
n_chan = length(chanlocs);
tr_pts = tr_len * srate;

% Initialize array of results
% Obtain sample spectrogram for initialization
d_temp = data(1,1:(tr_pts));
sp_temp = spectrogram(d_temp,window,noverlap,nfft,srate);
[M,N] = size(sp_temp);

%Here we calculate the number of trials 
n_tr = n_high_power_interictals +n_ictals;%These two come from the  boosted data information
%Stores PSD - this is in Tyler's original format
nn_inputs = cell(n_tr,1);
%This corresponds to each PSD 1-1: it is the label matrix
nn_targets = zeros(n_tr,1);
nn_targets(1:n_ictals) = 1;

%Intermediate PSD matrix that stores the results for one trial and is
%eventually put into the PSD matrix at the end of the trial
m_pwr = zeros(n_bands*n_chan,N); % spectral power array
%m_pwr = zeros(n_bands*n_chan,1);

for t = 1:n_tr
    i_psd = boostedIndices(t);
    start = 1 + (tr_pts)*(i_psd-1);
    stop = start + (tr_pts - 1);
    for q = 1:n_chan % for each channel
        d_temp = data(q,start:stop); % find relevant section of data
        sp_temp = spectrogram(d_temp,window,noverlap,nfft,srate); % this channel's spectral profile
        switch pwr_mode
            case 'abs'
                sp_temp = abs(sp_temp);
            case 'real'
                sp_temp = real(sp_temp);
            case 'imag'
                sp_temp = imag(sp_temp);
            otherwise
                error('Invalid "pwr_mode" assignment. Please check entry in User Parameters section.');
        end
        for qq = 1:n_bands % for each desired frequency band
            f_min = (qq-1)*srate/(2*n_bands)+1; % lower frequency bound (index)
            f_max = qq*srate/(2*n_bands); % upper frequency bound (index)
            sp_crop = sp_temp(f_min:f_max,:); % find relevant part of spectrogram
            i_pwr = (q-1)*n_bands + qq; % current index (row)
            m_pwr(i_pwr,:) = mean(sp_crop,1); % avg. power for this window per time step
            %m_pwr(i_pwr)=mean(mean(sp_crop,1)); %ave power for this window for all time steps %avg power for this window for all time steps
        end
    end
    nn_inputs{t}=m_pwr;%as stated before, the intermediate PSD is put into final PSD after trial
end

save(out_str,'boostedIndices','nn_inputs','nn_targets','-v7.3');