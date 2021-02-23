classdef helperBLEMeshNetworkLayerDES < matlab.DiscreteEventSystem & matlab.system.mixin.SampleTime
%helperBLEMeshNetworkLayerDES Bluetooth mesh network layer
%
%   This is an example helper class (Discrete Event System). This object
%   performs the following operations:
%
%       * Generate and decode network PDU
%       * Transmit network PDU using advertising bearer network interface
%       * Relay network PDU using advertising bearer network interface
%       * Send decoded information to lower transport layer

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Public properties
properties
    %Relay Relay feature
    %   Specify this property as one of 'On' | 'Off'. This property
    %   indicates whether the relay feature is enabled or disabled for this
    %   node. The default value is 'Off' (disabled).
    Relay = 'Off'
    
    %ElementAddresses Unicast address of the element in node
    %   Specify the element addresses as a 2-byte decimal value. This
    %   property indicates the unicast address of the element within the
    %   node (supporting single element within a node). The default value
    %   is [0; 0].
    ElementAddresses = [0; 0]
    
    %NetworkTransmitCount Count of network transmissions
    %   Specify the network transmit count as an integer in the range [1,
    %   8]. This property controls the number of message transmission of
    %   the network message originating from the node. The default value is
    %   1.
    NetworkTransmitCount (1, 1) {mustBeInteger, ...
        mustBeGreaterThanOrEqual(NetworkTransmitCount, 1), ...
        mustBeLessThanOrEqual(NetworkTransmitCount, 8)} = 1
    
    %NetworkTransmitInterval Interval between network transmissions (ms)
    %   Specify the network transmit interval steps as an integer in the
    %   range [10, 320]. This property controls the interval between
    %   message transmissions of network messages originating from the
    %   node. The default value is 10 ms.
    NetworkTransmitInterval (1, 1) {mustBeInteger, ...
        mustBeGreaterThanOrEqual(NetworkTransmitInterval, 10), ...
        mustBeLessThanOrEqual(NetworkTransmitInterval, 320)} = 10
    
    %RelayRetransmitCount Count of relay retransmissions
    %   Specify the relay retransmit count as an integer in the range [1,
    %   8]. This property controls the number of message transmission of
    %   the network message relayed by the node. The default value is 1.
    RelayRetransmitCount (1, 1) {mustBeInteger, ...
        mustBeGreaterThanOrEqual(RelayRetransmitCount, 1), ...
        mustBeLessThanOrEqual(RelayRetransmitCount, 8)} = 1
    
    %RelayRetransmitInterval Interval between relay retransmissions (ms)
    %   Specify the relay retransmit interval steps as an integer in the
    %   range [10, 320]. This property controls the interval between
    %   message retransmissions of the network message relayed by the node.
    %   The default value is 10 ms.
    RelayRetransmitInterval (1, 1) {mustBeInteger, ...
        mustBeGreaterThanOrEqual(RelayRetransmitInterval, 10), ...
        mustBeLessThanOrEqual(RelayRetransmitInterval, 320)} = 10
    
    %NodeID Unique device identification number
    NodeID (1, 1) {mustBeInteger, mustBeGreaterThan(NodeID, 0)} = 1
end

% Private properties
properties(Access = private)
    %pNetworkLayer Bluetooth mesh network layer handle object
    %(helperBLEMeshNetworkLayer)
    pNetworkLayer
    
    %pNetworkPDU Network PDU to lower layer
    % Fixed size PDU (for codegen) with maximum length of network layer PDU
    % i.e. 29 bytes.
    pNetworkPDU = zeros(29, 1)
    
    %pNetworkPDULength Length of network PDU in 'pNetworkPDU'
    pNetworkPDULength = 0
    
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
    
    %LowerTransportPDUQueueID
    LowerTransportPDUQueueID = 1
    
    %NetworkPDUQueueID
    NetworkPDUQueueID = 2
    
    %NetworkLayerTimerQueueID
    NetworkLayerTimerQueueID = 3
    
    %NetworkLayerConfigQueueID
    NetworkLayerConfigQueueID = 4
    
    %RelaySet Set of possible values
    RelaySet = matlab.system.StringSet({'On ', 'Off'});
end

