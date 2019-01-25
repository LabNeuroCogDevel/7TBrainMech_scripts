function write_out(data,out_dir,slice_num, varargin)
    name = strjoin([ {num2str(slice_num)} ,varargin],'_');
    name = fullfile(out_dir,name);
    fid = fopen(name, 'w');
    fwrite(fid, data, 'float');
    fclose(fid);
end
