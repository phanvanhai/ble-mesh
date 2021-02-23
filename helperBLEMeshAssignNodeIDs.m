function helperBLEMeshAssignNodeIDs(modelName)
%helperBLEMeshAssignNodeIDs Assign unique IDs to each node subsystem
% 
%   helperBLEMeshAssignNodeIDs(MODELNAME) assigns the node IDs dynamically
%   at the start of the simulation to all the nodes in the given MODELNAME.
% 
%   MODELNAME is a simulink model name

%   Copyright 2019 The MathWorks, Inc.

% Get names of nodes present in the model
data = helperBLEMeshGetNodeNamesList(modelName);
% Iterate over all nodes in the model and assign unique node id to it.
for i = 1:length(data)
%     set_param(data{i}, 'NodeID', num2str(i));
    % Edit: them khoi ben duoi
    blockPath = strsplit(data{i}, '/');
    id = regexp(blockPath{2}, '\d+', 'match');
    set_param(data{i}, 'NodeID', id{1});
    set_param([data{i} '/AppDES'], 'NodeID', id{1});
end
end
