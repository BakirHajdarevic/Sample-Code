%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Programmer: Bakir Hajdarevic
% Program: Multi_pidEstimation.m
% Date: 9/23/2017
% Description: This program was created to systematically optimize closed 
% loop transfer functions (CLTF) with a proportional integral derivative 
% (PID) controller of a plant, specifically an ECU-Proporitonal Solenoid 
% Valve (PSOL) (chosen by the user) in series with a lung-impedence model 
% (also chosen by the user), over a specified frequency range 
% (desired was 0.1:20 Hz). The optimization approach is to obtain unity gain
% (flat frequency response) over the intended frequency range. The 
% following transfer functions make up the closed loop transfer function: 
%
%            + pid_opt - parameters Kp, Ki, and Kd
%            + Ktrans - 0.0977 gain of pressure transducer (corresponds to 
%              a gain of V/cmH2O) 
%            + bwFilt - 8th Order ButterWorth Filter with a cutoff of 50 Hz.
%            + New_valveECU - the 5th order transfer function of the ASCO
%            Flow Valve that was valve of choice for this project.
%            + Old_valveECU - Dr. Kaczka's valve from his 2004 paper
%            involving servo controlled oscillatory ventilation. This valve
%            was listed in its part of the validation of the optimization
%            results using LABVIEW software.
%            + hthAdult - 3rd order transfer function of a healthy adult 
%            patient. 
%            + hthPed - 3rd order transfer function of a healthy pediatric 
%            patient. 
%            + copdAdult - 3rd order transfer function of a COPD adult 
%            patient. 
%            + tstLungModel_1 - 4th order transfer function of a mechanical 
%            test lung model.
%            + tstLungModel_2 - 6th order transfer function of a mechanical 
%            test lung model.
%            + lungBag - 5th order transfer function of a 3-L anesthesia 
%            lung bag.
%
% Note: Optimization is done entirely in continuous time. The implemenation
% of the PID invovles using a bilinear transformation 
% (also called trapezoidal) to best preserve the frequency response that 
% was obtained in continuous time.
%
% The optimization approach is a Monte Carlo Optimization algorithm using 
% MATLAB's constrained nonlinear function solver, fmincon. The user may 
% define the bounds of the frequency range, the number of iterations per 
% PID parameter, and the initial guess values (default range is 
% [-10 : 1000 : 10] ). The following is the cost function and regulariztion
% term used for the optimization: 
%
% objective = @(Param) sum(power(abs(closedLoopSys(Sobs,Param))-1,2)) + lambdaReg(aa).*sum(power(Param,2))
%
% - The initial portion of the objective function is as follows:
%   1. Deriving the transfer function of the CLTF in terms of its real and
%   imaginary parts.
%   2. Calculating the magnitude of the real and imaginary parts over the
%   intended frequency range.
%   3. Subtracting a value of 1 (want unity gain or flat frequency response).
%   4. Taking the squared value of the sum (to ensure non-negative
%   results).
%   5. Obtaining the sum of all values. This final value is the cost of the
%   objective.
%
% - The second portion of the objective function was added to implement
% the method of regularization in order to constrain the results from
% blowing up to infinity. The user is allowed to vary the lambda
% regularization parameter if they believe they can find desired results at
% varying regularizations.
%
% - The constrained function that is used in fmincon simply takes the roots
% of the closed loop transfer function's denominators and makes sure that
% they are in the left half plane.
%
% Once fmincon runs through all the iterations, a mat file is saved for 
% each specific optimization. The format of how each file is named is 
% ( in order of appearance): 
%               + pwd - path of the current directory
%               + SavedVariables - name of folder of where to save file
%               + UniqueName - unique name of file - has following:
%                            * fmin - min frequency to optimize
%                            * fmax - max frequency to optimize
%                            * lambdaReg - regularization parameter value
%               + valveName - the name of the value used (Old vs New)
%               + lungModelName - the name of the lung model used 
%               + char(t) - date of optimization
%               + .mat - mat file extension
%
% The following parameters are saved within the mat file:
%               + Popt - returned optimized PID results of fmincon
%               + exitflag - exitflag condition for each iteration
%               + output - output of 
%               + lambda - lagrange parameter to use for regularization
%               + grad - gradient matrix returned by fmincon
%               + hessian - hessian matrix returned by fmincon
%               + fval - final cost function value returned by fmincon
%               + fnum_save - save number of frequency points
%               + lambdaReg_save - regulariztion parameter value as
%               specified by the user.
%               + numParam_save_Kp - save # of parameters for Kp term
%               + numParam_save_Ki - save # of parameters for Ki term
%               + numParam_save_Kd - save # of parameters for Kd term
%               + fmin_save - save min. frequency
%               + fmax_save - save max. frequency
%               + rangeMin_Kp_save - save min. Kp value
%               + rangeMax_Kp_save - save max. Kp value 
%               + rangeMin_Ki_save - save min. Ki value
%               + rangeMax_Ki_save - save max. Ki value
%               + rangeMin_Kd_save - save min. Kd value
%               + rangeMax_Kd_save - save max. Kd value
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars
close all
clc

