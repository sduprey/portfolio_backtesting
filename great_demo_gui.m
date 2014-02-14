function varargout = great_demo_gui(varargin)
% GREAT_DEMO_GUI MATLAB code for great_demo_gui.fig
%      GREAT_DEMO_GUI, by itself, creates a new GREAT_DEMO_GUI or raises the existing
%      singleton*.
%
%      H = GREAT_DEMO_GUI returns the handle to a new GREAT_DEMO_GUI or the handle to
%      the existing singleton*.
%
%      GREAT_DEMO_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GREAT_DEMO_GUI.M with the given input arguments.
%
%      GREAT_DEMO_GUI('Property','Value',...) creates a new GREAT_DEMO_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before great_demo_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to great_demo_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help great_demo_gui

% Last Modified by GUIDE v2.5 12-Feb-2012 21:34:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @great_demo_gui_OpeningFcn, ...
    'gui_OutputFcn',  @great_demo_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before great_demo_gui is made visible.
function great_demo_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to great_demo_gui (see VARARGIN)

% Choose default command line output for great_demo_gui
handles.output = hObject;
set(handles.axes,'XTick',[]);
set(handles.axes,'YTick',[]);
% Update handles structure

guidata(hObject, handles);

% UIWAIT makes great_demo_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = great_demo_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%set(hObject,'Position',[10 10 1000 750])
movegui(hObject,'center');


% --- Executes on button press in import_excel.
function import_excel_Callback(hObject, eventdata, handles)
% hObject    handle to import_excel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = uigetfile( ...
    {'*.xls;*.csv'},'Pick a file');
if (filename ~=0)
%     S= load('lightBlueChipStocks');
%     handles.Dates = S.Date;
%     handles.Data = S.Data;
%     handles.Assets = S.Asset;
%     handles.Map = S.Map;
%     handles.Prices = S.Prices;
    [handles.Dates,handles.Data,handles.Assets,handles.Map]=importfile(filename);
    handles.Prices = ret2tick(handles.Data);
    
    plot(handles.axes,handles.Dates,handles.Prices(2:end,:));
    legend(handles.Assets,'Location','NorthWest','FontSize',4);
    datetick('x');
    axis tight;
end
guidata(handles.output, handles);

% --- Executes on button press in launch_analysis.
function launch_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to launch_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

histo_date_start_string=get(handles.histo_start,'String');
histo_date_end_string=get(handles.histo_end,'String');
startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == handles.Dates);
endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == handles.Dates);

%assetindex = logical(Map(endindex,:));
AssetList=handles.Assets(1:end-2);
%AssetList = Assets(assetindex);

% Set up date and return arrays

AssetReturns = handles.Data(startindex:endindex,1:end-2);
MarketReturns = handles.Data(startindex:endindex,end-1);
CashReturns = handles.Data(startindex:endindex,end);

% Compute returns and risks for market and cash returns

mret = mean(MarketReturns);
mrsk = std(MarketReturns);
cret = mean(CashReturns);
crsk = std(CashReturns);

