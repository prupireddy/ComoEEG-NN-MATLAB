-Each of the programs have their own readme in the metadata section, are documented, and I have
a more in depth notetaking for each program in lab book, so look at those as well. This is more of a broad explanation.

-There are three scripts (in order of execution):

1. EDF_to_MFile: Converts the raw EEG from EDF file format into MATLAB
Input: Patient #(insert patient number).edf - raw EDF EEG
Output: P(insert patient number)_EEG.mat - MATLAB EEG

2. PSD: Generates Features using PSD
Input: P(insert patient number)_Annotations.xslx - Contains Seizure On/Off Set Times
+ P(insert patient number)_EEG.mat (O from previous) - MATLAB EEG
Output: P(insert patient number)_Features - Features

3. NN_Train: Trains/Tests/Exports the NN
Input: P(Insert patient number)_Features - Features
Output: Accuracy is outputted in the command line and P(insert patient number)_NN.onnx - NN Classifier for Jetson Nano

*The actual implementation is pretty easy. At the very beginning of each program, there is a section for "user-defined parameters". Just 
change the patient number in the file names and change the current directory to the one with that patient's files and you are all set. )