%% %%%%%%%%%%%% Define all immutable functions here %%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%% Patient Impedance Transfer Function %%%%%%%%%%%%%%%%%%
% Healthy Adult
hthAdult = @(s) (0.011.*s.^3 + 1.82.*s.^2 + 54.59.*s + 102.2)./(s.^2 + 3.27.*s);
numHA = [0.011 1.82 54.59 102.2];
denHA = [1 3.27 0];

% Healthy Pediatric
hthPed = @(s) (0.003.*s.^3 + 7.24.*s.^2 + 196.47.*s + 282.13)./(s.^2 + 2.31.*s);
numHP = [0.003 7.24 196.47 282.13];
denHP = [1 2.31 0];

% COPD Adult
copdAdult = @(s) (0.01.*s.^3 + 4.67.*s.^2 + 839.94.*s + 809.81)./(s.^2 + 26.98.*s);
numCA = [0.01 4.67 839.94 809.81];
denCA = [1 26.98 0] ;

% Test Lung Model
%%% 7 poles, 7 zeros TLM TF
% tstLungModel_1 = @(s) (10.52.*s.^7 + 945.8.*s.^6 + 9.522e04.*s.^5 + 5.529e06.*s.^4 +...
%     2.01e08.*s.^3 + 1.717e09.*s.^2 + 3.943e09.*s + 1.893e09)./(s.^7 + 77.36.*s.^6 +...
%     1.479e04.*s.^5 + 4.758e05.*s.^4 + 5e07.*s.^3 + 2.369e08.*s.^2 + 1.784e08.*s + 4.543e06);
% numTLM_1 = [10.52 945.8 9.522e04 5.529e06 2.01e08 1.717e09 3.943e09 1.893e09];
% denTLM_1 = [1 77.36 1.479e04 4.758e05 5e07 2.369e08 1.784e08 4.543e06];
tstLungModel_1 = @(s) (1.222e04.*s.^3 + 8.813e05.*s.^2 + 7.084e06.*s + 4.302e06)./(s.^4 +...
    93.32.*s.^3 + 3.337e05.*s.^2 + 3.685e05.*s + 0.002404);
numTLM_1 = [1.222e04 8.813e05 7.084e06 4.302e06];
denTLM_1 = [1 93.32 3.337e05 3.685e05 0.002404];

%%% 4 poles, 6 zeros TLM TF
tstLungModel_2 = @(s) (1324.*s.^6 + 2.992e05.*s.^5 + 2.626e07.*s.^4 + 2.123e09.*s.^3 + 4.741e10.*s.^2 + 4.598e11.*s + 3.89e11)./...
    (s.^6 + 2.737e04.*s.^5 + 3.402e06.*s.^4 + 2.188e08.*s.^3 + 1.746e10.*s.^2 + 3.027e10.*s + 1.307e04);
