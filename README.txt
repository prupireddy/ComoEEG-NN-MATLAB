-Each of the programs have their own readme in the metadata section, are documented. 

-There are three scripts (in order of execution):

1. EDF_to_MFile: Converts the raw EEG from EDF file format into MATLAB
Input: Patient #(insert patient number).edf - raw EDF EEG
Output: P(insert patient number)_EEG.mat - MATLAB EEG

2. PSD: Generates PSD Features on all 20s fragments with 176 features, original (however many features) commented out. You also have the option to define an ictal window as one wherein if at least 1 data point is ictal, then the whole window is 
considered ictal. You also have the option to usethe time diff calc style were you determine start stop then diff. The default is all 3. 
Input: P(insert patient number)_Annotations.xslx - Contains Seizure On/Off Set Times
+ P(insert patient number)_EEG.mat (O from previous) - MATLAB EEG
Output: 3 options - 
1. P(insert patient number)_FullPSD_176 - Features
2. P(insert patient number)_TFullPSD_176: Time difference
3. P(insert patient number)_TIFullPSD_176: Time Difference as well as with the 1 ictal = ictal window definition
4. P(insert patient number)_TNIFullPSD_176: Post-start stop Time Differential on the first PSD as well as with the 1 ictal = ictal window definition (default)

3. Boosting: Generates multitaper spectrograms for all ictals and an equal number of highest power interictals, shape array, and state array - all in binary after taking out all the ictals
and an equal number of the highest power interictals
Input: P(Insert patient number)_(T)(N)(I)FullPSD_176 - Features
Output: All in a spectrograms folder - P(Insert patient number)_(Observation #)_(Channel #).bin - spectrograms, P(Insert patient number)_state&shape.bin - state and shape arrays

4. Feed the results of 3 into NN.py from the master branch in ComoEEG-NN-PYTHON

*The actual implementation is pretty easy. At the very beginning of each program, there is a section that states the names of the input and output files. Just 
change the patient number in the file names and change the current directory to the one with that patient's files and you are all set. 
