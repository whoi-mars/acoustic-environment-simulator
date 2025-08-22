function [CTD, full_depth_vec] = load_asc_CTD_data(datadir,dz,varargin)
    % LOAD_ASC_CTD_DATA Extract CTD data and take closest points along the
    % vector Dmin:dz:Dmax. If 'CTD_data.mat' is not saved in 'datadir'
    % already, then the data will be extracted. If it is, it will simply be
    % loaded.
    %
    % Parameters
    % ----------
    % required
    % --------
    % datadir: path to directory containing CTD data files.
    % dz:      spacing in depth vector.
    % optional
    % --------
    % Dmin:     minimum considered depth (to eliminate noise before cast
    %           begins.
    % Dmax:     maximum considered depth.
    % fill_top: whether or not to extend the SSP to z = 0 m.
    %
    % Results
    % -------
    % CTD_cell:       cell array where each element contains a result
    %                 matrix 'A' from each CTD file. the columns of 'A' are 
    %                 [depth, temp., salinity, sound speed].
    % full_depth_vec: depth vector that ranges from 2 to the max depth
    %                 among all CTD files with a spacing of 'dz'.
    
    
    % parse inputs
    parser = inputParser;
    addRequired(parser,'datadir');
    addRequired(parser,'dz',@isscalar);
    checkNonNegInt = @(x) isscalar(x) && x >= 0;
    addParameter(parser,'Dmin',2,checkNonNegInt);
    addParameter(parser,'Dmax',200,checkNonNegInt);
    addParameter(parser,'fill_top',false,@islogical);
    parse(parser,datadir,dz,varargin{:});

    % unpack inputs
    datadir = parser.Results.datadir;
    dz = parser.Results.dz;
    Dmin = parser.Results.Dmin;
    Dmax = parser.Results.Dmax;
    fill_top = parser.Results.fill_top;

    % depth range check
    assert(Dmin < Dmax,"'Dmin must be less than Dmax.");

    if exist(fullfile(datadir,'CTD_data.mat'),'file') == 2
        fprintf("Loading From Save...");
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
        A = A(A(:,1)>Dmin & A(:,1)<Dmax,:);

        % extract downcast
        [M,I] = max(A(:,1));
        A = A(1:I,:);
        
        % extract measurements on the approximate desired interval
        [inds,errs] = dsearchn(A(:,1),(Dmin:dz:floor(M))');
        
        % make sure error from desired depths are small enough
        if ~isempty(errs(errs > 1))
            warning("Due to choice of 'dz', some points differ from the desired depth by more than 1 meter.");
        end
        
        % replace depths with desired vector which the depths are
        % approximately taken from
        inds = unique(inds);
        A = A(inds,:);
        A(:,1) = (Dmin:floor(M))';
        
        % store results
        CTD_cell{f-num_ignore} = A;
        full_depth_vec = unique([full_depth_vec, A(:,1)']);
        clear A;

        % close file
        fclose(fid);
    end
    
    % rotate depth vector
    full_depth_vec = full_depth_vec';

    % move to matrix
    CTD = zeros(length(CTD_cell),length(full_depth_vec),4);
    for i = 1:length(CTD_cell)
        CTD(i,1:size(CTD_cell{i},1),:) = CTD_cell{i};
    end
    
    % fill top of SSP
    if fill_top
        z_fill = (0:dz:min(full_depth_vec))';
        full_depth_vec = [z_fill; full_depth_vec];
        CTD_fill = CTD(:,1,:) .* ones(size(CTD,1),length(z_fill),size(CTD,3));
        CTD_fill(:,1:length(z_fill),1) = repelem(z_fill',size(CTD,1),1);
        CTD = [CTD_fill CTD];
    end
    
    fprintf("Saving...");
    save(fullfile(datadir,"CTD_data.mat"),'CTD','full_depth_vec');
end