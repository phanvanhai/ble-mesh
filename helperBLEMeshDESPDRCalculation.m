% helperBLEMeshDESPDRCalculation Helper script to run multiple simulations
% by varying the network layer message repetitions at each node to observe
% the change in packet delivery ratio (PDR).8
%
% The configuration used for all the simulations:
%
%   -----------------------------------------------------------------------------------------
%   |  Number of nodes                       |  21                                          |
%   |  Source and destination node pairs     |  Node1 -> Node10,  Node4 -> Node20           |    
%                                               and Node21 --> Node16                       |
%   |  Relay nodes                           |  Node3, Node6, Node7, Node8, Node9, Node12,  |
%   |                                           Node13, Node14, Node15 and Node17           |
%   |  Total number of application packets   |  150 (maximum of 50 packets at each source)  |
%   |  Source packet rate                    |  2 (packets/second)                          |
%   |  Network transmit interval             |  60 milliseconds                             |
%   |  Relay retransmit interval             |  60 milliseconds                             |
%   |  Advertising interval                  |  20 milliseconds                             |
%   |  Scan interval                         |  30 milliseconds                             |
%   |  Random advertising                    |  enabled                                     |
%   |  Range propagation loss                |  enabled                                     |
%   |  Free-space path loss                  |  enabled                                     |
%   |  Tx power                              |  20 dBm                                      |
%   |  Noise figure                          |  0 dB                                        |
%   -----------------------------------------------------------------------------------------
%
% The configuration varied for each simulation:
%
%   -------------------------------------------------------
%   | Simulation number | Network layer repetitions (NLR) |
%   -------------------------------------------------------
%   |        1          |                 1               |
%   |        2          |                 2               |
%   |        3          |                 3               |
%   |        4          |                 4               |
%   |        5          |                 5               |
%   |        6          |                 6               |
%   -------------------------------------------------------
%
% To calculate the PDR, the above mesh network is simulated by varying the
% value of NLR at each node. These values are stored in a workspace named
% variable 'bleMeshPDRValues'.

% Copyright 2019 The MathWorks, Inc.

% Configure mesh network
modelName = 'BLEMeshPDRvsRateModel';

totNodes = 52;
% relayNodes = 1:52;
% relayNodes = [41 43 45 39];
%relayNodes = [2 6 7 11 14 41 42 43 44 45 46 47 39 48 26 18 19 23 24];
%relayNodes = [4 8 9 13 14 35 41 42 43 44 45 46 47 37 17 21 22 26 27 50]; 
%relayNodes = [4 8 9 13 14 35 5 10 15 41 42 43 44 45 46 47 37 20 25 30 39 17 21 22 26 27 48 50];
relayNodes =  [2 6 7 11 12 35 8 9 13 14 5 37 42 44 46 20 30 39 1 21 22 27 48 19 23 24 28];
srcDstPairs = [52 40 1;3 38 1; 18 36 1; 34 16 1];
ttls = [127 127 127 127; 13 13 13 13; 12 12 12 12; 11 11 11 11; 10 10 10 10; 9 9 9 9; 8 8 8 8; 7 7 7 7; 6 6 6 6; 5 5 5 5; 4 4 4 4];
% ttls = [127 127 127 127; 10 10 10 10; 9 9 9 9; 8 8 8 8; 7 7 7 7; 6 6 6 6; 5 5 5 5; 11 11 11 11; 12 12 12 12; 13 13 13 13; 14 14 14 14; 4 4 4 4];

% relayNodes = [];
% srcDstPairs = [1 2 1];                   %TTL = 5;    Node9 = Relay


% Create a new mesh network Simulink model
helperBLEMeshCreateNetworkModel(modelName, totNodes, srcDstPairs, relayNodes);

% Specify the number of simulations
nSims = size(ttls, 1);
% Simulation stop time, in seconds
stopTime = 10.3;
% Network repetition values
networkRepetitions = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
% Interval between network repetitions
networkRepetitionInterval = 60;
% Source packet rate for each simulation
srcRate = 3;
% Max number of packets at each node
totalPackets = 50;

% Pre-allocate PDR values with zeros
bleMeshPDRValues = zeros(1, nSims);
bleMeshTotalPHYTxMsgs = zeros(1, nSims);
bleMeshTotalReceivedMsgs = zeros(1, nSims);

% Open simulink model
open_system('BLEMeshPDRvsRateModel');
% Set simulation stop time in seconds
set_param('BLEMeshPDRvsRateModel', 'StopTime', num2str(stopTime));
% Set source packet rate and maximum number of packets to be transmitted at
% source
for idxOne = 1:size(srcDstPairs, 1)    
    % Edit: them doan duoi
    set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxOne, 1)) '/AppDES'], ...
            'ApplicationState', num2str(srcDstPairs(idxOne, 3)));
    set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxOne, 1)) '/AppDES'], ...
            'DestinationNode', num2str(srcDstPairs(idxOne, 2)));    
    if srcDstPairs(idxOne, 3) == 2 || srcDstPairs(idxOne, 3) == 3        
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxOne, 1)) '/AppDES'], ...
            'SourceRate', '0.3');
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxOne, 1)) '/AppDES'], ...
            'TotalPackets', '1');
    else
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxOne, 1)) '/AppDES'], ...
            'SourceRate', num2str(srcRate));
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxOne, 1)) '/AppDES'], ...
            'TotalPackets', num2str(totalPackets));
    end
end

fprintf('Simulation start\n');
% Simulate the BLE mesh network model for six different network layer
% configurations
for idxTwo = 1:nSims
    % Edit paper:
    for idxThree = 1:size(srcDstPairs, 1)
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxThree, 1)) '/AppDES'], ...
            'TTL', num2str(ttls(idxTwo, idxThree)));
    end
    % Update network layer repetitions and intervals at each node
    for idxThree = 1:totNodes
        % Update network repetitions and interval
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'NetworkTransmitCount', num2str(networkRepetitions(idxTwo)));
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'NetworkTransmitInterval', num2str(networkRepetitionInterval));
        % Update relay repetitions and interval
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'RelayRetransmitCount', num2str(networkRepetitions(idxTwo)));
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'RelayRetransmitInterval', num2str(networkRepetitionInterval));
    end
    sim('BLEMeshPDRvsRateModel','ReturnWorkspaceOutputs','on');
    status = get_param('BLEMeshPDRvsRateModel','SimulationStatus');
    if strcmp(status, 'stopped')
        % Get PDR for each simulation run
        bleMeshPDRValues(idxTwo) = PDR;
        bleMeshTotalPHYTxMsgs(idxTwo) = sum(statisticsAtEachNode.PHYTransmittedSignals);
        bleMeshTotalReceivedMsgs(idxTwo) = sum(statisticsAtEachNode.ReceivedApplicationMsgs);
    end
end

% Close Simulink model
writetable(array2table(bleMeshPDRValues),'PDR.txt');
close_system('BLEMeshPDRvsRateModel', false);
fprintf('Simulation done\n');
