function [pwgt, pbuy, psell] = maximizeSharpeRatio(obj)
%maximizeSharpeRatio - Estimate efficient portfolio that maximizes the Sharpe ratio.
%
%	[pwgt, pbuy, psell] = maximizeSharpeRatio(obj);
%
%	[pwgt, pbuy, psell] = obj.maximizeSharpeRatio;
%
% Inputs:
%	obj - A PortfolioDemo object [PortfolioDemo].
%
% Outputs:
%	pwgt - A portfolio on the efficient frontier with maximum Sharpe ratio [NumAssets vector].
%   pbuy - Purchases relative to an initial portfolio for a portfolio on the efficient frontier with
%           maximum Sharpe ratio [NumAssets vector].
%   psell - Sales relative to an initial portfolio for a portfolio on the efficient frontier with
%           maximum Sharpe ratio [NumAssets vector].
%
% Copyright 2011 The MathWorks, Inc.

% check arguments

if ~checkobject(obj) || isempty(obj)
	error('finance:PortfolioDemo:maximizeSharpeRatio:InvalidInputObject', ...
		'Input PortfolioDemo object is either invalid, empty, or an array of PortfolioDemo objects.');
end

% obtain range of portfolio returns on the efficient frontier

pret = obj.estimatePortReturn(obj.estimateFrontierLimits);

% minimize the local objective function to obtain a return that maximizes the Sharpe ratio

fhandle = @(r) local_objective(r, obj);

options = optimset('fminbnd');
options = optimset(options, 'Display', 'off', 'TolX', 1.0e-8);

[ropt, ~, exitflag] = fminbnd(fhandle, min(pret), max(pret), options);

if exitflag <= 0
	error('finance:PortfolioDemo:maximizeSharpeRatio:CannotObtainMaximum', ...
        'Unable to maximize the Sharpe ratio. Exit flag from fminbnd is %d.\n', ...
        exitflag);
end

[pwgt, pbuy, psell] = obj.estimateFrontierByReturn(ropt);

function sratio = local_objective(r, obj)
%local_objective - Local objective function which is the negative of the Sharpe ratio.

s = obj.estimatePortRisk(obj.estimateFrontierByReturn(r));

if ~isempty(obj.RiskFreeRate)
	sratio = -(r - obj.RiskFreeRate)/s;
else
	sratio = -r/s;
end
