eeg_data_path = '../dataset/Bon/EEG';
eeg_file_all = dir(eeg_data_path);
eeg_file_all = {eeg_file_all(~[eeg_file_all(:).isdir]).name};
eeg_file_chosen = eeg_file_all{1};
load(fullfile(eeg_data_path, eeg_file_chosen), 'eeg');

lfp_data_idxs = regexp(eeg_file_chosen, '\d*','match');
lfp_data_idxs = cellfun(@str2num, lfp_data_idxs);
lfp_data = eeg{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.data;

smpl_rate = eeg{lfp_data_idxs(1)}{lfp_data_idxs(2)}{lfp_data_idxs(3)}.samprate;

ripples = detect_ripple(lfp_data, smpl_rate, 'wilson07');
