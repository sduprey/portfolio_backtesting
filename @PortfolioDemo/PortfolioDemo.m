classdef PortfolioDemo < Portfolio
	%PortfolioDemo - Extended Portfolio object that has a few additional methods.
    %
    % Copyright 2011 The MathWorks, Inc.

	methods (Access = 'public', Static = false, Hidden = false)
		
		% constructor method
		
		function obj = PortfolioDemo(varargin)
			%PortfolioDemo - Construct PortfolioDemo object.
			
			if nargin < 1 || isempty(varargin)
				% no argument list
				% create a PortfolioDemo object from scratch and put into obj
				% return object with empty properties
				return
			elseif isa(varargin{1}, 'PortfolioDemo')
				% first argument is a PortfolioDemo object so put into obj
				% put remaining argument list into the variable arglist
				obj = varargin{1};
				if ~isscalar(obj)
					error('finance:PortfolioDemo:PortfolioDemo:NonScalarPortfolioDemoObject', ...
						['A non-scalar PortfolioDemo object was passed into the constructor.\n' ...
						'Only scalar PortfolioDemo objects can be processed by the constructor.']);
				end
				if nargin > 1
					arglist = varargin(2:end);
				else
					return
				end
			else
				% argument list is just parameter-value pairs
				% make sure that no PortfolioDemo object in the argument list after the first argument
				% if ok, put argument list into the variable arglist
				arglist = varargin;
				for i = 1:numel(arglist)
					if isa(arglist{i}, 'PortfolioDemo')
						error('finance:PortfolioDemo:PortfolioDemo:ImproperObjectInput',...
							['A PortfolioDemo object was passed incorrectly into the constructor.\n' ...
							'Only the first argument may be a PortfolioDemo object with syntax\n\t', ...
								'obj = PortfolioDemo(obj, ''Property1'', value1, ... );']);
					end
				end
			end
			
			% separate parameters and values from argument list
			parameters = arglist(1:2:end);
			values = arglist(2:2:end);

			% make sure pairs of parameters and values
			if numel(parameters) ~= numel(values)
				error('finance:PortfolioDemo:PortfolioDemo:InvalidParameterValuePairs',...
					['Invalid syntax for parameter-value pairs for PortfolioDemo constructor. ', ...
					'Syntax must be either\n\t' ...
					'obj = PortfolioDemo(''Property1'', value1, ... );\n' ...
					'or\n\t' ...
					'obj = PortfolioDemo(obj, ''Property1'', value1, ... );']);
			end
			
			% make sure parameters are strings
			for i = 1:numel(parameters)
				if ~ischar(parameters{i})
					error('finance:PortfolioDemo:PortfolioDemo:InvalidParameterString',...
						['Non-string parameter encountered for a parameter-value pair. ', ...
						'Syntax must be either\n\t' ...
						'obj = PortfolioDemo(''Property1'', value1, ... );\n' ...
						'or\n\t' ...
						'obj = PortfolioDemo(obj, ''Property1'', value1, ... );']);
				end
			end
			
			% parse arguments
			obj = parsearguments(obj, parameters, values);
			
			% check arguments
			obj = checkarguments(obj);
		
        end
		
		% demo methods		
		[pwgt, pbuy, psell] = maximizeSharpeRatio(obj);
	
	end
	

end
