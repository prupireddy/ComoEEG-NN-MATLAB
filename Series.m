%% Program
data_str = 'P10_EEG.mat'; % EEG input filename
boostedDataInfo = 'P10_BoostedDataInfo';
%out_str = 'P10_FullPSD_176.mat'; % output filename
out_str = 'P10_BoostedPSD_2640.mat';
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
n_tr = floor(n_pts/tr_pts);
%Stores PSD - this is in Tyler's original format
PSD_cell = cell(n_tr,1);
%This corresponds to each PSD 1-1: it is the label matrix
State_array = zeros(n_tr,1);

%Initial start and stop for PSD
start = 1;
stop = tr_pts;
%Intermediate PSD matrix that stores the results for one trial and is
%eventually put into the PSD matrix at the end of the trial
m_pwr = zeros(n_bands*n_chan,N); % spectral power array
%m_pwr = zeros(n_bands*n_chan,1);

for t = 1:n_tr
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
    PSD_cell{t}=m_pwr;%as stated before, the intermediate PSD is put into final PSD after trial
    %Reset Trial Start and Stop points
    start = start + tr_pts;
    stop = start + (tr_pts - 1);
end