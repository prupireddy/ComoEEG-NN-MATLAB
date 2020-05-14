-Each of the programs have their own readme in the metadata section, are documented. This is more of a broad explanation. 

-There are three MATLAB scripts (in order of execution):

1. EDF_to_MFile: Converts the raw EEG from EDF file format into MATLAB format and performs spatial difference preprocessing. 
Input: Patient #(insert patient number).edf - raw EDF EEG
Output: P(insert patient number)_DEEG.mat - MATLAB EEG

2. PSD: Generates PSD Features on all 20s fragments with 176 features, original (however many features) commented out. You have the option to use the time diff
erential method or use the default. You also have the option to define an ictal window as one wherein if at least 1 data point is ictal, then the whole window is 
considered ictal. The default is the time difference and the definition. 
Input: P(insert patient number)_Annotations.xslx - Contains Seizure On/Off Set Times
+ P(insert patient number)_DEEG.mat - MATLAB Spatially Differentiated EEG
Output:  
P(insert patient number)_TIDFullPSD_176 - The "T" means I am taking the time diference, "I" means I am using at least one data point ictal definition, "D" means
that I am generating the PSDs based on spatially differentiated EEG data.

3. Boosting: Generates TIFF spectrograms (each page/layer is one channel's spectrogram in grayscale) for all ictals and an equal number of highest power interictals
Input: P(Insert patient number)_TIDFullPSD_176 - Features
Output: P(Insert patient number)_(#Observation).TIFF. Stored in the ictal and interictal folders respectively. 

4. Feed the results of 3 into NN.py from the CNN_V5 in ComoEEG-NN-PYTHON

*The actual implementation is pretty easy. At the very beginning of each program, there is a section that states the names of the input and output files. Just 
change the patient number in the file names and change the current directory to the one with that patient's files and you are all set. 
