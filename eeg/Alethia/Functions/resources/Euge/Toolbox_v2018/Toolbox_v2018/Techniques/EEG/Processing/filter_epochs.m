function result_EEG = filter_epochs(epochs, EEG)
results = calculate_epochs_mask(epochs, EEG);
EEG.data = EEG.data(:,:,results);
EEG.epoch = EEG.epoch(results);
result_EEG = EEG;
