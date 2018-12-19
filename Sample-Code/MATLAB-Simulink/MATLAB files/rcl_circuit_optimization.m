%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Programmer: Bakir Hajdarevic
% Program: rcl_circuit_optimization.m
% Date: 9/23/2017
% Description: This program was created to optimize a closed loop transfer
% function with a proportional integral derivative (PID) controller of a 
% circuit plant, specifically a 3rd Order Sallen-Key Low Pass Filter, over a 
% specified frequency range. The optimization approach
% is a Monte Carlo Optimization algorithm using MATLAB's constrained 
% nonlinear function solver, fmincon. The user may define the bounds of the
% frequency range, the number of iterations per PID parameter (default is
% 10 each), and the initial guess values (default range is [-10 : 1000 : 10] ).
% Once fmincon runs through all the iterations, the user is displayed the 
% results:
%        + A 3-D plot of the values returned by the function solver per
%        iteration. The results are colored in accordance to the exitflag
%        value returned (1:2 = good ; 0 = zero ; -2:-1 = bad).
%        + Step Response of the 'top 5' PID parameters. The top 5 are
%        chosen according to the lowest cost amongst the results which had
%        an exitflag of 1:2 as well as having poles located in the left half
%        plane (or equal to 0).
%        + Bode plots (magnitude in absolute and phase in degrees) of the
%        'top 5' results.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear variables
close all
clc
% Initialize 2nd Order Sallen Key Low Pass Filter Transfer Function
lpf_sk2 = @(s) 9.45e19 ./ ( s.^8 + 1610.*s.^7 + 1.295e06.*s.^6 + 6.763e08.*s.^5 +...
    2.497e11.*s.^4 + 6.668e13.*s.^3 + 1.259e16.*s.^2 + 1.543e18.*s + 9.45e19 ) ;
num_lpf_sk2 = 9.45e19 ;
den_lpf_sk2 =  [ 1 1610 1.295e06 6.763e08 2.497e11 6.668e13 1.259e16 1.543e18 9.45e19 ] ;

% Initialize 3rd Order Sallen-Key Low Pass Fitler Transfer Function
plant = @(s) ( 4889.4577932345*11 )./( s.^3 + 13.2777257442567.*s.^2 + 14673.16111881.*s + 4889.4577932345 ) ;
num_plant = 4889.4577932345*11 ;
den_plant = [ 1 13.2777257442567 14673.16111881 4889.4577932345 ] ;

% Initialize 8th Order Butterworth Low Pass Filter
bwFilt = @(s) (9.45e19)./(s.^8 + 1610.*s.^7 + 1.295e06.*s.^6 + 6.763e08.*s.^5 +...
    2.497e11.*s.^4 + 6.668e13.*s.^3 + 1.259e16.*s.^2 + 1.543e18.*s + 9.45e19) ;
numBW = 9.45e19 ;
denBW = [ 1 1610 1.295e06 6.763e08 2.497e11 6.668e13 1.259e16 1.543e18 9.45e19 ] ;

% Initialize PID Transfer Function
pid = @(s,P) P(1) + P(2)./s + P(3).*s;

% Initialize Frequency range
fmin = 0.6 ;
fmax = 18 ;
F = logspace( log10(fmin) , log10(fmax) , 1000 ) ;
radF = F*2*pi ;
Sobs = 2j*pi*F ;

% Number of initial guesses for each design variable (3 - P.I.D.)
numInitGuess = [ 10 10 10 ] ;

% Initialize range of parameters values to be used
paramInitGuess = {
    linspace( -10 , 10 , 10 )
    linspace( -10 , 10 , 10 )
    linspace( -10 , 10 , 10 )
    } ;

