classdef helperBLEMeshVisualizeNetwork < handle
%helperBLEMeshVisualizeNetwork Creates an object for Bluetooth mesh network
%visualization
%   MESHNETWORK = helperBLEMeshVisualizeNetwork creates a Bluetooth mesh
%   network visualization object with properties and methods related to
%   visualization.
%
%   MESHNETWORK = helperBLEMeshVisualizeNetwork(Name, Value) creates a
%   network visualization object with the specified property Name set to
%   the specified Value. You can specify additional name-value pair
%   arguments in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   helperBLEMeshVisualizeNetwork properties:
%
%   NumberOfNodes      - Number of nodes in the network
%   VicinityRange      - Node transmission and reception range
%   NodeState          - State of each node
%   Positions          - List of all node positions
%   NodePositionType   - Type of node position allocation
%   GridInitX          - X coordinate where the grid starts
%   GridInitY          - Y coordinate where the grid starts
%   GridDeltaX         - X space between nodes
%   GridDeltaY         - Y space between nodes
%   GridWidth          - Number of nodes laid out on a line
%   GridLayout         - Type of layout
%   Title              - Title of the network plot
%   SrcDstPairs        - Source destination pairs
%   FriendPairs        - Friend and Low Power node pairs
%   SimulationTime     - Simulation time
%   DisplayProgressBar - Display progress bar

%   Copyright 2019-2020 The MathWorks, Inc.
    
properties
    %NumberOfNodes Number of nodes in the network
    %   Specify number of nodes as an integer. Identifies the total number
    %   of nodes in the network. The default value is 30.
    NumberOfNodes = 30
    
    %VicinityRange Node transmission and reception range
    %   Specify vicinity range as an integer. Identifies the transmission
    %   and reception range of a node. The default value is 15.
    VicinityRange = 7
    
    %NodeState State of each node
    %   Specify node state as a vector of size total number of nodes with 
    %   the following values:
    %   0 - Node off
    %   1 - Node on
    %   2 - Relay on
    %   3 - Friend feature on
    %   4 - Low Power feature on
    %   The default value for all nodes is 1.
    NodeState = ones(1, 30)
    
    %Positions List of all node positions
    %   Specify positions as an array of size (NumberOfNodes, 2) where each
    %   row indicates x, y coordinates of the node.
    Positions
    
    %NodePositionType Type of node position allocation
    %   Specify node position type as one of the 'Grid' | 'UserInput'. The
    %   default value is 'Grid'.
    NodePositionType = 'Grid'
    
    %GridInitX X coordinate where the grid starts
    %   Specify grid initial x as an integer. Identifies x position of the
    %   first node in the grid. The default value is 5.
    GridInitX = 5
    
    %GridInitY Y coordinate where the grid starts.
    %   Specify grid initial y as an integer. Identifies y position of the
    %   first node in the grid. The default value is 5.
    GridInitY = 5
    
    %GridDeltaX X space between nodes
    %   Specify grid delta x as an integer. Identifies distance between x
    %   coordinates of the consecutive nodes. The default value is 10.
    GridDeltaX = 10
    
    %GridDeltaY Y space between nodes
    %   Specify grid delta y as an integer. Identifies distance between y
    %   coordinates of the consecutive nodes. The default value is 10.
    GridDeltaY = 10
    
    %GridWidth Number of nodes laid out on a line
    %   Specify grid width as an integer. Identifies the width of the grid
    %   if row based or height of the grid if column based. The default
    %   value is 5.
    GridWidth = 5
    
    %GridLayout Type of layout
    %   Specify grid layout as one of the 'Row' | 'Column'. Identifies row
    %   or column based grid. The default value is 'Row'.
    GridLayout = 'Row'
    
    %Title Title of the network plot
    %   Specify the title as a char array or string. The default value is
    %   'Network Visualization'.
    Title = 'Network Visualization'
	
	%SrcDstPairs Source destination pairs
    %   Specify source-destination pairs as a numeric matrix having each
    %   row corresponding to a source-destination pair.
    SrcDstPairs
    
    %FriendPairs Friend and Low Power node pairs
    %   Specify friend pairs as a vector of two elements or a numeric
    %   matrix having each row corresponding to a friend and Low Power node
    %   pair.
    FriendPairs
    
    %SimulationTime Simulation time
    %   Specify the simulation time as an integer indicating the simulation
    %   time in milliseconds. The default value is 0.
    SimulationTime = 0
    
    %DisplayProgressBar Display progress bar
    %   Specify this property as a scalar logical. A true value indicates
    %   that the progress bar display is enabled for this node. The default
    %   value is true.
    DisplayProgressBar (1, 1) logical = true
end

