function [CTD, full_depth_vec] = load_asc_CTD_data(datadir,dz)
    % LOAD_ASC_CTD_DATA Extract CTD data and take closest points along the
    % vector 2:dz:max_depth. If 'CTD_data.mat' is not saved in 'datadir'
    % already, then the data will be extracted. If it is, it will simply be
    % loaded.
    %
    % Parameters
    % ----------
    % datadir: path to directory containing CTD data files.
    % dz:      spacing in depth vector.
    %
    % Results
    % -------
    % CTD_cell:       cell array where each element contains a result
    %                 matrix 'A' from each CTD file. the columns of 'A' are 
    %                 [depth, temp., salinity, sound speed].
    % full_depth_vec: depth vector that ranges from 2 to the max depth
    %                 among all CTD files with a spacing of 'dz'.
    
    if exist(fullfile(datadir,'CTD_data.mat'),'file') == 2
        load(fullfile(datadir,'CTD_data.mat'));
        return
    end

    % grab .asc files
    fileList = dir(fullfile(datadir,'*.asc'));
    fileList = {fileList.name};
    
    CTD_cell = {};
    full_depth_vec = [];
    num_ignore = 0;
    for f = 1:length(fileList)
        % open file
        fid = fopen(fullfile(datadir,cell2mat(fileList(f))));
        
        % get data line-by-line
        tline = fgetl(fid);
        i=1;
        while ischar(tline)
            tline = fgetl(fid);
            if tline ~=-1
                A(i,:)=str2num(tline);
                i=i+1;
            end
        end
        
        % check for downcast
        if A(1,1) > 3
            num_ignore = num_ignore + 1;
            continue;
        end

        % get indices after the cast begins
        A = A(A(:,1)>2 & A(:,1)<200,:);

        % extract downcast
        [M,I] = max(A(:,1));
        A = A(1:I,:);
        
        % extract measurements on the approximate desired interval
        [inds,~] = dsearchn(A(:,1),(2:dz:floor(M))');
        inds = unique(inds);
        A = A(inds,:);
        A(:,1) = (2:floor(M))';
        
        % store results
        CTD_cell{f-num_ignore} = A;
        full_depth_vec = unique([full_depth_vec, A(:,1)']);
        clear A;

        % close file
        fclose(fid);
    end
    
    % move to matrix
    CTD = zeros(length(CTD_cell),length(full_depth_vec),4);
    for i = 1:length(CTD_cell)
        CTD(i,1:size(CTD_cell{i},1),:) = CTD_cell{i};
    end

    save(fullfile(datadir,"CTD_data.mat"));
end