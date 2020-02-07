%% Metadata

% This script takes a given .edf file and converts it into a .mat file for
% use with further scripts. It uses EEGLAB's pop_biosig() function as a
% base but includes additional code to load .edf files piece-by-piece and
% save on memory usage.

% In order for this script to run, EEGLAB and its BIOSIG extension must be
% installed. EEGLAB must be launched (by adding it to the path and typing
% 'eeglab' in the command window) before this script will run properly.

%% User-Defined Parameters  

edf_name = 'Patient#3.edf';
mat_name = 'temp.mat';
% Input and output filenames. Use full path names or move MATLAB's working
% directory to the correct location beforehand. Output extension should be
% .mat.

buffer = 5000;
% The number of seconds' worth of data loaded in at one time. Higher values
% should result in faster but less stable operation. Set to 0 if you don't
% want to use a buffer. For this project, a buffer of 5000s was used.

edf_chan = 2:23;
% Array of all EEG channel indices of interest to the user. To save on
% space, the .mat file includes only these channels. Default is 2:23.

%% Script

% Obtain length of recording, in seconds
fid = fopen(edf_name); % opens .edf file
fseek(fid,236,'bof'); % jumps to recording length in file header
blocks = str2double(fread(fid,8,'*char')); % reads recording length in blocks
b_length = str2double(fread(fid,8,'*char')); % reads block time in seconds
t_max = blocks * b_length; % recording length in seconds
fseek(fid,11272,'bof'); % jumps to first sampling rate datum
b_rate = str2double(fread(fid,8,'*char')); % samples per block
fclose(fid); % closes .edf file

% Additional Calculations and Initialization
srate = b_rate / b_length; % sampling rate
% n.b. this assumes all channels in the recording have the same sampling
% rate, which should be the case but might cause hard-to-detect errors in
% the results if it isn't
n_pts = srate * t_max; % no. of data points
data = zeros(length(edf_chan),n_pts); % array of all data
t_end = 0; % loop end time
if buffer == 0 % if the user does not wish to use a buffer
    buffer = t_max;
end

% Read file and fill data
complete = false;
n = 0; % number of iterations completed
while complete == false
    t_start = t_end; % loop start time
    % update t_end and check for loop completion
    t_end = t_start + buffer;
    if t_end >= t_max % if the block goes past the recording end time
        t_end = t_max;
        complete = true;
    end
    temp_EEG = pop_biosig(edf_name,'channels',edf_chan,'blockrange', [t_start t_end]); % runs EEGLAB on data set
    temp_data = temp_EEG.data; % current block of data
    n_start = (n*buffer*srate)+1; % start index of data block
    %n_end = (n+1)*buffer*srate; % end index of data block
    n_end = n_start + srate * (t_end - t_start) - 1; % end index of data block
    data(:,(n_start:n_end)) = temp_data; % update m_all
    n = n+1; % update loop completion tracker
end

% Export data to .mat files
chanlocs = temp_EEG.chanlocs; % struct array that contains data on recording sites
save(mat_name,'data','chanlocs','srate','t_end','n_pts','-v7.3'); % saves to .mat file