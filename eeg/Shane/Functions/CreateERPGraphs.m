function [] = CreateERPGraphs(condition, cfg, datapath, Bins, Resultados_folder)


cfg.orig_dir_first=datapath;
cfg.orig_dir_second=datapath;

%% to run ERP graphs on subjects
for i = 1:length(condition)
    cfg.set_files = dir([datapath '/*' condition{i} '.set']);
    cfg.set_names = {cfg.set_files.name};
    
    for j = 1:length(cfg.set_names)
        cfg.set_first_filename = cfg.set_names{:,j};
        cfg.set_name1 = cfg.set_names{:,j}; 
        Permutame_1Condition(cfg, condition{i})

    end
end
  


%% to run ERP graphs on bins

for i = 1:length(condition)
    for j = 1:length(fieldnames(Bins))
    cfg.set_names{i,j} = [condition{i}, '_GAv_AgeBin' num2str(j)];

    end
end

% for i = 1:length(condition)
%     for j = 1:length(fieldnames(Bins))
        cfg.set_first_filename = [cfg.set_names{7,1} '.set'];
        cfg.set_second_filename = [cfg.set_names{7,4} '.set'];
        
        
        cfg.set_name1 = cfg.set_names{7,1};
        cfg.set_name2 = cfg.set_names{7,4};
        cfg.name_fig = [cfg.set_name1 'vs' cfg.set_name2];
        
        cfg.outpath = [Resultados_folder, '/' cfg.name_fig];
%         mkdir(cfg.outpath)
        cfg.grouping = 'off';
        Permutame_2Conditions(cfg)
%         
%     end
% end











