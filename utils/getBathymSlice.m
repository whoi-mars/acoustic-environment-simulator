function [pts_ind_grid,r_list_grid] = getBathymSlice(range, loc_s, loc_r, dr, mesh_x, mesh_y)
    % GETBATHYMSLICE Gets points along a slice of bathymetry which are 
    % approximately a desired length apart (potentially with the exception 
    % of the last step if the residual is less than the desired length). It 
    % is approximate because this method uses the flat-Earth assumption.
    %
    % Parameters
    % ----------
    % range:         An L X M map where each point contains the range of 
    %                those coordinates on the bathymetry map to a 
    %                particular TOSSIT.
    % loc_s:         Pixel coordinates of the source on the bathymetry map.
    % loc_r:         Pixel coordinates of the TOSSIT on the bathymetry map.
    % dr:            Desired distance in km between points along the 
    %                bathymetry slice. One of the steps will probably be 
    %                shorter because the interval likely cannot be divided 
    %                into an whole number of equal segments.
    % mesh_x:        grids of x distances relative to each TOSSIT in km.
    % mesh_y:        grids of y distances relative to each TOSSIT in km.
    %
    % Returns
    % -------
    % pts_ind_grid:  An N X 2 matrix containing y coordinates in the first 
    %                column and x coordinates in the second column for the 
    %                points which create the bathymetry slice.
    % r_list_grid:   List of approximate distances between the points in
    %                the pts matrix in m (from receiver to source)

    % angle of vector from receiver to source location
    theta = rad2deg(atan2((mesh_y(loc_s(1),loc_s(2)) - mesh_y(loc_r(1),loc_r(2))), (mesh_x(loc_s(1),loc_s(2)) - mesh_x(loc_r(1),loc_r(2)))));

    % get receiver/source range
    r_s = range(loc_s(1), loc_s(2));

    % make list of ranges spaced by 'dr' accounting for potential residual
    % in the last step
    r_list = 0:dr:r_s;
    if r_list(end) ~= r_s
        r_list = [r_list r_s];
    end

    %----------------------------------------------
    %        Calculate Points Along Slice 
    %----------------------------------------------
    % get unit vector from source to receiver
    n_hat = repelem([sind(theta) cosd(theta)],length(r_list),1);
    % calculate raw points
    pts = r_list'.*n_hat;
    
    % get x indices of points in mesh
    pts_x_d3(1,1,:) = pts(:,2);
    stack_mesh_x = repelem(mesh_x,1,1,size(pts,1));
    mesh_x_dists = abs(stack_mesh_x - pts_x_d3);
    x_errs = sum(mesh_x_dists,1);
    [~,pts_ind_x] = min(x_errs,[],2); 
    
    % get y indices of points in mesh
    pts_y_d3(1,1,:) = pts(:,1);
    stack_mesh_y = repelem(mesh_y,1,1,size(pts,1));
    mesh_y_dists = abs(stack_mesh_y - pts_y_d3);
    y_errs = sum(mesh_y_dists,2);
    [~,pts_ind_y] = min(y_errs,[],1);
    
    % get points matrix
    pts_ind_grid = [squeeze(pts_ind_y) squeeze(pts_ind_x)];

    %----------------------------------------------
    %               Post Processing 
    %----------------------------------------------
    % delete redundant points at the end which round to the same as the
    % source position due to a small residual
    while isequal(pts_ind_grid(end,:),pts_ind_grid(end-1,:))
        % r_list(end-1) = [];
        pts_ind_grid(end-1,:) = [];
    end
    
    % remake r_list using determined closest grid points
    pts_grid_x_km = mesh_x(sub2ind(size(mesh_x),pts_ind_grid(:,1),pts_ind_grid(:,2)));
    pts_grid_y_km = mesh_y(sub2ind(size(mesh_y),pts_ind_grid(:,1),pts_ind_grid(:,2)));
    r_list_grid = zeros(1,size(pts_ind_grid,1));
    for i = 1:length(r_list_grid)
        r_list_grid(i) = sqrt((pts_grid_y_km(1) - pts_grid_y_km(i)).^2 + (pts_grid_x_km(1) - pts_grid_x_km(i)).^2);
    end


    % rearrange so the points for from source to receiver
    pts_ind_grid = flip(pts_ind_grid,1);
    r_list_grid = flip(r_list_grid(end) - r_list_grid);
end