% Initialize Closed Loop Transfer Function for Optimization
openLoopSys = @(s,P) pid(s,P) .* plant(s) ;
%openLoopSys = @(s,P) pid(s,P) .* lpf_sk2(s) .* plant(s) ;
%cltfden = @(s,P) (1 + bwFilt(s).* openLoopSys(s,P)) ;
cltfden = @(s,P) (1 + openLoopSys(s,P)) ;
closedLoopSys = @(s,P) openLoopSys(s,P) ./ (cltfden(s,P)) ;

% Initialize Lambda Regularization Constant
lambdaReg = 1e-6 ;

% objective function
objective = @(Param) sum( power( abs( closedLoopSys( Sobs , Param ) ) -1 , 2 ) ) + lambdaReg.*sum( power (Param,2) ) ;

% Numerator(zeros) and Denominator(poles) closed loop transfer function
% coefficient initialization (PID parameters are convolved inside the
% function polesLHP).

%zerosVLK = num_plant .* numBW .* num_lpf_sk2 ;
%polesVLK = conv(conv( conv( den_plant , den_lpf_sk2 ),denBW ), [1 0] ) ;

% zerosVLK = num_plant .* numBW ;
% polesVLK = conv(conv( den_plant ,denBW ), [1 0] ) ;

zerosVLK = num_plant ;
polesVLK = conv( den_plant , [1 0] ) ;

% constraint function(s)
stabilityLHP = @(Param) polesLHP( zerosVLK , polesVLK , Param ) ;

%% %%%%%%%%%%%%%%% MONTE-CARLO OPTIMIZATION %%%%%%%%%%%%%%%%%%%%%%%%
Pinit = cell( 10 , 10 , 10 ) ;
Popt  = cell( 10 , 10 , 10 ) ;

options = optimset( 'LargeScale' , 'off' );
options.MaxFunEvals = 1e4 ;
options.MaxIter = 1e4 ;
options.TolFun = 0 ;
options.TolCon = 0 ;

for ii = 1:numInitGuess(1)
    
    waitbar( ii/numInitGuess(1) )
    drawnow()
    
    for jj = 1:numInitGuess(2)
        for kk = 1:numInitGuess(3)
            % Initialize Cell for Initial Guess
            Pinit{ ii , jj , kk } = [ paramInitGuess{1}(ii) , paramInitGuess{2}(jj) , paramInitGuess{3}(kk) ];
            
            % Call fmincon function with initial guess and store result in
            % Popt{ii,jj,kk}
            [Popt{ii,jj,kk}, fval{ii,jj,kk} , exitflag{ii,jj,kk} , output{ii,jj,kk} , lambda{ii,jj,kk} , grad{ii,jj,kk} , hessian{ii,jj,kk} ] = ...
                fmincon( objective , Pinit{ii,jj,kk,:} , [] , [] , [] , [] , [] , [] , stabilityLHP , options );
        end
    end
end

%%
% Process only "good" results here
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
goodResults = find( cat( 1 , exitflag{:} ) > 0) ;
zeroResults = find( cat( 1 , exitflag{:} )  == 0 ) ;
negResults = find( cat( 1 , exitflag{:} ) < 0 ) ;

% Sort Optimizied solutions according to exit flag conditions
Popt_good_results = cat( 1 , Popt{goodResults} );
Popt_zero_Results = cat( 1 , Popt{zeroResults} );
Popt_neg_Results = cat( 1 , Popt{negResults} );

% Obtain the cost of the good results
Eopt_good_results = double.empty ;
for aa = 1: size( Popt_good_results ,  1 )
    Eopt_good_results( aa , : ) = objective( Popt_good_results( aa , : ) ) ;
end

% Sort the Cost and Optimized PID parameters
sortedCost_PID = sortrows( [ Eopt_good_results(:,:) , Popt_good_results(:,:) ] ) ;
    
