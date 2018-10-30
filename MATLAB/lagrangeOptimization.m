%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Program: lagranageOptimization.m
% Programmer: Bakir Hajdarevic
% Date: 8/7/2017
% Description: This program allows the user to see the relationship between
% varying lagrange values within a cost function of a PID optimization. 
% The user is displayed the following results of the top PID result in 
% terms of cost:
%       + proportional term 
%       + integral term
%       + derivative term
%       + function cost
%       + number of convergences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

directoryPath = strcat(pwd,'\SavedVariables\BestParameters\');

patientType = {'COPDAdult_OldValve\','COPDAdult_NewValve\','HealthyAdult_OldValve\',...
    'HealthyAdult_NewValve\','HealthyPediatric_OldValve\','HealthyPediatric_NewValve\',...
    'TestLungModel_1_OldValve\','TestLungModel_2_OldValve\','\Lung_Bag\'};

% Prompt the user for the desired patient type to process
ok = 0;
[patientIndex,ok] = listdlg('PromptString','Select a patient type to process:',...
    'SelectionMode','single',...
    'ListString',patientType);
if ok == 1
    
    filePath = strcat(directoryPath,char(patientType(patientIndex)));
    fileList = dir(filePath);
    
    % Obtain a list of all the file names within the folder SavedVariables
    for ii = 1: size(fileList,1)
        fileNames{ii} = fileList(ii).name;
    end
    
    % Prompt the user for the desired files to load
    ok = 0;
    [filesSelected,ok] = listdlg('PromptString','Select a file (ctrl-hold for multiple):',...
        'SelectionMode','multiple',...
        'ListString',fileNames);
    
    if ok == 1
        % Convert cell of characters into string
        fileNames = cellstr(fileNames);
        numFiles = size(filesSelected,2);
        
        % Initialize the maatrix for storing the various parameters
        unOptCost = 0;
        pidParamsArray = zeros(numFiles,6);
        
        for ii = 1 : numFiles
            % Load file
            filePathToLoad = strcat(filePath,fileNames{filesSelected(ii)});
            
            % Read in csv file and store matrix of optimized parameters
           MatrixRead = csvread(filePathToLoad);
           
           % Find the row which contains the greatest number of elements
           % (excluding the row of the unoptimized PID)
           mostElements = find(MatrixRead(2:end,5) == max(MatrixRead(2:end,5))) + 1;
           
           % Read in values for best parameters per file
           % Store the unoptimzed closed loop function cost
           unOptCost = MatrixRead(1,1);
           % Store lambda values here
           pidParamsArray(ii,1) = MatrixRead(mostElements(1),6);
           % Store optimized PID parameters
           pidParamsArray(ii,2:4) = MatrixRead(mostElements(1),2:4);
           % Store function cost here
           pidParamsArray(ii,5) = MatrixRead(mostElements(1),1);
           % Store number of elements here
           pidParamsArray(ii,6) = MatrixRead(mostElements(1),5);
        end
        
        % Resort rows based on the value of lambda
        pidParamsArray = sortrows(pidParamsArray);
        
        % Plot Kp versus Lambda
        figure( ...
            'Color' , [1,1,1] )
        subplot( 2 , 3 , 1)
        semilogx(pidParamsArray(:,1), pidParamsArray(:,2))
        ylabel('Kp Values')
        xlabel('Lambda/Regularization Constant')        
        title('Constant Gain parameter (Kp) per Lambda Value')
        
        % Plot Ki versus Lambda
        subplot( 2 , 3 , 2)
        semilogx(pidParamsArray(:,1), pidParamsArray(:,3))
        ylabel('Ki Values')
        xlabel('Lambda/Regularization Constant')
        title('Integral parameter (Ki) per Lambda Value')
        
        % Plot Kd versus Lambda
        subplot( 2 , 3 , 3)        
        semilogx(pidParamsArray(:,1), pidParamsArray(:,4))
        ylabel('Kd Values')
        xlabel('Lambda/Regularization Constant')        
        title('Derivative Parameter (Kd) per Lambda Value')
        
        % Plot Cost versus Lambda       
        subplot( 2 , 2 , 3)
        semilogx(pidParamsArray(:,1), pidParamsArray(:,5))
        ylabel('Optimization Cost Values')
        xlabel('Lambda/Regularization Constant')
        title(sprintf('Optimization Cost per Lambda Value (Unoptimized = %d)',unOptCost))
        
        % Plot Number of Elements versus Lambda       
        subplot( 2 , 2 , 4)
        semilogx(pidParamsArray(:,1), pidParamsArray(:,6))
        ylabel('Number of Elements')
        xlabel('Lambda/Regularization Constant')
        title('Number of Elements per Lambda Value')
    end
end
