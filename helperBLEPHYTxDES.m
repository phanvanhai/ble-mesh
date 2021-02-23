classdef helperBLEPHYTxDES < matlab.DiscreteEventSystem
%helperBLEPHYTxDES Generate and transmit the BLE waveform
%
%   This is an example helper Discrete Event System class.
%
%   This object performs these operations on the frame to be transmitted:
%
%      * Handle requests from link Layer (LL)
%      * Generate waveform using input LL PDU
%      * Apply impairments to the waveform and send it to the shared
%      channel

%   Copyright 2019 The MathWorks, Inc.

% Public, tunable properties
properties
    % Tx Power (dBm)
    % Specify the Tx power as a scalar integer be in the range [-20, 20].
    % It specifies the signal transmission power in dBm. The default value
    % is 20 dBm.
    TxPower (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(TxPower, -20), ...
        mustBeLessThanOrEqual(TxPower, 20)} = 20
    
    % Node position
    %   Specify the position of node position as a row-vector of integer
    %   values representing the three-dimensional coordinate (x, y, z). The
    %   'z' value is not considered. The default value is [0 0 0].
    NodePosition (1, 3) {mustBeNumeric} = [0 0 0]
    
    % Node identifier
    %   Specify node identifier as an integer value representing the node.
    %   It is a unique identifier for the nodes in the network. The default
    %   value is 1.
    NodeID (1, 1) {mustBeInteger, mustBeGreaterThan(NodeID, 0)} = 1
end

properties(Access = private)
    %pPHYTx Handle for BLE PHY transmitter
    pPHYTx
    
    %pLLPDU PDU from the LL
    pLLPDU % in bits
    
    %pLLPDULen Length of the LL PDU
    pLLPDULen % number of bits
    
    %pAccessAddress Access address of the received LL PDU
    pAccessAddress % in bits
    
    %pWaveformDuration Duration for transmitting the BLE waveform
    pWaveformDuration = 0 % in microseconds
    
    %pTransmission Defines the packet is transmitting or not
    pTransmission = false
    
    %pChannelIndex Transmission channel index
    pChannelIndex = -1
end

properties (Constant, Hidden)
    % Storage queue IDs
    PhyTxReqQueueID = 1;
    LLPDUQueueID = 2;
    WaveformQueueID = 3;
    DurationQueueID = 4;
    
    % Output port indexes
    OUTPUT_PORT_1_INDEX = 1;
    
    % Maximum size of the LL PDU
    % Refer Bluetooth Core Specification version 5.0, volume 6, part B,
    % Figure 2.1
    LLPDUMaxSize = 2080 % in bits (260 octets)
    
    % Access address length
    % Refer Bluetooth Core Specification version 5.0, volume 6, part B,
    % Figure 2.1
    AccessAddressLen = 32; % in bits (4 octets)
end

methods
    % Set Node ID
    function set.NodeID(obj, value)
        % Validate node ID
        coder.extrinsic('helperBLEMeshValidateNodeID');
        helperBLEMeshValidateNodeID(value);
        obj.NodeID = value;
    end
    
    % LL to PHY requests entry
    function [entity, events] = phyTxReqEntry(obj, ~, entity, ~)
        %phyTxReqEntry Handles the requests from LL
        
        % Initialize the events
        events = obj.initEventArray;
        
        % Update the channel index
        obj.pChannelIndex = entity.data.ChannelIndex;
        
        events = [events obj.eventDestroy()];
    end
    
    % LL PDU to PHY entry
    function [entity, events] = linkLayerPDUEntry(obj, ~, entity, ~)
        %linkLayerPDUEntry Store the LL PDU in buffer and schedule a waveform
        %generate event
        
        % Initialize the events
        events = obj.initEventArray;
        
        % Ready to transmit a LL packet
        if (obj.pChannelIndex ~= -1) && (~obj.pTransmission)
            % Store the received LL PDU and access address
            obj.pLLPDU = entity.data.PDU;
            obj.pLLPDULen = entity.data.Length;
            obj.pAccessAddress = entity.data.AccessAddress;
            
            % Update the channel index in the PHY Tx module
            obj.pPHYTx.ChannelIndex = obj.pChannelIndex;
            
            % Schedule a waveform generate event
            events = [events obj.eventGenerate(obj.WaveformQueueID, 'generate', 0, 100)];
        end
        
        events = [events obj.eventDestroy()];
    end
    
    % Generate PHY waveform
    function [entity, events] = waveformGenerate(obj, ~, entity, ~)
        %waveformGenerate Generate the BLE PHY waveform using the  stored
        %LL PDU and access address
        
        % Initialize the events
        events = obj.initEventArray;
        
        % Generate BLE waveform
        [nextInvokeTime, bleWaveform] = run(obj.pPHYTx, 0, obj.pLLPDU(1:obj.pLLPDULen), ...
            obj.pAccessAddress);
        
        if ~isempty(bleWaveform)
            numSamples = length(bleWaveform);
            obj.pWaveformDuration = nextInvokeTime; % in microseconds
            waveformDuration = nextInvokeTime*1e-6; % in seconds
            
            % Initialize the waveform
            entity.data.Waveform(:) = 0 + 1i*0;
            % Update the generated waveform into the entity
            entity.data.Waveform(1:numSamples) = bleWaveform;
            entity.data.NumSamples = numSamples;
            % Update the sample rate
            entity.data.SampleRate = obj.pPHYTx.SampleRate;
            % Update node position
            entity.data.NodePosition = obj.NodePosition;
            % Update channel bandwidth
            entity.data.Bandwidth = obj.pPHYTx.ChannelBandwidth;
            % Update center frequency
            entity.data.CenterFrequency = bleFrequency(obj.pPHYTx);
            % Update node ID
            entity.data.SourceID = obj.NodeID;
            % Update samples per symbol
            entity.data.SamplesPerSymbol = obj.pPHYTx.SamplesPerSymbol;
            
            % Update the transmission flag
            obj.pTransmission = true;
            
            events = [events obj.eventGenerate(obj.DurationQueueID, 'generate', waveformDuration, 100)];
            
            % Forward the generated waveform to the output port connected
            % to the shared channel
            events = [events obj.eventForward('output', obj.OUTPUT_PORT_1_INDEX, 0)];
        else
            events = [events obj.eventDestroy()];
        end
    end
    
    % Waveform duration timer
    function [entity, events] = durationGenerate(obj, ~, entity, ~)
        % Initialize the events
        events = obj.initEventArray;

        % Invoke PHY Tx module after waveform duration
        [~, ~] = run(obj.pPHYTx, obj.pWaveformDuration, zeros(1, 0), zeros(1, 0));
        
        % Reset the transmission flag
        obj.pTransmission = false;
        
        events = [events obj.eventDestroy()]; 
    end
