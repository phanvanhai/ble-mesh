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

totNodes = 68;
relayNodes = 1:68;
srcDstPairs = [10 65 1; 68 40 1; 2 66 1; 21 30 1];
% relayNodes = 1:52;
% srcDstPairs = [52 41 1; 25 21 1; 10 8 1; 30 27 1];    %72 node
% srcDstPairs = [68 71 1; 70 69 1;23 1 1; 28 10 1];    %72 node
% srcDstPairs = [89 96 1; 93 92 1; 14 23 1; 62 59 1];
% relayNodes = [1:30, 31 32 33 38 39 40 41 42 43 48 49 50 51 52 53 58 59 60 61 62 63 68 69 70 71 72 73 78 79 80 81 82 83 88 89 90 91 92 93 98 99 100];
% srcDstPairs = [93 98 1; 91 100 1; 12 19 1; 10 38 1];
% srcDstPairs = [1 100 1; 10 91 1; 41 60 1; 6 95 1];    %TTL = 15;   Node9 = End
% relayNodes = [16 30 44 58 52 38 24 10 18 32 46 60 54 40 26 12 20 34 48 62];
% srcDstPairs = [1 70 1; 7 64 1; 36 42 1; 67 4 1];    %TTL = 15;   Node9 = End
% relayNodes = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70];
% srcDstPairs = [1 70 1; 7 64 1; 36 42 1; 67 4 1];    %TTL = 15;   Node9 = End
% relayNodes = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51];
% srcDstPairs = [68 71 1; 70 69 1;23 1 1; 28 10 1];    %TTL = 15;   Node9 = End
% relayNodes = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38];

% relayNodes = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19];
% relayNodes = [18 15 7 14 8 13 9 2];
% relayNodes = [];
% srcDstPairs = [1 2 1];                   %TTL = 5;    Node9 = Relay
% srcDstPairs = [1 16 1; 2 1 3];            %TTL = 15;   Node9 = Relay
% srcDstPairs = [1 16 1; 10 9 2];           %TTL = 5;    Node9 = End


% Create a new mesh network Simulink model
helperBLEMeshCreateNetworkModel(modelName, totNodes, srcDstPairs, relayNodes);

% Specify the number of simulations
nSims = 1;
% Simulation stop time, in seconds
stopTime = 10.2;
% Network repetition values
networkRepetitions = [1 2 3 4 5 6];
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

% Simulate the BLE mesh network model for six different network layer
% configurations
for idxTwo = 1:nSims
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
close_system('BLEMeshPDRvsRateModel', false);