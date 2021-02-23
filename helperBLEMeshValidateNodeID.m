function helperBLEMeshValidateNodeID(nodeID)
%helperBLEMeshValidateNodeID Validate NodeID parameter in the given mesh
%network model
%
%   NODEID is unique device identification number for a node in the mesh
%   network model. NodeID value is a unique positive integer value in the
%   range of [1, TotalNodesInNetwork].

%   Copyright 2019-2020 The MathWorks, Inc.

totalNodes = numel(helperBLEMeshGetNodeNamesList(bdroot));
if nodeID > totalNodes
    error(['''NodeID'' value must be a positive integer less than or equal '...
        'to the total number of nodes in the network.']);
end
end