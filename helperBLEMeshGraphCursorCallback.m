function nodeInfo = helperBLEMeshGraphCursorCallback(~, eventObj, nodeStatistics)
%helperBLEMeshGraphCursorCallback Display the node statistics when mouse
%hover action is performed on a node in the plot
%   NODEINFO = helperBLEMeshGraphCursorCallback(~, EVENTOBJ,
%   NODESTATISTICS) display the node statistics when mouse hover action is
%   performed on a node.
%
%   NODEINFO is a cell array of character vectors indicating the data
%   cursor text.
%
%   EVENTOBJ is a handle to data cursor event object.
%
%   NODESTATISTICS is a cell array containing node statistics.

%   Copyright 2019 The MathWorks, Inc.

% Get the target node 
h = get(eventObj, 'Target');

% Get the position of the target node
pos = get(eventObj, 'Position');

% Get node Identifier based on position
ind = find(h.XData == pos(1) & h.YData == pos(2), 1);

% Get node statistics
data = nodeStatistics(ind);

% Format the node data to display when hover
if (~cellfun(@isempty, data'))
    nodeInfo = cell(length(data{1})/2, 1);
    count = 1;
    for idx = 1:2:length(data{1})
        nodeInfo(count) = {[data{1}{idx} ' : ' num2str(data{1}{idx+1})]};
        count = count+1;
    end
else % If no statistics to display
    nodeInfo = {'No data to display'};
end
end
