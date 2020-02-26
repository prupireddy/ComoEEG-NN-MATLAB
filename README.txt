-Each of the programs have their own readme in the metadata section, are documented. This is more of a broad explanation. Process-oriented notes are stored in Report in the Boosting folder. 
Brainstorming notes are stored in the Brainstorming folder in the same location. 

-There are three scripts (in order of execution):

1. EDF_to_MFile: Converts the raw EEG from EDF file format into MATLAB
Input: Patient #(insert patient number).edf - raw EDF EEG
Output: P(insert patient number)_EEG.mat - MATLAB EEG

2. PSD: Generates PSD Features on all 20s fragments
Input: P(insert patient number)_Annotations.xslx - Contains Seizure On/Off Set Times
+ P(insert patient number)_EEG.mat (O from previous) - MATLAB EEG
Output: P(insert patient number)_FullPSD - Features

3. Boosting: LDA and generates ROC curves for various thresholds. You have the option to do a PCA if the number of features exceeds the number of number of observations.
Input: P(Insert patient number)_FullPSD - Features
Output: ROC curve for that patient

*The actual implementation is pretty easy. At the very beginning of each program, there is a section that states the names of the input and output files. Just 
change the patient number in the file names and change the current directory to the one with that patient's files and you are all set. 
