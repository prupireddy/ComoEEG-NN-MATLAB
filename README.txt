-Each of the programs have their own readme in the metadata section, are documented. This is more of a broad explanation.

-There are three MATLAB scripts (in order of execution):

1. EDF_to_MFile: Converts the raw EEG from EDF file format into MATLAB
Input: Patient #(insert patient number).edf - raw EDF EEG
Output: P(insert patient number)_EEG.mat - MATLAB EEG

2. PSD: Generates PSD Features on all 20s fragments with 176 features, original (however many features) commented out. You have the option to use the time diff
erential method or use the default. You also have the option to define an ictal window as one wherein if at least 1 data point is ictal, then the whole window is 
considered ictal. The default is the time difference and the definition. 
Input: P(insert patient number)_Annotations.xslx - Contains Seizure On/Off Set Times
+ P(insert patient number)_EEG.mat (O from previous) - MATLAB EEG
Output: 3 options - 
1. P(insert patient number)_FullPSD_176 - Features
2. P(insert patient number)_TFullPSD_176: Time difference
3. P(insert patient number)_TIFullPSD_176: Time Difference as well as with the ictal window definition

3. Boosting: Generates TIFF spectrograms (each page/layer is one channel's spectrogram in grayscale) for all ictals and an equal number of highest power interictals
Input: P(Insert patient number)_(T)(I)FullPSD_176 - Features
Output: P(Insert patient number)_1-(#Observations).TIFF. Stored in the ictal and interictal folders respectively. 

4. Feed the results of 3 into NN.py from the CNN_V4 in ComoEEG-NN-PYTHON

*The actual implementation is pretty easy. At the very beginning of each program, there is a section that states the names of the input and output files. Just 
change the patient number in the file names and change the current directory to the one with that patient's files and you are all set. 
