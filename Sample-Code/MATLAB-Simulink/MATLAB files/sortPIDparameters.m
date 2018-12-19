%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Program: 
% Programmer: Bakir Hajdarevic
% Date: 7/20/2017
% Description: Allows a user to upload a file created using
% Multi_pidEstimation.m then process it accordingly. Here the user may view
% a 3-D plot of their optimized values then create a transfer function
% for the top parameters.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Define Immutable Functions/Parameters
% Healthy Adult
hthAdult = @(s) (0.011.*s.^3 + 1.82.*s.^2 + 54.59.*s + 102.2)./(s.^2 + 3.27.*s);
numHA = [0.011 1.82 54.59 102.2];
denHA = [1 3.27 0];

% COPD Adult
copdAdult = @(s) (0.01.*s.^3 + 4.67.*s.^2 + 839.94.*s + 809.81)./(s.^2 + 26.98.*s);
numCA = [0.01 4.67 839.94 809.81];
denCA = [1 26.98 0] ;

% Healthy Pediatric
hthPed = @(s) (0.003.*s.^3 + 7.24.*s.^2 + 196.47.*s + 282.13)./(s.^2 + 2.31.*s);
numHP = [0.003 7.24 196.47 282.13];
denHP = [1 2.31 0];

% Initialize ASCO ECU-Valve Transfer Function
valveECU = @(s) (7.027e05.*s.^2 + 2.063e08.*s.^1 + 2.763e09) ./ ...
	(s.^5 + 270.6.*s.^4 + 8.645e04.*s.^3 + 7.733e06.*s.^2 + 4.773e08.*s + 4.298e09);
numECU = [7.027e05 2.063e08 2.763e09];
denECU = [1 270.6 8.645e04 7.733e06 4.773e08 4.298e09] ;

% Initialize 8th Order Butterworth Low Pass Filter
bwFilt = @(s) (9.45e19)./(s.^8 + 1610.*s.^7 + 1.295e06.*s.^6 + 6.763e08.*s.^5 +...
     2.497e11.*s.^4 + 6.668e13.*s.^3 + 1.259e16.*s.^2 + 1.543e18.*s + 9.45e19);
numBW = [9.45e19];
denBW = [1 1610 1.295e06 6.763e08 2.497e11 6.668e13 1.259e16 1.543e18 9.45e19];

% pressure transducer gain
Ktrans = 0.0977;

% PID model
pid = @(s,P) P(1) + P(2)./s + P(3).*s;