properties(Constant, Hidden)
    %NodePositionTypeValues Two types of position allocations grid and user
    %input
    NodePositionTypeValues = {'Grid', 'UserInput'}
    
    %GridLayoutValues Row based or column based grid allocation
    GridLayoutValues = {'Row', 'Column'}
    
    % Edit: so luong cap src-dst maximum = size(Colors) + 1
    %Colors Colors of different paths
    Colors = [0, 0.5, 0; ... % Green
        0, 0.75, 0.75; ... % Teal
        0.4941, 0.1843, 0.5569; ...  
        1 0.4 0.6] % Purple
end

properties(Access = private)
    %pFigureObj Figure object
    pFigureObj
    
    %pPlotObj Graph plot object
    pPlotObj
    
    %pXMax Maximum x value including offset
    pXMax = 100
    
    %pYMax Maximum y value including offset
    pYMax = 100
    
    %pXMin Minimum x value including offset
    pXMin = 0
    
    %pYMin Minimum y value including offset
    pYMin = 0
    
    %pSrcDstPairs Source and destination pairs
    pSrcDstPairs
    
    %pPaths Highlighted paths
    pPaths
    
    %pPathCount Highlighted paths count
    pPathCount = 0
    
    %pTransmissionIDs Transmission IDs
    pTransmissionIDs = [-1 -1 -1]
    
    %pGraph digraph object
    pGraph
    
    %pProgressInfo Progress bar information
    pProgressInfo
    
    %pPercentageInfo Progress bar percentage
    pPercentageInfo
end

properties(Constant, Hidden)
    %ErrorPacketID Transmission ID of the corrupted packet
    ErrorPacketID = -1
    
    % Progress bar dimensions
    ProgressX = 0.85;
    ProgressY = 0.025;
    ProgressH = 0.02;
    ProgressW = 0.08;

    % Progress bar colors
    ProgressBarBackgroundColor = [0.9412, 0.9412, 0.9412];
    ProgressBarColor = [0.0235, 0.7412, 0.2510];
end
 