% Discrete-event algorithms
methods
    % Constructor
    function obj = helperBLEMeshNetworkLayerDES(~)
        % Initialize network layer object
        obj.pNetworkLayer = helperBLEMeshNetworkLayer();
    end
    
    % Set network transmit interval
    function set.NetworkTransmitInterval(obj, value)
        % Accept multiples of 10
        if rem(value, 10) ~= 0
            error('''NetworkTransmitInterval'' value must be a multiple of 10');
        end
        obj.NetworkTransmitInterval = value;
    end
    
    % Set relay retransmit interval
    function set.RelayRetransmitInterval(obj, value)
        % Accept multiples of 10
        if rem(value, 10) ~= 0
            error('''RelayRetransmitInterval'' value must be a multiple of 10');
        end
        obj.RelayRetransmitInterval = value;
    end
    
    % Set element address
    function set.ElementAddresses(obj, value)
        validateattributes(value, {'numeric'}, {'column', 'integer', ...
            'nonnegative', '<=', 255, 'nonempty'}, mfilename, 'ElementAddresses')
        if numel(value) ~= 2
            error('''ElementAddresses'' value must be specified as a 2-byte decimal vector');
        end
        obj.ElementAddresses = value;
    end
    
    % Set Node ID
    function set.NodeID(obj, value)
        % Validate node ID
        coder.extrinsic('helperBLEMeshValidateNodeID');
        helperBLEMeshValidateNodeID(value);
        obj.NodeID = value;
    end
    
    % Invoke network layer object
    function [entity, events] = networkLayerGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Schedule timer event
        events = [events, obj.eventTimer('invoke network handle', obj.pNextInvokeTime/obj.USecPerSec)];
    end
    
    % Specify events when timer completed
    function [entity, events] = networkLayerTimer(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Get elapsed time in microseconds
        elapsedTime = obj.getElapsedTime();
        
        % Empty Rx PDU
        networkPDU = zeros(1, 0);
        
        % Update flag as timer expired
        obj.pNextInvokeTime = -1;
        
        % Network layer invocation from DES
        events = obj.invokeNetworkLayerHandle(elapsedTime, networkPDU, events);
        
        % Store current simulation time indicating recent invoke time
        obj.pLastInvocationTime = obj.getCurrentTime();
        
        % Destroy entity
        events = [events, obj.eventDestroy()];
    end
    
    % Lower transport PDU entry action
    function [entity, events] = lowerTransportPDUEntry(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Get data from entity
        src =  reshape(dec2hex(entity.data.SourceAddress, 2)', 1, []);
        dst = reshape(dec2hex(entity.data.DestinationAddress, 2)', 1, []);
        ttl = entity.data.TTL;
        lowerTransportPDU = entity.data.PDU(1:entity.data.Length);
        ctl = entity.data.CTL;
        
        % Push to network layer queue
        obj.pNetworkLayer.pushUpperLayerPDU(src, dst, ttl, lowerTransportPDU, ctl);
        
        % Get elapsed time in microseconds
        elapsedTime = obj.getElapsedTime();
        
        % Empty Rx PDU
        networkPDU = zeros(1, 0);
        
        % Network layer invocation from DES
        events = obj.invokeNetworkLayerHandle(elapsedTime, networkPDU, events);
        
        % Store current simulation time indicating recent invoke time
        obj.pLastInvocationTime = obj.getCurrentTime();
        
        % Destroy entity
        events = [events, obj.eventDestroy()];
    end
    
    % Network PDU entry action
    function [entity, events] = networkPDUEntry(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Get elapsed time in microseconds
        elapsedTime = obj.getElapsedTime();
        
        % Non-empty Rx PDU
        networkPDU = entity.data.PDU(1:entity.data.Length);
        
        % Network layer invocation from DES
        events = obj.invokeNetworkLayerHandle(elapsedTime, networkPDU, events);
        
        % Store current simulation time indicating recent invoke time
        obj.pLastInvocationTime = obj.getCurrentTime();
        
        % Destroy entity
        events = [events, obj.eventDestroy()];
    end
    
    % Specify actions when network layer handle object is invoked
    function events = invokeNetworkLayerHandle(obj, elapsedTime, rxPDU, events)
        % Networks layer invocation from DES
        [nextInvokeTime, txPDU] = obj.pNetworkLayer.run(elapsedTime, rxPDU);
        
        % No active timer
        if nextInvokeTime >= 0 && nextInvokeTime ~= obj.pNextInvokeTime
            % Cancel old timer
            if obj.pNextInvokeTime ~= -1
                events = [events, obj.cancelTimer('invoke network handle')];
            end
            % Schedule timer generate event
            events = [events, obj.eventGenerate(obj.NetworkLayerTimerQueueID, 'Start timer', 0, obj.DefaultPriority)];
            % Store next invoke time
            obj.pNextInvokeTime = nextInvokeTime;
        end
        
        % PDU to transmit
        if ~isempty(txPDU)
            % Store link layer PDU
            obj.pNetworkPDULength = numel(txPDU);
            obj.pNetworkPDU(1:obj.pNetworkPDULength) = txPDU;
            % Schedule event for network PDU transmission
            events = [events, obj.eventGenerate(obj.NetworkPDUQueueID, 'Network PDU transmission', 0, obj.DefaultPriority)];
        end
        
        % Decoding success
        if obj.pNetworkLayer.pMessageDestinedToNode
            % Schedule an event to send the decoded information to
            % higher layer (lower transport layer)
            events = [events, obj.eventGenerate(obj.LowerTransportPDUQueueID, 'Network PDU reception', 0, obj.DefaultPriority)];
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
    
    % Lower transport PDU generate action
    function [entity, events] = lowerTransportPDUGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Lower transport PDU
        lowerTransportPDULength = numel(obj.pNetworkLayer.DecodedLowerTransportPDU);
        entity.data.PDU(1:lowerTransportPDULength) = obj.pNetworkLayer.DecodedLowerTransportPDU;
        entity.data.Length = lowerTransportPDULength;
        entity.data.CTL = obj.pNetworkLayer.pDecodedCTL;
        entity.data.TTL = obj.pNetworkLayer.pDecodedTTL;
        entity.data.SourceAddress = hex2dec(reshape(obj.pNetworkLayer.pDecodedSRC, 2, [])');
        entity.data.DestinationAddress = hex2dec(reshape(obj.pNetworkLayer.pDecodedDST, 2, [])');
        
        % Send lower transport PDU to higher layer (transport layer)
        events = [events, obj.eventForward('output', obj.LowerTransportPDUQueueID, 0)];
    end
    
    % Network PDU generate action
    function [entity, events] = networkPDUGenerate(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
        
        % Network PDU
        entity.data.PDU = obj.pNetworkPDU;
        entity.data.Length = obj.pNetworkPDULength;
        
        % Send network PDU to lower layer (link layer)
        events = [events, obj.eventForward('output', obj.NetworkPDUQueueID, 0)];
    end
    
    % edit: them khoi ben duoi
    function [entity,events] = configEntry(obj, ~, entity, ~)
        % Initialize events array
        events = obj.initEventArray();
                
        coder.extrinsic('fprintf');        
        switch entity.data.ConfigParam
            case 1                
                if entity.data.ConfigValue == 1                  
                    obj.Relay = 'On ';
                    obj.pNetworkLayer.Relay = true;
                else
                    obj.Relay = 'Off';
                    obj.pNetworkLayer.Relay = false;
                end                                                    
                fprintf('Network layer: Node:%f sets Relay feature:%s\n', obj.NodeID, obj.Relay);
        end
        % Destroy input entity
        events = [events, obj.eventDestroy()];
    end
end

% Protected methods
methods(Access = protected)
    % Perform setup operation
    function setupImpl(obj)        
        % Configure network layer parameters
        if strcmp(obj.Relay, 'On ')
            obj.pNetworkLayer.Relay = true;
        else
            obj.pNetworkLayer.Relay = false;
        end
        % Set network layer element address
        obj.pNetworkLayer.ElementAddresses = reshape(dec2hex(obj.ElementAddresses, 2)', 1, 4);
        % Set NetworkTransmitCount in handle based on specified count of
        % network transmissions, refer Bluetooth mesh profile v1.0, section
        % 4.2.19
        obj.pNetworkLayer.NetworkTransmitCount = obj.NetworkTransmitCount - 1;
        % Set NetworkTransmitIntervalSteps in handle based on specified
        % network transmit interval, refer Bluetooth mesh profile v1.0,
        % section 4.2.19. As the handle object accepts intervals as
        % multiple of 10 milliseconds
        obj.pNetworkLayer.NetworkTransmitIntervalSteps = (obj.NetworkTransmitInterval/10) - 1;
        % Set RelayRetransmitCount in handle based on specified count of
        % relay retransmissions, refer Bluetooth mesh profile v1.0, section
        % 4.2.20
        obj.pNetworkLayer.RelayRetransmitCount = obj.RelayRetransmitCount - 1;
        % Set RelayRetransmitIntervalSteps in handle based on specified
        % relay transmit interval, refer Bluetooth mesh profile v1.0,
        % section 4.2.20. As the handle object accepts intervals as
        % multiple of 10 milliseconds
        obj.pNetworkLayer.RelayRetransmitIntervalSteps = (obj.RelayRetransmitInterval/10) - 1;
        % Set rng seed
        rng(obj.NodeID);        
    end
    
    % Store network layer statistics
    function releaseImpl(obj)
        % Declare function as extrinsic
        coder.extrinsic('helperBLEMeshUpdateStatistics');
        
        % Update respective layer statistics based on node ID
        opcode = 1; % For updating the statistics table
        helperBLEMeshUpdateStatistics(opcode, obj.NodeID, 'NetworkLayer', ...
            [obj.pNetworkLayer.Relay obj.pNetworkLayer.MsgsTransmitted obj.pNetworkLayer.MsgsReceived ...
            obj.pNetworkLayer.MsgsForAppRx obj.pNetworkLayer.MsgsRelayed obj.pNetworkLayer.MsgsDropped]);
    end
    
    % Define types of entities used in this Discrete Event System
    function entityTypes = getEntityTypesImpl(obj)
        % Specifies the entity types are used inside the Discrete Event
        % System
        entityTypes = [...
            obj.entityType('networkPDU', 'NetworkPDU'), ...
            obj.entityType('lowerTransportPDU', 'LowerTransportPDU'), ...
            obj.entityType('networkLayer', 'double', [1, 1], false), ...
            obj.entityType('config', 'NetworkConfig')];  % edit: them dong nay
    end
    
    % Define types of input and output ports used in this Discrete Event
    % System
    function [inTypes, outTypes] = getEntityPortsImpl(~)
        % Specifies input and output port data types and complexity
        inTypes = {'lowerTransportPDU', 'networkPDU', 'config'}; % edit: 'them config'
        outTypes = {'lowerTransportPDU', 'networkPDU'};
    end
    
    % Define storage elements used in this Discrete Event System
    function [storage, input, output] = getEntityStorageImpl(obj)
        queueSize = 2;
        % Creates the internal storage queues and associate those input and
        % output ports.
        storage = [...
            obj.queueFIFO('lowerTransportPDU', queueSize), ...
            obj.queueFIFO('networkPDU', queueSize), ...
            obj.queueFIFO('networkLayer', queueSize), ...
            obj.queueFIFO('config', queueSize)  ];   % edit: them dong nay
        input = [obj.LowerTransportPDUQueueID, obj.NetworkPDUQueueID, obj.NetworkLayerConfigQueueID]; % edit: them 4
        output = [obj.LowerTransportPDUQueueID, obj.NetworkPDUQueueID];
    end
    
    % Define number of input ports used in this Discrete Event System
    function num = getNumInputsImpl(~)
        % This DES block contains 2 input ports. One is for PDU from lower
        % transport layer and the other is for PDU from bearer
                
        num = 3;  % edit: 2->3
    end
    
    % Define number of output ports used in this Discrete Event System
    function num = getNumOutputsImpl(~)
        % This DES block contains 2 output ports. One is for PDU to lower
        % transport layer and the other is for PDU to bearer
        num = 2;
    end
    
%     % Define names for input ports used in this Discrete Event System
%     function [input1, input2] = getInputNamesImpl(~)
%         % Specify names for input ports
%         input1 = 'lowerTransportPDU';
%         input2 = 'networkPDU';
%     end
    
    % edit: comment khoi tren, them khoi duoi
    % Define names for input ports used in this Discrete Event System
    function [input1, input2, input3] = getInputNamesImpl(~)
        % Specify names for input ports
        input1 = 'lowerTransportPDU';
        input2 = 'networkPDU';
        input3 = 'networkConfig';
    end

    % Define names for output ports used in this Discrete Event System
    function [output1, output2] = getOutputNamesImpl(~)
        % Specify names for output ports
        output1 = 'lowerTransportPDU';
        output2 = 'networkPDU';
    end
end
end