-Each of the programs have their own readme in the metadata section, are documented. This is more of a broad explanation. Process-oriented notes are stored in Boosting pt2 and LSTM Report 
Brainstorming notes are stored in the Brainstorming folder in the same location. 

-There are three scripts (in order of execution):

1. EDF_to_MFile: Converts the raw EEG from EDF file format into MATLAB
Input: Patient #(insert patient number).edf - raw EDF EEG
Output: P(insert patient number)_EEG.mat - MATLAB EEG

2. PSD: Generates PSD Features on all 20s fragments with 176 features, original commented out 
Input: P(insert patient number)_Annotations.xslx - Contains Seizure On/Off Set Times
+ P(insert patient number)_EEG.mat (O from previous) - MATLAB EEG
Output: P(insert patient number)_FullPSD_176 - Features

3. Boosting: Uses in sample LDA to return indices of the n highest power interictals, where n is the number of seizures. 
Input: P(Insert patient number)_FullPSD_176 - Features
Output: P(Insert patient number)_BoostedDataInfo

4. Series: Takes the locations of ictal data and high power interictal data to generate full, per-time step, 2640 feature PSD of ictal and high power interictal
Input: P(Inset patient number)_BoostedDataInfo
Output:P(Insert patient number)_BoostedPSD_2640

5. NN_Train: Takes the boosted data - output of Series - and trains an LSTM
Input: P(Insert patient number)_BoostedPSD_2640
Output: P(Insert parient number)_NN.mat

*The actual implementation is pretty easy. At the very beginning of each program, there is a section that states the names of the input and output files. Just 
change the patient number in the file names and change the current directory to the one with that patient's files and you are all set. 
