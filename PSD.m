%% Metadata

% This script takes as input a .mat file containing a patient's EEG data as
% well as an .xlsx spreadsheet containing timestamps for seizure onset and
% end. Its purpose is to prepare a labeled feature set for use in MATLAB's
% pattern recognition application, and it outputs another .mat file
% containing applicable feature and target arrays. The input .mat file is
% created from an .edf file using the script tk_stitcher.m. The .xlsx file
% was transcribed by hand from a plaintext file. In the .xlsx file, the
% "state" column indicates beginning (1) and end (0) of each seizure.

% The features calculated by this script are the average spectral
% frequencies across eight bands per channel (the files used in this 
% project had 22 selected channels for a total of 176 features).

% In the output matrix, each column of the array indicates a list of
% features from a single trial. The features are average spectral power
% across a given frequency band in a given channel. Features are grouped
% such that all band powers from one channel, in increasing order of
% frequency, appear before the band powers of the next channel.

% This script is identical to tk_dataprep but does not average the spectral
% power with respect to time. In this case the targets output is an N-by-1
% cell array, where N is the number of observations. Each element of the
% cell is an array describing the evolution over time for each feature.

% This script is identical to tk_deepprep but the method of gathering
% trials has changed to accommodate datasets where one class vsatly
% outweighs the other (which a simple neural net cannot accommodate). The
% old method is still present, only it's been commented out.
%% User-Defined Parameters

data_str = 'P10_EEG.mat'; % input filename (data)
times_str = 'P10_Annotations.xlsx'; % input filename (seizure times)
out_str = 'P10_FullPSD.mat'; % output filename
% Input and output filenames. Use full path names or move MATLAB's working
% directory to the correct location beforehand. Output extension should be
% .mat.

tr_len = 20; % trial length (s) (recommended: 20).

thr = 0.5; % classification threshold
% The "seiz_weight" variable is essentially the percentage of data points
% in any given trial that are ictal. This classification threshold
% determines what percentage of points need to be ictal for this script to
% classify the entire trial as ictal. Altering this parameter will most
% likely impact false positive vs. false negative rates.

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
seiz_table = readtable(times_str);
seiz_array = table2array(seiz_table);
tr_pts = tr_len * srate;

% Parse timestamp array into seconds
seiz_sec = zeros(length(seiz_array),1); % initialize sseconds-only array
t_0 = seiz_array(1,4) + 60*seiz_array(1,3) + 3600*seiz_array(1,2) + 86400*seiz_array(1,1); % start time
for k = 1:length(seiz_array)
    seiz_sec(k) = seiz_array(k,4) + 60*seiz_array(k,3) + 3600*seiz_array(k,2) + 86400*seiz_array(k,1) - t_0;
end

% Create a binary array indicating whether a given data point is in an
% ictal (1) or interictal  (0) region, based on above timestamps
s = zeros(1,n_pts);
nt = 2; % current highlighted timestamp index
i_state = seiz_array(1,5); % current ictal state
for k = 1:n_pts
    t_now = (k - 1)/srate; % current time
    if nt <= length(seiz_sec)
        t_next = seiz_sec(nt); % next event marker
        if t_now >= t_next % if the next event has been reached
            i_state = seiz_array(nt,5); % update the ictal tracker
            nt = nt + 1; % update the event tracker
        end
    end
    s(k) = i_state;
end

% Initialize array of results
% Obtain sample spectrogram for initialization
d_temp = data(1,1:(tr_pts));
sp_temp = spectrogram(d_temp,window,noverlap,nfft,srate);
[M,N] = size(sp_temp);
n_tr = floor(n_pts/tr_pts);
State_array = zeros(n_tr,1);%corresponds to each PSD 1-1
start = 1;
stop = tr_pts;
m_pwr = zeros(n_bands*n_chan,N); % spectral power array
PSD_cell = cell(n_tr,1);

for t = 1:n_tr
    seiz_weight = mean(s(start:stop));
    if seiz_weight > .5
        State_array(t)=1;
    else 
        State_array(t)=0;
    end 
    for q = 1:n_chan % for each channel
        d_temp = data(q,start:stop); % find relevant section of data
        sp_temp = spectrogram(d_temp,window,noverlap,nfft,srate); % this section's spectral profile
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
            i_pwr = (q-1)*n_bands + qq; % current index
            m_pwr(i_pwr,:) = mean(sp_crop,1); % avg. power for this window per time step
        end
    end
    PSD_cell{t}=m_pwr;
    start = start + tr_pts;
    stop = start + (tr_pts - 1);
end

PSD_row = PSD_cell;
for t = 1:n_tr
    PSD_row{t} = transpose(PSD_row{t});
    PSD_row{t} = reshape(PSD_row{t},1,n_bands*n_chan*N);
end
PSD_row = cell2mat(PSD_row);

ictal_indices = find(State_array);
interictal_indices=find(~State_array);

save(out_str,'PSD_row','State_array','ictal_indices','interictal_indices','-v7.3');