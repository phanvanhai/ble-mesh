classdef helperBLEChannelDES < matlab.DiscreteEventSystem
%helperBLEChannelDES Apply channel model on the received BLE waveform
%
%   This is an example helper Discrete Event System class.
%
%   This object performs the range propagation loss and free-space path
%   loss on the received waveform.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Public, tunable properties
properties
    %RangePropagationLoss Range propagation loss
    %   Specify this property as one of 'On' | 'Off'. This property
    %   indicates whether the range propagation loss is enabled or disabled
    %   for this node. Signal strength is same within its receiving range.
    %   Signal strength becomes zero if the distance is outside the
    %   receiving range limits. The default value is 'On' (enabled).
    RangePropagationLoss = 'On'
    
    %FSPLModel Free-space path loss
    %   Specify this property as one of 'On' | 'Off'. This property
    %   indicates whether the free-space path loss is enabled or disabled
    %   for this node. Signal strength reduces as the distance is
    %   increasing. The default value is 'On' (enabled).
    FSPLModel = 'On'

    %RxRange Receiving range (meters)
    %   Specify Rx range as a scalar integer in the range [1, 400] meters.
    %   It defines the receiving range of the BLE node. The default value
    %   is 10 meters.
    RxRange (1, 1) {mustBeInteger, mustBePositive, mustBeLessThanOrEqual(RxRange, 400)} = 10
    
    %NodePosition Node position
    %   Specify the position of node position as a row-vector of integer
    %   values representing the three-dimensional coordinate. The 'z' value
    %   is not considered. The default value is [0 0 0].
    NodePosition (1, 3) {mustBeNumeric} = [0 0 0]
    
    %NodeID Node identifier
    %   Specify node identifier as an integer value representing the node.
    %   It is a unique identifier for the nodes in the network. The default
    %   value is 1.
    NodeID (1, 1) {mustBeInteger, mustBeGreaterThan(NodeID, 0)} = 1
end

properties(Access = private)
    %pChannel Handle for BLE channel model
    pChannel
    
    %pReception Flag to specify the receiver is on/off
    pReception = false
end

properties (Constant, Hidden)
    % Storage queue IDs
    PhyRxReqQueueID = 1;
    WaveformQueueID = 2;
    
    % Output port indexes
    OUTPUT_PORT_1_INDEX = 1;
    
    % Maximum number of IQ samples for a single waveform in LE1M mode
    % (considered up to 100 samples per symbol)
    WaveformMaxSize = 40000
    
    % Set of possible values
    RangePropagationLossSet = matlab.system.StringSet({'On', 'Off'});
    FSPLModelSet = matlab.system.StringSet({'On', 'Off'});
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
        %phyRxReqEntry Handles the requests from link layer
        
        % Initialize the events
        events = obj.initEventArray;
        
        % Update the reception flag
        obj.pReception = entity.data.Reception;
        
        % Switch on the reception
        if obj.pReception
            % Update the channel index and access address
            obj.pChannel.ChannelIndex = entity.data.ChannelIndex;
        end
        
        events = [events obj.eventDestroy()];
    end
    
    % Waveform entry from shared channel
    function [entity, events] = waveformEntry(obj, ~, entity, ~)
        %waveformEntry Schedule a waveform decode event
        
        % Initialize the events
        events = obj.initEventArray;
        % Switch on the reception and received waveform is not from the
        % self node
        if obj.pReception && (obj.NodeID ~= entity.data.SourceID)
            % Decode BLE waveform
            meshWaveform = run(obj.pChannel, ...
                entity.data.Waveform(1:entity.data.NumSamples), entity.data.CenterFrequency, ...
                entity.data.NodePosition);
            
            if ~isempty(meshWaveform)
                % Update the waveform after applying the channel models
                entity.data.NumSamples = numel(meshWaveform);
                entity.data.Waveform(1:entity.data.NumSamples) = meshWaveform;
                
                % Forward the waveform to the BLE PHY receiver after
                % applying the channel model on the received waveform
                events = [events obj.eventForward('output', obj.OUTPUT_PORT_1_INDEX, 0)];
            end
        end
        
        events = [events obj.eventDestroy()];
    end
end

methods(Access = protected)
    function setupImpl(obj)
        % Create BLE channel model object
        obj.pChannel = helperBLEChannel;
        
        % Update the receiving range
        obj.pChannel.RxRange = obj.RxRange;
        
        % Update the flag to perform range propagation loss
        if strcmp(obj.RangePropagationLoss, 'On')
            obj.pChannel.RangePropagationLoss = true;
        else
            obj.pChannel.RangePropagationLoss = false;
        end
        
        % Update the flag to perform free-space path loss
        if strcmp(obj.FSPLModel, 'On')
            obj.pChannel.FSPLModel = true;
        else
            obj.pChannel.FSPLModel = false;
        end
        
        % Update node position
        obj.pChannel.NodePosition = obj.NodePosition;
        
        % Set rng seed
        rng(obj.NodeID);
    end
    
    function [st, I, O] = getEntityStorageImpl(obj)
        % Initialize the queue size for the different entities
        PhyRxReqQueueSize = 1;
        WaveformQueueSize = 1;
        
        % Creates the internal storage queues and associate those input and
        % output ports.
        st = [obj.queueFIFO('phyRxReq', PhyRxReqQueueSize), ...
            obj.queueFIFO('waveform', WaveformQueueSize)];
        
        % Define the storage types at the input/output ports
        I = [obj.PhyRxReqQueueID obj.WaveformQueueID];
        O = [obj.WaveformQueueID];
    end
    
    function [inTypes, outTypes] = getEntityPortsImpl(~)
        % Specifies input and output port data types and complexity
        inTypes = {'phyRxReq', 'waveform'};
        outTypes = {'waveform'} ;
    end
    
    function entityTypes = getEntityTypesImpl(obj)
        % Specifies the entity types used inside this class
        entityTypes = [obj.entityType('phyRxReq', 'LLPHYRxRequest'), ...
            obj.entityType('waveform', 'BLEWaveform')];
    end
    
    function num = getNumInputsImpl(~)
        % Channel block contains 2 input ports. One is for link layer
        % requests to channel and the other is for input waveform from the
        % shared channel.
        num = 2;
    end
    
    function num = getNumOutputsImpl(~)
        % Channel block contains 1 output port. This port is used to
        % transmit the waveform to the PHY Rx block after applying the
        % channel model.
        num = 1;
    end
    
    function [input1, input2] = getInputNamesImpl(~)
        % Names given to the input ports
        input1 = 'phyRxReq';
        input2 = 'waveform';
    end
    
    function output1 = getOutputNamesImpl(~)
        % Name given to the output port
        output1 = 'waveform';
    end
end
end
