classdef KLE
    % KLE A class that performs a KL expansion on provided 1D function
    % examples that are all sampled at the same coordinates and allows one 
    % to sample from the process using a truncated series from the 
    % expansion.

    properties
        mu
        V
        D
        sigma
    end

    methods
        function obj = KLE(data,varargin)
            % KLE Class constructor which calculates the RBF kernel matrix
            % along with its eigendecomposition.
            %
            % Parameters
            % ----------
            % required
            % --------
            % data: examples used to derive the eigenbasis for the KL
            %       expansion. Each row is a function sample.
            % optional
            % --------
            % sigma: correlation length for the radial basis function
            %        kernel.
            %
            % Returns
            % -------
            % obj: KLE object.
            
            % parse input
            parser = inputParser;
            addRequired(parser,'data',@ismatrix);
            checkPosInt = @(x) isscalar(x) && x > 0;
            addParameter(parser,'sigma',2,checkPosInt);
            parse(parser,data,varargin{:});
            
            % unpack inputs
            data = parser.Results.data;
            obj.sigma = parser.Results.sigma;

            % get data mean and center data
            obj.mu = mean(data,1,"omitnan")';
            data = data - obj.mu';
            
            % calculate kernel
            kernel = zeros(size(data,2));
            for i = 1:size(data,2)
                kernel(i,:) = obj.rbf(data(:,i),data);
            end
            
            % get eigenvalues/vectors
            [V,D] = eig(kernel);
            
            % sort with most significant basis functions first
            [vals,I] = sort(diag(D),'descend');
            obj.V = V(:,I);
            obj.D = diag(vals);
        end

        function [samples, varargout] = sample(obj,n,trunc,varargin)
            % SAMPLE Sample data modeled as a Gaussian random process using
            % a truncated KL expansion. Note that NaN values are ignored.
            %
            % Parameters
            % ----------
            % required
            % --------
            % obj:    KLE object.
            % n:      number of samples to generate.
            % trunc:  if > 1, will truncate to that many modes. if in (0,1),
            %         will truncate to keep that percentage of explained
            %         variance.
            % optional
            % --------
            % coeffs: flag to return random coefficients used of shape 
            %         M X n.
            %
            % Returns
            % -------
            % samples: matrix of sampled functions where they are the
            %          columns.
            % coeffs:  utilized eigenvalues in sampling
            
            % parse inputs
            parser = inputParser;
            checkPosInt = @(x) isscalar(x) && x > 0;
            addRequired(parser,'n',checkPosInt);
            addRequired(parser,'trunc');
            addParameter(parser,'coeffs',false,@islogical);
            parse(parser,n,trunc,varargin{:});

            % unpack inputs
            n = parser.Results.n;
            trunc = parser.Results.trunc;
            coeffs = parser.Results.coeffs;

            if trunc > 1 && trunc <= size(obj.V,1)
                M = trunc;
            elseif trunc > 0 && trunc < 1
                evs = diag(obj.D);
                evs(evs < 0) = 0;
                exp_var = cumsum(evs) / sum(evs);
                M = find(exp_var >= trunc,1,'first');
            else
                error("'trunc' must be > 0 and < # samples per function.");
            end
            
            % sample SSP using truncatedobj KL expansion
            Z = randn(M,n);
            D_M = sqrt(obj.D(1:M,1:M));
            V_M = obj.V(:,1:M);
            samples = obj.mu + V_M*D_M*Z;
            
            % get random coefficients used if desired
            if coeffs
                varargout{1} = Z .* diag(D_M);
            end
        end
    end

    methods (Access = private)
        function res = rbf(obj,x,y)
            % RBF Radial basis function. NaN values are ignored. inner
            % product calculated along rows.
            %
            % Parameters
            % ----------
            % obj: KLE object.
            % x:   vector.
            % y:   vector or matrix of samples as columns.
            
            res = exp(-sum((x - y).^2,1,"omitnan") / (2 * obj.sigma.^2));
        end
    end
end


