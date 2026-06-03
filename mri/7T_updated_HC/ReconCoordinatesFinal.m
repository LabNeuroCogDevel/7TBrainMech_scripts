function [poslrp] = ReconCoordinatesFinal(posInfo)
%% Function to compute transformed coordinates dynamically

% Extract parameters from the provided info structure
vo = posInfo.vert;
ho = posInfo.horz;
angle = posInfo.angle * (pi / 180.0); % Convert degrees to radians
pos = posInfo.pos; % Extract position coordinates

% Image resolution
res = 216;

% Ensure pos has 12 coordinates
num_positions = size(pos, 1);

% Define the additional 218x218 coordinates if needed
default_pos = [218, 218];  % This is a placeholder; adjust based on your needs

% If fewer than 12 positions exist, add 218x218 until pos has 12 rows
if num_positions < 12
    num_to_add = 12 - num_positions;
    pos = [pos; repmat(default_pos, num_to_add, 1)];
end

% Create transformation matrix
rotm1 = [cos(angle), sin(angle), vo];
rotm2 = [-sin(angle), cos(angle), ho];
rotm = [rotm1; rotm2];

% Convert to MATLAB coordinate system
poslr = res + 2 - pos;

% Convert to homogeneous coordinates
thirdrow = ones(1, size(poslr, 1)); % Ensure this matches the number of rows in poslr
poslrtemp = [poslr'; thirdrow];  % Add ones as the third row, matching size

lastrow = [0 0 1];  % For 2D transformations, you can add a last row for homogeneity
rotmtemp = [rotm; lastrow];  % Rotation matrix with homogeneous coordinate row

% Apply transformation
retposlr = rotmtemp \ poslrtemp;

% Convert back to required resolution
poslrtemp = res + 2 - retposlr(1:2, :)';
poslrp = poslrtemp;
end