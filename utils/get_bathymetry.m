function [D_grid, locs_ok, TOSSIT_latlons_grid, TOSSIT_latlons_inds, range_grids, mesh_lon, mesh_lat, mesh_x, mesh_y] = get_bathymetry(filepath,bathym_round,loc_dilation,env_bounds,TOSSIT_latlons,min_water_depth)
    % GET_BATHYMETRY Properly load the bathymetry and calculate and return
    % all the relevant metadata used in simulation.
    %
    % Parameters
    % ----------
    % filepath  :      path to bathymetry file.
    % bathym_round:    nearest interval to round the depths to.
    % loc_dilation:    dilation factor for valid source locations.
    % env_bounds:      lat/lon corners of a rectangular region of the form 
    %                  [UL; LL; LR; UR] where the first column is lat and 
    %                  the second is lon.
    % TOSSIT_latlons:  raw lat/lon values of the TOSSITs where the first
    %                  column is lat and the second is lon.
    % min_water_depth: minimum acceptable source water depth.
    %
    % Returns
    % -------
    % D_grid:              grid of depths (NB: latitudes increase downwards 
    %                      with index).
    % locs_ok:             logical grid denoting valid source positions.
    % TOSSIT_latlons_grid: lat/lon values of the TOSSITs snapped to closest
    %                      points in the bathymetry grid where the first
    %                      column is the lat and the second is the lon.
    % TOSSIT_latlons_inds: indices in the bathymetry grid for the TOSSITs.
    % range_grids        : grids of ranges from each point to each TOSSIT
    %                      in km.
    % mesh_lon           : grid of longitude values.
    % mesh_lat           : grid of latitude values.
    % mesh_x             : grids of x distances relative to each TOSSIT in
    %                      km.
    % mesh_y             : grids of y distances relative to each TOSSIT in 
    %                      km.
    
    % get number of TOSSITs
    num_TOSSITs = size(TOSSIT_latlons,1);

    % grab bathymetry
    bath = load(filepath);

    % orient lat correctly
    bath.lat = fliplr(bath.lat);
    bath.d = flipud(bath.d);
    
    %--------------------------------------
    %     Trim to Environmental Bounds
    %--------------------------------------
    
    % get bounds
    min_lat = env_bounds(2,1);
    max_lat = env_bounds(1,1);
    min_lon = env_bounds(2,2);
    max_lon = env_bounds(3,2);

    % get indices
    [~,min_lat_ind] = min(abs(bath.lat - min_lat));
    [~,max_lat_ind] = min(abs(bath.lat - max_lat));
    [~,min_lon_ind] = min(abs(bath.lon - min_lon));
    [~,max_lon_ind] = min(abs(bath.lon - max_lon));

    % trim lat/lon
    bath.lat = bath.lat(min_lat_ind:max_lat_ind);
    bath.lon = bath.lon(min_lon_ind:max_lon_ind);

    % trim depths
    bath.d = bath.d(min_lat_ind:max_lat_ind,min_lon_ind:max_lon_ind);

    %--------------------------------------
    %  Get Closest TOSSIT Latlons on Grid
    %--------------------------------------

    % repeat lats/lons for each TOSSIT
    lat_rep = repelem(bath.lat,num_TOSSITs,1);
    lon_rep = repelem(bath.lon,num_TOSSITs,1);

    % get closest lat/lon indices on grid from actual values
    [~,lat_inds] = min(abs(lat_rep - TOSSIT_latlons(:,1)),[],2);
    [~,lon_inds] = min(abs(lon_rep - TOSSIT_latlons(:,2)),[],2);
    
    % construct TOSSIT lat/lon values from grid matches
    TOSSIT_latlons_grid = [bath.lat(lat_inds).' bath.lon(lon_inds).'];
    TOSSIT_latlons_inds = [lat_inds lon_inds];

    %--------------------------------------
    %        Global Lon/Lat Meshes
    %--------------------------------------
    
    % assume the considered region is small enough such that lat/lon make a
    % uniform grid
    [mesh_lon,mesh_lat] = meshgrid(bath.lon,bath.lat);

    %--------------------------------------
    %  Range Grids Relative to Each TOSSIT
    %--------------------------------------
    
    % for storing ranges
    range_grids = zeros(length(bath.lat),length(bath.lon),num_TOSSITs);
    
    % point column vectors for lat/lon meshgrids
    lat_lon_grid_cols = [reshape(mesh_lat,[numel(mesh_lat) 1]) reshape(mesh_lon,[numel(mesh_lon) 1])];
    
    % calculate ranges
    for i = 1:num_TOSSITs
        range_grids(:,:,i) = reshape(deg2km(distance([TOSSIT_latlons_grid(i,1) * ones(size(lat_lon_grid_cols,1),1),...
                             TOSSIT_latlons_grid(i,2) * ones(size(lat_lon_grid_cols,1),1)],lat_lon_grid_cols)),[length(bath.lat),length(bath.lon)]);
    end

    %-----------------------------------------
    %   X/Y Meshes Relative to Each TOSSIT 
    %-----------------------------------------
    
    % store meshes
    mesh_x = zeros(length(bath.lat),length(bath.lon),num_TOSSITs);
    mesh_y = zeros(length(bath.lat),length(bath.lon),num_TOSSITs);
    
    % calculate meshes
    for i = 1:num_TOSSITs
        % handle x meshes
        lon_origin_x = mesh_lon(:,lon_inds(i));
        lat_origin_x = mesh_lat(:,lon_inds(i));
        for j = 1:length(bath.lon)
            mesh_x(:,j,i) = deg2km(distance([mesh_lat(:,j) mesh_lon(:,j)],[lat_origin_x lon_origin_x]));
        end
        mesh_x(:,1:lon_inds(i),i) = -mesh_x(:,1:lon_inds(i));

        % handle y meshes
        lon_origin_y = mesh_lon(lat_inds(i),:);
        lat_origin_y = mesh_lat(lat_inds(i),:);
        for j = 1:length(bath.lat)
            mesh_y(j,:,i) = deg2km(distance([mesh_lat(j,:); mesh_lon(j,:)].',[lat_origin_y; lon_origin_y].'));
        end
        mesh_y(1:lat_inds(i),:,i) = -mesh_y(1:lat_inds(i),:,i);
    end

    %-----------------------------------------
    %  Round Depth And Mark Valid Locations 
    %-----------------------------------------
    
    % round
    D_grid = -bath.d;
    D_grid = round(D_grid/bathym_round)*bathym_round;
    
    % get valid locations
    locs_ok = zeros(size(D_grid));
    locs_ok(1:loc_dilation:end,1:loc_dilation:end) = 1;
    locs_ok(D_grid < min_water_depth) = 0;
end