function x = fix_status_channel(x)
%FIX_STATUS_CHANNEL make status channel report values we expect
%   readjust by min of timseries, replace extrm vals w/0
 x = x - min(x);
 x(x>65000) = 0;
end