% Find unique values according to exit flag indices
[ Popt_uni_goodRes , ~ , ind_uni_goodRes ] = unique( round( Popt_good_results , 3 ) , 'rows' ) ;
num_uni_good = length( unique( ind_uni_goodRes ) ) ;
[ Popt_uni_zeroRes , ~ , ind_uni_zeroRes ] = unique( round( Popt_zero_Results , 3 ) , 'rows' ) ;
num_uni_zero = length( unique( ind_uni_zeroRes ) ) ;
[ Popt_uni_negRes , ~ , ind_uni_negRes ] = unique( round( Popt_neg_Results , 3 ) , 'rows' ) ;
num_uni_neg = length( unique( ind_uni_zeroRes ) ) ;

% Map out lines of unique converged solutions
cmap_good = lines( num_uni_good ) ;
cmap_zero = lines( num_uni_zero ) ;
cmap_neg = lines( num_uni_neg ) ;

% Find the median value of the sorted PID cost
medianValIndex =  round((find(sortedCost_PID(:,1)>median(sortedCost_PID(:,1)), 1 ) + find(sortedCost_PID(:,1)<median(sortedCost_PID(:,1)), 1, 'last' )) / 2);

if( isempty( medianValIndex ) == 0 && size( goodResults , 1 ) > 2 )
    col_num = medianValIndex ;
    
    [ ~ , col_bin , col_ind ] = histcounts( ...
        Eopt_good_results , ...
        linspace( sortedCost_PID(1,1) , sortedCost_PID(medianValIndex,1) ,col_num-1) ) ;
    col_ind( Eopt_good_results >= max(col_bin) ) = col_num ;
    
    % Make background of figure white
    col_map = jet( col_num ) ;
    
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
        plot3(...
            Popt_good_results(tmp,1),...
            Popt_good_results(tmp,2),...
            Popt_good_results(tmp,3),...
            'ko',...
            'MarkerFaceColor' , col_map(cc,:) );
    end
    if( isempty(Popt_zero_Results) == 0 )
        % Plot zero flag results
        plot3(...
            Popt_zero_Results(:,1),...
            Popt_zero_Results(:,2),...
            Popt_zero_Results(:,3),...
            '.',...
            'Color' , [0,0,0]+0.5);
    end
    
    if( isempty(Popt_neg_Results) == 0 )
        % Plot "Bad" Results
        plot3(...
            Popt_neg_Results(:,1),...
            Popt_neg_Results(:,2),...
            Popt_neg_Results(:,3),...
            '.',...
            'Color' , [0,0,0]+0.8);
    end
    xlabel( 'K_p' )
    ylabel( 'K_i' )
    zlabel( 'K_d' )
    
    colorbar()
end

Num_uni = double.empty ;
Ecost_uni = double.empty ;

for bb = 1: num_uni_good
    Num_uni(bb ,:) = numel( Popt_good_results( ind_uni_goodRes == bb ) );
    Ecost_uni(bb,:) = mean( Eopt_good_results( ind_uni_goodRes == bb ) );
end

sortedResults = sortrows( [ Ecost_uni ,Popt_uni_goodRes , Num_uni ] ) ;

top_5_param = 1 ;

if( num_uni_good < 5 )
    % Set max top parameters to top 5
    maxTopParam = num_uni_good + 1 ;
else
    % Set max top parameters to 6 (including unoptimized PID)
    maxTopParam = 6 ;
end

% Initialize matrix for storing unoptimized PID and top 5 (or fewer) PID
% optimized parameters along with the cost, number of unique solutions
% for the particular PID parameters, and the lambda regularization
% value that was used.
Popt_top_Param = zeros( maxTopParam , 6 ) ;
% Use 6th column of matrix for storing the lambda regularization
% constant
Popt_top_Param( 2 : end , 6 ) = lambdaReg ;

% Pre-allocate a tf variable type for computing the optimized PID
% closed loop transfer functions
sysTopCLTF = tf( zeros( [1 1 1] ) ) ;
sysTopOL = tf( zeros( [1 1 1] ) ) ;

% Initialize legend for storage
titleTxt = cell( maxTopParam ,1) ;

