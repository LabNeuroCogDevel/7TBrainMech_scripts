function [ output_args ] = derivate( input_args )
%DERIVATE Summary of this function goes here
%   Detailed explanation goes here
d = diff(input_args);
output_args = [d d(end)];
end

