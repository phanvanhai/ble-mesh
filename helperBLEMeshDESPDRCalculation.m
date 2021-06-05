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

totNodes = 72;
relayNodes = 1:72;
% relayNodes = [69 57 45 33 13 25 27 29 40 52 64];
% relayNodes = [13 4 24 22 12 33 45 49 56 57 50 16 7 18 9 35 48 53 52 60 64 65]; %1.0

ttls = 3;
srcDstPairs = [69 37 1; 5 31 1; 26 10 1; 40 72 1];

% relayNodes = [];
% srcDstPairs = [1 2 1];                   %TTL = 5;    Node9 = Relay


% Create a new mesh network Simulink model
helperBLEMeshCreateNetworkModel(modelName, totNodes, srcDstPairs, relayNodes);

% Specify the number of simulations
% nSims = size(ttls, 1);
nSims = numel(ttls);
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
%         set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxThree, 1)) '/AppDES'], ...
%             'TTL', num2str(ttls(idxTwo, idxThree)));
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(srcDstPairs(idxThree, 1)) '/AppDES'], ...
            'TTL', num2str(ttls(idxTwo)));
    end
    % Update network layer repetitions and intervals at each node
    for idxThree = 1:totNodes
        % Update network repetitions and interval
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'NetworkTransmitCount', num2str(1));
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'NetworkTransmitInterval', num2str(networkRepetitionInterval));
        % Update relay repetitions and interval
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'RelayRetransmitCount', num2str(1));
        set_param(['BLEMeshPDRvsRateModel/Node' num2str(idxThree) '/Network layer'], ...
            'RelayRetransmitInterval', num2str(networkRepetitionInterval));
    end
    sim('BLEMeshPDRvsRateModel','ReturnWorkspaceOutputs','on');
    status = get_param('BLEMeshPDRvsRateModel','SimulationStatus');
    if strcmp(status, 'stopped')
        % Get PDR for each simulation run
        bleMeshPDRValues(idxTwo) = PDR;
        fprintf('Scene %f: %f\n', idxTwo, PDR);
        bleMeshTotalPHYTxMsgs(idxTwo) = sum(statisticsAtEachNode.PHYTransmittedSignals);
        bleMeshTotalReceivedMsgs(idxTwo) = sum(statisticsAtEachNode.ReceivedApplicationMsgs);
    end
end

% Close Simulink model
writetable(array2table(bleMeshPDRValues),'PDR.txt');
close_system('BLEMeshPDRvsRateModel', false);
fprintf('Simulation done\n');
