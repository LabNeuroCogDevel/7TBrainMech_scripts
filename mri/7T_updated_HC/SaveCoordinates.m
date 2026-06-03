% Define the path to the subject directories
subject_dirs = dir('/Volumes/Hera/Projects/7TBrainMech/scripts/mri/7T_updated_HC/spectrum/2*'); 
subject_dirs = subject_dirs([subject_dirs.isdir]); % Keep only directories
subject_dirs = subject_dirs(~ismember({subject_dirs.name}, {'.', '..'})); % Exclude '.' and '..'

for i = 1:length(subject_dirs)
    % Define the spectrum directory for the current subject
    spectrum_dir = fullfile(subject_dirs(i).folder, subject_dirs(i).name);

    % Define the output file path
    output_file = fullfile(spectrum_dir, 'coordinates_m.txt');
    if isfile(output_file)
       fprintf('%s exists, skipping\n', output_file);
       continue;
    end
    
    % Check if orient.txt exists — skip if missing
    orient_file = fullfile(spectrum_dir, 'orient.txt');
    if ~isfile(orient_file)
        warning('Missing orient.txt in: %s. Skipping...', spectrum_dir);
        continue;
    end
    
    % Extract position info using pos_from_spectrum
    posInfo = pos_from_spectrum(spectrum_dir);
    
    % Compute transformed coordinates using ReconCoordinatesFinal
    poslrp = ReconCoordinatesFinal(posInfo);
    
    % Ensure poslrp is padded to match size of posInfo.pos (fill with zeros)
    if size(poslrp, 1) < size(posInfo.pos, 1)
        % Pad missing rows with zeros
        padding = zeros(size(posInfo.pos, 1) - size(poslrp, 1), size(poslrp, 2));
        poslrp = [poslrp; padding];
    end
    

    % Open the file for writing
    fid = fopen(output_file, 'w');
    if fid == -1
        error('Cannot open file: %s', output_file);
    end
    
    % Write data (row number, original pos, transformed pos)
    for j = 1:size(posInfo.pos, 1)
        fprintf(fid, '%d\t%d\t%d\t%.2f\t%.2f\n', ...
            j, ...
            posInfo.pos(j, 1), posInfo.pos(j, 2), ...
            poslrp(j, 1), poslrp(j, 2));
    end
    
    % Close the file
    fclose(fid);
    
    fprintf('Wrote coordinates to: %s\n', output_file);
end