methods
    function obj = helperBLEMeshVisualizeNetwork(varargin)
        % Assign name-value pairs
        for idx = 1:2:nargin
            obj.(varargin{idx}) = varargin{idx+1};
        end
    end
    
    % Set number of nodes
    function set.NumberOfNodes(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 2, '<=', 1024}, mfilename, 'NumberOfNodes');
        obj.NumberOfNodes = value;
    end
    
    % Set vicinity range
    function set.VicinityRange(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 1, '<=', 500}, mfilename, 'VicinityRange');
        obj.VicinityRange = value;
    end
    
    % Set node state
    function set.NodeState(obj, value)
        validateNodeState(obj, value);
        obj.NodeState = value;
    end
    
    % Set node positions
    function set.Positions(obj, value)
        validatePositions(obj, value);
        obj.Positions = value;
    end
    
    % Set type of node position allocation
    function set.NodePositionType(obj, value)
        value = validatestring(value, obj.NodePositionTypeValues, ...
            mfilename, 'NodePositionType');
        obj.NodePositionType = value;
    end
    
    % Set grid layout
    function set.GridLayout(obj, value)
        validatestring(value, obj.GridLayoutValues, mfilename, 'GridLayout');
        obj.GridLayout = value;
    end
    
    % Set grid initial x value
    function set.GridInitX(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer'}, mfilename, 'GridInitX');
        obj.GridInitX = value;
    end
    
    % Set grid initial y value
    function set.GridInitY(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer'}, mfilename, 'GridInitY');
        obj.GridInitY = value;
    end
    
    % Set grid delta x value
    function set.GridDeltaX(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', 'positive'}, mfilename, 'GridDeltaX');
        obj.GridDeltaX = value;
    end
    
    % Set grid delta y value
    function set.GridDeltaY(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', 'positive'}, mfilename, 'GridDeltaY');
        obj.GridDeltaY = value;
    end
    
    % Set grid width
    function set.GridWidth(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', 'positive'}, mfilename, 'GridWidth');
        obj.GridWidth = value;
    end
    
    % Set Title
    function set.Title(obj, value)
        validateattributes(value, {'string', 'char'}, ...
            {}, mfilename, 'Title');
        obj.Title = value;
    end
    
	% Set SrcDstPairs
    function set.SrcDstPairs(obj, value)
        validateSrcDstPairs(obj, value);
        obj.SrcDstPairs = value;
    end
    
    % Set FriendPairs
    function set.FriendPairs(obj, value)
        validateFriendPairs(obj, value);
        obj.FriendPairs = value;
    end
end

methods
    % Create mesh network with given number of nodes
    function createNetwork(obj)
        % Grid position allocation
        if (obj.NodePositionType == "Grid")
            obj.Positions = obj.gridPositionAllocator();
        else
            if isempty(obj.Positions)
                fprintf('Positions must be given for node position allocation of type ''UserInput''\n');
            end
        end
        
        % Check for network creation
        if isempty(obj.pFigureObj)
            % Get screen resolution and adjust the figure accordingly
            resolution = get(0, 'screensize');
            screenWidth = resolution(3);
            screenHeight = resolution(4);
            figureWidth = screenWidth*0.8;
            figureHeight = screenHeight*0.8;
            
            % Create figure object
            obj.pFigureObj = figure('Name', obj.Title, 'Tag', 'VisualizeNetwork', ...
                'Position', [screenWidth*0.1, screenHeight*0.1, figureWidth, figureHeight], ...
                'NumberTitle', 'off', 'Units', 'Normalized', 'Tag', 'Mesh Network');
        end
        
        % Create graph
        obj.plotNetwork();
    end
    
    % Highlight relay transmission based on inputs
    function messageTransmissions(obj, relays)
        % Check for network creation
        if isempty(obj.pFigureObj)
            fprintf('createNetwork() must be called first.\n');
            return;
        elseif (~isvalid(obj.pFigureObj))
            return;
        end
        
        relayCount = size(relays, 1);
        % Highlight the transmitting node
        for relayIdx = 1 : relayCount
            % Highlight corrupted packets
            if (relays(relayIdx, 3) == obj.ErrorPacketID)
                highlight(obj.pPlotObj, relays(relayIdx, 1), 'MarkerSize', 10);
                highlight(obj.pPlotObj, relays(relayIdx, 2), 'MarkerSize', 10);
                if edgecount(obj.pGraph, relays(relayIdx, 1), relays(relayIdx, 2))
                    highlight(obj.pPlotObj, relays(relayIdx, 1:2), 'LineStyle', ...
                        '-', 'LineWidth', 5, 'EdgeColor', '#D95319');
                else
                    highlight(obj.pPlotObj, fliplr(relays(relayIdx, 1:2)), 'LineStyle', ...
                        '-', 'LineWidth', 5, 'EdgeColor', '#D95319');
                end
            % Highlight Friendship transmissions
            elseif ~isempty(obj.FriendPairs) && any(ismember(obj.FriendPairs, [relays(relayIdx, 1), ...
                    relays(relayIdx, 2)], 'rows')) && ...
                    ~any(ismember(obj.pTransmissionIDs, relays(relayIdx, 3)))			
                highlight(obj.pPlotObj, relays(relayIdx, 1:2), 'LineStyle', ...
                    '-', 'LineWidth', 5, 'ArrowSize', 12);
            elseif ~isempty(obj.FriendPairs) && any(ismember(obj.FriendPairs, [relays(relayIdx, 2), ...
                    relays(relayIdx, 1)], 'rows')) && ...
                    ~any(ismember(obj.pTransmissionIDs, relays(relayIdx, 3)))
                highlight(obj.pPlotObj, relays(relayIdx, 1:2), 'LineStyle', ...
                    '-', 'LineWidth', 5, 'ArrowSize', 12);
            % Highlight normal transmissions
            elseif relays(relayIdx, 3)
                if ~isempty(obj.pSrcDstPairs)
                    % New transmission ID
                    if ~ismember(relays(relayIdx, 3), obj.pTransmissionIDs)
                        pairIdx = find(ismember(obj.pSrcDstPairs(:, 1), relays(relayIdx, 1)));
                        if ~isempty(pairIdx)
                            for pairIndex = 1 : length(pairIdx)
                                if obj.pTransmissionIDs(pairIdx(pairIndex)) == -1
                                    obj.pTransmissionIDs(pairIdx(pairIndex)) = relays(relayIdx, 3);
                                    % Highlight new transmission ID
                                    color = obj.Colors(pairIdx(pairIndex), :);
                                    if obj.NodeState(relays(relayIdx, 2)) % Node off check
                                        highlight(obj.pPlotObj, relays(relayIdx, 2), 'MarkerSize', 10);
                                        if edgecount(obj.pGraph, relays(relayIdx, 1), relays(relayIdx, 2))
                                            highlight(obj.pPlotObj, relays(relayIdx, 1:2), 'LineStyle', ...
                                                '-', 'LineWidth', 5, 'EdgeColor', color);
                                        else
                                            highlight(obj.pPlotObj, fliplr(relays(relayIdx, 1:2)), 'LineStyle', ...
                                                '-', 'LineWidth', 5, 'EdgeColor', color);
                                        end
                                    end
                                    break;
                                end
                            end
                        else
                            continue;
                        end
                    % Highlight for an existing transmission ID
                    else
                        colorIdx = ismember(obj.pTransmissionIDs, relays(relayIdx, 3));
                        color = obj.Colors(colorIdx, :);
                        if obj.NodeState(relays(relayIdx, 2)) % Node off check
                            highlight(obj.pPlotObj, relays(relayIdx, 1), 'MarkerSize', 10);
                            highlight(obj.pPlotObj, relays(relayIdx, 2), 'MarkerSize', 10);
                            if edgecount(obj.pGraph, relays(relayIdx, 1), relays(relayIdx, 2))
                                highlight(obj.pPlotObj, relays(relayIdx, 1:2), 'LineStyle', ...
                                    '-', 'LineWidth', 5, 'EdgeColor', color);
                            else
                                highlight(obj.pPlotObj, fliplr(relays(relayIdx, 1:2)), 'LineStyle', ...
                                    '-', 'LineWidth', 5, 'EdgeColor', color);
                            end
                        end
                    end
                end
            end
        end
                
        % Normalize the current transmission
        pause(0.3);
        
        % Check for empty figure handle
        if (~isvalid(obj.pFigureObj))
            return;
        end
        
        for relayIdx = 1 : relayCount
            % Normalize the source node
            if ~ismember(relays(relayIdx, 1), obj.pSrcDstPairs) && ...
                    ~ismember(relays(relayIdx, 1), obj.FriendPairs)
                highlight(obj.pPlotObj, relays(relayIdx, 1), 'MarkerSize', 6);
            end
            
            % Normalize the destination node
            if (~ismember(relays(relayIdx, 2), obj.pSrcDstPairs)) && ...
                    (~ismember(relays(relayIdx, 2), obj.FriendPairs))
                highlight(obj.pPlotObj, relays(relayIdx, 2), 'MarkerSize', 6);
            end
                
            % Normalize friend transmissions
            if ~isempty(obj.FriendPairs) && ...
                    (any(ismember(obj.FriendPairs, [relays(relayIdx, 1), relays(relayIdx, 2)], 'rows')) || ...
                    any(ismember(fliplr(obj.FriendPairs), [relays(relayIdx, 1), relays(relayIdx, 2)], 'rows')))					
                highlight(obj.pPlotObj, relays(relayIdx, 1:2), 'LineStyle', ...
                    '-.', 'LineWidth', 1, 'EdgeColor', [0.2627, 0.2471, 0.2510], 'ArrowSize', 8);
            else               
                % Normalize the transmission based on the path already
                % shown
                pathFlag = 0;
                if ~isempty(obj.pPaths)
                    for pathIdx = 1:size(obj.pPaths, 1)
                        % Check if edge is member of path
                        if diff(find(ismember(obj.pPaths(pathIdx, :), relays(relayIdx, 1:2)))) == 1
                            path = nonzeros(obj.pPaths(pathIdx, :));
                            
                            % Get index based on source-destination pair
                            pairIndx = 0;
                            pairIdxs = find(ismember(obj.pSrcDstPairs, path(1))); % Compare with source
                            for pairIndex = 1:length(pairIdxs)
                                % Compare with destination
                                if any(ismember(obj.pSrcDstPairs(pairIdxs(pairIndex), :), path(end)))
                                    pairIndx = pairIdxs(pairIndex);
                                    break;
                                end
                            end
                            % Get pair index if Friend node is the
                            % destination node
                            if ~isempty(obj.FriendPairs) && ~pairIndx
                                frndIdx = find(obj.FriendPairs(:, 1) == path(end), 1);
                                if ~isempty(frndIdx)
                                    if any(ismember(obj.pSrcDstPairs(pairIdxs, :), obj.FriendPairs(frndIdx, 2)))
                                        pairIndx = pairIdxs;
                                    end
                                end
                            end
                            % Highlight the given path
                            for elementIdx = 1:numel(path)-1
                                if edgecount(obj.pGraph, path(elementIdx), path(elementIdx+1))
                                    highlight(obj.pPlotObj, path(elementIdx:elementIdx+1), 'EdgeColor', ...
                                        obj.Colors(pairIndx, :), 'LineWidth', 5);
                                else
                                    highlight(obj.pPlotObj, [path(elementIdx+1), path(elementIdx)], 'EdgeColor', ...
                                        obj.Colors(pairIndx, :), 'LineWidth', 5);
                                end
                            end
                            pathFlag = 1;
                        end
                    end
                end
                % Edge is not member of any shown path
                if ~pathFlag
                    if edgecount(obj.pGraph, relays(relayIdx, 1), relays(relayIdx, 2))
                        highlight(obj.pPlotObj, relays(relayIdx, 1:2), 'LineStyle', ...
                            '-', 'LineWidth', 1, 'EdgeColor', [0 0 0]);
                    else
                        highlight(obj.pPlotObj, fliplr(relays(relayIdx, 1:2)), 'LineStyle', ...
                            '-', 'LineWidth', 1, 'EdgeColor', [0 0 0]);
                    end
                end
            end
        end
    end
    
    % Show path from source to destination
    function showPath(obj, path)
        % Check for network creation
        if isempty(obj.pFigureObj)
            fprintf('createNetwork() must be called first.\n');
            return;
        elseif (~isvalid(obj.pFigureObj))
            return;
        elseif (obj.pPathCount >= 3)
            return;
        end
        
        % Validate path
        validateattributes(path, {'numeric'}, {'vector', '>=', 1, ...
            '<=', obj.NumberOfNodes}, 'showPath');
        
        % Node off check, to identify off nodes in the path
        if (sum(~obj.NodeState(path)))
            fprintf('All nodes in the path must be on\n');
            return;
        end
        
        % Get index based on source-destination pair
        pairIndx = 0;
        pathStr = blanks(0);
        pairIdxs = find(ismember(obj.pSrcDstPairs, path(1))); % Compare with source
        for idx = 1:length(pairIdxs)
            % Compare with destination
            if any(ismember(obj.pSrcDstPairs(pairIdxs(idx), :), path(end)))
                pairIndx = pairIdxs(idx);
                pathStr = 'Path from Source to Destination (';
                break;
            end
        end
        % Get pair index when path having Friend node as the destination
        if ~isempty(obj.FriendPairs) && ~pairIndx
            frndIdx = find(obj.FriendPairs(:, 1) == path(end), 1);
            if ~isempty(frndIdx)
                if any(ismember(obj.pSrcDstPairs(pairIdxs, :), obj.FriendPairs(frndIdx, 2)))
                    pairIndx = pairIdxs;
                    pathStr = 'Path from Source to Friend (';
                else
                    return;
                end
            else
                return;
            end
        end
        
        % Highlight the given path
        if pairIndx
            for idx = 1:numel(path)-1
                if edgecount(obj.pGraph, path(idx), path(idx+1))
                    highlight(obj.pPlotObj, path(idx:idx+1), 'EdgeColor', ...
                        obj.Colors(pairIndx, :), 'LineWidth', 5);
                else
                    highlight(obj.pPlotObj, [path(idx+1), path(idx)], 'EdgeColor', ...
                        obj.Colors(pairIndx, :), 'LineWidth', 5);
                end
            end
        else
            return;
        end
        
        % Store paths
        for i = 1 : length(path)
            obj.pPaths(obj.pPathCount+1, i) = path(i);
        end
        
        % Display path when destination reached
        minPos = min(obj.Positions);
        switch obj.pPathCount + 1
            case 1
                posFactor = 0.25;
                tag = 'Path1';
            case 2
                posFactor = 0.45;
                tag = 'Path2';
            case 3
                posFactor = 0.65;
                tag = 'Path3';
            otherwise
                fprintf('Maximum of 3 paths can be displayed in the plot.\n');
                return;
        end
        text(obj.pFigureObj.CurrentAxes,  obj.pXMax/15, ...
            minPos(2)-((abs(minPos(2))+abs(obj.pYMin))*posFactor), ...
            {[pathStr num2str(path(1)) ', ' num2str(path(end)) '): ' replace(num2str(path), '  ', ', ')]}, ...
            'color', obj.Colors(pairIndx, :), 'Tag', tag, ...
            'FontSize', 12, 'Clipping', 'on', 'HorizontalAlignment', 'left', 'FontUnits', 'Normalized');
        % Increment path count
        obj.pPathCount = obj.pPathCount + 1;
    end
    
    % Highlight destination node when reached
    function highlightDstNode(obj, nodeID)
        % Check for network creation
        if isempty(obj.pFigureObj)
            fprintf('createNetwork() must be called first.\n');
            return;
        elseif (~isvalid(obj.pFigureObj))
            return;
        end
        
        % Validate node ID
        validateattributes(nodeID, {'numeric'}, {'scalar', 'integer', ...
            '>=', 1, '<=', obj.NumberOfNodes}, 'highlightDstNode');
        
        % Node off check
        if ~obj.NodeState(nodeID)
            fprintf('To highlight transmissions, node must be in ''On'' state.\n');
            return;
        end
        
        highlight(obj.pPlotObj, nodeID, 'MarkerSize', 15);
        pause(0.15);
        % Check for empty figure handle
        if (~isvalid(obj.pFigureObj))
            return;
        end
        highlight(obj.pPlotObj, nodeID, 'MarkerSize', 10);
        pause(0.15);
        % Check for empty figure handle
        if (~isvalid(obj.pFigureObj))
            return;
        end
    end
    
    % Change state of the node to on or off
    function updateNodeState(obj, nodeID, nodeState)
        % Check for network creation
        if isempty(obj.pFigureObj)
            fprintf('createNetwork() must be called first.\n');
            return;
        elseif (~isvalid(obj.pFigureObj))
            return;
        end
        
        % Validate node ID
        validateattributes(nodeID, {'numeric'}, {'scalar', 'integer', ...
            '>=', 1, '<=', obj.NumberOfNodes}, 'updateNodeState');
        
        % Validate node state
        validateattributes(nodeState, {'numeric'}, {'scalar', 'integer', ...
            '>=', 0, '<=', 2}, 'updateNodeState');
        
        % Update node state
        obj.NodeState(nodeID) = nodeState;
        
        % The network is recreated to change the node state
        obj.plotNetwork();
    end
    
    % Update node statistics
    function updateNodeStatistics(obj, statistics)
        % Check for network creation
        if isempty(obj.pFigureObj)
            fprintf('createNetwork() must be called first.\n');
            return;
        elseif (~isvalid(obj.pFigureObj))
            return;
        end
        
        % Validate statistics
        statsCount = numel(statistics);
        if (~iscell(statistics) || (statsCount ~= obj.NumberOfNodes))
            fprintf('Statistics value must be a cell array of size %d.\n', obj.NumberOfNodes);
            return;
        end
        
        % Display node information on hover
        dcm = datacursormode;
        datacursormode off;
        
        % Connect helperBLEMeshGraphCursorCallback function to the data cursor
        set(dcm, 'update', {@helperBLEMeshGraphCursorCallback, statistics});
    end
    
    % Update Low Power node state
    function updateLowPowerNodeState(obj, nodeID, state)
        % Check for network creation
        if isempty(obj.pFigureObj)
            fprintf('createNetwork() must be called first.\n');
            return;
        elseif (~isvalid(obj.pFigureObj))
            return;
        end
        
        % Change node color based on Low Power node state
        switch state
            case 0 % Sleep
                highlight(obj.pPlotObj, nodeID, 'NodeColor', [0.75 0.75 0]);
            otherwise % Active
                idx = 0;
                for i = 1:size(obj.pSrcDstPairs, 1)
                    res = find(ismember(obj.pSrcDstPairs(i, :), nodeID), 1);
                    if ~isempty(res)
                        idx = i;
                        break;
                    end
                end
                if idx
                    highlight(obj.pPlotObj, nodeID, 'NodeColor', obj.Colors(idx(1), :));
                end
        end
    end
    
    function updateProgressBar(obj, currentTime)
        % Check for network creation
        if isempty(obj.pFigureObj)
            fprintf('createNetwork() must be called first.\n');
            return;
        elseif (~isvalid(obj.pFigureObj))
            return;
        end
        
        %updateProgressBar Update the progress bar status
        if (obj.SimulationTime)
            % Update simulation progress
            percentage = (currentTime/obj.SimulationTime)*100;
            obj.pProgressInfo.Position(3) = obj.ProgressW*(percentage/100);
            obj.pPercentageInfo.String = [ num2str(round(percentage)) '%'];
            pause(0.01);
        end
    end
end

methods (Access = private)
    function plotNetwork(obj)
        % Create graph
        nw = digraph;
        
        % Add nodes to the graph
        nw = addnode(nw, obj.NumberOfNodes);
        
        % Get vicinity nodes and draw edges
        for i = 1:obj.NumberOfNodes
            % Get nodes in the vicinity to draw edges
            nodes = helperBLEMeshVicinityNodes(i, obj.Positions, obj.VicinityRange);
            for j = 1 : length(nodes)
                % Add bi-directional edges for friend pairs
                if ~isempty(obj.FriendPairs)
                    if ((obj.NodeState(i) == 3 && obj.NodeState(nodes(j)) == 4) || ...
                            (obj.NodeState(i) == 4 && obj.NodeState(nodes(j)) == 3)) && ...
                            (any(ismember(obj.FriendPairs, [i, nodes(j)], 'rows')) || ...
                            any(ismember(obj.FriendPairs, [nodes(j), i], 'rows')))
                        if ~sum(findedge(nw, nodes(j), i)) && ~sum(findedge(nw, i, nodes(j)))
                            nw = addedge(nw, i, nodes(j));
                            nw = addedge(nw, nodes(j), i);
                        end
                    end
                end
                idx = findedge(nw, nodes(j), i);
                if ~idx
                    nw = addedge(nw, i, nodes(j));
                end
            end
        end
        
        % Store graph object
        obj.pGraph = nw; 
        
        % Plot graph
        obj.pPlotObj = plot(axes(obj.pFigureObj, 'Position', [0.08, 0.1, 0.9, 0.8]), nw, 'k', 'ArrowSize', 0);
        title(obj.Title, 'FontSize', 15, 'Tag', 'PlotTitle', 'FontUnits', 'Normalized');
        obj.pPlotObj.LineStyle = '--';
        
        % Label axes
        xlabel(obj.pFigureObj.CurrentAxes, 'X-position (meters)', 'Tag', 'XLabel');
        ylabel(obj.pFigureObj.CurrentAxes, 'Y-position (meters)', 'Tag', 'YLabel');
        obj.pFigureObj.CurrentAxes.XTickMode = 'auto';
        obj.pFigureObj.CurrentAxes.YTickMode = 'auto';
        obj.pFigureObj.CurrentAxes.Box = 'off';
        obj.pFigureObj.CurrentAxes.TickDir = 'out';
        obj.pFigureObj.CurrentAxes.Tag = 'PlotAxes';
        obj.pFigureObj.CurrentAxes.ClippingStyle = 'rectangle';
        
        % Assign positions to graph nodes
        obj.pPlotObj.XData = obj.Positions(:, 1);
        obj.pPlotObj.YData = obj.Positions(:, 2);
        nodeFontSize = 11;
        
        % Mark relay node color as red
        for i = 1: obj.NumberOfNodes
            switch obj.NodeState(i)
                case 0 % Node off
                    % Get vicinity nodes of the current node
                    vicNodes = helperBLEMeshVicinityNodes(i, obj.Positions, obj.VicinityRange);
                    highlight(obj.pPlotObj, i, 'NodeColor', ...
                        [0.8 0.8 0.8], 'MarkerSize', 6);
                    for j = 1:length(vicNodes)
                        if edgecount(obj.pGraph, i, vicNodes(j))
                            highlight(obj.pPlotObj, i, vicNodes(j), ...
                                'EdgeColor', [0.8 0.8 0.8]);
                        else
                            highlight(obj.pPlotObj, vicNodes(j), i, ...
                                'EdgeColor', [0.8 0.8 0.8]);
                        end
                    end
                case 1 % End nodes
                    highlight(obj.pPlotObj, i, 'NodeColor', ...
                        [0 0.5 1], 'MarkerSize', 6);
                case 2 % Relay nodes
                    highlight(obj.pPlotObj, i, 'NodeColor', [1 0.4980 0.4980], ...
                        'MarkerSize', 6);
                case 3 % Friend node
                    highlight(obj.pPlotObj, i, 'NodeColor', ...
                        [1 0.498 1], 'MarkerSize', 10, 'NodeFontSize', nodeFontSize);
                case 4 % Low Power node
                    highlight(obj.pPlotObj, i, 'NodeColor', ...
                        [0.75 0.75 0], 'MarkerSize', 10, 'NodeFontSize', nodeFontSize);
            end
        end
        
        % Highlight friend connection with dashed lines
        for i = 1 : size(obj.FriendPairs, 1)
            highlight(obj.pPlotObj, obj.FriendPairs(i, :), 'LineStyle', '-.', 'ArrowSize', 8, 'EdgeColor', [0.2627, 0.2471, 0.2510]);
            highlight(obj.pPlotObj, fliplr(obj.FriendPairs(i, :)), 'LineStyle', '-.', 'ArrowSize', 8, 'EdgeColor', [0.2627, 0.2471, 0.2510]);
        end
		
		% Create empty plots for legend
        legendStr = {'\color[rgb]{1 0.4980 0.4980} Relay node', '\color[rgb]{0 0.5 1} End node'};
        hold on;
        p(1) = plot(NaN, '.', 'color', [1 0.4980 0.4980], 'MarkerSize', 30);
        p(2) = plot(NaN, '.', 'color', [0 0.5 1], 'MarkerSize', 30);
        plotCount = 2;
        
        % Failed node legend
        if any(~obj.NodeState)
            p(plotCount+1) = plot(NaN, '.', 'color', [0.6, 0.6, 0.6], 'MarkerSize', 30);
            legendStr{plotCount+1} = '\color[rgb]{0.6, 0.6, 0.6} Failed node';
            plotCount = plotCount + 1;
        end
         
        % Create legend for Friend node and Low Power node
        if size(obj.FriendPairs, 1) >= 1
            % Friend node legend
            p(plotCount+1) = plot(NaN, '.', 'color', [1 0.498 1], 'MarkerSize', 30);
            legendStr{plotCount+1} = '\color[rgb]{1 0.498 1} Friend node';
            % Low Power node legend
            p(plotCount+2) = plot(NaN, '.', 'color', [0.75 0.75 0], 'MarkerSize', 30);
            legendStr{plotCount+2} = '\color[rgb]{0.75 0.75 0} Low Power node';
            plotCount = plotCount + 2;
        end
        
        % Edit: Comment khoi duoi
        % More than 3 source-destination pairs
%         if size(obj.SrcDstPairs, 1) > 3
%             obj.SrcDstPairs = obj.SrcDstPairs(1:3, :);
%             fprintf('Maximum of 3 source-destination pairs supported.\n');
%         end
        
        validPairCount = 1;
        for k = 1:size(obj.SrcDstPairs, 1)
            % Get non-zero elements from pair
            srcDstPair = obj.SrcDstPairs(k, :);
            validSrcDstPair = srcDstPair(srcDstPair ~= 0);
            
            % Highlight source node
            if (obj.NodeState(srcDstPair(1)) == 4)
                fprintf('Low Power node is not supported as a source node.\n');
                continue;
            elseif ~obj.NodeState(srcDstPair(1))
                fprintf('Source node must not be a failed node.\n');
                continue;
            elseif (obj.NodeState(srcDstPair(1)) ~= 3)
                highlight(obj.pPlotObj, obj.SrcDstPairs(k, 1), 'NodeColor', ...
                    obj.Colors(validPairCount, :), 'MarkerSize', 10, 'NodeFontSize', nodeFontSize);       
            end
            obj.pSrcDstPairs(validPairCount, :) = srcDstPair;
            validPairCount = validPairCount + 1;
            % Highlight destination node
            for i = 1:numel(validSrcDstPair(2:end))
                if (obj.NodeState(validSrcDstPair(i+1))) && ...
                        (obj.NodeState(validSrcDstPair(i+1)) ~= 3) && ...
                        (obj.NodeState(validSrcDstPair(i+1)) ~= 4)
                    highlight(obj.pPlotObj, validSrcDstPair(i+1), 'NodeColor', ...
                        obj.Colors(validPairCount-1, :), 'MarkerSize', 10, 'NodeFontSize', nodeFontSize);
                end
            end
            
            % Add legend for source-destination pairs
            p(plotCount+1) = plot(NaN, '.', 'color', obj.Colors(validPairCount-1, :), 'MarkerSize', 30);
            if numel(validSrcDstPair(2:end)) > 1
                legendStr{plotCount+1} = ['\color[rgb]{' num2str(obj.Colors(validPairCount-1, :)) '} Source - Destinations group (' ...
                    num2str(validSrcDstPair(1)) ' - ' replace(num2str(validSrcDstPair(2:end)), '  ', ', ') ')'];
            else
                legendStr{plotCount+1} = ['\color[rgb]{' num2str(obj.Colors(validPairCount-1, :)) '} Source - Destination pair (' ...
                    num2str(validSrcDstPair(1)) ', ' num2str(validSrcDstPair(2)) ')'];
            end
            plotCount = plotCount+1;
        end
                
        hold off;
        legend(p, legendStr, 'Location', 'northeastoutside', ...
            'Box', 'off');
        
        % Call node statics to remove default values
        obj.updateNodeStatistics(cell(1, obj.NumberOfNodes));
        
        % For static visualization
        if obj.DisplayProgressBar
            % Progress bar dimensions
            progressDimension = [obj.ProgressX, obj.ProgressY, obj.ProgressW, obj.ProgressH];
            
            % Add progress bar
            annotation(obj.pFigureObj, 'rectangle', progressDimension, ...
                'FaceColor', obj.ProgressBarBackgroundColor, 'Tag', ...
                'MeshVisualizationProgressBar');
            obj.pProgressInfo = annotation(obj.pFigureObj, 'rectangle', ...
                progressDimension, 'FaceColor', obj.ProgressBarColor, 'Tag', ...
                'MeshVisualizationProgressBar');
            obj.pProgressInfo.Position(3) = 0;
            % Progress percentage display text
            obj.pPercentageInfo = annotation(obj.pFigureObj, 'textbox', ...
                progressDimension, 'String', '0%', ...
                'FitBoxToText', 'on', 'FontUnits', 'normalized', ...
                'LineStyle', 'none', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'Tag', ...
                'MeshVisualizationProgressBarPercentage');
        end
    end
    
    % Allocate the grid positions
    function positions = gridPositionAllocator(obj)
        x = zeros(1, obj.NumberOfNodes);
        y = zeros(1, obj.NumberOfNodes);
        for i = 1:(obj.NumberOfNodes)
            switch(obj.GridLayout)
                case 'Row' % Arrange nodes row by row
                    x(i) = obj.GridInitX + obj.GridDeltaX*(mod(i-1, obj.GridWidth));
                    y(i) = obj.GridInitY + obj.GridDeltaY*(floor((i-1)/obj.GridWidth));
                    
                case 'Column' % Arrange nodes column by column
                    x(i) = obj.GridInitX + obj.GridDeltaX*(floor(i-1/obj.GridWidth));
                    y(i) = obj.GridInitY + obj.GridDeltaY*(mod(i-1, obj.GridWidth));
                    
                otherwise
                    fprintf('Invalid layout type. Valid options are ''Row'' and ''Column''.\n');
            end
        end
        positions = [x', y'];
    end
    
    % Validate positions
    function validatePositions(obj, value)
        validateattributes(value, {'numeric'}, {'2d', 'ncols', 2, ...
            'nrows', obj.NumberOfNodes}, mfilename, 'Positions');
    end
    
    % Validate node state
    function validateNodeState(obj, value)
        validateattributes(value, {'numeric'}, {'row', 'numel', ...
            obj.NumberOfNodes, '>=', 0, '<=', 4}, mfilename, 'NodeState');
    end
	
	% Validate source-destination pairs
    function validateSrcDstPairs(obj, value)
        validateattributes(value, {'numeric'}, ...
        {'nonnegative', '<=', obj.NumberOfNodes, '>=', 0}, mfilename, 'SrcDstPairs');
    end
    
    % Validate friend pairs
    function validateFriendPairs(obj, value)
        validateattributes(value, {'numeric'}, ...
        {'nonnegative', '<=', obj.NumberOfNodes, '>=', 1, 'ncols', 2}, mfilename, 'SrcDstPairs');
    end
end
end
