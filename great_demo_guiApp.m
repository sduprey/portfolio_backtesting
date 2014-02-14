classdef great_demo_guiApp < handle
%
% Usage:
%     app.great_demo_guiApp

  properties
      AppPath = {'/PORTFOLIO_STRATEGY_GUI'};
	  AppClass = 'great_demo_guiApp';
	  AppHandle;
      ExistCloseFcn = '';
      GuideApp;
      Output;
      CurrClass;
      FigureIsThisApp = 0;
  end

  methods
    % Create the application object
    function obj = great_demo_guiApp()      
      obj.CurrClass = metaclass(obj);
      startApp(obj)
    end

    function value = get.AppPath(obj)
       appview = com.mathworks.appmanagement.AppManagementViewSilent;
       appAPI = com.mathworks.appmanagement.AppManagementApiBuilder.getAppManagementApiCustomView(appview);
           
       myAppsLocation = char(appAPI.getMyAppsLocation);
       
       value = cellfun(@(x) fullfile(myAppsLocation, x), obj.AppPath, 'UniformOutput', false);
    end

    % Start the application
    function startApp(obj)

      % Put the application directory on the path
      allpaths = genpath(obj.AppPath{:});
      addpath(strrep(allpaths, [obj.AppPath{:} filesep 'metadata;'], ''));      

      % Must load function (force by using function handle) or nargout lies.
      % Check if the app is a GUIDE app
      if nargout(@great_demo_gui) == 0  
          obj.GuideApp = 0;
          figures = get(0,'CurrentFigure'); % Get a handle to all the figures currently open
          if figures 
              for figcount = 1:figures  % Run through all open figure to find the figure opened by the app
                  closefcn = get(figcount,'CloseRequestFcn'); 
                  if iscell(closefcn)
                    % Check if the figure has the stopapp function defined as CloseRequestFcn
                    % and if it was created by the app class
                    if(strcmp('appinstall.internal.stopapp',func2str(closefcn{1})) && isa(closefcn{2}, obj.CurrClass.Name))
                        obj.FigureIsThisApp = 1;
                        set(figcount,'Visible','on');
                    end
                  end
              end                                  
              if ~obj.FigureIsThisApp
                  eval('great_demo_gui');  
                  obj.AppHandle = get(0, 'CurrentFigure');
              end
          else 
              eval('great_demo_gui');  
              obj.AppHandle = get(0, 'CurrentFigure');              
          end                         
      else
          obj.GuideApp = 1;
          obj.AppHandle = eval('great_demo_gui');   
      end     
      try      
          if (ishghandle(obj.AppHandle) && ~iscell(get(obj.AppHandle, 'CloseRequestFcn'))) || (~obj.GuideApp && ~iscell(get(obj.AppHandle, 'CloseRequestFcn')))
              % Before setting the closeReq function we lock the class so that we can warn the user if
              % he tries to uninstall the app while it is running 
              mlock;
              obj.ExistCloseFcn = get(obj.AppHandle, 'CloseRequestFcn');
              set(obj.AppHandle, 'CloseRequestFcn', {@appinstall.internal.stopapp,obj});          
          end
      catch e
%            This is executed when the app is a command line app. The value
%            of obj.AppHandle is not a handle object but the output from
%            the entrypoint function. Display the output from the
%            entrypoint.   
          munlock(obj.AppClass);  
          obj.Output = obj.AppHandle;
          obj.GuideApp = 0;          
      end
    end
  end
end