%% Load file
directoryPath = strcat(pwd,'\SavedVariables\');
patientType = {'Healthy_Adult\','COPD_Adult\','Healthy_Pediatric\'};

[LungModelType,ok] = listdlg('PromptString','Select a patient type to process:',...
    'SelectionMode','single',...
    'ListString',patientType);

switch LungModelType
    case 1, patient =  hthAdult ; patient_NUM = numHA; patient_DEN = denHA;
        nameOfFile = 'Healthy_Adult';
    case 2, patient = copdAdult ; patient_NUM = numCA; patient_DEN = denCA;
        nameOfFile = 'COPD_Adult';
    case 3, patient =    hthPed ; patient_NUM = numHP; patient_DEN = denHP;
        nameOfFile = 'Healthy_Pediatric';
end

[freqRangeSelected,ok] = listdlg('PromptString','Select a frequency range to process:',...
    'SelectionMode','single',...
    'ListString',frequencyType);

filesToList = char(strcat(directoryPath,patientType(LungModelType),frequencyType(freqRangeSelected)));
fileList = dir(filesToList);

% Obtain a list of all the file names within the folder SavedVariables
for ii = 1: size(fileList,1)
    fileNames{ii} = fileList(ii).name;
end

[filesSelected,ok] = listdlg('PromptString','Select a file (ctrl-hold for multiple):',...
    'SelectionMode','single',...
    'ListString',fileNames);

% Convert cell of characters into string
fileNames = cellstr(fileNames);

%% Process File and Define Objective/Error and Closed Loop TF Function
% Load file
filePathToLoad = strcat(filesToList,fileNames{filesSelected});

loadedStruct = load(filePathToLoad);

lambdaReg = loadedStruct.lambdaReg_save;
exitflag = loadedStruct.exitflag;
Popt = loadedStruct.Popt;

fmin = loadedStruct.fmin_save;
fmax = loadedStruct.fmax_save;
fnum = loadedStruct.fnum_save;

% Initialize Frequency range
F = logspace( log10(fmin) , log10(fmax) ,fnum) ;
radF = F*2*pi;
Sobs = 2j*pi*F;

% F2 = logspace( log10(0.01) , log10(100) ,1e3) ;
% radF2 = F2*2*pi;
% Sobs2 = 2j*pi*F2;

% Initialize Closed Loop Transfer Function (and open loop if needed)
openLoopSys = @(s,P) pid(s,P) .* patient(s) .* valveECU(s) .* Ktrans;
cltfden = @(s,P) (1 + bwFilt(s).*openLoopSys(s,P));
closedLoopSys = @(s,P) openLoopSys(s,P) ./ (cltfden(s,P));

% objective function
objective = @(P) sum(power(abs(closedLoopSys(Sobs,P))-1,2)) + lambdaReg.*sum(power(P,2)) ;

%% Separate Data based on ExitFlag Conditions
%%Proces only "good" results here
% Index wheret the results where greater than -1
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
goodResults = 0;                            % Set to zero initially
goodResults = find(cat(1,exitflag{:}) > 0);
zeroResults = find(cat(1,exitflag{:}) == 0);
negResults = find(cat(1,exitflag{:}) < 0);

% Sort Optimizied solutions according to exit flag conditions
Popt_good_results = cat(1,Popt{goodResults});
Popt_zero_Results = cat(1,Popt{zeroResults});
Popt_neg_Results = cat(1,Popt{negResults});

% Obtain cost for "good-results"
for aa = 1: size(Popt_good_results,1)
    Eopt_good_results(aa,:) = objective(Popt_good_results(aa,:));
end

% Find unique values according to exit flag indices
[Popt_uni_goodRes,~,ind_uni_goodRes] = unique(round(Popt_good_results,1),'rows');
[Popt_uni_zeroRes,~,ind_uni_zeroRes] = unique(round(Popt_zero_Results,1),'rows');
[Popt_uni_negRes,~,ind_uni_negRes] = unique(round(Popt_neg_Results,1),'rows');

% Define colorbar/histogram for 3D plot for "good-results"
% Within linspace: 
% min(Eopt_good results) is the minimum cost or lowest color
% the second value should be adjustable per user
col_num = size(Popt_good_results,1) ;
[ ~ , col_bin , col_ind ] = histcounts( ...
    Eopt_good_results , ...
    linspace( min(Eopt_good_results) , 200 ,col_num-1) ) ;
col_ind( Eopt_good_results >= max(col_bin) ) = col_num ;

% Set the color map according to the chosen color spectrum
col_map = jet( col_num ) ;

%% Create a 3-D Plot of the Optimized P.I.D. According to Exitflag Integers
figure( ...
    'Colormap' , col_map , ...
    'Color' , [1,1,1] )
subplot( 1 , 1 , 1,...
    'Xlim' , [-1e1 1e1],...
    'Ylim' , [-1e1 1e1],...
    'Zlim' , [-1e1 1e1],...
    'CLim' , [ min(col_bin) , max(col_bin) ] , ...
    'NextPlot' , 'add' )
grid on
for cc = 1 : col_num
    tmp = find( col_ind == cc ) ;
    plot3(...
        Popt_good_results(tmp,1),...
        Popt_good_results(tmp,2),...
        Popt_good_results(tmp,3),...
        'ko',...
        'MarkerFaceColor' , col_map(cc,:) );
end
plot3(...
    Popt_zero_Results(:,1),...
    Popt_zero_Results(:,2),...
    Popt_zero_Results(:,3),...
    '.',...
    'Color' , [0,0,0]+0.5);
plot3(...
    Popt_neg_Results(:,1),...
    Popt_neg_Results(:,2),...
    Popt_neg_Results(:,3),...
    '.',...
    'Color' , [0,0,0]+0.8);
xlabel( 'K_p' )
ylabel( 'K_i' )
zlabel( 'K_d' )

colorbar()