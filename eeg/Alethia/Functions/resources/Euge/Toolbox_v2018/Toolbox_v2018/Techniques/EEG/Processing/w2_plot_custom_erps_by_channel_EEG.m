function data = w2_plot_custom_erps_by_channel_EEG(path_to_file,file_name,condition_nr,mean_mat,stats,path_to_save,data)

%-------DESCRIPTION---------------
%Plots time frequency charts per channel calculated by w_custom_erps_by_channel_EEG
%or w_custom_newtimef_2_precalculated_conditions_by_channel_EEG and saves plots in specified path.
%INPUT:
%   * path_to_file: directory to file
%   * file_name: filename
%   * condition_nr: 1 or 2 - condition to plot. If 2 is selected, difference
%       between conditions will be plot alongside time frequency charts for
%       condition 1 or condition 2
%   * stats: 0 or 1 - 0 to plot time frequency charts without statistical results,
%                     1 to plot time freqyency charts with statistical
%                     results (relevant parameters must be set).
%   * path_to_save: directory where plots will be saved.
%OUTPUT:
%   * plots per channel stored in path_to_save directory.
%----------------------------------

%-------PATH MANAGEMENT-----------
%----------------------------------

%modifies paths to include parent directory
path_to_save = fullfile(data.parent_directory, path_to_save);

%create directory where the trimmed sets will be stored
if ~exist(path_to_save, 'dir')
  mkdir(path_to_save);
end

%check if path to files exist
assert(exist(path_to_file, 'dir') == 7,['Directory not found! path_to_file: ' path_to_file '.']);
%assert if file exists
pfile_name = fullfile(path_to_file,file_name);
assert(exist(pfile_name,'file') == 2,['File not found! file name: ' pfile_name '.']);

%-------LOAD PARAMETERS------------
%----------------------------------
condition_nr = str2num(condition_nr);
mean_mat = str2num(mean_mat);

%assert possible values are 1 or 2
assert((condition_nr == 1 || condition_nr == 2),'Error. condition_nr allowed values are 1 or 2.');

%---------RUN---------------------
%---------------------------------
%assert if stats = 1 that relevant parameters are loaded....in g struct?
if condition_nr == 1
    plot_erps_custom_by_channel(pfile_name,stats,path_to_save);
else
    if mean_mat == 1
        plot_erps_custom_2_mean_conditions_by_channel(pfile_name,stats,path_to_save)
    else
        plot_erps_custom_2_conditions_by_channel(pfile_name,stats,path_to_save)
    end        
end