end

methods(Access = protected)
    function setupImpl(obj)
        % Create PHY Tx handle object
        obj.pPHYTx = helperBLEPHYTransmitter;
        % Update the Tx power
        obj.pPHYTx.TxPower = obj.TxPower;
        % Initialize the PHY Tx handle object
        init(obj.pPHYTx);
        
        % Initialize the LL PDU buffer
        obj.pLLPDU = zeros(obj.LLPDUMaxSize, 1); % 260 octets
        % Initialize the LL PDU length
        obj.pLLPDULen = 0;
        % Initialize the access address
        obj.pAccessAddress = zeros(obj.AccessAddressLen, 1); % 4 octets
        % Set rng seed
        rng(obj.NodeID);
    end
    
    function [st, I, O] = getEntityStorageImpl(obj)
        % Initialize the queue size for the different entities
        LLPDUQueueSize = 1;
        PhyTxReqQueueSize = 1;
        WaveformQueueSize = 1;
        DurationQueueSize = 1;
        
        % Creates the internal storage queues and associate those input and
        % output ports.
        st = [obj.queueFIFO('phyTxReq', PhyTxReqQueueSize), obj.queueFIFO('linkLayerPDU', LLPDUQueueSize), ...
            obj.queueFIFO('waveform', WaveformQueueSize), ...
            obj.queueFIFO('duration', DurationQueueSize)];
        
        % Define the storage types at the input/output ports
        I = [obj.PhyTxReqQueueID obj.LLPDUQueueID];
        O = obj.WaveformQueueID;
    end
    
    function [inTypes, outTypes] = getEntityPortsImpl(~)
        % Specifies input and output port data types and complexity
        inTypes = {'phyTxReq', 'linkLayerPDU'};
        outTypes = {'waveform'} ;
    end
    
    function entityTypes = getEntityTypesImpl(obj)
        % Specifies the entity types used inside this class
        entityTypes = [obj.entityType('phyTxReq', 'LLPHYTxRequest'), ...
            obj.entityType('linkLayerPDU', 'LinkLayerPDU'), ...
            obj.entityType('waveform', 'BLEWaveform'), ...
            obj.entityType('duration', 'double', [1, 1], false)];
    end
    
    function num = getNumInputsImpl(~)
        % PHY Tx block contains 2 input ports. One is for LL requests to
        % PHY and the other is for input PDU from LL.
        num = 2;
    end
    
    function num = getNumOutputsImpl(~)
        % PHY Tx block contains one output port is to transmit the
        % generated waveform to the shared channel.
        num = 1;
    end
    
    function [input1, input2] = getInputNamesImpl(~)
        % Names given to the input ports
        input1 = 'phyTxReq';
        input2 = 'linkLayerPDU';
    end
    
    function output = getOutputNamesImpl(~)
        % Name given to the output port
        output = 'waveform';
    end
    
    function releaseImpl(obj)
        % Release resources and update the statistics to base workspace
        
        % Declare function as extrinsic
        coder.extrinsic('helperBLEMeshUpdateStatistics');
        
        % Get PHY Tx statistics from handle object
        transmittedSignals = obj.pPHYTx.TransmittedSignals;
        transmittedBits = obj.pPHYTx.TransmittedBits;
       
        % Update respective layer statistics based on node ID
        opcode = 1; % For updating the statistics table
        helperBLEMeshUpdateStatistics(opcode, obj.NodeID, 'PHYTx', [transmittedSignals transmittedBits]); 
    end
end

methods(Access = protected, Static)
    function flag = showSimulateUsingImpl(~)
        % Simulation mode is hidden in System block dialog
        flag = false;
    end
end
end
