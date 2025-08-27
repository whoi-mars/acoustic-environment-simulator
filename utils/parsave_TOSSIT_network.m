function parsave_TOSSIT_network(path,p_f,t_far,t_close,labels,vg_integal,fs,df,i_loc)
    % PARSAVE_TOSSIT_NETWORK Save data into HDF5 file.
    %
    % Parameters
    % ----------
    % path:        path to directory where data is to be saved.
    % p_f:         frequency domain signals.
    % t_far:       end time of simulated signals at the receiver.
    % t_close:     arrival time of simulated signals at the receiver.
    % labels:      matrix of labels
    % vg_integral: group speeds for each mode.
    % fs:          sampling frequency
    % df:          discrete step used to sample frequency
    % i_loc:       index of sampled source location

    % construct save file path
    file_path = strcat(path,'/data_',string(i_loc),'_',string(now),'.h5');

    % create hdf5 file
    h5create(file_path,"/p_f_re",size(p_f),'Datatype','single','Chunksize',[size(p_f,[1 2]) 1]);
    h5create(file_path,"/p_f_im",size(p_f),'Datatype','single','Chunksize',[size(p_f,[1 2]) 1]);
    h5create(file_path,"/t_far",size(t_far),'Datatype','single','Chunksize',[size(t_far,1) 1]);    
    h5create(file_path,"/t_close",size(t_close),'Datatype','single','Chunksize',[size(t_close,1) 1]);
    h5create(file_path,"/labels",size(labels),'Datatype','single','Chunksize',[size(labels,1) 1]);
    h5create(file_path,"/vg_integral",size(vg_integal),'Datatype','single','Chunksize',[size(vg_integal,[1 2 3]) 1]);
    h5create(file_path,"/fs",size(fs));
    h5create(file_path,"/df",size(df));

    % write data
    h5write(file_path,"/p_f_re",real(p_f));
    h5write(file_path,"/p_f_im",imag(p_f));
    h5write(file_path,"/t_far",t_far);
    h5write(file_path,"/t_close",t_close);
    h5write(file_path,"/labels",labels);
    h5write(file_path,"/vg_integral",vg_integal);
    h5write(file_path,"/fs",fs);
    h5write(file_path,"/df",df);
end