% Compute function cost of unoptimized PID closed loop transfer function
% Matrix [1 0 0] = Kp Ki Kd
unOptCost = objective( [1 0 0] ) - lambdaReg ;

% Compute unoptimized PID transfer function here
numOLTF = num_plant ;
denOLTF = den_plant ;
% numOLTF = num_plant .* num_lpf_sk2 ;
% denOLTF = conv( den_plant , den_lpf_sk2 ) ;
sysOLTF = tf(numOLTF,denOLTF) ;
%sysBW = tf( numBW , denBW ) ;
% sys_cl_unOpt = feedback( sysOLTF , sysBW ) ;
sys_cl_unOpt = feedback( sysOLTF , 1 ) ;

% Store unoptimized transfer function here
sysTopCLTF( : , : , top_5_param ) = sys_cl_unOpt ;

titleTxt{top_5_param} = sprintf( '(%.3f, %.3f, %.3f) : %.3f, %d' ,[1 0 0], unOptCost, 0);

% Store unoptimized PID closed loop parameters here
Popt_top_Param( top_5_param , 2:5 ) = [1 0 0 1] ;                            % Unoptimzied PID parameters ( Kp = 1 , rest set to 0 )
Popt_top_Param( top_5_param , 6 ) = 0 ;                                      % Unoptimized regularization constant = 0
Popt_top_Param( top_5_param , 1 ) = unOptCost ;                              % Unoptimized function cost


% Increase number of top parameters
top_5_param = top_5_param + 1 ;

%% Sort "Good" Results for Top 5 PID Values
% Initialize iteration
cc = 1 ;

while( top_5_param <= maxTopParam && cc < num_uni_good )
    % Obtain matrix of Open Loop Transfer Function using top 5 PID
    % Parameters
%     numOLTF = conv( conv( num_plant, den_lpf_sk2 ) , [ sortedResults(cc,4), sortedResults(cc,2), sortedResults(cc,3) ] ) ;
%     denOLTF = conv( conv( den_plant , den_lpf_sk2 ), [1 0] ) ;
    numOLTF = conv( num_plant , [ sortedResults(cc,4), sortedResults(cc,2), sortedResults(cc,3) ] ) ;
    denOLTF = conv( den_plant , [1 0] ) ;
    sysOLTF = tf( numOLTF , denOLTF ) ;
    
    % Derive closed loop transfer function
     % sysCLTF = feedback( sysOLTF , sysBW ) ;
    sysCLTF = feedback( sysOLTF , 1 ) ;
    
    % Find the poles and zeros of the closed loop transfer
    % function
    [ poles1 , zeros1 ] = pzmap( sysCLTF ) ;
    
    % Check if real parts of poles are in left half plane (i.e. negative)
    if( real(poles1) < 0 )
            % Store the current and unique PID parameters
            Popt_top_Param(top_5_param,1:5) = sortedResults(cc,:) ;
            % Title for legend(s)
            titleTxt{top_5_param} = sprintf( '(%.3f, %.3f, %.3f) : %.3f, %d' ,...
                Popt_top_Param(top_5_param,2:4) ,  Popt_top_Param(top_5_param,1), Popt_top_Param(top_5_param,5) )  ;
        
            % Store optimal transfer function (top 5/max)
            sysTopCLTF(:,:,top_5_param) = sysCLTF ;
            sysTopOL(:,:,top_5_param) = sysOLTF ;
        
            % Increase number of top parameters
            top_5_param = top_5_param + 1 ;
    end 
    cc = cc + 1 ;
    
end

%% Plot Top 5 Results and Assess Stability

% Initialize empty arrays for storing magnitude and phase
magCLTF = double.empty() ;
phaseCLTF = double.empty() ;
disc_magCLTF = double.empty() ;
disc_phaseCLTF = double.empty() ;
mag = zeros(size(radF)) ;
phase = zeros(size(radF)) ;

