function results = calculate_epochs_mask(epochs, EEG)
results = 0;
for i = 1:length(epochs(1,:))
    epoch = epochs(:,i);
    mask = arrayfun(@(x)strcmp(x, epoch), {EEG.epoch.eventtype});
    results = results | mask;
end
