classdef helperBLEPHYRxDES < matlab.DiscreteEventSystem & matlab.system.mixin.SampleTime
%helperBLEPHYRxDES Receive and decode the BLE waveform
%
%   This is an example helper Discrete Event System class.
%
%   This object performs these operations on the received waveform:
%
%      * Handle requests from link layer (LL)
%      * Apply interference to the waveform
%      * Decode the waveform and send the decoded bits to LL

%   Copyright 2019 The MathWorks, Inc.

% Public, tunable properties
properties
    % Noise Figure (dB)
    %   Specify the noise figure as a scalar double nonnegative value. It
    %   is used in applying the thermal noise on the received waveform in
    %   dB. The default value is 0 dB.
    NoiseFigure (1, 1){mustBeNumeric, mustBeReal, mustBeNonnegative} = 0
    
    % Node identifier
    %   Specify node identifier as an integer value representing the node.
    %   It is a unique identifier for the nodes in the network. The default
    %   value is 1.
    NodeID (1, 1) {mustBeInteger, mustBeGreaterThan(NodeID, 0)} = 1
end

properties (Constant, Hidden)
    % Storage queue IDs
    PhyRxReqQueueID = 1;
    LLPDUQueueID = 2;
    WaveformQueueID = 3;
    
    % Output port indexes
    OUTPUT_PORT_1_INDEX = 1;
    
    % Maximum number of IQ samples for a single waveform in LE1M mode
    % (considered up to 100 samples per symbol)
    WaveformMaxSize = 40000
    
    % Access address length
    AccessAddressLen = 32; % in bits (4 octets)
end

properties(Access = private)
    %pPHYRx Handle for BLE PHY receiver
    pPHYRx
    
    %pWaveformDuration Duration for the reception of BLE waveform
    pWaveformDuration = 0 % in microseconds
    
    %pReception Flag to specify the receiver is on/off
    pReception = false
    
    %pSignal BLE signal along with metadata
    pSignal
    
    %pPrevEventTime Previous event time in microseconds
    pPrevEventTime = 0
end

methods
    % Set Node ID
    function set.NodeID(obj, value)
        % Validate node ID
        coder.extrinsic('helperBLEMeshValidateNodeID');
        helperBLEMeshValidateNodeID(value);
        obj.NodeID = value;
    end
    
    % LL to PHY indications entry
    function [entity, events] = phyRxReqEntry(obj, ~, entity, ~)
        %phyRxReqEntry Handles the requests from LL
        
        % Initialize the events
        events = obj.initEventArray;
        
        % Update the reception flag
        obj.pReception = entity.data.Reception;
        
        % Reception on
        if obj.pReception
            % Update the channel index and access address
            obj.pPHYRx.ChannelIndex = entity.data.ChannelIndex;
            obj.pPHYRx.AccessAddress = entity.data.AccessAddress;
        end
        
        events = [events obj.eventDestroy()];
    end
    
    % Waveform entry from shared channel
    function [entity, events] = waveformEntry(obj, ~, entity, ~)
        %waveformEntry Schedule a waveform decode event
        
        % Initialize the events
        events = obj.initEventArray;
        % Reception on
        if obj.pReception
            % Update the BLE waveform and metadata from the received entity
            obj.pSignal.Waveform = entity.data.Waveform;
            obj.pSignal.NumSamples = entity.data.NumSamples;
            obj.pSignal.SampleRate = entity.data.SampleRate;
            obj.pSignal.StartTime = getCurrentTime(obj)*1e6;
            obj.pSignal.SamplesPerSymbol = entity.data.SamplesPerSymbol;

            % Waveform decoding is not started
            if (~obj.pPHYRx.pProcessing)
                % Remove the interfered signals whose end time is less than
                % the start time of the currently processing waveform
                removeInterferedSignals(obj.pPHYRx, obj.pSignal.StartTime)
                
                % Update the samples per symbol value
                obj.pPHYRx.SamplesPerSymbol = entity.data.SamplesPerSymbol;
                
                % Decode BLE waveform
                [nextEventTime, ~, ~] = run(obj.pPHYRx, 0, obj.pSignal);
                obj.pWaveformDuration = nextEventTime; % in microseconds
                waveformDuration = nextEventTime*1e-6; % in seconds
                
                % Schedule a waveform decode event
                events = [events obj.eventGenerate(obj.LLPDUQueueID, 'generate', waveformDuration, 100)];
            % Waveform decoding is in progress
            else
                % Calculate the elapsed time in microseconds
                elapsedTime = getCurrentTime(obj)*1e6 - obj.pPrevEventTime;
                
                % Add received waveform as interference to the currently
                % decoding waveform
                [~, ~, ~] = run(obj.pPHYRx, elapsedTime, obj.pSignal);
                % Update the remaining waveform duration time
                obj.pWaveformDuration = obj.pWaveformDuration - elapsedTime; % in microseconds
            end
            % Update the previous event time
            obj.pPrevEventTime = obj.pSignal.StartTime;
        end
        
        events = [events obj.eventDestroy()];
    end
    
    % Decode PHY waveform
    function [entity, events] = linkLayerPDUGenerate(obj, ~, entity, ~)
        %linkLayerPDUGenerate Decode the BLE PHY waveform using the stored
        %access address
        
        % Initialize the events
        events = obj.initEventArray;
        
        % Update the BLE waveform and metadata
        obj.pSignal.NumSamples = 0;
        obj.pSignal.SampleRate = 0;
        
        % Decode BLE waveform
        [~, llPDU, accessAddress] = run(obj.pPHYRx, obj.pWaveformDuration, obj.pSignal);
        
        % Successfully decoded the received waveform
        if ~isempty(accessAddress) && ~isempty(llPDU)
            % Update the decoded access address
            entity.data.AccessAddress = accessAddress;
            % Update the LL PDU length
            entity.data.Length = numel(llPDU);
            % Update the decoded PDU
            entity.data.PDU(1:entity.data.Length) = llPDU;
            
            % Forward the decoded LL packet to the output port connected to
            % the LL and schedule a 'RxEnd' indication to LL after waveform
            % duration
            events = [events obj.eventForward('output', obj.OUTPUT_PORT_1_INDEX, 0)];
        % Failed to decode the received waveform
        else
            events = [events obj.eventDestroy()];
        end
    end
