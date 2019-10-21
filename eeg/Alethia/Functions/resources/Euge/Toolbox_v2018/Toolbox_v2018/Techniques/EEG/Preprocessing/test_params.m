function [ input ] = test_params( number, param2, param3, input )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
number = str2double(number);
disp(number)
disp(param2)
disp(param3)
input = input.*number;
end

