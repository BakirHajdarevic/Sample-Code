%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Program: PIDsortBestResults_withFilter.m
% Programmer: Bakir Hajdarevic
% Date: 7/14/2017
% Description: This program let's the user look at the mat file(s) created
% by the program Multi_pidEstimation.m which tries to obtain a unity gain
% over a user specified frequency range. 
%
%
% The top 5 are chosen according to the lowest cost amongst the results 
% which had an exitflag of 1:2 as well as having poles located in the left 
% half plane (or equal to 0).
%
%        + A 3-D plot of the values returned by the function solver per
%        iteration. The results are colored in accordance to the exitflag
%        value returned (1:2 = good ; 0 = zero ; -2:-1 = bad).
%        + Step Response of the 'top 5' PID parameters.
%        + Bode plots (magnitude in absolute and phase in degrees) of the
%        'top 5' results.
% 
% At the end of each file iteration, the program asks the user if they
% would like to save the top 5 results for later processing as .csv files.
% These files are used in the program lagrangeOptimization.m where they are
% used to observe a relationship between varying lambda regularization 
% values and objective function cost, PID parameter value, and number of 
% local minima per 'top PIDs'. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all
clc

% Healthy Adult
hthAdult = @(s) (0.011.*s.^3 + 1.82.*s.^2 + 54.59.*s + 102.2)./(s.^2 + 3.27.*s);
numHA = [0.011 1.82 54.59 102.2];
denHA = [1 3.27 0];

% COPD Adult
copdAdult = @(s) (0.01.*s.^3 + 4.67.*s.^2 + 839.94.*s + 809.81)./(s.^2 + 26.98.*s);
numCA = [0.01 4.67 839.94 809.81];
denCA = [1 26.98 0];

% Healthy Pediatric
hthPed = @(s) (0.003.*s.^3 + 7.24.*s.^2 + 196.47.*s + 282.13)./(s.^2 + 2.31.*s);
numHP = [0.003 7.24 196.47 282.13];
denHP = [1 2.31 0];

% Test Lung Model
% %%% 7 poles, 7 zeros TLM TF
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
empt_pat = @(s) 1; 
num_empt_pat = 1;
den_empt_pat = 1;

% Initialize ASCO ECU-Valve Transfer Function
%%%%%%%%%%%%%%%%%%%%%%%%%% NEW VALVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
New_valveECU = @(s) ( -5756.*s.^3 + 2.333e6.*s.^2 + 1.863e8.*s + 2.919e9 ) ./ ...
	( s.^5 + 562.9.*s.^4 + 1.25e5.*s.^3 + 1.017e7.*s.^2 + 4.518e8.*s + 4.563e9 );
New_numECU = [ -5756 2.333e6 1.863e8 2.919e9 ];
New_denECU = [ 1 562.9 1.25e5 1.017e7 4.518e8 4.563e9 ];

