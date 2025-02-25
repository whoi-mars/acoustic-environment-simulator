function getBathymSlice(range, loc_s, loc_r, dr, mesh_x, mesh_y)
    % Gets points along a slice of bathymetry which are approximately a
    % desired length apart (potentially with the exception of the last step
    % if the residual is less than the desired length). It is approximate
    % because this method uses the flat-Earth assumption.
    %
    % Parameters
    % range        : An L X M map where each point contains the range of those
    %                coordinates on the bathymetry map to a particular TOSSIT.
    % loc_s        : Pixel coordinates of the source on the bathymetry map.
    % loc_r        : Pixel coordinates of the TOSSIT on the bathymetry map.
    % dx           : Approximatly how many meters across each pixel is in the x
    %                dimension.
    % dy           : Approximatly how many meters across each pixel is in the y
    %                direction.
    % dr           : Desired distance in km between points along the bathymetry
    %                slice. One of the steps will probably be shorter because the
    %                interval likely cannot be divided into an whole number of
    %                equal segments.
    %
    % Returns
    % pts          : An N X 2 matrix containing y coordinates in the first column
    %                and x coordinates in the second column for the points which
    %                create the bathymetry slice.
    % delta_r_list : List of approximate distances between the points in
    %                the pts matrix in m (from receiver to source)

    % angle of vector from source to receiver location
    theta = rad2deg(atan2((mesh_y(loc_r(1),loc_r(2)) - mesh_y(loc_s(1),loc_s(2))), (mesh_x(loc_r(1),loc_r(2)) - mesh_x(loc_s(1),loc_s(2)))));
   
    
    % if loc_s(1) <= loc_r(1) && loc_s(2) <= loc_r(2)
    %     a_fac = -1;
    %     b_fac = -1;
    % elseif loc_s(1) > loc_r(1) && loc_s(2) <= loc_r(2)
    %     a_fac = -1;
    %     b_fac = 1;
    % elseif loc_s(1) > loc_r(1) && loc_s(2) > loc_r(2)
    %     a_fac = 1;
    %     b_fac = 1;
    % else
    %     a_fac = 1;
    %     b_fac = -1;
    % end
    
    % % get source/receiver range
    % r_s = range(loc_s(1), loc_s(2));
    % 
    % % make list of ranges, accounting for residual in the last step
    % r_list = 0:dr:r_s;
    % if r_list(end) ~= r_s
    %     r_list = [r_list r_s];
    % end
    % 
    % % calculate points
    % a = a_fac*(r_list / sqrt(dx^2 + dy^2*slope^2));
    % b = b_fac*(r_list / sqrt((dx / slope)^2 + dy^2));
    % 
    % % get final range list and points aligned with TOSSIT
    % pts = [(round(b) + loc_r(1))', (round(a) + loc_r(2))'];
    % % eliminate redundant points at the end where the last jump
    % % rounds to the same final point
    % while isequal(pts(end,:),pts(end-1,:))
    %     r_list(end-1) = [];
    %     pts(end-1,:) = [];
    % end
    % delta_r_list = 1000*range(sub2ind(size(range),pts(:,1),pts(:,2))).';
    % % delta_r_list = 1000*sqrt((a*dx).^2 + (b*dy).^2);
    % 
    % %pts = flip(pts,1);
    % %delta_r_list = flip(max(delta_r_list) - delta_r_list);
end