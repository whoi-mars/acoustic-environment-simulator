function TOSSIT_latlons = get_TOSSIT_latlons(layout, varargin)
    % Function to automatically generate the TOSSIT longitude/latitude points for
    % a particular TOSSIT layout.
    % 
    % Parameters
    % Layout         : The type of layout to generate.
    %              - 'ccb2022' : TOSSIT layout from the 2022 CCB experiment
    %                'ccb2023' : TOSSIT layout from the 2023 CCB experiment
    %              - 'grid'    : Construct a grid layout from the TOSSITs
    %              - 'circle'  : Construct a concentric circle layout from the TOSSITs
    % StartLocation      : For the 'grid' layout, this parameter provides the most
    %                      upper-left TOSSIT location. For the 'circle' layout, this
    %                      provides the center of the concentric circle TOSSIT layout.
    % Dims               : For the 'grid' layout, this parameter provides the dimensions
    %                      of the TOSSIT grid to draw out.
    % Spacing            : For the 'grid' layout, thi parameter provides the distance between
    %                      every pair of adjacent TOSSITs.
    % Spokes             : For the 'circle' layout, this specifies the number of spokes from
    %                      StartLocation
    % NumberPerSpoke     : For the 'circle' layout, this specifies the number of TOSSITs
    %                      on each spoke.
    %
    % Returns
    % TOSSIT_latlons     : An N X 2 matrix where the first column contains latitudes
    %                      and the second column contains longitudes.
    
    p = inputParser;
    addRequired(p,'Layout',@(l)validateattributes(l,{'char', 'string'},{'nonempty'}));
    addOptional(p,'StartLocation',[1 1],@(x)validateattributes(x,{'numeric'},{'size',[1,2]}));
    addOptional(p,'Dims',[2 2],@(x)validateattributes(x,{'numeric'},{'size',[1,2],'integer','positive'}));
    addOptional(p,'Spacing',5,@(x)validateattributes(x,{'numeric'},{'scalar'}));
    addOptional(p,'Spokes',3,@(x)validateattributes(x,{'numeric'},{'scalar'}));
    addOptional(p,'NumberPerSpoke',1,@(x)validateattributes(x,{'numeric'},{'scalar'}));
    parse(p,layout,varargin{:});
    
    if strcmpi(layout, "ccb2022")
        TOSSIT_latlons = [42.003699488862175, -70.376033211521670;
                          42.035427096800000, -70.418802396800000;
                          42.035427096800000, -70.332969334700010;
                          41.972094000000000, -70.418802000000000;
                          41.972094000000000, -70.332969000000000];
    elseif strcmpi(layout, "ccb2023")
        TOSSIT_latlons = [41.910825, -70.429297;
                          41.956023, -70.429105;
                          42.001120, -70.428992;
                          42.001098, -70.368635;
                          42.000940, -70.305142;
                          42.001002, -70.247648;
                          41.955833, -70.247817;
                          41.916856, -70.243174;
                          41.911469, -70.307519;
                          41.955866, -70.308182;
                          41.957085, -70.368867;
                          41.911413, -70.368597];
    elseif strcmpi(layout, "ccb2023_reduced_5")
        TOSSIT_latlons = [41.910825, -70.429297;
                          41.956023, -70.429105;
                          41.955866, -70.308182;
                          41.957085, -70.368867;
                          41.911413, -70.368597];
    elseif strcmpi(layout, "ccb2023_reduced")
        TOSSIT_latlons = [41.910825, -70.429297;
                          41.956023, -70.429105;
                          42.001120, -70.428992;
                          42.001098, -70.368635;
                          42.000940, -70.305142;
                          41.911469, -70.307519;
                          41.955866, -70.308182;
                          41.957085, -70.368867;
                          41.911413, -70.368597];
    elseif strcmpi(layout, "ccb2023_reduced_4")
        TOSSIT_latlons = [41.910825, -70.429297;
                          41.956023, -70.429105;
                          41.957085, -70.368867;
                          41.911413, -70.368597];
    elseif strcmpi(layout, "mudpatch")
        TOSSIT_latlons = [40.46, -70.5663
                         40.4365, -70.506;
                         40.4304, -70.4913;
                         40.4825, -70.6225;
                         40.489, -70.6381;
                         40.4919, -70.514;
                         40.5004, -70.5014;
                         40.4581, -70.4986;
                         40.4598, -70.481;
                         40.4591, -70.6301;
                         40.4577, -70.6484;
                         40.5093, -70.5664;
                         40.5218, -70.5669;
                         40.4708, -70.5941;
                         40.4473, -70.534;
                         40.4758, -70.5411;
                         40.4407, -70.5963];
    elseif strcmpi(layout, "grid")
        j1_latlon = p.Results.StartLocation;
        TOSSIT_latlons = zeros(prod(p.Results.Dims),2);
        for i=1:p.Results.Dims(1)
            TOSSIT_latlons((i-1)*p.Results.Dims(2) + 1,:) = j1_latlon;
            curr_latlon = j1_latlon;
            for j=2:p.Results.Dims(2)
                curr_latlon = reckon(curr_latlon(1), curr_latlon(2), km2deg(p.Results.Spacing), 90);
                TOSSIT_latlons((i-1)*p.Results.Dims(2) + j, :) = curr_latlon; 
            end
            j1_latlon = reckon(j1_latlon(1), j1_latlon(2), km2deg(p.Results.Spacing), 180);
        end
    elseif strcmpi(layout, "circle")
        delta_theta = 360 / p.Results.Spokes;
        center_latlon = p.Results.StartLocation;
        TOSSIT_latlons = zeros(p.Results.Spokes * p.Results.NumberPerSpoke,2);
        
        current_theta = 0;
        for i=1:p.Results.Spokes
            curr_latlon = reckon(center_latlon(1), center_latlon(2), km2deg(p.Results.Spacing / 2), current_theta);
            TOSSIT_latlons((i-1)*p.Results.NumberPerSpoke + 1, :) = curr_latlon;
            for j=2:p.Results.NumberPerSpoke
                curr_latlon = reckon(curr_latlon(1), curr_latlon(2), km2deg(p.Results.Spacing), current_theta);
                TOSSIT_latlons((i-1)*p.Results.NumberPerSpoke + j, :) = curr_latlon;
            end
            current_theta = current_theta + delta_theta;
        end
    else
        error("layout must be one of 'ccb2022', 'ccb2023', 'grid', 'circle'.");
    end
end