numTLM_2 = [1324 2.992e05 2.626e07 2.123e09 4.741e10 4.598e11 3.89e11];
denTLM_2 = [1 2.737e04 3.402e06 2.188e08 1.746e10 3.027e10 1.307e04];

% Lung Bag Model
lungBag = @(s) (0.002359.*s.^5 + 0.315.*s.^4 + 793.7.*s.^3 + 6.033e04.*s.^2 + 2.309e06.*s + 5.35e06)./...
    (s.^3 + 4.331e04.*s.^2 + 1.224e05.*s + 7711);
numLB = [0.002359 0.315 793.7  6.033e04 2.309e06 5.35e06];
denLB = [1 4.331e04 1.224e05 7711];

% Initialize Empty-Patient
empt_pat = @(s) 1 ;
num_empt_pat = 1 ;
den_empt_pat = 1 ;

% Initialize ASCO ECU-Valve Transfer Function
%%%%%%%%%%%%%%%%%%%%%%%%%% NEW VALVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
New_valveECU = @(s) ( -5756.*s.^3 + 2.333e6.*s.^2 + 1.863e8.*s + 2.919e9 ) ./ ...
	( s.^5 + 562.9.*s.^4 + 1.25e5.*s.^3 + 1.017e7.*s.^2 + 4.518e8.*s + 4.563e9 );
New_numECU = [ -5756 2.333e6 1.863e8 2.919e9 ];
New_denECU = [ 1 562.9 1.25e5 1.017e7 4.518e8 4.563e9 ] ;

