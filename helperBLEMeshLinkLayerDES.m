classdef helperBLEMeshLinkLayerDES < matlab.DiscreteEventSystem & matlab.system.mixin.SampleTime
%helperBLEMeshLinkLayerDES BLE link layer
%
%   This is an example helper class (Discrete Event System). This object
%   performs the following operations:
%
%       * Maintain link layer state machine, supporting Broadcaster and
%         Observer roles
%       * Store higher layer data (network PDU) in link layer queue
%       * Transmit and receive link layer advertising packets
%       * Send decoded information to higher layer (network layer)
%       * Send link layer requests to PHY (transmission and
%         reception)

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Public properties
properties
    %RandomAdvertising Random advertising packet transmissions
    %   Specify this property as one of 'On' | 'Off'. This property
    %   indicates whether the random selection of advertising channels is
    %   enabled or disabled. The default value is 'On'.
    RandomAdvertising = 'On'
    
    %AdvertisingInterval Advertising interval (ms)
    %   Specify advertising interval as a scalar integer in the range [20,
    %   10485750] milliseconds. Specify value for this parameter in
    %   multiples of 5 milliseconds. It is used in transmitting the
    %   advertising packets in an advertising event. The default value is
    %   20 milliseconds.
    AdvertisingInterval = 20
    
    %ScanInterval Scan interval (ms)
    %   Specify scan interval as a scalar integer in the range [5, 40960]
    %   milliseconds. Specify value for this parameter in multiples of 5
    %   milliseconds. It is used in scanning the advertising packets in
    %   scanning state. The default value is 5 milliseconds.
    ScanInterval = 5
    
    %NodeID Unique device identification number
    NodeID (1, 1) {mustBeInteger, mustBeGreaterThan(NodeID, 0)} = 1
end

% Private properties
properties (Access = private)
    %pLinkLayer BLE link layer handle object (helperBLEMeshLLGAPBearer)
    pLinkLayer
    
    %pLinkLayerPDU Link layer PDU to physical layer
    % Fixed size PDU (for codegen) with maximum length of link layer PDU
    % i.e. 2080 bits (260 bytes).
    pLinkLayerPDU = zeros(2080, 1)
    
    %pLinkLayerPDULength Length of link layer PDU in 'pLinkLayerPDU'
    pLinkLayerPDULength = 0
    
    %pReception Flag indicating link layer reception
    pReception = false
    
    %pNextInvokeTime Next invocation time of handle object in microseconds
    pNextInvokeTime = -1
    
    %pLastInvocationTime Simulation time at recent invocation of handle
    %object in seconds
    pLastInvocationTime = -1
end

% Constant, Hidden properties
properties (Constant, Hidden)
    %DefaultPriority Default priority for an event
    DefaultPriority = 100
    
    %USecPerSec Microseconds per second
    USecPerSec = 1e6
    
    %NetworkPDUQueueID
    NetworkPDUQueueID = 1
    
    %LLPDUQueueID
    LLPDUQueueID = 2
    
    %PHYTxReqQueueID
    PHYTxReqQueueID = 3
    
    %PHYRxReqQueueID
    PHYRxReqQueueID = 4
    
    %LLTimerStorageID
    LLTimerStorageID = 5
    
    %RandomAdvertisingSet Set of possible values
    RandomAdvertisingSet = matlab.system.StringSet({'On', 'Off'});
end

