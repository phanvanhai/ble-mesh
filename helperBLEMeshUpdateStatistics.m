function helperBLEMeshUpdateStatistics(opcode, nodeid, layer, statisticsValues)
%helperBLEMeshUpdateStatistics Create and update statistics in a Bluetooth
%mesh network simulation
%
%   helperBLEMeshUpdateStatistics(OPCODE) create statistics table for a
%   Bluetooth mesh network.
%
%   OPCODE specifies operation to be performed. Opcode value '0' indicates
%   creating the statistics table, value '1' indicates updating the
%   statistics table.
%    
%   helperBLEMeshUpdateStatistics(OPCODE, NODEID, LAYER, STATISTICSVALUES)
%   updates statistics in the created table for a Bluetooth mesh network.
%
%   NODEID indicates unique node identifier.
%
%   LAYER indicates layer to which the specified statistics belong.
%
%   STATISTICSVALUES is an vector contains statistics for specified layer.

%   Copyright 2019 The MathWorks, Inc.

% Check for number of arguments
narginchk(1, 4);

% Create statistics table
if opcode == 0
    % Get model name and number of nodes from base workspace
    ModelName = evalin('base', 'ModelName');
    NumberOfNodes = evalin('base', 'NumberOfNodes');
    % Create statistics table
    variableNames = {...
        'NodeType'; 'PHYTransmittedSignals'; 'PHYTransmittedBits'; 'PHYReceivedSignals'; 'PHYReceivedBits'; ...
        'TotalCollisions'; 'TwoSignalsCollision'; 'ThreeSignalsCollision'; 'FourSignalsCollision'; ...
        'LinkLayerTransmittedMsgs'; 'LinkLayerReceivedMsgs'; ...
        'CRCFailedMsgs'; 'LinkLayerTransmittedBytes'; 'LinkLayerReceivedBytes'; ...
        'NetworkLayerTransmittedMsgs'; 'NetworkLayerReceivedMsgs'; ...
        'ReceivedApplicationMsgs'; 'NetworkLayerRelayedMsgs'; 'NetworkLayerDroppedMsgs'; ...
        };
    % Statistics data types
    variableTypes = {...
        'string'; 'double'; 'double'; 'double'; 'double'; ...
        'double'; 'double'; 'double'; 'double'; 'double'; ...
        'double'; 'double'; 'double'; 'double'; 'double'; ...
        'double'; 'double'; 'double'; 'double'};
    % Get the node names in the model
    nodeNamesList = helperBLEMeshGetNodeNamesList(ModelName);
    NodeNames = cell(NumberOfNodes, 1);
    for i = 1:NumberOfNodes
        NodeNames{i} = strrep(nodeNamesList{i}, [ModelName '/'], '');        
    end
    statisticsAtEachNode = table('Size', [NumberOfNodes numel(variableNames)], ...
        'RowNames', NodeNames, 'VariableNames', variableNames, ...
        'VariableTypes', variableTypes);
    % Create the statistics table in base workspace
    assignin('base', 'statisticsAtEachNode', statisticsAtEachNode);
    
% Update statistics table
elseif opcode == 1
    % Get statistics table from base workspace
    statistics = evalin('base', 'statisticsAtEachNode');
    % Update table as specified by layer and corresponding statistics
    switch layer
        case 'PHYTx'
            statistics{nodeid, 2:3} = statisticsValues;
        case 'PHYRx'
            statistics{nodeid, 4:9} = statisticsValues;
        case 'LinkLayer'
            statistics{nodeid, 10:14} = statisticsValues;
        case 'NetworkLayer'
            if statisticsValues(1)
                nodeType = "Relay";
            else
                nodeType = "End";
            end
            statistics{nodeid, 1} = nodeType;
            statistics{nodeid, 15:19} = statisticsValues(2:end);
    end
    % Reassign the updated table to base workspace
    assignin('base', 'statisticsAtEachNode', statistics);
end
end
