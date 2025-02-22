function [inds] = find_in_vec(x,nums,varargin)
    % FIND_IN_VEC find a element/elements and warn based on found value,
    % desired value, and provided threshold.
    %
    % Parameters
    % ----------
    % required
    % --------
    % x:      vector of numbers.
    % nums:   number(s) to find.
    % optional
    % --------
    % thresh: threshold at which to warn of found value inaccuracy. 
    
    % parse inputs
    parser = inputParser;
    addRequired(parser,'x',@isvector);
    addRequired(parser,'nums',@isvector);
    checkPosScalar = @(x) isscalar && x >= 0;
    addParameter(parser,'thresh',1e-6,checkPosScalar);
    parse(parser,x,nums,varargin{:});

    % unpack inputs
    x = parser.Results.x;
    nums = parser.Results.nums;
    thresh = parser.Results.thresh;

    % find values
    [inds,dist] = dsearchn(x,nums);
    
    % check threshold
    if ~isempty(dist(dist>thresh))
        warning("Some points exceed the established tolerance threshold.");
    end
end