% Discrete-event algorithms
methods
    % Constructor
    function obj = helperBLEMeshLinkLayerDES()
        % Initialize link layer object
        obj.pLinkLayer = helperBLEMeshLLGAPBearer();
    end
    
    % Set Node ID
    function set.NodeID(obj, value)
        % Validate node ID
        coder.extrinsic('helperBLEMeshValidateNodeID');
        helperBLEMeshValidateNodeID(value);
        obj.NodeID = value;
    end
    
    % Set advertising interval
    function set.AdvertisingInterval(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 20, '<=', 10485750}, mfilename, ...
            'AdvertisingInterval');
        % Accept multiples of 5
        if rem(value, 5) ~= 0
            error('''AdvertisingInterval'' value must be a multiple of 5');
        end
        obj.AdvertisingInterval = value;
    end
    
    % Set scan interval
    function set.ScanInterval(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 5, '<=', 40960}, mfilename, 'ScanInterval');
        % Accept multiples of 5
        if rem(value, 5) ~= 0
            error('''ScanInterval'' value must be a multiple of 5');
        end
        obj.ScanInterval = value;
    end
    
    % Set up entity generation events at start of simulation
    function events = setupEvents(obj)
        % Initialize events array
        events = obj.initEventArray();
        
        % Generate event to invoke link layer object
        events = [events, obj.eventGenerate(obj.LLTimerStorageID, 'Start invoke', 0, obj.DefaultPriority)];
    end
    
    % Initial invocation of link layer handle object
    function [entity, events] = llGAPBearerGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Get elapsed time in microseconds
        elapsedTime = obj.getElapsedTime();
        
        % Empty Rx PDU
        rxPDU = zeros(1, 0);
        
        % Link layer handle invocation from DES
        events = obj.invokeLLHandle(elapsedTime, rxPDU, events);
        
        % Store current simulation time indicating recent invoke time
        obj.pLastInvocationTime = obj.getCurrentTime();
    end
    
    % Specify events when timer completed
    function [entity, events] = llGAPBearerTimer(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Get elapsed time in microseconds
        elapsedTime = obj.getElapsedTime();
        
        % Empty Rx PDU
        rxPDU = zeros(1, 0);
        
        % Set to default as timer completed
        obj.pNextInvokeTime = -1;
        
        % Link layer invocation from DES
        events = obj.invokeLLHandle(elapsedTime, rxPDU, events);
        
        % Store current simulation time indicating recent invoke time
        obj.pLastInvocationTime = obj.getCurrentTime();
    end
    
    % Specify actions when link layer handle object is invoked
    function events = invokeLLHandle(obj, elapsedTime, rxPDU, events)
        % Invoke link layer handle
        [nextInvokeTime, llPDU, ~, rxFlag] = obj.pLinkLayer.run(elapsedTime, rxPDU);
        
        % Do not schedule an event if it is already scheduled
        if nextInvokeTime >= 0 && nextInvokeTime ~= obj.pNextInvokeTime
            % Cancel old timer
            if obj.pNextInvokeTime ~= -1        
                events = [events, obj.cancelTimer('invoke LL handle')];
            end
            % Schedule new timer based on next invoke time specified by object
            events = [events, obj.eventTimer('invoke LL handle', nextInvokeTime/obj.USecPerSec)];
            % Store next invoke time
            obj.pNextInvokeTime = nextInvokeTime;
        end
        
        % Decoding success
        if obj.pLinkLayer.pGAPDataRxFlag
            % Schedule an event to send the decoded information to
            % higher layer (network layer)
            events = [events, obj.eventGenerate(obj.NetworkPDUQueueID, 'Link layer reception', 0, obj.DefaultPriority)];
        end
        
        % Start reception
        if rxFlag == 1
            % Update reception flag
            obj.pReception = true;
            % Schedule an event to request PHY about link layer reception
            events = [events, obj.eventGenerate(obj.PHYRxReqQueueID, 'LL PHY Rx request', 0, obj.DefaultPriority)];
            
        % Stop reception
        elseif rxFlag == 0
            % Update reception flag
            obj.pReception = false;
            % Schedule an event to request PHY about link layer reception
            events = [events, obj.eventGenerate(obj.PHYRxReqQueueID, 'LL PHY Rx request', 0, obj.DefaultPriority)];
        end
        
        % PDU to transmit
        if ~isempty(llPDU)
            % Store link layer PDU
            obj.pLinkLayerPDULength = numel(llPDU);
            obj.pLinkLayerPDU(1:obj.pLinkLayerPDULength) = llPDU;
            
            % Schedule event for advertising packet transmission
            events = [events, obj.eventGenerate(obj.LLPDUQueueID, 'Link layer transmission', 0, obj.DefaultPriority)];
        end
    end
    
    % Elapsed time to call handle in microseconds
    function elapsedTime = getElapsedTime(obj)
        % Timer active, get elapsed time
        if obj.pNextInvokeTime ~= -1
            % Get elapsed time in microseconds
            elapsedTime = round((obj.getCurrentTime() - obj.pLastInvocationTime)*obj.USecPerSec);
            % Update next invoke time
            obj.pNextInvokeTime = obj.pNextInvokeTime - elapsedTime;
            
        % Timer inactive, pass zero as elapsed time 
        else
            % Default elapsed time
            elapsedTime = 0;
        end
    end
    
    % Specify event actions when network PDU entity enters storage
    function [entity, events] = networkPDUEntry(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();

        % Network PDU
        networkPDU = entity.data.PDU(1:entity.data.Length);
        
        % GAP data block
        gapData = helperBLEMeshGAPDataBlock(networkPDU);
        
        % Push GAP data into link layer queue
        obj.pLinkLayer.pushGAPData(gapData);
        
        % Destroy entity
        events = [events, obj.eventDestroy()];
    end
    
    % Specify event actions when link layer PDU entity enters storage
    function [entity, events] = linkLayerPDUEntry(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Link layer is scanning
        if obj.pReception
            % Get elapsed time in microseconds
            elapsedTime = obj.getElapsedTime();
            
            % Valid access address
            if isequal(entity.data.AccessAddress, reshape(obj.pLinkLayer.pAccessAddress, [], 1))
                % Non-empty Rx PDU
                rxPDU = entity.data.PDU(1:entity.data.Length);
            % Invalid access address
            else
                % Empty Rx PDU
                rxPDU = zeros(1, 0);
            end
            
            % Link layer invocation from DES
            events = obj.invokeLLHandle(elapsedTime, rxPDU, events);
            
            % Store current simulation time indicating recent invoke time
            obj.pLastInvocationTime = obj.getCurrentTime();
        end
        
        % Destroy entity
        events = [events, obj.eventDestroy()];
    end
    
    % Specify event actions when network PDU entity generated in storage
    function [entity, events] = networkPDUGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Non-empty GAP data
        if ~isempty(obj.pLinkLayer.pGAPDataRx)
            % Decode GAP data block
            networkPDU = helperBLEMeshGAPDataBlockDecode(reshape(obj.pLinkLayer.pGAPDataRx, [], 1));
            
            % Network PDU
            networkPDULen = numel(networkPDU);
            entity.data.PDU(1:networkPDULen) = networkPDU;
            entity.data.Length = networkPDULen;
            
            % Send network PDU to higher layer (network layer)
            events = [events, obj.eventForward('output', obj.NetworkPDUQueueID, 0)];
        end
    end
    
    % Specify event actions when link layer PDU entity generated in storage
    function [entity, events] = linkLayerPDUGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Schedule an event to request PHY about link layer transmission
        events = [events, obj.eventGenerate(obj.PHYTxReqQueueID, 'LL PHY Tx request', 0, obj.DefaultPriority/2)];
        
        % Link layer PDU
        entity.data.PDU = obj.pLinkLayerPDU;
        % Advertising packet length
        entity.data.Length = obj.pLinkLayerPDULength;
        % Default access address for advertising packets
        entity.data.AccessAddress = obj.pLinkLayer.pAccessAddress;
        
        % Send link layer PDU to lower layer (PHY)
        events = [events, obj.eventForward('output', obj.LLPDUQueueID, 0)];
    end
    
    % Specify event actions when PHY Tx request entity generated in
    % storage
    function [entity, events] = phyTxReqGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();

        % Channel index to PHY for transmission
        entity.data.Transmission = true;
        entity.data.ChannelIndex = obj.pLinkLayer.pChannelIndex;
        
        % Send Tx request to lower layer (PHY) for transmission
        events = [events, obj.eventForward('output', obj.PHYTxReqQueueID, 0)];
    end
    
    % Specify event actions when PHY Rx request entity generated in
    % storage
    function [entity, events] = phyRxReqGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Access address and channel index to PHY for reception
        entity.data.Reception = obj.pReception;
        entity.data.AccessAddress = obj.pLinkLayer.pAccessAddress;
        entity.data.ChannelIndex = obj.pLinkLayer.pChannelIndex;
        
        % Send Rx request to lower layer (PHY) for reception
        events = [events, obj.eventForward('output', obj.PHYRxReqQueueID, 0)];
    end
end

% Protected methods
methods(Access = protected)
    % Perform setup operation
    function setupImpl(obj)
        % Configure the link layer intervals, as the handle object accepts
        % intervals as multiple of 5 milliseconds
        obj.pLinkLayer.AdvertisingInterval = obj.AdvertisingInterval/5;
        obj.pLinkLayer.ScanInterval = obj.ScanInterval/5;
        % Set random advertising channel selection
        if strcmp(obj.RandomAdvertising, 'On')
            obj.pLinkLayer.RandomAdvertising = true;
        else
            obj.pLinkLayer.RandomAdvertising = false;
        end
        % Initialize link layer handle object
        obj.pLinkLayer.init();
        % Set rng seed
        rng(obj.NodeID);
    end
    
    % Store link layer statistics
    function releaseImpl(obj)
        % Declare function as extrinsic
        coder.extrinsic('helperBLEMeshUpdateStatistics');
        
        % Update respective layer statistics based on node ID
        opcode = 1; % For updating the statistics table
        helperBLEMeshUpdateStatistics(opcode, obj.NodeID, 'LinkLayer', [obj.pLinkLayer.TransmittedMsgs ...
            obj.pLinkLayer.ReceivedMsgs obj.pLinkLayer.CRCFailedMsgs ...
            obj.pLinkLayer.BytesTransmitted obj.pLinkLayer.BytesReceived]);
    end
    
    % Define types of entities used in this Discrete Event System
    function entityTypes = getEntityTypesImpl(obj)
        % Specifies the entity types are used inside the Discrete Event
        % System
        entityTypes = [...
            obj.entityType('networkPDU', 'NetworkPDU'), ...
            obj.entityType('linkLayerPDU', 'LinkLayerPDU'), ...
            obj.entityType('phyTxReq', 'LLPHYTxRequest'), ...
            obj.entityType('phyRxReq', 'LLPHYRxRequest'), ...
            obj.entityType('llGAPBearer', 'double', [1, 1], false)];
    end
    
    % Define types of input and output ports used in this Discrete Event
    % System
    function [inTypes, outTypes] = getEntityPortsImpl(~)
        % Specifies input and output port data types and complexity
        inTypes = {'networkPDU', 'linkLayerPDU'};
        outTypes = {'networkPDU', 'linkLayerPDU', 'phyTxReq', 'phyRxReq'};
    end
    
    % Define storage elements used in this Discrete Event System
    function [storage, input, output] = getEntityStorageImpl(obj)
        % Considering queue size as two. At a time there cannot be more
        % than one entries in any of these ports. But, there can be entry
        % and generate actions on a storage element at same time
        PDUPortQueueSize = 2;
        requestPortQueueSize = 1;
        % Creates the internal storage queues and associate those input and
        % output ports
        storage = [...
            obj.queueFIFO('networkPDU', PDUPortQueueSize), ...
            obj.queueFIFO('linkLayerPDU', PDUPortQueueSize), ...
            obj.queueFIFO('phyTxReq', requestPortQueueSize), ...
            obj.queueFIFO('phyRxReq', requestPortQueueSize), ...
            obj.queueFIFO('llGAPBearer', requestPortQueueSize)];
        input = [obj.NetworkPDUQueueID, obj.LLPDUQueueID];
        output = [obj.NetworkPDUQueueID, obj.LLPDUQueueID, obj.PHYTxReqQueueID, obj.PHYRxReqQueueID];
    end
    
    % Define number of input ports used in this Discrete Event System
    function num = getNumInputsImpl(~)
        % This DES block contains 4 input ports. One is for PDU from
        % network layer
        num = 2;
    end
    
    % Define number of output ports used in this Discrete Event System
    function num = getNumOutputsImpl(~)
        % This DES block contains 4 output ports. One is for PDU to network
        % layer, one is for PDU to PHY and other outputs for PHY
        % requests
        num = 4;
    end
    
    % Define names for input ports used in this Discrete Event System
    function [input1, input2] = getInputNamesImpl(~)
        % Specify names for input ports
        input1 = 'networkPDU';
        input2 = 'linkLayerPDU';
    end
    
    % Define names for output ports used in this Discrete Event System
    function [output1, output2, output3, output4] = getOutputNamesImpl(~)
        % Specify names for output ports
        output1 = 'networkPDU';
        output2 = 'linkLayerPDU';
        output3 = 'phyTxReq';
        output4 = 'phyRxReq';
    end
end
end