%%%%%%%%%%%%%%%%%%%%%%%%%% OLD VALVE (DAVE'S) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Old_valveECU = @(s) ( 7.783e08 )./( s.^4 + 160.1.*s.^3 + 9.043e04.*s.^2 + 4.832e06.*s + 1.414e09 );
Old_numECU = 7.783e08;
Old_denECU = [ 1 160.1 9.043e04 4.832e06 1.414e09 ];

% pressure transducer gain
Ktrans = 0.0977;

% PID model
pid = @(s,P) P(1) + P(2)./s + P(3).*s;

%% Load file and file-structure here
% Specify folder location to save best variables
filePathToSave = strcat(pwd,'\SavedVariables\BestParameters\');
directoryPath = strcat(pwd,'\SavedVariables\');

patientType = {'Healthy_Adult\','COPD_Adult\','Healthy_Pediatric\',...
    'Healthy_Adult_with_Filters\','COPD_Adult_with_Filters\','Healthy_Pediatric_with_Filters\',...
    'Test_Lung_Model_1\','Test_Lung_Model_2\','Lung_Bag\','Empty_Patient\'};

valveType = {'New Valve','Old Valve'};

frequencyType = {'Frequency_Range_0.1-10Hz\','Frequency_Range_0.1-20Hz\',...
    'Frequency_Range_1-10Hz\','Frequency_Range_1-20Hz\'};

% Prompt the user for the desired patient type to process
ok = 0;
while(ok == 0)
    [LungModelType,ok] = listdlg('PromptString','Select a patient type to process:',...
                'SelectionMode','single',...
                'ListString',patientType);
end

% Select Lung Model Type
switch LungModelType
    case 1, patient =  hthAdult ; patient_NUM = numHA; patient_DEN = denHA;
        nameOfFile = 'Healthy_Adult';
    case 2, patient = copdAdult ; patient_NUM = numCA; patient_DEN = denCA;
        nameOfFile = 'COPD_Adult';
    case 3, patient =    hthPed ; patient_NUM = numHP; patient_DEN = denHP;
        nameOfFile = 'Healthy_Pediatric';
    case 4, patient = tstLungModel_1 ; patient_NUM = numTLM_1; patient_DEN = denTLM_2;
        nameOfFile = 'Test_Lung_Model_1';
    case 5, patient = tstLungModel_2 ; patient_NUM = numTLM_2; patient_DEN = denTLM_2;
        nameOfFile = 'Test_Lung_Model_2';
    case 6, patient = lungBag; patient_NUM = numLB; patient_DEN = denLB; nameOfFile = 'Lung_Bag';
    case 7, patient = empt_pat ; patient_NUM = num_empt_pat ; patient_DEN = den_empt_pat ;
        lungModelName = 'Empty_Patient';
end

ok = 0;
while( ok == 0 )
    [valveTypeSelect, ok] = listdlg('PromptString','Select a valve type to process:',...
                'SelectionMode','single',...
                'ListString',valveType);
end

switch valveTypeSelect
    case 1, valveECU = New_valveECU; numECU = New_numECU; denECU = New_denECU;
        valveName = valveType{valveTypeSelect};
    case 2, valveECU = Old_valveECU; numECU = Old_numECU; denECU = Old_denECU; 
        valveName = valveType{valveTypeSelect};
end

% Prompt the user for the desired frequency range to process
ok = 0;
while(ok == 0)
    [freqRangeSelected,ok] = listdlg('PromptString','Select a frequency range to process:',...
                'SelectionMode','single',...
                'ListString',frequencyType);
end

filesToList = char(strcat(directoryPath,patientType(LungModelType),frequencyType(freqRangeSelected)));

fileList = dir(filesToList);

% Obtain a list of all the file names within the folder SavedVariables
for ii = 1: size(fileList,1)
    fileNames{ii} = fileList(ii).name;
end

% Prompt the user for the desired files to load
ok = 0;
while(ok == 0)
    [filesSelected,ok] = listdlg('PromptString','Select a file (ctrl-hold for multiple):',...
        'SelectionMode','multiple',...
        'ListString',fileNames);
end
 
% Convert cell of characters into string
fileNames = cellstr(fileNames);

for ii = 1 : size(filesSelected,2)
    % Load file
    filePathToLoad = strcat(filesToList,fileNames{filesSelected(ii)});
    
    % Load file (mat-structure)
    loadedStruct = load(filePathToLoad);
    
    % Load variables from file structure into distinct variables
    lambdaReg = loadedStruct.lambdaReg_save;        % Regularization parameter used
    exitflag = loadedStruct.exitflag;               % Exitflag array from function solver 
    Popt = loadedStruct.Popt;                       % Optimization results
    fmin = loadedStruct.fmin_save;                  % Minimum optimization frequency
    fmax = loadedStruct.fmax_save;                  % Maximum optimization frequency
    fnum = loadedStruct.fnum_save;                  % Number of frequency data points used
    rangeMin_Kp = loadedStruct.rangeMin_Kp_save;    % Minimum Kp value guess
    rangeMax_Kp = loadedStruct.rangeMax_Kp_save;    % Maximum Kp value guess
    rangeMin_Ki = loadedStruct.rangeMin_Ki_save;    % Minimum Ki value guess
    rangeMax_Ki = loadedStruct.rangeMax_Ki_save;    % Maximum Ki value guess
    rangeMin_Kd = loadedStruct.rangeMin_Kd_save;    % Minimum Kd value guess
    rangeMax_Kd = loadedStruct.rangeMax_Kd_save;    % Maximum Kd value guess
    rlpf_order = loadedStruct.rlpf_order;           % Reconstruction filter order
    rlpf_cutoff = loadedStruct.rlpf_cutoff;         % Reconstruction filter cutoff
    lpf_order = loadedStruct.lpf_order;             % Low-papss filter order
    lpf_cutoff = loadedStruct.lpf_cutoff;           % Low-pass fitler cutoff
    
    % Initialize frequency range to be used
    F = logspace( log10(fmin) , log10(fmax) ,fnum);
    radF = F*2*pi;
    Sobs = 2j*pi*F;
    
    % Derive coefficients for the reconstruction filter and low-pass filter
    [ numRLPF , denRLPF ] = butter( rlpf_order , rlpf_cutoff , 's' );
    [ numBW , denBW ] = butter( lpf_order , lpf_cutoff , 's' );
    
    % Derive annonymous function handles for the above filters
    [ numRLPF_fun , denRLPF_fun ] = der_tf_funct( numRLPF , denRLPF ) ;
    [ numBW_fun , denBW_fun ] = der_tf_funct( numBW , denBW ) ;
    
    % Calculate the frequency response
    recLPF = freqs( denRLPF , numRLPF , radF );
    bwLPF = freqs( denBW , numBW , radF );
    
%     openLoopSys = @(s,P) pid(s,P) .* patient(s) .* valveECU(s) .* Ktrans;
%     cltfden = @(s,P) (1 + bwFilt(s).*openLoopSys(s,P));
    openLoopSys = @(s,P) pid(s,P) .* patient(s) .* valveECU(s) .* Ktrans .* recLPF;
    cltfden = @(s,P) (1 + bwLPF.*openLoopSys(s,P));
    closedLoopSys = @(s,P) openLoopSys(s,P) ./ (cltfden(s,P));

    % objective function
    objective = @(P) sum(power(abs(closedLoopSys(Sobs,P))-1,2)) + lambdaReg*sum(power(P,2));

    % Process only "good" results here
    % Index where the results where greater than -1
    %  1  First order optimality conditions satisfied.
    %  0  Too many function evaluations or iterations.
    % -1  Stopped by output/plot function.
    % -2  No feasible point found.
    % Trust-region-reflective, interior-point, and sqp:
    %  2  Change in X too small.
    % Trust-region-reflective:
    %  3  Change in objective function too small.
    % Active-set only:
    %  4  Computed search direction too small.
    %  5  Predicted change in objective function too small.
    % Interior-point and sqp:
    % -3  Problem seems unbounded.
    goodResults = find(cat(1,exitflag{:}) > 0);
    zeroResults = find(cat(1,exitflag{:}) == 0);
    negResults = find(cat(1,exitflag{:}) < 0);
    
    % Sort Optimizied solutions according to exit flag conditions
    Popt_good_results = cat(1,Popt{goodResults});
    Popt_zero_Results = cat(1,Popt{zeroResults});
    Popt_neg_Results = cat(1,Popt{negResults});
    
    % Obtain the cost of the good results
    Eopt_good_results = 0;
    for aa = 1: size(Popt_good_results,1)
        Eopt_good_results(aa,:) = objective(Popt_good_results(aa,:));
    end
    
    % Sort the Cost and Optimized PID parameters
    sortedCost_PID = sortrows([Eopt_good_results(:,:),Popt_good_results(:,:)]);
    
    % Find unique values according to exit flag indices
    [ Popt_uni_goodRes , ~ , ind_uni_goodRes ] = unique( round( Popt_good_results , 3 ) , 'rows' );
    num_uni_good = length( unique( ind_uni_goodRes ) );
    [ Popt_uni_zeroRes , ~ , ind_uni_zeroRes ] = unique( round( Popt_zero_Results , 3 ) , 'rows' );
    num_uni_zero = length( unique( ind_uni_zeroRes ) );
    [ Popt_uni_negRes , ~ , ind_uni_negRes ] = unique( round( Popt_neg_Results , 3 ) , 'rows' );
    num_uni_neg = length( unique( ind_uni_zeroRes ) );
    
    % Map out lines of unique converged solutions
    cmap_good = lines( num_uni_good );
    cmap_zero = lines( num_uni_zero );
    cmap_neg = lines( num_uni_neg );
    
    % Find the median value of the sorted PID cost
    medianValIndex =  round((min(find(sortedCost_PID(:,1)>median(sortedCost_PID(:,1)))) + ...
        max(find(sortedCost_PID(:,1)<median(sortedCost_PID(:,1))))) / 2);
    
    if( isempty(medianValIndex) == 0 && size(goodResults,1) > 2)
        col_num = medianValIndex ;
        
        [ ~ , col_bin , col_ind ] = histcounts( ...
            Eopt_good_results , ...
            linspace( sortedCost_PID(1,1) , sortedCost_PID(medianValIndex,1) ,col_num-1) );
        col_ind( Eopt_good_results >= max(col_bin) ) = col_num;

        col_map = jet( col_num );
        
        figure( ...
            'Colormap' , col_map , ...
            'Color' , [1,1,1] )
        subplot( 1 , 1 , 1,...
            'CLim' , [ min(col_bin) , max(col_bin) ] , ...
            'NextPlot' , 'add' )
        grid on
        % Plot "Good" Results for PID optimization
        for cc = 1 : col_num
            tmp = find( col_ind == cc ) ;
            lgd1 = plot3(...
                Popt_good_results(tmp,1) , ...
                Popt_good_results(tmp,2) , ...
                Popt_good_results(tmp,3) , ...
                'ko' , ...
                'MarkerFaceColor' , col_map(cc,:) );
        end
        if( isempty(Popt_zero_Results) == 0 )
            % Plot zero flag results
            lgd2 = plot3(...
                Popt_zero_Results(:,1) , ...
                Popt_zero_Results(:,2) , ...
                Popt_zero_Results(:,3) , ...
                '.' , ...
                'Color' , [0,0,0]+0.5);
        end
        
        if( isempty(Popt_neg_Results) == 0 )
            % Plot "Bad" Results
            lgd3 = plot3(...
                Popt_neg_Results(:,1) , ...
                Popt_neg_Results(:,2) , ...
                Popt_neg_Results(:,3) , ...
                '.' , ...
                'Color' , [0,0,0] + 0.8 );
        end
        xlabel( 'K_p' , 'FontWeight' , 'bold', 'FontSize' , 14)
        ylabel( 'K_i' , 'FontWeight' , 'bold', 'FontSize' , 14)
        zlabel( 'K_d' , 'FontWeight' , 'bold', 'FontSize' , 14)
        legend( [ lgd1 , lgd2 , lgd3 ] , ...
            { 'Good Result (Exitflag: 1:2' , ...
            '(Zero Result (Exitflag: 0)' , ...
            'Bad Results (Exitflag: -2:-1)' } , ...
            'FontWeight' , 'bold', 'FontSize' , 12 ) 
        colorbar()
    end
    
    % Initialize variables for storing unique numbers of convergences and
    % their respective objective costs
    Num_uni = double.empty ;
    Ecost_uni = double.empty ;
    
    for bb = 1: size(Popt_uni_goodRes,1)
        Num_uni(bb ,:) = numel(Popt_good_results(ind_uni_goodRes == bb));
        Ecost_uni(bb,:) = mean(Eopt_good_results(ind_uni_goodRes == bb));
    end
    
    % Sort the PID optimization results using the function cost from lowest
    % to highest cost
    sortedResults = sortrows([ Ecost_uni ,Popt_uni_goodRes , Num_uni ]) ;
    % Initialize top PID parameters count
    top_5_param = 1 ;
    
    if( num_uni_good < 5)
        % Set max top parameters to top 5
        maxTopParam = size( Popt_uni_goodRes , 1 ) + 1 ;
    else
        % Set max top parameters to 6 (including unoptimized PID)
        maxTopParam = 6 ;
    end
    
    % Initialize matrix for storing unoptimized PID and top 5 (or fewer) PID 
    % optimized parameters along with the cost, number of unique solutions
    % for the particular PID parameters, and the lambda regularization
    % value that was used.
    Popt_top_Param = zeros( maxTopParam , 6 );
    % Use 6th column of matrix for storing the lambda regularization
    % constant
    Popt_top_Param( 2 : end , 6 ) = lambdaReg;
    
    % Pre-allocate a tf variable type for computing the optimized PID
    % closed loop transfer functions
    sysTopCLTF = tf( zeros([1 1 1] ) ) ;
    sysTopOL = tf( zeros([1 1 1] ) ) ;
    disc_CL_sys5 = tf( zeros( [1 1 1] ) ) ;
    disc_OL_sys5 = tf( zeros( [1 1 1] ) ) ;
    
    % Initialize legend for storage
    titleTxt = cell( maxTopParam ,1) ;
     
    % Compute function cost of unoptimized PID closed loop transfer function
    unOptCost = objective([1 0 0]) - lambdaReg;
    
    % Compute unoptimized PID transfer function here
    numOLTF = conv(numECU,patient_NUM)*Ktrans;
    denOLTF = conv(conv(denECU,patient_DEN),[1 0]);
    sysOLTF = tf(numOLTF,denOLTF);
    sysBW = tf( numBW , denBW ) ;
    sysCLTF = feedback( sysOLTF , sysBW ) ;
    
    % Store unoptimized transfer function here
    sysTopCLTF(:,:,top_5_param) = sysCLTF;
    sysTopOL(:,:,top_5_param) = sysOLTF;
    
    titleTxt{top_5_param} = sprintf( '(%.3f, %.3f, %.3f) : %.3f, %d' ,[1 0 0], unOptCost, 0);
    
    % Store unoptimized PID closed loop parameters here
    Popt_top_Param(top_5_param,2:5) = [1 0 0 1];          % Unoptimzied PID parameters ( Kp = 1 , rest set to 0 )
    Popt_top_Param(top_5_param,6) = 0;                    % Unoptimized regularization constant = 0
    Popt_top_Param(top_5_param,1) = unOptCost;            % Unoptimized function cost 
    
    % Increase number of top parameters
    top_5_param = top_5_param + 1 ;
                 
    % Initialize iteration
    cc = 1 ;
    smp_period = 0.01 ;
    
    % Initialize continuous to discrete options
    % opt = c2dOptions('Method','tustin','PrewarpFrequency',3.4);
    opt = c2dOptions( 'Method' , 'tustin' ) ;
    
    % Run through the best results (i.e. exitflag value of 1 or higher)
    % and store the PID parameters, cost, and number of parameters that
    % converged to the specific local minima
    % The best result must have all poles in the left half plane
     while( top_5_param <= maxTopParam && cc < num_uni_good )
         % Obtain matrix of Open Loop Transfer Function using top 5 PID
         % Parameters
         numOLTF = conv(conv(numECU,patient_NUM),[sortedResults(cc,4), sortedResults(cc,2),sortedResults(cc,3)])*Ktrans;
         denOLTF = conv(conv(denECU,patient_DEN),[1 0]);
         sysOLTF = tf(numOLTF,denOLTF);
         
         % Derive closed loop transfer function
         sysCLTF = feedback( sysOLTF , sysBW );
         
         % Find the poles and zeros of the closed loop transfer
         % function
         [poles1, zeros1] = pzmap(sysCLTF);
         
         % Check if the real parts of poles are in right half plane
         if(real(poles1) <= 0)
             % Store the current and unique PID parameters
             Popt_top_Param(top_5_param,1:5) = sortedResults(cc,:);
             % Title for legend(s)
             titleTxt{top_5_param} = sprintf( '(%.3f, %.3f, %.3f) : %.3f, %d' ,...
                 Popt_top_Param(top_5_param,2:4) ,  Popt_top_Param(top_5_param,1), Popt_top_Param(top_5_param,5));
             
             % Store optimal transfer function (top 5/max)
             sysTopCLTF(:,:,top_5_param) = sysCLTF;
             sysTopOL(:,:,top_5_param) = sysOLTF;
             % Obtain discrete time transfer function for continuous model
             disc_CL_sys5(:,:,top_5_param) = c2d( sysCLTF , smp_period ,opt );
             disc_OL_sys5(:,:,top_5_param) = c2d( sysOLTF , smp_period ,opt );
             
             % Increase number of top parameters
             top_5_param = top_5_param + 1;
         end
             
         cc = cc + 1;
     end     
     
    
    % Initialize empty arrays for storing magnitude and phase
    magCLTF = double.empty();
    phaseCLTF = double.empty();
    disc_magCLTF = double.empty();
    disc_phaseCLTF = double.empty();
    mag = zeros(size(radF));
    phase = zeros(size(radF));
    
    % Obtain and store the magnitude and phase of the top 5 PID-CLTF
    for ee = 1 : ( top_5_param - 1 )
        % Obtain frequency response of continuous time system
        [ mag , phase , ~ ] = bode( sysTopCLTF(:,:,ee) , radF );
        
        % Store the magnitude (in absolute) of the current iteration of the
        % top 5 PID-CLTF
        magCLTF(ee,:) = mag;
        
        % Store the phase (in degrees) of current iteration of the top 5
        % PID-CLTF.
        % Set all phases to 0
        phaseCLTF(ee,:) = phase - phase(1);
        
        % Obtain frequency response of discrete time system
        [ mag , phase , ~ ] = bode( disc_CL_sys5(:,:,ee) , radF );
                % Store the magnitude (in absolute) of the current iteration of the
        % top 5 PID-CLTF
        disc_magCLTF(ee,:) = mag;
        
        % Store the phase (in degrees) of current iteration of the top 5
        % PID-CLTF.
        % Set all phases to 0
        disc_phaseCLTF(ee,:) = phase - phase(1); 
    end

    
    % Plot Step Response(s) of Continuous Closed Loop Transfer Function
    figure( ...
        'Color' , [1,1,1] )
    subplot( 1 , 1 , 1 , ...
        'NextPlot' , 'add')
    % Display Step Response of CLTF (exclude un-optimized (no) PID CLTF)
    for dd = 2 : (top_5_param - 1)
        step(sysTopCLTF( : , : , dd ) )
    end
    title( 'Continuous Time Step Response' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 )
    legend_obj = legend( [ titleTxt( 2 : ( top_5_param - 1 ) ) ] );
    legend_obj_title = get( legend_obj , 'title' );
    set( legend_obj_title , 'string' , '(K_p, K_i, K_d) : \phi cost, #-elements' );
    
    
    % Plot Step Response(s) of Discrete Closed Loop Transfer Function
    figure( ...
        'Color' , [1,1,1] )
    subplot( 1 , 1 , 1 , ...
        'NextPlot' , 'add')
    % Display Step Response of CLTF (exclude un-optimized (no) PID CLTF)
    for dd = 2 : (top_5_param - 1)
        step(disc_CL_sys5( : , : , dd ) )
    end
    title( 'Discrete Time Step Response' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 )
    legend_obj = legend( [ titleTxt( 2 : ( top_5_param - 1 ) ) ] );
    legend_obj_title = get( legend_obj , 'title' );
    set( legend_obj_title , 'string' , '(K_p, K_i, K_d) : \phi cost, #-elements' );
    
    
    % Plot Bode Plot of Continuous Time Closed Loop Transfer Function
    figure( ...
        'Color' , [1,1,1] )
    % Plot of Magnitude (absolute)
    subplot(  2 , 1 , 1 , ...
        'XScale' , 'log' , ...
        'Ylim' , [1e-2 1e1],...
        'NextPlot' , 'add', ...
        'TickDir' , 'out' , ...
        'YScale' , 'log')
    area( [ 0.1 , 20] , max(ylim())+[0,0] , min(ylim()) , ...
        'FaceColor' , [0,0,0] , ...
        'FaceAlpha' , 0.02 , ...
        'EdgeColor' , 'none' )
    for ff = 1 : (top_5_param - 1)
        plot(F,magCLTF(ff,:) );
    end
    plot( [ 0.1 , 20] , [1,1] , 'k--' )
    ylabel( 'Magnitude (Absolute)' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 )
    title( 'Continuous Time Bode Plot' , ...
        'FontWeight' , 'bold', 'FontSize' , 16 )
    set( gca , 'TickDir' , 'out' ) ;
    
    % Plot of Phase (in degrees)
    subplot(  2 , 1 , 2 , ...
        'NextPlot' , 'add', ...
        'TickDir' , 'out' , ...
        'XScale' , 'log')
    for ff = 1 : (top_5_param - 1)
        plot(F,phaseCLTF(ff,:))
    end
    xlabel( 'Frequency (Hz)' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 )
    ylabel( 'Phase (Degrees)' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 )
    set( gca , 'TickDir' , 'out' ) ;
    legend_obj = legend([ titleTxt( 1 : (top_5_param-1) ) ] , ...
        'FontWeight' , 'bold', 'FontSize' , 12 );
    legend_obj_title = get(legend_obj,'title');% Handle response
    set( legend_obj_title,'string','(K_p, K_i, K_d) : \phi cost, #-elements' ) ;
    
    % Plot Bode Plot of Discrete Time Closed Loop Transfer Function
    figure( ...
        'Color' , [1,1,1] )
    % Plot of Magnitude (absolute)
    subplot(  2 , 1 , 1 , ...
        'XScale' , 'log' , ...
        'Ylim' , [1e-2 1e1],...
        'NextPlot' , 'add', ...
        'TickDir' , 'out' , ...
        'YScale' , 'log')
    area( [ 0.1 , 20] , max(ylim())+[0,0] , min(ylim()) , ...
        'FaceColor' , [0,0,0] , ...
        'FaceAlpha' , 0.02 , ...
        'EdgeColor' , 'none' )
    for ff = 1 : (top_5_param - 1)
        plot( F , disc_magCLTF(ff,:) );
    end
    plot( [ 0.1 , 20] , [1,1] , 'k--' )
    ylabel( 'Magnitude (Absolute)' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 )
    title( 'Discrete Time Bode Plot' , ...
        'FontWeight' , 'bold', 'FontSize' , 16 )
    set( gca , 'TickDir' , 'out' ) ;
    
    % Plot of Phase (in degrees)
    subplot(  2 , 1 , 2 , ...
        'NextPlot' , 'add', ...
        'TickDir' , 'out' , ...
        'XScale' , 'log' )
    for ff = 1 : (top_5_param - 1)
        plot(F,disc_phaseCLTF(ff,:))
    end
    xlabel( 'Frequency (Hz)' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 ) 
    ylabel('Phase (Degrees)' , ...
        'FontWeight' , 'bold', 'FontSize' , 14 )
    set( gca , 'TickDir' , 'out' ) ;
    legend_obj = legend([ titleTxt( 1 : (top_5_param-1) ) ] , ...
        'FontWeight' , 'bold', 'FontSize' , 12 );
    legend_obj_title = get(legend_obj,'title');% Handle response
    set( legend_obj_title , 'string' , '(K_p, K_i, K_d) : \phi cost, #-elements' );
    
    % Plot pole zero map of top PID result in continuous time closed loop
    figure( 'Color' , [1 1 1] )
    cont_CL = iopzplot( sysTopCLTF(:,:,2) )
    p = getoptions(cont_CL); % get options for plot
    p.Title.String = ...
        sprintf( 'Continuous Time Closed Loop of:\n (P,I,D), Cost, Number of Convergences \n %s', ...
        string( titleTxt(2)) ) ; % change title in options
    setoptions( cont_CL , p , 'FreqUnits' , 'Hz' ); % apply options to plot
    
    % Plot pole zero map of top PID result in continuous time open loop
    figure( 'Color' , [1 1 1] )
    cont_OL = iopzplot( sysTopOL(:,:,2) )
    p = getoptions(cont_OL); % get options for plot
    p.Title.String = ...
        sprintf( 'Continuous Time Open Loop of:\n (P,I,D), Cost, Number of Convergences \n %s' , ...
        string(titleTxt(2)) ); % change title in options
    setoptions( cont_OL , p , 'FreqUnits' , 'Hz' ); % apply options to plot
    
    % Plot pole zero map of top PID result in discrete time closed loop
    figure( 'Color' , [1 1 1] )
    disc_CL = iopzplot( disc_CL_sys5(:,:,2) )
    p = getoptions(disc_CL); % get options for plot
    p.Title.String = ...
        sprintf( 'Discrete Time Closed Loop of:\n (P,I,D), Cost, Number of Convergences \n %s', ...
        string(titleTxt(2)) ); % change title in options
    setoptions( disc_CL , p , 'FreqUnits' , 'Hz' ); % apply options to plot
    
    % Plot pole zero map of top PID result in discrete time open loop
    figure( 'Color' , [1 1 1] )
    disc_OL = iopzplot( disc_OL_sys5(:,:,2) )
    p = getoptions( disc_OL ); % get options for plot
    p.Title.String = ...
        sprintf( 'Discrete Time Open Loop of:\n (P,I,D), Cost, Number of Convergences \n %s' , ...
        string(titleTxt(2)) ); % change title in options
    setoptions( disc_OL , p , 'FreqUnits' , 'Hz' ); % apply options to plot
    
    % Construct a questdlg to ask the user if they would like to save the
    % top 5 parameters
    choice = questdlg('Would you like to save the top parameters?' , ...
        'Save Top Parameters', ...
        'Yes','No','No') ;
    
    % Handle response for saving file
    switch choice
        case 'Yes'
        filenameToSave = char( fileNames{ filesSelected(ii) } );
        filenameToSave = filenameToSave(1:end-4);  
        fileToSave = strcat( filePathToSave , '_' , filenameToSave , '.csv' );
        matrix_to_save = { Popt_top_Param }; 
        csvwrite( fileToSave , matrix_to_save );
        case 'No'
    end
    
end