% Initialize empty transfer function object
disc_CL_sys5 = tf( zeros( [1 1 1] ) ) ;
disc_OL_sys5 = tf( zeros( [1 1 1] ) ) ;

% Initialize continuous to discrete options
% opt = c2dOptions('Method','tustin','PrewarpFrequency',3.4);
opt = c2dOptions('Method','tustin') ;

for ee=1 : (top_5_param - 1)
    [ mag, phase, ~ ] = bode( sysTopCLTF(:,:,ee) , radF ) ;
    magCLTF(ee,:) = mag ;                % Store magnitude of CLTF
    phaseCLTF(ee,:) = phase - phase(1) ; % Store phase of CLTF
    
    % Obtain discrete time transfer function from continuous time model
    disc_CL_sys5(ee) = c2d( sysTopCLTF(:,:,ee) , 0.01 ,opt ) ;
    [ mag, phase, freq ] = bode( disc_CL_sys5(ee) , radF ) ;
    disc_magCLTF(ee,:) = mag ;                % Store magnitude of discrete CLTF
    disc_phaseCLTF(ee,:) = phase - phase(1) ; % Store phase of discrete CLTF
    
    % Obtain discrete time transfer function from continuous time model
    disc_OL_sys5(ee) = c2d( sysTopOL(:,:,ee) , 0.01 , opt ) ;
end

% Plot Step Responses of CLTF
figure( ...
    'Color' , [1,1,1] )
subplot( 1 , 1 , 1 , ...
    'NextPlot' , 'add')
for dd = 2 : (top_5_param - 1)
    step(sysTopCLTF(:,:,dd))
end
title('Continuous Time Step Response')
legend_obj = legend(titleTxt( 2 : (top_5_param-1) ));
legend_obj_title = get(legend_obj,'title');
set(legend_obj_title,'string','(K_p, K_i, K_d) : \phi cost, #-elements');

% Plot Step Responses of discrete CLTF
figure( ...
    'Color' , [1,1,1] )
subplot( 1 , 1 , 1 , ...
    'NextPlot' , 'add')
for dd = 2 : (top_5_param - 1)
    step(disc_CL_sys5(dd))
end
title('Discrete Time Step Response')
legend_obj = legend(titleTxt( 2 : (top_5_param-1) )) ;
legend_obj_title = get(legend_obj,'title');
set(legend_obj_title,'string','(K_p, K_i, K_d) : \phi cost, #-elements') ;

% Plot step response of top CLTF in continuous time and discrete time
figure( ...
    'Color' , [1,1,1] )
step( sysTopCLTF(:,:,2) , disc_CL_sys5(2) )
title(sprintf('Step Response of:\n (P,I,D), Cost, Number of Convergences \n %s',string(titleTxt(2))))
legend('Continuous Time','Discrete Time')

% Plot Bode Plot of Continuous Closed Loop Transfer Function
figure( ...
    'Color' , [1,1,1] )
subplot(  2 , 1 , 1 , ...
    'XScale' , 'log' , ...
    'Ylim' , [1e-2 1e1],...
    'Xlim' , [fmin fmax],...
    'NextPlot' , 'add', ...
    'TickDir' , 'out' , ...
    'YScale' , 'log')
area( [ fmin , fmax] , max(ylim())+[0,0] , min(ylim()) , ...
    'FaceColor' , [0,0,0] , ...
    'FaceAlpha' , 0.02 , ...
    'EdgeColor' , 'none' )
for ff = 1 : (top_5_param - 1)
    plot(F,magCLTF(ff,:) );
end
plot( [ fmin, fmax] , [1,1] , 'k--' )
ylabel('Magnitude (Absolute)')
title('Continuous Time Bode Plot')

subplot(  2 , 1 , 2 , ...
    'NextPlot' , 'add', ...
    'TickDir' , 'out' , ...
    'Xlim' , [fmin fmax],...
    'XScale' , 'log')
for ff = 1 : (top_5_param - 1)
    plot(F,phaseCLTF(ff,:))
