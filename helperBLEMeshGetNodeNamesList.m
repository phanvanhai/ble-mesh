function nodeNamesList = helperBLEMeshGetNodeNamesList(modelName)
%helperBLEMeshGetNodeNamesList Get the list of node names in the model
% 
%   NODENAMESLIST = helperBLEMeshGetNodeNamesList(MODELNAME) returns a cell
%   array, where each element consists of a complete path to a node
%   configured by the user. The size of the cell array is the same as the
%   number of nodes configured by the user in the given MODELNAME.
% 
%   MODELNAME is a simulink model name.

%   Copyright 2019 The MathWorks, Inc.

% Loop over each block name in the model and checks whether it is a node
% subsystem or not
nodeNamesList = cell(1, 0);

% Edit: them khoi ben duoi
NumberOfNodes = evalin('base', 'NumberOfNodes');
for i = 1:NumberOfNodes
    nodeNamesList{i} = char(sprintf("%s/Node%d",modelName, i));
end
% Edit: comment ben duoi
% for i = 1:length(data)
%     % Extract the initial part of block path.
%     blockPath = strsplit(data{i}, '/');
%     % Check whether that block is from model or a library.
%     if (strcmp(blockPath{1}, modelName)) && (numel(blockPath) == 2)
%         try            
%             % If that block is from model, check whether it has nodeId
%             % property or not.
%             get_param(data{i}, 'NodeID');
%             nodeNamesList{count} = data{i};
%             count = count + 1;            
%         catch
%         end
%     end
% end
