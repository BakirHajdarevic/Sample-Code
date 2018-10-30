%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Programmer: Bakir Hajdarevic 
% Function Name: polesLHP.m
%
% Inputs:
% - zerosVLK = the numerator co-efficients of the closed loop transfer 
%              function (CLTF)
% - polesVLK = the denominator co-efficients of the CLTF
% - x = fmincon's returned values for PID parameters
%
% Outputs:
% - c = array of the real roots of the CLTF for the inequality variable.
% This assumes that the values are less than or equal to 0.
% - cq = empty equality array
%
% Description: This function takes in the parameters of the coefficients of
% the CLTF numerator and denominator and the returned values from fmincon
% for the PID parameters. The function finds the real roots of the CLTF and
% returns them in the array c. The nonlinear function sovler fmincon will
% use these values as part of its gradient descent (optimization).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c,ceq] = polesLHP( zerosVLK , polesVLK , x )

% The numerator co-efficients of the CLTF.
zerosVLKpid = conv( zerosVLK , [ x(3) , x(1) , x(2)] , 'full' ) ;

% Add the coefficients of the numerator and denominator after padding the
% the smaller array with zeros 
if( length(zerosVLKpid) < length(polesVLK) )
    coefs = padarray( zerosVLKpid , ( size( polesVLK ) - size( zerosVLKpid ) ) , 'pre' ) + polesVLK ;
else
    coefs = padarray( polesVLK , ( size( zerosVLKpid) - size( polesVLK ) ) , 'pre' ) + zerosVLKpid ;
end

% Return the real part of the roots of the CLTF to fmincon. The array c 
% is used as the inequality of =< 0. 
c = real( roots( coefs ) ) ;
% Empty equality array
ceq = [] ;
end