%%%%%%%%%%%%%%%%%%%%%%%%%% OLD VALVE (DAVE'S) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Old_valveECU = @(s) (7.783e08)./(s.^4 + 160.1.*s.^3 + 9.043e04.*s.^2 + 4.832e06.*s + 1.414e09);
Old_numECU = 7.783e08 ;
Old_denECU = [1 160.1 9.043e04 4.832e06 1.414e09];

% Initialize 8th Order Butterworth Low Pass Filter
% bwFilt = @(s) (9.45e19)./(s.^8 + 1610.*s.^7 + 1.295e06.*s.^6 + 6.763e08.*s.^5 +...
%     2.497e11.*s.^4 + 6.668e13.*s.^3 + 1.259e16.*s.^2 + 1.543e18.*s + 9.45e19);
% numBW = [9.45e19];
% denBW = [1 1610 1.295e06 6.763e08 2.497e11 6.668e13 1.259e16 1.543e18 9.45e19];
% bwFilt = @(s) 1 ;
% numBW = 1 ;
% denBW = 1 ;

% pressure transducer gain
Ktrans = 0.0977;

%% Prompt user for patient lung model type and filename to save.
PatientType = {'Healthy Adult','COPD Adult','Healthy Pediatric','Test Lung Model 1','Test Lung Model 2','Lung Bag','Empty Patient'};

[LungModelType,ok] = listdlg('PromptString',...
    'Select patient types to be optimized:',...
    'SelectionMode','multiple',...
    'ListString',PatientType);
if( ok == 1 )
    ValveType = {'New Valve','Old Valve'};
    
    [valveTypeSelect,ok_1] = listdlg('PromptString',...
        'Select patient types to be optimized:',...
        'SelectionMode','single',...
        'ListString',ValveType);
    
    if( ok_1 == 1 )
        
        valueSelection = {'Load File','Manually enter values'};
        [loadFileOrNot,~] = listdlg('PromptString',...
            'Select if you want to load a file\n or to manually enter parameters:',...
            'SelectionMode','single',...
            'ListString',valueSelection);
        
        % If/else for loading a specific file (if) or allowing the user to manually
        % enter values (else).
        if (loadFileOrNot == 1)
            % Obtain the folder which stores the .mat files of the saved optimized
            % variables
            directoryPath = strcat(pwd,'\pidOptimizationParameters\');
            fileList = dir(directoryPath);
            fileNames = cell.empty ;    % Initialize empty cell variable for storing filenames
            
            % Obtain a list of all the file names within the folder SavedVariables
            for ii = 1: size(fileList,1)
                fileNames{ii} = fileList(ii).name;
            end
            
            % Prompt the user for the desired files to load
            [filesSelected,ok_2] = listdlg('PromptString','Select a file (ctrl-hold for multiple):',...
                'SelectionMode','single',...
                'ListString',fileNames);
            
            if ( ok_2 == 1 )
                % Convert cell of characters into string
                fileNames = cellstr(fileNames);
                
                % Read in the selected file and store values into variable answer of type
                % double
                answer = csvread(strcat(directoryPath,fileNames{filesSelected}));
                numVariations = size(answer,1) ;
                
                % Initialize variables to store optimization parameters
                fmin = double.empty ; fmax = double.empty ; fnum = double.empty ; lambdaReg = double.empty ;
                numParam_Kp = double.empty ; numParam_Ki = double.empty ; numParam_Kd = double.empty ;
                rangeMin_Kp = double.empty ; rangeMax_Kp = double.empty ; rangeMin_Ki = double.empty ;
                rangeMax_Ki = double.empty ; rangeMin_Kd = double.empty ; rangeMax_Kd = double.empty ;
                
                for ii = 1 : numVariations
                    fmin(ii) = answer(ii,1) ;
                    fmax(ii) = answer(ii,2) ;
                    fnum(ii) = answer(ii,3) ;
                    lambdaReg(ii) = answer(ii,4) ;
                    numParam_Kp(ii) = answer(ii,5) ;
                    numParam_Ki(ii) = answer(ii,6) ;
                    numParam_Kd(ii) = answer(ii,7) ;
                    rangeMin_Kp(ii) = answer(ii,8) ;
                    rangeMax_Kp(ii) = answer(ii,9) ;
                    rangeMin_Ki(ii) = answer(ii,10) ; 
                    rangeMax_Ki(ii) = answer(ii,11) ;
                    rangeMin_Kd(ii) = answer(ii,12) ;
                    rangeMax_Kd(ii) = answer(ii,13) ;
                end
            end
        else
            % Initialize numVariations_toIterate
            % This will store the number of variations requested
            numVariations_toIterate = {};
            
            while(isempty(numVariations_toIterate) == true)
                prompt = {'Enter the number of variations you wish to run'};
                dlg_title = 'Input';
                num_lines = 1;
                defaultans = {'1'};
                numVariations_toIterate = ...
                    inputdlg( prompt , dlg_title , num_lines , defaultans );
            end
            
            % Convert cell to num to obtain integer form the number of desired
            % variations
            numVariations = str2double(cell2mat(numVariations_toIterate));
            
            % Initialize variables to store optimization parameters
            fmin = double.empty ; fmax = double.empty ; fnum = double.empty ; lambdaReg = double.empty ; 
            numParam_Kp = double.empty ; numParam_Ki = double.empty ; numParam_Kd = double.empty ; 
            rangeMin_Kp = double.empty ; rangeMax_Kp = double.empty ; rangeMin_Ki = double.empty ; 
            rangeMax_Ki = double.empty ; rangeMin_Kd = double.empty ; rangeMax_Kd = double.empty ;
            
            % Prompt user for optimization parameters
            for ii = 1 : numVariations
                prompt = { 'Enter the minimum frequency (Hertz (Hz)) to be optimized:' , ...
                    'Enter the maximum frequency (Hertz (Hz)) to be optimized:' , ...
                    'Enter the number of frequency points to be used:' , ...
                    'Enter a value for lambda (regularization constant):' , ...
                    'Enter the number of initial guesses for Kp:' , ...
                    'Enter the number of initial guesses for Ki:' , ...
                    'Enter the number of initial guesses for Kd:' , ...
                    'Enter the minimum (negative) integer value for the initial guesses (Kp):' , ...
                    'Enter the maximum (positive) integer value for the initial guesses (Kp):' , ...
                    'Enter the minimum (negative) integer value for the initial guesses (Ki):' , ...
                    'Enter the maximum (positive) integer value for the initial guesses (Ki):' , ...
                    'Enter the minimum (negative) integer value for the initial guesses (Kd):' , ...
                    'Enter the maximum (positive) integer value for the initial guesses (Kd):' } ;
                
                % Number of lines per user response
                num_lines = 1 ;
                % Default answers
                defaultans = { '0.1' , '20' , '1000' , '1' , '10' , '10' , ...
                    '10' , '10' , '10' , '10' , '10' , '10' , '10' } ;
                % Prompt user for input/responses
                answer = inputdlg( prompt , 'Optimization Parameters' , ...
                    1 , defaultans );
                
                % Initialize values for various parameters for optimization
                fmin(ii) = str2double(cell2mat(answer(1,1))) ;
                fmax(ii) = str2double(cell2mat(answer(2,1))) ;
                fnum(ii) = str2double(cell2mat(answer(3,1))) ;
                lambdaReg(ii) = str2double(cell2mat(answer(4,1))) ;
                numParam_Kp(ii) = str2double(cell2mat(answer(5,1))) ;
                numParam_Ki(ii) = str2double(cell2mat(answer(6,1))) ;
                numParam_Kd(ii) = str2double(cell2mat(answer(7,1))) ;
                rangeMin_Kp(ii) = str2double(cell2mat(answer(8,1))) ;
                rangeMax_Kp(ii) = str2double(cell2mat(answer(9,1))) ;
                rangeMin_Ki(ii) = str2double(cell2mat(answer(10,1))) ;
                rangeMax_Ki(ii) = str2double(cell2mat(answer(11,1))) ;
                rangeMin_Kd(ii) = str2double(cell2mat(answer(12,1))) ;
                rangeMax_Kd(ii) = str2double(cell2mat(answer(13,1))) ;
                
            end % End for loop
        end % End if/else statment
        
        % Title of filter parameters-prompt
        filt_title = 'Reconstruction and Low-Pass Filter' ;
        
        % Initialize empty variables for reconstruction filter and lpf
        % parameters after user input
        rec_lpf_order = double.empty ; rec_lpf_cf = double.empty ; 
        lpf_order = double.empty ; lpf_cf = double.empty ;
        
        % Prompt user for filter specifications (reconstruction and lpf)
        for ii = 1 : numVariations
            % Prompt User for reconstruction filter ( used after DAC)
            % and for the low-pass filter (before ADC) parameters.
            prompt = { 'Enter an integer for the order of the reconstruction low-pass-filter (RLPF):' , ...
                'Enter the cutoff frequency (in Hertz) of the RLPF:' , ...
                'Enter an integer for the order of the low-pass-filter (LPF):' , ...
                'Enter the cutoff frequency (in Hertz) of the LPF:'} ;
            % Number of lines per response
            num_lines = 1 ;
            % Default responses
            defaultans = {'4' , '25' , '4' , '25' } ;
            % Prompt user for input/responses
            answer = inputdlg( prompt , filt_title , 1 , defaultans ) ;
            % Store parameters obtained from user
            rec_lpf_order(ii,1) = str2double( cell2mat( answer(1,1) ) ) ;
            rec_lpf_cf(ii,1) = str2double( cell2mat( answer(2,1) ) ) ;
            lpf_order(ii,1) = str2double( cell2mat( answer(3,1) ) ) ;
            lpf_cf(ii,1) = str2double( cell2mat( answer(4,1) ) ) ;
        end
        
        for aa = 1 : numVariations
            for bb = 1 : size(LungModelType,2)
                % Initialize Frequency range
                F = logspace( log10(fmin(aa)) , log10(fmax(aa)) ,fnum(aa)) ;
                radF = F*2*pi ;
                Sobs = 2j*pi*F ;
                
                % Number of initial guesses for each design variable (3 - P.I.D.)
                numInitGuess = [ numParam_Kp(aa) numParam_Ki(aa) numParam_Kd(aa) ] ;
                
                % Initialize range of parameters values to be used
                paramInitGuess = {
                    linspace(-rangeMin_Kp(aa),rangeMax_Kp(aa),numInitGuess(1))
                    linspace(-rangeMin_Ki(aa),rangeMax_Ki(aa),numInitGuess(2))
                    linspace(-rangeMin_Kd(aa),rangeMax_Kd(aa),numInitGuess(3))
                    } ;
                
                % Select Lung Model Type
                switch LungModelType(bb)
                    case 1, patient =  hthAdult ; patient_NUM = numHA; patient_DEN = denHA;
                        lungModelName = 'Healthy_Adult';
                    case 2, patient = copdAdult ; patient_NUM = numCA; patient_DEN = denCA;
                        lungModelName = 'COPD_Adult';
                    case 3, patient =    hthPed ; patient_NUM = numHP; patient_DEN = denHP;
                        lungModelName = 'Healthy_Pediatric';
                    case 4, patient = tstLungModel_1 ; patient_NUM = numTLM_1; patient_DEN = denTLM_2;
                        lungModelName = 'Test_Lung_Model_1';
                    case 5, patient = tstLungModel_2 ; patient_NUM = numTLM_2; patient_DEN = denTLM_2;
                        lungModelName = 'Test_Lung_Model_2';
                    case 6, patient = lungBag ; patient_NUM = numLB; patient_DEN = denLB; 
                        lungModelName = 'Lung_Bag';
                    case 7, patient = empt_pat ; patient_NUM = num_empt_pat ; patient_DEN = den_empt_pat ;
                        lungModelName = 'Empty_Patient' ;
                end
                
                % Select ECU Valve Type
                switch valveTypeSelect
                    case 1, valveECU = New_valveECU ; numECU = New_numECU ; denECU = New_denECU ;
                        valveName = 'New_Valve' ;
                    case 2, valveECU = Old_valveECU ; numECU = Old_numECU ; denECU = Old_denECU ;
                        valveName = 'Old_Valve' ;
                end
                
                % Initialize reconstruction and lpf filters
                [ numRLPF , denRLPF ] = butter( rec_lpf_order(aa) , rec_lpf_cf(aa) , 's' ) ;                
                [ numBW , denBW ] = butter( lpf_order(aa) , lpf_cf(aa) , 's' ) ;
                
                % Calculate the frequency response of the filters
                recLPF = freqs( denRLPF , numRLPF , radF ) ;
                bwLPF = freqs( denBW , numBW , radF ) ;
                
                %%%%%%%% Intialize CLTF, objective, and cost functions %%%%%%%%%%%%
                % PID model
                pid_opt = @(s,P) P(1) + P(2)./s + P(3).*s ;
                
                % total system transfer function,open loop and closed loop
                openLoopSys = @(s,P) pid_opt(s,P) .* valveECU(s) .* patient(s) .* Ktrans .* recLPF ;
                cltfden = @(s,P) (1 + bwLPF .* openLoopSys(s,P)) ;
                closedLoopSys = @(s,P) openLoopSys(s,P) ./ (cltfden(s,P)) ;
                
                % objective function
                objective = @(Param) sum(power(abs(closedLoopSys(Sobs,Param))-1,2)) + lambdaReg(aa).*sum(power(Param,2)) ;
                
                % Numerator(zeros) and Denominator(poles) closed loop transfer function
                % coefficient initialization (PID parameters are convolved inside the
                % function polesLHP).
                zerosVLK = conv( conv( conv( numECU , patient_NUM ) , numRLPF ) , numBW ) .* Ktrans ;
                polesVLK = conv( conv( conv( conv( conv( denECU , patient_DEN ) , denBW) , [1 0] ) , denRLPF ) , denBW ) ;
                
                % constraint function(s)
                stabilityLHP = @(Param) polesLHP( zerosVLK , polesVLK , Param ) ;
                
                % Define unique name for current file (based on parameters chosen)
                UniqueName = sprintf('%.2f-%.2f_freqRange_%d_numParams_%d_Lambda_rplf-%d-%d_lpf_%d-%d' , ...
                    fmin(aa) , fmax(aa) , lambdaReg(aa) , rec_lpf_order(aa) , ...
                    rec_lpf_cf(aa) , lpf_order(aa) , lpf_cf(aa) ) ;
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MONTE-CARLO OPTIMIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Initialize variables to store optimization
                % parameters/results
                Pinit = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                Popt  = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                fval = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                exitflag = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                output = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                lambda = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                grad = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                hessian = cell( numInitGuess(1) , numInitGuess(2) , numInitGuess(3) ) ;
                
                % Turn's off Large-Scale Algorithm -> 
                % Medium-Scale is better for constraint type problems -> improves accuracy
                options = optimset('LargeScale','off') ;
                opstions.MaxFunEvals = 1e4 ; % Max number of function solver evaluations
                options.MaxIter = 1e4 ;      % Max number of function iterations
                options.TolFun = 0 ;         % Tolerance of function solver -> set to 0
                options.TolCon = 0 ;         % Tolerance of function solver's constraint
                
                for ii = 1:numInitGuess(1)
                    
                    waitbar( ii/numInitGuess(1) )
                    drawnow()
                    
                    for jj = 1:numInitGuess(2)
                        for kk = 1:numInitGuess(3)
                            % Initialize range of guesses to be used in
                            % current iteration
                            Pinit{ii,jj,kk} = [paramInitGuess{1}(ii),paramInitGuess{2}(jj),paramInitGuess{3}(kk)] ;
                            % Fmincon - non-linear function solver
                            [ Popt{ii,jj,kk} , fval{ii,jj,kk} , exitflag{ii,jj,kk} , output{ii,jj,kk} , ...
                               lambda{ii,jj,kk}, grad{ii,jj,kk} , hessian{ii,jj,kk} ] = ...
                               fmincon( objective , Pinit{ii,jj,kk,:} , [],[],[],[],[],[], stabilityLHP , options ) ;
                        end
                    end
                end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                % Obtain today's date to use as name of file to store specific variables
                t = datetime() ;
                t.Format = strcat('yyyy-MM-dd') ;
                
                % Create the name of the file to store specific variables
                filename = strcat(pwd,'\SavedVariables\',UniqueName,'_',valveName,'_',lungModelName,char(t),'.mat') ;
                
                % Save specific variables to file
                numParam_save_Kp = numParam_Kp(aa) ;
                numParam_save_Ki = numParam_Ki(aa) ;
                numParam_save_Kd = numParam_Kd(aa) ;
                fmin_save = fmin(aa) ;
                fmax_save = fmax(aa) ;
                fnum_save = fnum(aa) ;
                lambdaReg_save = lambdaReg(aa) ;
                rangeMin_Kp_save = rangeMin_Kp(aa) ;
                rangeMax_Kp_save = rangeMax_Kp(aa) ;
                rangeMin_Ki_save = rangeMin_Ki(aa) ;
                rangeMax_Ki_save = rangeMax_Ki(aa) ;
                rangeMin_Kd_save = rangeMin_Kd(aa) ;
                rangeMax_Kd_save = rangeMax_Kd(aa) ;
                rlpf_order = rec_lpf_order(aa) ;
                rlpf_cutoff = rec_lpf_cf(aa) ;
                lpf_order = lpf_order(aa) ;
                lpf_cutoff =  lpf_cf(aa) ;
                
                % Save file with following variables to a mat file in
                % folder location SavedVariables
                save(filename,'Popt', 'numParam_save_Kp','numParam_save_Ki','numParam_save_Kd',...
                    'fmin_save' ,'fmax_save' , 'fnum_save' ,'lambdaReg_save','fval' , 'exitflag' ,...
                    'output' , 'lambda' , 'grad' , 'hessian' , 'rangeMin_Kp_save',...
                    'rangeMax_Kp_save','rangeMin_Ki_save','rangeMax_Ki_save','rangeMin_Kd_save',...
                    'rangeMax_Kd_save', 'rlpf_order' , 'rlpf_cutoff' , 'lpf_order' ,'lpf_cutoff' ) ;
            end
        end
    end
end