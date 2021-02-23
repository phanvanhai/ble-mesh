function vicinityNodeIDs = helperBLEMeshVicinityNodes(nodeID, positions, vicinityRange)
%helperBLEMeshVicinityNodes Helper to get vicinity nodes of a given node
%   VICINITYNODEIDS = helperBLEMeshVicinityNodes(NODEID, POSITIONS,
%   VICINITYRANGE) returns vicinity node IDs of a given node.
%
%   VICINITYNODEIDS is a vector of node IDs which are in the range of given
%   node.
%
%   NODEID is an integer.
%
%   POSITIONS is an array of all node positions in the network.
%
%   VICINITYRANGE is an integer which indicates the transmission and
%   reception range of the node.

%   Copyright 2019 The MathWorks, Inc.

% Validate node ID
validateattributes(nodeID, {'numeric'}, {'scalar', ...
            'integer', '>=', 1, '<=', length(positions)}, mfilename, 'nodeID');
        
% Validate positions
validateattributes(positions, {'numeric'}, {'2d', 'ncols', 2}, mfilename, 'Positions')
        
% Validate vicinity range
validateattributes(vicinityRange, {'numeric'}, {'scalar', ...
            'integer', '>=', 1}, mfilename, 'VicinityRange');
        
% Source node position
sourceNodePos = [positions(nodeID, 1), positions(nodeID, 2)];

% Distance between source node and remaining nodes in the network
distance = sqrt(((positions(:, 1)-sourceNodePos(1)).^2) + (positions(:, 2)-sourceNodePos(2)).^2);

% Get vicinity nodes based on vicinity range
vicinityNodeIDs = find(distance <= vicinityRange);
vicinityNodeIDs(vicinityNodeIDs == nodeID) = [];
end