end
xlabel('Frequency (Hz)')
ylabel('Phase (Degrees)')
legend_obj = legend( titleTxt( 1 : (top_5_param-1) ) );
legend_obj_title = get(legend_obj,'title');% Handle response
set( legend_obj_title , 'string' , '(K_p, K_i, K_d) : \phi cost, #-elements' ) ;

% Plot Bode Plot of discrete CLTF
figure( ...
    'Color' , [1,1,1] )
subplot(  2 , 1 , 1 , ...
    'XScale' , 'log' , ...
    'Ylim' , [1e-2 1e1],...
    'Xlim' , [fmin fmax],...
    'NextPlot' , 'add', ...
    'TickDir' , 'out' , ...
    'YScale' , 'log')
area( [ fmin  , fmax ] , max(ylim())+[0,0] , min(ylim()) , ...
    'FaceColor' , [0,0,0] , ...
    'FaceAlpha' , 0.02 , ...
    'EdgeColor' , 'none' )
for ff = 1 : (top_5_param - 1)
    plot( F , disc_magCLTF(ff,:) );
end
plot( [ fmin , fmax ] , [1,1] , 'k--' )
ylabel( 'Magnitude (Absolute)' )
title('Discrete Time Bode Plot')

subplot(  2 , 1 , 2 , ...
    'NextPlot' , 'add', ...
    'TickDir' , 'out' , ...
    'Xlim' , [fmin fmax],...
    'XScale' , 'log')
for ff = 1 : (top_5_param - 1)
    plot( F , disc_phaseCLTF(ff,:) )
end
xlabel('Frequency (Hz)')
ylabel('Phase (Degrees)')
legend_obj = legend( titleTxt( 1 : (top_5_param-1) ) );
legend_obj_title = get(legend_obj,'title');% Handle response
set( legend_obj_title , 'string' , '(K_p, K_i, K_d) : \phi cost, #-elements' ) ;

% Plot pole zero map of top PID result in continuous time closed loop
figure( 'Color' , [1 1 1] )
cont_CL = iopzplot( sysTopCLTF(:,:,2) )
p = getoptions(cont_CL) ; % get options for plot
p.Title.String = sprintf('Continuous Time Closed Loop of:\n (P,I,D), Cost, Number of Convergences \n %s', string(titleTxt(2)) ) ; % change title in options
setoptions(cont_CL,p,'FreqUnits','Hz') ; % apply options to plot  

% Plot pole zero map of top PID result in continuous time open loop
figure( 'Color' , [1 1 1] )
cont_OL = iopzplot( sysTopOL(:,:,2) )
p = getoptions(cont_OL) ; % get options for plot
p.Title.String = sprintf('Continuous Time Open Loop of:\n (P,I,D), Cost, Number of Convergences \n %s', string(titleTxt(2)) ) ; % change title in options
setoptions(cont_OL,p,'FreqUnits','Hz') ; % apply options to plot  

% Plot pole zero map of top PID result in discrete time closed loop
figure( 'Color' , [1 1 1] )
disc_CL = iopzplot( disc_CL_sys5(2) )
p = getoptions(disc_CL); % get options for plot
p.Title.String = sprintf('Discrete Time Closed Loop of:\n (P,I,D), Cost, Number of Convergences \n %s', string(titleTxt(2)) ) ; % change title in options
setoptions(disc_CL,p,'FreqUnits','Hz'); % apply options to plot  

% Plot pole zero map of top PID result in discrete time open loop
figure( 'Color' , [1 1 1] )
disc_OL = iopzplot( disc_OL_sys5(2) )
p = getoptions(disc_OL); % get options for plot
p.Title.String = sprintf('Discrete Time Open Loop of:\n (P,I,D), Cost, Number of Convergences \n %s', string(titleTxt(2)) ) ; % change title in options
setoptions(disc_OL,p,'FreqUnits','Hz'); % apply options to plot 