function helperBLEMeshCreateNetworkModel(modelname, numberOfNodes, srcDstPairs, relayNodeIds)
%helperBLEMeshCreateNetworkModel Create a Bluetooth mesh network with given
%number of nodes, and assign the specified configuration
%
%   helperBLEMeshCreateNetwork(MODELNAME, NUMBEROFNODES, SRCDSTPAIRS,
%   RELAYNODEIDS) creates a Bluetooth mesh network with specified number of
%   nodes. Configure the relay nodes and source-destination pairs as
%   specified.
%
%   MODELNAME specifies the name of the new network model.
%
%   NUMBEROFNODES specifies the number of nodes.
%
%   SRCDSTPAIRS is an n-by-2 array contains source and destination node
%   identifiers.
%
%   RELAYNODEIDS is a vector contains relay node identifiers.

%   Copyright 2019-2020 The MathWorks, Inc.

% Simulation time
simTime = '5';

% % Initialize destinations for all the nodes
% destinationNodes = zeros(1, numberOfNodes);
% % Set destination nodes at each source based on specified srcDstPairs. Here
% % in destinationNodes vector index indicates source node ID and value
% % indicates destination node ID
% for idx = 1:numel(srcDstPairs)/3    % Edit: /2 -> /3
%     destinationNodes(srcDstPairs(idx, 1)) = srcDstPairs(idx, 2);
% end

% Initialize relay feature for all the nodes
relayNodes = zeros(1, numberOfNodes);
% Set relay features based on specified relayNodeIds
for idx = 1:numel(relayNodeIds)
  relayNodes(relayNodeIds(idx)) = 1;
end

% To create a new model, copy the example model to retain the model
% initialization settings
exampleModelName = 'BLEMeshDiscreteEventSimulationModel';
% Model name cannot be the example model name
if strcmp(modelname, exampleModelName)
    error('Unable to create model. Model name and example model name must be different.');
end

if exist(modelname, 'file') ~= 4
    success = copyfile([exampleModelName '.slx'], [modelname '.slx']);
    if ~success
        error('Unable to create requested model because copying the example model failed.');
    end
else
    fprintf(['Unable to create new Simulink model because a model already exists with the name ' ...
        modelname '.slx. Updating ' modelname '.slx with the given configuration.\n']);
end

% Load new model
load_system(modelname);
% Open system
open_system(modelname);
% Clear contents in new model
Simulink.BlockDiagram.deleteContents(modelname);
% Node subsystem block path used in example for creating the network
exampleBlockPath = [exampleModelName '/Node1'];
% New model node path
newBlockPath = [modelname '/Node1'];
% Copy a node subsystem from the example model
add_block(exampleBlockPath, newBlockPath, 'MakeNameUnique', 'on');
% Number of blocks in a row
if numberOfNodes < 60
    noOfBlksInRow = 10;
else
    noOfBlksInRow = 20;
end
% Offset between 2 blocks
widthoffset = 60;
heightoffset = 80;
% Get current position of a given block
currentPos = get_param(newBlockPath, 'Position');
% Get height from current position
height = currentPos(4)-currentPos(2);
% Get width from current position
width = currentPos(3)-currentPos(1);
% Number of utility blocks
numUtilBlks = 3;
% Utils position
utilityBlksPos = zeros(numUtilBlks, 4);
assignin('base', 'NumberOfNodes', numberOfNodes);
% Create total number of nodes
for idx = 1:(numberOfNodes+numUtilBlks-1)
    % Calculate X and Y positions for a new block
    x = currentPos(1) + widthoffset*(mod(idx, noOfBlksInRow));
    y = currentPos(2) + heightoffset*(floor((idx)/noOfBlksInRow));
    % Position of a new block
    position = [x y x+width y+height];
    if idx <= numberOfNodes-1
        % Add given block to the given block with unique names and positions
        add_block(newBlockPath, newBlockPath, 'MakeNameUnique', 'on', 'Position', position);
    else
        utilityBlksPos(idx-(numberOfNodes-1), :) = position;
    end
end

% Add the node position allocator, node information, and visualizer blocks
% required for the model configuration
add_block([exampleModelName '/NodeInfo'], [modelname '/NodeInfo'], 'Position', utilityBlksPos(1, :));
add_block([exampleModelName '/NPA'], [modelname '/NPA'], 'Position', utilityBlksPos(2, :));
add_block([exampleModelName '/Visualizer'], [modelname '/Visualizer'], 'Position', utilityBlksPos(3, :));

% Configure at all nodes
for idx = 1:numberOfNodes
    % Get node path
    nodePath = [modelname '/Node' num2str(idx)];
    
    set_param([nodePath '/AppDES'], 'ApplicationState', num2str(0));
%     % Configure destination node at source node
%     if destinationNodes(idx)
%         % Edit: them doan duoi
%         set_param([nodePath '/AppDES'], 'ApplicationState', num2str(1));
%         set_param([nodePath '/AppDES'], 'DestinationNode', num2str(destinationNodes(idx)));
%     else
%         % Edit: them doan duoi
%         set_param([nodePath '/AppDES'], 'ApplicationState', num2str(0));
%     end
    
    % Configure relay nodes
    if relayNodes(idx)
        set_param([nodePath '/Network layer'], 'Relay', 'On ');
    else
        set_param([nodePath '/Network layer'], 'Relay', 'Off');
    end
end

% Set simulation time
set_param(modelname, 'StopTime', simTime);
% Save system
save_system(modelname);
% Close system
close_system(modelname);
end