end

methods(Access = protected)
    function setupImpl(obj)
        % Create PHY Rx handle object
        obj.pPHYRx = helperBLEPHYReceiver;
        
        % Update noise figure
        obj.pPHYRx.NoiseFigure = obj.NoiseFigure;
        
        % Initialize BLE signal
        obj.pSignal = struct('Waveform', complex(zeros(obj.WaveformMaxSize, 1)), ...
                             'NumSamples', 0, ...
                             'SampleRate', 0, ...
                             'SamplesPerSymbol', 0, ...
                             'StartTime', 0, ...
                             'EndTime', 0);
                         
        % Set rng seed
        rng(obj.NodeID);
    end
    
    function [st, I, O] = getEntityStorageImpl(obj)
        % Initialize the queue size for the different entities
        LLPDUQueueSize = 1;
        PhyRxReqQueueSize = 1;
        WaveformQueueSize = 1;
        
        % Creates the internal storage queues and associate those input and
        % output ports.
        st = [obj.queueFIFO('phyRxReq', PhyRxReqQueueSize), obj.queueFIFO('linkLayerPDU', LLPDUQueueSize), ...
            obj.queueFIFO('waveform', WaveformQueueSize)];
        
        % Define the storage types at the input/output ports
        I = [obj.PhyRxReqQueueID obj.WaveformQueueID];
        O = obj.LLPDUQueueID;
    end
    
    function [inTypes, outTypes] = getEntityPortsImpl(~)
        % Specifies input and output port data types and complexity
        inTypes = {'phyRxReq', 'waveform'};
        outTypes = {'linkLayerPDU'} ;
    end
    
    function entityTypes = getEntityTypesImpl(obj)
        % Specifies the entity types used inside this class
        entityTypes = [obj.entityType('phyRxReq', 'LLPHYRxRequest'), ...
            obj.entityType('linkLayerPDU', 'LinkLayerPDU'), ...
            obj.entityType('waveform', 'BLEWaveform')];
    end
    
    function num = getNumInputsImpl(~)
        % PHY Rx block contains 2 input ports. One is for PHY responses to
        % LL and the other is for receiving waveform from the shared
        % channel.
        num = 2;
    end
    
    function num = getNumOutputsImpl(~)
        % PHY Rx block contains one output port is to transmit the bits to
        % the LL by decoding the waveform received from the shared channel.
        num = 1;
    end
    
    function [input1, input2] = getInputNamesImpl(~)
        % Names given to the input ports
        input1 = 'phyRxReq';
        input2 = 'waveform';    
    end
    
    function output = getOutputNamesImpl(~)
        % Name given to the output port
        output = 'linkLayerPDU';
    end
    
    function releaseImpl(obj)
        % Release resources and update the statistics to base workspace
        
        % Declare function as extrinsic
        coder.extrinsic('helperBLEMeshUpdateStatistics');
        
        % Get PHY Rx statistics from handle object
        receivedSignals = obj.pPHYRx.ReceivedSignals;
        receivedBits = obj.pPHYRx.ReceivedBits;
        totalCollisions = obj.pPHYRx.TotalCollisions;
        twoSignalsCollision = obj.pPHYRx.TwoSignalsCollision;
        threeSignalsCollision = obj.pPHYRx.ThreeSignalsCollision;
        fourSignalsCollision = obj.pPHYRx.FourSignalsCollision;
        
        % Update respective layer statistics based on node ID
        opcode = 1; % For updating the statistics table
        helperBLEMeshUpdateStatistics(opcode, obj.NodeID, 'PHYRx', [receivedSignals receivedBits totalCollisions ...
            twoSignalsCollision threeSignalsCollision fourSignalsCollision]);
    end
end

methods(Access = protected, Static)
    function flag = showSimulateUsingImpl(~)
        % Simulation mode is hidden in System block dialog
        flag = false;
    end
end
end
