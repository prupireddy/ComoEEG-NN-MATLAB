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
    
mkdir ictal
fpath = strcat(pwd,'\ictal');
baseStr = erase(data_str,"EEG.mat");
baseStr = strcat(fpath,'\',baseStr);
for l = 1:n_ictals
    fileStr = strcat(baseStr,num2str(l),'.TIFF');
    i_psd = boostedIndices(l);
    start = 1 + (tr_pts)*(i_psd-1);
    stop = start + (tr_pts - 1);
    for c = 1:n_chan
        S=spectrogram(diff(data(c,start:stop)),512,256);
        h = image(log(abs(S)));
        colormap('gray')
        H = getimage(h);
        H = (H - min(H,[],'all'))/(max(H,[],'all')-min(H,[],'all'));
        %H = imresize(H,[875 656]);
        if c == 1
            imwrite(H,fileStr);
        else
            imwrite(H,fileStr,'WriteMode','append');
        end
    end
end   

n_tr = n_ictals + n_high_power_interictals;
mkdir interictal
fpath = strcat(pwd,'\interictal');
baseStr = erase(data_str,"EEG.mat");
baseStr = strcat(fpath,'\',baseStr);
for l = (n_ictals+1):n_tr
    fileStr = strcat(baseStr,num2str(l),'.TIFF');
    i_psd = boostedIndices(l);
    start = 1 + (tr_pts)*(i_psd-1);
    stop = start + (tr_pts - 1);
    for c = 1:n_chan
        S=spectrogram(diff(data(c,start:stop)),512,256);
        h = image(log(abs(S)));
        colormap('gray')
        H = getimage(h);
        H = (H - min(H,[],'all'))/(max(H,[],'all')-min(H,[],'all'));
        %H = imresize(H,[875 656]);
        if c == 1
            imwrite(H,fileStr);
        else
            imwrite(H,fileStr,'WriteMode','append');
        end
    end
end





