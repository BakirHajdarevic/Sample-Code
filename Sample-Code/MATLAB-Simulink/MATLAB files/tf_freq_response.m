function freq_response = tf_freq_response( num_funct , den_funct , rad_freq )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Programmer: Bakir Hajdarevic
% Program: tf_freq_response.m
% Date: 1/1/2018
% Description: This function evaluates a transfer function's handles,
% specifically the numerator and denominator coefficients separately. This
% function returns the overall frequency response as a vector in the return
% variable freq_response.
% 
% Input Variables:
%   + num_funct : annonymous function handle of a transfer function's
%   numerator coefficients.
%   + den_funct : same as num_funct except it is the denominator.
%   + rad_freq : frequency in radians used to evaluate the function
%   handles.
%
% Output Variables:
%   + freq_response : the frequency response of the transfer function given
%   input radial frequency of the variable rad_freq.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize storage values for the numerator & denominator frequency
% responses
num_resp = 0 ;
den_resp = 0 ;

% Obtain the numerator's frequency response
for ii = 1 : length( num_funct )
    num_resp = num_funct{ii}(rad_freq) + num_resp ;
end

% Obtain the denominator's frequency response
for ii = 1 : length( den_funct )
    den_resp = num_funct{ii}(rad_freq) + den_resp ;
end

% Calculate the overall frequency response for each frequency
freq_response = num_resp ./ den_resp ;

return