Turnover = get(handles.turnover,'Value') ;
Cost = get(handles.cost,'Value') ;
BuyCost = Cost;
SellCost = Cost;
p = Portfolio('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);

% Set up an equal-weight initial portfolio
p = p.setInitPort(1/p.NumAssets);
[ersk, eret] = p.estimatePortMoments(p.InitPort);

p = p.setDefaultConstraints;
pwgt = p.estimateFrontier(20);
[prsk,pret] = p.estimatePortMoments(pwgt);

p = p.setCosts(BuyCost, SellCost);
p = p.setTurnover(Turnover);

[qwgt, ~, ~] = p.estimateFrontier(20);
[qrsk, qret] = p.estimatePortMoments(qwgt);

% Plot efficient frontier with turnover constraint
assets_plot(['Assets Risks and Returns for historic period from ', histo_date_start_string,' to ', histo_date_end_string], ...
    {'scatter', mrsk, mret, {'Market'}}, ...
    {'scatter', crsk, cret, {'Cash'}}, ...
    {'scatter', ersk, eret, {'Equal'}}, ...
    {'scatter', sqrt(diag(p.AssetCovar)), p.AssetMean, p.AssetList, '.r'});
hold(handles.axes,'on');
handles.unconstrained_line =plot(handles.axes,sqrt(12)*prsk,12*pret,...
    '-bs','LineWidth',1);
hold(handles.axes,'on');
handles.constrained_line = plot(handles.axes,sqrt(12)*qrsk,12*qret,...
    '--rs','LineWidth',2);

guidata(handles.output, handles);

% --- Executes on button press in backtesting.
function backtesting_Callback(hObject, eventdata, handles)
% hObject    handle to backtesting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% control parameters for backtest

% Hints: get(hObject,'String') returns contents of EdRebalancing as text
%        str2double(get(hObject,'String'))
% todo : customize from the GUI
numportfolio = 20;					
% number of portfolios on each efficient frontier					% historical estimation window in months
window=str2double(get(handles.historic_period_edit,'String')) ;	
offset = str2double(get(handles.EdRebalancing,'String')) ;							% shift in time for each frontier in months
cutoff = 0.4;						% this fraction of data in a series must be non-NaN values
relative = true;					% true if relative returns, false if absolute returns
accumulate = true;					% true if accumulation of assets, false if current universe only
Turnover = get(handles.turnover,'Value') ;
Cost = get(handles.cost,'Value') ;
buycost = Cost;					% proportional cost to purchase shares
sellcost = Cost;					% proportional cost to sell shares
% default value 0.4
maxturnover = Turnover;					% upper bound for portfolio turnover (annual)
%todo : make it come from Excel
imarket = strcmpi('Market', handles.Assets);	% locate "market" series
icash = strcmpi('Cash', handles.Assets);		% locate "cash" series (riskfree rate proxy)

% bookkeeping

pfactor = 12/offset;				% factor to convert periodicity to annual period

% form cumulative map of assets (include all prior active assets that are still listed)

if accumulate
    for t = 2:size(handles.Map,1)
        handles.Map(t,:) = handles.Map(t - 1,:) | handles.Map(t,:);
    end
end

% ex-ante analysis

PortDate = [];
PortRisk = [];
PortReturn = [];
PortSigma = [];
PortMean = [];

PerfDate = [];
GrossPerfPort = [];
NetPerfPort = [];
GrossComposition = [];
NetComposition = [];
PerfMarket = [];
PerfCash = [];
Date = handles.Dates;
for t = window:offset:numel(Date)
    
    % set up date indices for current period
    startindex = t - window + 1;
    endindex = t;
    
    % select "market" series
    Xmarket = handles.Data(startindex:endindex,imarket);
    
    % select assets that are active on the endindex date
    iasset = handles.Map(endindex,:);
    
    % keep series with sufficient numbers of non-NaN values
    imissing = sum(isnan(handles.Data(startindex:endindex,:))) > cutoff*window;
    
    % form active universe for current endindex date
    iasset = logical(iasset) & ~logical(imissing);
    iasset(end-1:end) = 0;		% last two series are not stocks (not used in this step)
    
    % select data for active universe
    A = handles.Assets(iasset);
    X = handles.Data(startindex:endindex,iasset);
    
    fprintf('Estimation period %s to %s with %d assets ...\n', ...
        datestr(handles.Dates(startindex)), datestr(handles.Dates(endindex)),numel(A));
    % map prior portfolios into current universe
    contents = cellstr(get(handles.console_output,'String'));
    contents = {contents{:},['Estimation period ',datestr(handles.Dates(startindex)),' to ',datestr(handles.Dates(endindex)),' with ',num2str(numel(A)),' assets ...'] }; %#ok<AGROW>
    set(handles.console_output,'String',contents);
    set(handles.console_output,'Value',length(contents));
    drawnow;

    if t > window
        pinit = zeros(numel(iasset0),1);
        qinit = zeros(numel(iasset0),1);
        rinit = zeros(numel(iasset0),1);
        
        % adjust prior portfolio weights for prior period's returns
        retinit = Xret(iasset0);
        
        pinit(iasset0) = (1/(1 + retinit*pwgt))*((1 + retinit') .* pwgt);
        rinit(iasset0) = (1/(1 + retinit*rwgt))*((1 + retinit') .* rwgt);
    end
    
    % remove "market" from the data (market-neutral relative returns)  
    if relative
        X = X - repmat(Xmarket, 1, numel(A));
    end
    
    % construct portfolio object (use RiskFreeRate if not market-neutral)
    p = PortfolioDemo('AssetList', A, 'Name', sprintf('Universe %s', datestr(handles.Dates(endindex))));
    if ~relative
        p = PortfolioDemo(p, 'RiskFreeRate', handles.Data(endindex,icash));
    end
    p = p.setDefaultConstraints;
    p = p.estimateAssetMoments(X, 'MissingData', true);
    if t > window
        p = p.setTurnover(maxturnover/pfactor, pinit(iasset));
    end
    

    r = p.setCosts(buycost, sellcost, 0);		% intrinsic net returns
    if t > window
        r = r.setTurnover(maxturnover/pfactor, rinit(iasset));
    end
    
    % estimate portfolios on turnover-constrained frontier
    
    fwgt = r.estimateFrontier(numportfolio);
    
    % estimate portfolio that maximizes the ratio of relative risk to relative return
    %	if absolute returns, then maximize the Sharpe ratio
    
    pwgt = p.maximizeSharpeRatio;
    [prsk, pret] = p.estimatePortMoments(pwgt);
    
    rwgt = r.maximizeSharpeRatio;
    [rrsk, rret] = r.estimatePortMoments(rwgt);
    
    % enter data for 3D frontier   
    PortDate = [ PortDate; Date(endindex) ];%#ok<AGROW>
    PortRisk = [ PortRisk; sqrt(pfactor)*(p.estimatePortRisk(fwgt))' ];%#ok<AGROW>
    PortReturn = [ PortReturn; pfactor*(p.estimatePortReturn(fwgt))' ];%#ok<AGROW>
    
    PortSigma = [ PortSigma; sqrt(pfactor)*rrsk ];%#ok<AGROW>
    PortMean = [ PortMean; pfactor*rret ];%#ok<AGROW>
    
    % evaluate performance
    if (endindex + offset) <= numel(Date)
        Xret = ret2tick(handles.Data(endindex+1:endindex+offset,:));
        Xret = Xret(end,:) - 1;
        
        PerfDate = [ PerfDate; Date(endindex+offset) ];%#ok<AGROW>
        
        % gross portfolio return
        if t > window
            pcurrent = zeros(numel(iasset),1);
            pcurrent(iasset) = pwgt;
            pbuy = max(0, pcurrent - pinit);
            psell = max(0, pinit - pcurrent);
            pcost = 0;
            pturnover = pturnover + 0.5*(sum(pbuy) + sum(psell));
        else
            pcost = 0;
            pturnover = 0;
        end
        GrossPerfPort = [ GrossPerfPort; Xret(iasset)*pwgt ]; %#ok<AGROW>
        pcompo = zeros(numel(iasset),1);
        pcompo(iasset) = pwgt;
        GrossComposition = [GrossComposition, pcompo]; %#ok<AGROW>
        %  net portfolio return
        if t > window
            rcurrent = zeros(numel(iasset),1);
            rcurrent(iasset) = rwgt;
            rbuy = max(0, rcurrent - rinit);
            rsell = max(0, rinit - rcurrent);
            rcost = buycost*sum(rbuy) + sellcost*sum(rsell);
            rturnover = rturnover + 0.5*(sum(rbuy) + sum(rsell));
        else
            rcost = 0;
            rturnover = 0;
        end
        NetPerfPort = [NetPerfPort; (Xret(iasset)*rwgt - rcost) ];%#ok<AGROW>
        rcompo = zeros(numel(iasset),1);
        rcompo(iasset) = rwgt;
        NetComposition = [NetComposition, rcompo]; %#ok<AGROW>
        
        PerfMarket = [ PerfMarket; Xret(imarket) ];%#ok<AGROW>
        PerfCash = [ PerfCash; Xret(icash) ];%#ok<AGROW>
    end
    
    % save information from current period to be used in next period 
    iasset0 = iasset;
end

% set up dates across 3D frontier
hist_Dates = PortDate;
PortDate = repmat(PortDate, 1, numportfolio);

%% plot results
%load computation_done;
cla(handles.axes);
surf(PortDate, PortRisk, PortReturn, ...
    'FaceColor', 'interp', 'EdgeColor', 'none', 'FaceLighting', 'phong');
hold on
plot3(PortDate(:,1), PortSigma, PortMean + 1.0e-3, 'w', 'LineWidth',6);
datetick('x');
xlabel('');
ylabel('Portfolio Risk');
zlabel('Portfolio Returns');
title('\bfTime Evolution of Efficient Frontier');
camlight right
view(30, 30);
hold off
% load quaterly_computations,
figure(1);
surf(PortDate, PortRisk, PortReturn, ...
    'FaceColor', 'interp', 'EdgeColor', 'none', 'FaceLighting', 'phong');
hold on
plot3(PortDate(:,1), PortSigma, PortMean + 1.0e-3, 'w', 'LineWidth', 6);
datetick('x');
ylabel('Portfolio Risk');
zlabel('Portfolio Returns');
title('\bfTime Evolution of Efficient Frontier');
camlight right
view(30, 30);
hold off

figure(2);
plot([datenum(Date(window)); PerfDate], ...
    ret2tick([GrossPerfPort,NetPerfPort, PerfMarket, PerfCash]));
datetick('x');
title('\bfBacktest Performance of Portfolio Strategy');
ylabel('Cumulative Value of $1 Invested 31-Dec-1984');
legend('Gross', 'Net', 'Market', 'Cash', 'Location', 'NorthWest');

%% summarize results
comp = {GrossComposition,NetComposition};
perf = [GrossPerfPort, NetPerfPort, PerfMarket, PerfCash];

pmean = pfactor*mean(perf);
pstdev = sqrt(pfactor)*std(perf);
perfret = ret2tick(perf);
ptotret = (perfret(end,:) .^ (pfactor/size(perf,1))) - 1;
pmaxdd = maxdrawdown(perfret);

fprintf('Results for Backtest Period from %s to %s\n',datestr(Date(window)),datestr(PerfDate(end)));
fprintf('%14s %12s %12s %12s %12s %12s\n','','Mean','Std.Dev.','Tot.Ret.','Max.DD','Turnover');
fprintf('%14s %12g %12g %12g %12g %12g\n','Gross', ...
    100*pmean(1),100*pstdev(1),100*ptotret(1),100*pmaxdd(1),100*pfactor*pturnover/numel(PerfDate));
fprintf('%14s %12g %12g %12g %12g %12g\n','Net', ...
    100*pmean(2),100*pstdev(2),100*ptotret(2),100*pmaxdd(2),100*pfactor*rturnover/numel(PerfDate));
fprintf('%14s %12g %12g %12g %12g\n','Market', ...
    100*pmean(3),100*pstdev(3),100*ptotret(3),100*pmaxdd(3));
fprintf('%14s %12g %12g %12g %12g\n','Cash', ...
    100*pmean(4),100*pstdev(4),100*ptotret(4),100*pmaxdd(4));

% Report creation
%% variable initialization for report creation
alpha = [10 5 1];
sampling_step=5;
tol=10;
strategies={'Best Information ratio ','Information ratio with costs-turnover'};
comp = {GrossComposition,NetComposition};
perf = [GrossPerfPort, NetPerfPort, PerfMarket, PerfCash];
nb_strategies=length(strategies);
assets=handles.Assets;
hist_dates=PortDate(:,1);

assignin('base', 'alpha', alpha);
assignin('base', 'sampling_step', sampling_step);
assignin('base', 'tol', tol);
assignin('base', 'strategies', strategies);
assignin('base', 'comp', comp);
assignin('base', 'perf', perf);
assignin('base', 'nb_strategies', nb_strategies);
assignin('base', 'assets', assets);
assignin('base', 'hist_dates', hist_dates);

% efficient frontier visualization
histo_date_start_string='30/01/1998';
histo_date_end_string='31/12/2004';
startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == Date);
endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == Date);
%assetindex = logical(Map(endindex,:));
AssetList=handles.Assets(1:end-2);
%AssetList = Assets(assetindex);
% Set up date and return arrays
AssetReturns = handles.Data(startindex:endindex,1:end-2);
MarketReturns = handles.Data(startindex:endindex,end-1);
CashReturns = handles.Data(startindex:endindex,end);
% Compute returns and risks for market and cash returns
mret = mean(MarketReturns);
mrsk = std(MarketReturns);
cret = mean(CashReturns);
crsk = std(CashReturns);
Turnover = get(handles.turnover,'Value') ;
Cost = get(handles.cost,'Value') ;
BuyCost = Cost;
SellCost = Cost;
p = Portfolio('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);
% Set up an equal-weight initial portfolio
p = p.setInitPort(1/p.NumAssets);
[ersk, eret] = p.estimatePortMoments(p.InitPort);
p = p.setDefaultConstraints;
pwgt = p.estimateFrontier(20);
[prsk,pret] = p.estimatePortMoments(pwgt);
p = p.setCosts(BuyCost, SellCost);
p = p.setTurnover(Turnover);
[qwgt, ~, ~] = p.estimateFrontier(20);
[qrsk, qret] = p.estimatePortMoments(qwgt);

assignin('base', 'PortDate', PortDate);
assignin('base', 'PortRisk', PortRisk);
assignin('base', 'PortReturn', PortReturn);
assignin('base', 'PortDate', PortDate);
assignin('base', 'PortSigma', PortSigma);
assignin('base', 'PortMean', PortMean);
assignin('base', 'mrsk', mrsk);
assignin('base', 'mret', mret);
assignin('base', 'crsk', crsk);
assignin('base', 'cret', cret);
assignin('base', 'ersk', ersk);
assignin('base', 'eret', eret);
assignin('base', 'qrsk', qrsk);
assignin('base', 'qret', qret);
assignin('base', 'prsk', prsk);
assignin('base', 'pret', pret);
assignin('base', 'p', p);
assignin('base', 'eret', eret);

report reportStrategy;

function histo_start_Callback(hObject, eventdata, handles)
% hObject    handle to histo_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of histo_start as text
%        str2double(get(hObject,'String')) returns contents of histo_start as a double


% --- Executes during object creation, after setting all properties.
function histo_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histo_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function histo_end_Callback(hObject, eventdata, handles)
% hObject    handle to histo_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of histo_end as text
%        str2double(get(hObject,'String')) returns contents of histo_end as a double


% --- Executes during object creation, after setting all properties.
function histo_end_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histo_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function backtest_start_Callback(hObject, eventdata, handles)
% hObject    handle to backtest_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of backtest_start as text
%        str2double(get(hObject,'String')) returns contents of backtest_start as a double


% --- Executes during object creation, after setting all properties.
function backtest_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to backtest_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function backtest_end_Callback(hObject, eventdata, handles)
% hObject    handle to backtest_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of backtest_end as text
%        str2double(get(hObject,'String')) returns contents of backtest_end as a double


% --- Executes during object creation, after setting all properties.
function backtest_end_CreateFcn(hObject, eventdata, handles)
% hObject    handle to backtest_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function turnover_Callback(hObject, eventdata, handles)
% hObject    handle to turnover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
histo_date_start_string=get(handles.histo_start,'String');
histo_date_end_string=get(handles.histo_end,'String');
startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == handles.Dates);
endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == handles.Dates);

%assetindex = logical(Map(endindex,:));
AssetList=handles.Assets(1:end-2);
%AssetList = Assets(assetindex);

% Set up date and return arrays
AssetReturns = handles.Data(startindex:endindex,1:end-2);
CashReturns = handles.Data(startindex:endindex,end);

% Compute returns and risks for market and cash returns
Turnover = get(handles.turnover,'Value') ;
Cost = get(handles.cost,'Value') ;
set(handles.turnover_box,'String',num2str(Turnover*100));
BuyCost = Cost;
SellCost = Cost;
p = Portfolio('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);

% Set up an equal-weight initial portfolio

p = p.setInitPort(1/p.NumAssets);

p = p.setDefaultConstraints;

p = p.setCosts(BuyCost, SellCost);
p = p.setTurnover(Turnover);

[pwgt, ~, ~] = p.estimateFrontier(20);
[prsk, pret] = p.estimatePortMoments(pwgt);
% Plot efficient frontier with turnover constraint
set(handles.constrained_line,'XData',sqrt(12)*prsk,'YData',12*pret);


guidata(handles.output, handles);
% --- Executes during object creation, after setting all properties.
function turnover_CreateFcn(hObject, eventdata, handles)
% hObject    handle to turnover (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function cost_Callback(hObject, eventdata, handles)
% hObject    handle to cost (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
histo_date_start_string=get(handles.histo_start,'String');
histo_date_end_string=get(handles.histo_end,'String');
startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == handles.Dates);
endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == handles.Dates);

AssetList=handles.Assets(1:end-2);

% Set up date and return arrays

AssetReturns = handles.Data(startindex:endindex,1:end-2);
CashReturns = handles.Data(startindex:endindex,end);

% Compute returns and risks for market and cash returns

Turnover = get(handles.turnover,'Value') ;
Cost = get(handles.cost,'Value') ;
set(handles.cost_box,'String',num2str(Cost*100));
BuyCost = Cost;
SellCost = Cost;
p = Portfolio('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);

% Set up an equal-weight initial portfolio

p = p.setInitPort(1/p.NumAssets);
p = p.setDefaultConstraints;
p = p.setCosts(BuyCost, SellCost);
p = p.setTurnover(Turnover);

[pwgt, ~, ~] = p.estimateFrontier(20);
[prsk, pret] = p.estimatePortMoments(pwgt);

% Plot efficient frontier with turnover constraint
set(handles.constrained_line,'XData',sqrt(12)*prsk,'YData',12*pret);

guidata(handles.output, handles);



function turnover_box_Callback(hObject, eventdata, handles)
% hObject    handle to turnover_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of turnover_box as text
%        str2double(get(hObject,'String')) returns contents of turnover_box as a double


% --- Executes during object creation, after setting all properties.
function turnover_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to turnover_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cost_box_Callback(hObject, eventdata, handles)
% hObject    handle to cost_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cost_box as text
%        str2double(get(hObject,'String')) returns contents of cost_box as a double


% --- Executes during object creation, after setting all properties.
function cost_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cost_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in PuStrategy.
function PuStrategy_Callback(hObject, eventdata, handles)
% hObject    handle to PuStrategy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PuStrategy contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PuStrategy


% --- Executes during object creation, after setting all properties.
function PuStrategy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PuStrategy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in console_output.
function console_output_Callback(hObject, eventdata, handles)
% hObject    handle to console_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns console_output contents as cell array
%        contents{get(hObject,'Value')} returns selected item from console_output


% --- Executes during object creation, after setting all properties.
function console_output_CreateFcn(hObject, eventdata, handles)
% hObject    handle to console_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cons_budget.
function cons_budget_Callback(hObject, eventdata, handles)
% hObject    handle to cons_budget (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cons_budget

if get(hObject,'Value')
    Turnover = get(handles.turnover,'Value') ;
    Cost = get(handles.cost,'Value') ;
    BuyCost = Cost;
    SellCost = Cost;
    
    histo_date_start_string=get(handles.histo_start,'String');
    histo_date_end_string=get(handles.histo_end,'String');
    startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == handles.Dates);
    endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == handles.Dates);
    
    %assetindex = logical(Map(endindex,:));
    AssetList=handles.Assets(1:end-2);
    %AssetList = Assets(assetindex);
    
    % Set up date and return arrays
    
    AssetReturns = handles.Data(startindex:endindex,1:end-2);
    CashReturns = handles.Data(startindex:endindex,end);
    
    p = PortfolioDemo('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
    p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);
    p = p.setInitPort(1/p.NumAssets);
    p = p.setDefaultConstraints;
    
    p = p.setCosts(BuyCost, SellCost);
    p = p.setTurnover(Turnover);
    
    p=p.setBudget(0,1);
    [tuqwgt, ~, ~] = p.estimateFrontier(20);
    [tc_prsk, tc_pret] = p.estimatePortMoments(tuqwgt);
    
    swgt = p.maximizeSharpeRatio;
    [srsk, sret] = p.estimatePortMoments(swgt);
    
    if isfield(handles, 'constrained_tangent_line')
        set(handles.constrained_tangent_line,'XData',sqrt(12)*tc_prsk,'YData',12*tc_pret);
        set(handles.constrained_sharpe_pf,'XData',sqrt(12)*srsk,'YData',12*sret);
    else
        hold(handles.axes,'on');
        handles.constrained_tangent_line = plot(handles.axes,sqrt(12)*tc_prsk,12*tc_pret,...
            '-r','LineWidth',2);
        handles.constrained_sharpe_pf = plot(handles.axes,sqrt(12)*srsk,12*sret,...
            'gd','LineWidth',2);
    end
else
    if isfield(handles, 'constrained_tangent_line')
        set(handles.constrained_tangent_line,'XData',[],'YData',[]);
        set(handles.constrained_sharpe_pf,'XData',[],'YData',[]);
    end
end
if get(hObject,'Value')
    Turnover = get(handles.turnover,'Value') ;
    Cost = get(handles.cost,'Value') ;
    BuyCost = Cost;
    SellCost = Cost;
    
    histo_date_start_string=get(handles.histo_start,'String');
    histo_date_end_string=get(handles.histo_end,'String');
    startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == handles.Dates);
    endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == handles.Dates);
    
    %assetindex = logical(Map(endindex,:));
    AssetList=handles.Assets(1:end-2);
    %AssetList = Assets(assetindex);
    
    % Set up date and return arrays
    
    AssetReturns = handles.Data(startindex:endindex,1:end-2);
    CashReturns = handles.Data(startindex:endindex,end);
    
    p = PortfolioDemo('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
    p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);
    p = p.setInitPort(1/p.NumAssets);
    p = p.setDefaultConstraints;
    
    
    p=p.setBudget(0,1);
    [tqwgt, ~, ~] = p.estimateFrontier(20);
    [t_prsk, t_pret] = p.estimatePortMoments(tqwgt);
    
    swgt = p.maximizeSharpeRatio;
    [srsk, sret] = p.estimatePortMoments(swgt);
    
    if isfield(handles, 'unconstrained_tangent_line')
        set(handles.unconstrained_tangent_line,'XData',sqrt(12)*t_prsk,'YData',12*t_pret);
        set(handles.unconstrained_sharpe_pf,'XData',sqrt(12)*srsk,'YData',12*sret);
    else
        hold(handles.axes,'on');
        handles.unconstrained_tangent_line = plot(handles.axes,sqrt(12)*t_prsk,12*t_pret,...
            '-b','LineWidth',2);
        handles.unconstrained_sharpe_pf = plot(handles.axes,sqrt(12)*srsk,12*sret,...
            'gd','LineWidth',2);
    end
else
    if isfield(handles, 'unconstrained_tangent_line')
        set(handles.unconstrained_tangent_line,'XData',[],'YData',[]);
        set(handles.unconstrained_sharpe_pf,'XData',[],'YData',[]);
    end
end
guidata(handles.output, handles);

% --- Executes on button press in uncons_budget.
function uncons_budget_Callback(hObject, eventdata, handles)
% hObject    handle to uncons_budget (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of uncons_budget
if get(hObject,'Value')
    Turnover = get(handles.turnover,'Value') ;
    Cost = get(handles.cost,'Value') ;
    BuyCost = Cost;
    SellCost = Cost;
    
    histo_date_start_string=get(handles.histo_start,'String');
    histo_date_end_string=get(handles.histo_end,'String');
    startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == handles.Dates);
    endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == handles.Dates);
    
    %assetindex = logical(Map(endindex,:));
    AssetList=handles.Assets(1:end-2);
    %AssetList = Assets(assetindex);
    
    % Set up date and return arrays
    
    AssetReturns = handles.Data(startindex:endindex,1:end-2);
    CashReturns = handles.Data(startindex:endindex,end);
    
    p = PortfolioDemo('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
    p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);
    p = p.setInitPort(1/p.NumAssets);
    p = p.setDefaultConstraints;
    
    
    p=p.setBudget(0,1);
    [tqwgt, ~, ~] = p.estimateFrontier(20);
    [t_prsk, t_pret] = p.estimatePortMoments(tqwgt);
    
    swgt = p.maximizeSharpeRatio;
    [srsk, sret] = p.estimatePortMoments(swgt);
    
    if isfield(handles, 'unconstrained_tangent_line')
        set(handles.unconstrained_tangent_line,'XData',sqrt(12)*t_prsk,'YData',12*t_pret);
        set(handles.unconstrained_sharpe_pf,'XData',sqrt(12)*srsk,'YData',12*sret);
    else
        hold(handles.axes,'on');
        handles.unconstrained_tangent_line = plot(handles.axes,sqrt(12)*t_prsk,12*t_pret,...
            '-b','LineWidth',2);
        handles.unconstrained_sharpe_pf = plot(handles.axes,sqrt(12)*srsk,12*sret,...
            'gd','LineWidth',2);
    end
else
    if isfield(handles, 'unconstrained_tangent_line')
        set(handles.unconstrained_tangent_line,'XData',[],'YData',[]);
        set(handles.unconstrained_sharpe_pf,'XData',[],'YData',[]);
    end
end
guidata(handles.output, handles);



function EdRebalancing_Callback(hObject, eventdata, handles)
% hObject    handle to EdRebalancing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EdRebalancing as text
%        str2double(get(hObject,'String')) returns contents of EdRebalancing as a double


% --- Executes on button press in short_allowed.
function short_allowed_Callback(hObject, eventdata, handles)
% hObject    handle to short_allowed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of short_allowed
if get(hObject,'Value')
    
    histo_date_start_string=get(handles.histo_start,'String');
    histo_date_end_string=get(handles.histo_end,'String');
    startindex = find(datenum(histo_date_start_string,'dd/mm/yyyy') == handles.Dates);
    endindex = find(datenum(histo_date_end_string,'dd/mm/yyyy') == handles.Dates);
    
    %assetindex = logical(Map(endindex,:));
    AssetList=handles.Assets(1:end-2);
    %AssetList = Assets(assetindex);
    
    % Set up date and return arrays
    
    AssetReturns = handles.Data(startindex:endindex,1:end-2);
    CashReturns = handles.Data(startindex:endindex,end);
    
    p = PortfolioDemo('AssetList', AssetList, 'RiskFreeRate', CashReturns(end));
    p = p.estimateAssetMoments(AssetReturns, 'missingdata', true);
    p = p.setDefaultConstraints;
    p = p.setInitPort(1/p.NumAssets);
    
    Leverage = 0.3;
    
    p = p.setTurnover(0.5*(1 + 2*Leverage), 0);
    p = p.setBounds(-Leverage, (1 + Leverage));
    
    [pwgt, pbuy, psell] = p.estimateFrontier(20);
    [prsk, pret] = p.estimatePortMoments(pwgt);
    disp(sum(pbuy));
    disp(sum(psell));
    
    [pswgt, psbuy, pssell] = p.maximizeSharpeRatio;
    disp(sum(psbuy));
    disp(sum(pssell));
    [srsk, sret] = p.estimatePortMoments(pswgt);
    hold(handles.axes,'on');
    handles.unconstrained_short_line = plot(handles.axes,sqrt(12)*prsk,12*pret,...
        '-ks','LineWidth',2);
    handles.unconstrained_short_sharpe_pf = plot(handles.axes,sqrt(12)*srsk,12*sret,...
        'gd','LineWidth',2);
    
end



function historic_period_edit_Callback(hObject, eventdata, handles)
% hObject    handle to historic_period_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of historic_period_edit as text
%        str2double(get(hObject,'String')) returns contents of historic_period_edit as a double


% --- Executes during object creation, after setting all properties.
function historic_period_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to historic_period_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
