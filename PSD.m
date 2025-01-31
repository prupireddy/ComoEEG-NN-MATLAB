%% Metadata

% This script takes as input a .mat file containing a patient's EEG data as
% well as an .xlsx spreadsheet containing timestamps for seizure onset and
% end. Its purpose is to prepare a labeled feature set for use in MATLAB's
% pattern recognition application, and it outputs another .mat file
% containing applicable feature and target arrays.  The .xlsx file
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

% In this case the targets output is an N-by-1
% cell array, where N is the number of observations. Each element of the
% cell is an array describing the evolution over time for each feature.

% This script is intended to sample an equal number of interictals as
% ictals, but actually does not because of a logic error. 
%% User-Defined Parameters

data_str = 'P10_EEG.mat'; % input filename (data)
times_str = 'P10_Annotations.xlsx'; % input filename (seizure times)
out_str = 'P10_Features.mat'; % output filename
% Input and output filenames. Use full path names or move MATLAB's working
% directory to the correct location beforehand. Output extension should be
% .mat.

tr_len = 20; % trial length (s) (recommended: 20)
n_tr = 500; % number of trials to collect for each state
% In this version of the code, trials are collected from random points in
% the dataset until [n_tr] trials of both states are found.

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
seiz_table = readtable(times_str);
seiz_array = table2array(seiz_table);
n_chan = length(chanlocs);
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
d_temp = data(1,1:(1+tr_pts));
sp_temp = spectrogram(d_temp,window,noverlap,nfft,srate);
[M,N] = size(sp_temp);
m_pwr = zeros(n_bands*n_chan,N); % spectral power array

% Fill arrays
nn_targets = [zeros(n_tr,1);ones(n_tr,1)];
start_max = n_pts - tr_pts; % maximum index at which a trial can start
ictal_bool = false;
inter_bool = false;
nn_ictal = cell(n_tr,1);
nn_inter = cell(n_tr,1);
n_ictal = 1;
n_inter = 1;
n_loop = 0; % number of loops

tic
while ictal_bool == false && inter_bool == false % while the two categories are not full
    % throw an error if the code has run too long
    toki = toc;
    if toki > tomare
        error_str = ['With the current variables, the script found ',num2str(n_ictal),' ictal and ',num2str(n_inter),' interictal observations in time.'];
        disp(error_str);
        error('Script could not locate enough trials in time. Reduce the number of trials you are looking for or give the program more time to function.');
    end
    
    % Grab a random data point to start from
    i_0 = randi(start_max);
    % Check whether the bin starting at this location is ictal or
    % interictal
    seiz_weight = mean(s(i_0:(i_0+tr_pts)));
    if seiz_weight > thr % if the trial qualifies as ictal
        if n_ictal <= n_tr % if the bin is not full
            % Fill out entries in Inputs
            for q = 1:n_chan % for each channel
                d_temp = data(q,i_0:(i_0+tr_pts)); % find relevant section of data
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
            nn_ictal{n_ictal} = m_pwr; % update input array
            n_ictal = n_ictal + 1; % update count of ictal trials
        else % if the bin is full
            ictal_bool = true;
        end
    else % if the trial qualifies as interictal
        if n_inter <= n_tr % if the bin is not full
            % Fill out entries in Inputs
            for q = 1:n_chan % for each channel
                d_temp = data(q,i_0:(i_0+tr_pts)); % find relevant section of data
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
            nn_inter{n_inter} = m_pwr; % update input array
            n_inter = n_inter + 1; % update count of interictal trials
        else % if the bin is full
            inter_bool = true;
        end
    end
end

% Merge arrays
nn_inputs = [nn_inter;nn_ictal];

%{
% Fill arrays
T = floor(n_pts / (n_tr+1)); % trial collection period
for k = 1:n_tr % for each trial
    i_start = (k-1)*T + 1; % starting index for the current trial
    i_end = i_start + tr_pts; % ending index
    
    % Fill out entry in Targets
    seiz_weight = mean(s(i_start:i_end)); % see user section for details
    if seiz_weight > thr % if the trial qualifies as ictal
        nn_targets(k) = 1; % update Targets
    end
    
    % Fill out entries in Inputs
    for q = 1:n_chan % for each channel
        d_temp = data(q,i_start:i_end); % find relevant section of data
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
    nn_inputs{k} = m_pwr; % update input array
end
%}
% Save results
save(out_str,'nn_inputs','nn_targets','-v7.3');