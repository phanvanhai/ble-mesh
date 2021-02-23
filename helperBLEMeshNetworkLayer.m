classdef helperBLEMeshNetworkLayer < handle
%helperBLEMeshNetworkLayer Create an object for Bluetooth mesh network
%layer
%   MESHNET = helperBLEMeshNetworkLayer creates a Bluetooth mesh network
%   layer object with properties and methods related to network layer.
%
%   MESHNET = helperBLEMeshNetworkLayer(Name, Value) creates a Bluetooth
%   mesh network layer object with the specified property Name set to the
%   specified Value. You can specify additional name-value pair arguments
%   in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   helperBLEMeshNetworkLayer properties:
%
%   Relay                        - Relay feature support
%   ElementAddresses             - List of unicast addresses of the node
%   SubscriptionAddresses        - List of subscription addresses
%   LowPowerNodeAddresses        - List of Low Power node addresses
%   NetworkTransmitCount         - Count of network transmissions
%   NetworkTransmitIntervalSteps - Interval between network transmissions
%   RelayRetransmitCount         - Count of relay retransmissions
%   RelayRetransmitIntervalSteps - Interval between relay retransmissions

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Public properties
properties
    %Relay Relay feature support
    %   Specify this property as a scalar logical. A true value indicates
    %   that the relay feature is enabled for this node. The default value
    %   is false.
    Relay (1, 1) logical = false
    
    %ElementAddresses List of unicast addresses of the node
    %   Specify the element addresses as a four-element character vector or
    %   string scalar denoting a two-octet hexadecimal value or a cell
    %   array containing list of unicast addresses. This property indicates
    %   the unicast address of the elements within the node. The default
    %   value is '0000'.
    ElementAddresses = '0000'
    
    %SubscriptionAddresses List of subscription addresses
    %   Specify the subscription addresses as a four-element character
    %   vector or string scalar denoting a two-octet hexadecimal value or a
    %   cell array containing list of group addresses. This property
    %   indicates the list of subscription address of this node. The
    %   default value is 'FFFF' denoting the fixed group address for all
    %   the nodes in the Bluetooth mesh network.
    SubscriptionAddresses = 'FFFF'
    
    %LowPowerNodeAddresses List of Low Power node addresses
    %   Specify the Low Power node addresses as a four-element character
    %   vector or string scalar denoting a two-octet hexadecimal value or a
    %   cell array containing list of valid addresses. This property
    %   indicates the addresses of the Low Power node which are in
    %   Friendship with this node. The default value is '0000'.
    LowPowerNodeAddresses = '0000'
    
    %NetworkTransmitCount Count of network transmissions
    %   Specify the network transmit count as an integer in the range [0,
    %   7]. This property controls the number of message transmission of
    %   the network message originating from the node. The number of
    %   transmissions is (NetworkTransmitCount+1). The default value is 0
    %   (1 transmission).
    NetworkTransmitCount = 0
    
    %NetworkTransmitIntervalSteps Interval between network transmissions
    %   Specify the network transmit interval steps as an integer in the
    %   range [0, 31]. This property controls the interval between message
    %   transmissions of network messages originating from the node. Each
    %   unit is considered as 10 milliseconds so that the resultant
    %   transmission interval (NetworkTransmitIntervalSteps+1)*10. The
    %   default value is 0 (10 milliseconds).
    NetworkTransmitIntervalSteps = 0
    
    %RelayRetransmitCount Count of relay retransmissions
    %   Specify the relay retransmit count as an integer in the range [0,
    %   7]. This property controls the number of message transmission of
    %   the network message relayed by the node. The number of
    %   transmissions of a relayed packet is (RelayRetransmitCount+1). The
    %   default value is 0 (1 transmissions).
    RelayRetransmitCount = 0
    
    %RelayRetransmitIntervalSteps Interval between relay retransmissions
    %   Specify the relay retransmit interval steps as an integer in the
    %   range [0, 31]. This property controls the interval between message
    %   retransmissions of the network message relayed by the node. Each
    %   unit is considered as 10 milliseconds so that the resultant
    %   transmission interval (RelayRetransmitIntervalSteps+1)*10. The
    %   default value is 0 (10 milliseconds).
    RelayRetransmitIntervalSteps = 0
end

% Private properties
properties (Access = private)
    %pNetworkTxQueue Queue for storing application messages
    % Queue size can be varied based on the scale of network and it can be
    % updated in the constructor.
    pNetworkTxQueue
    
    %pRelayQueue Queue for storing relayed messages
    % Queue size can be varied based on the scale of network and it can be
    % updated in the constructor.
    pRelayQueue
    
    %pMessageCache Message cache
    % Queue size can be varied based on the scale of network and it can be
    % updated in the constructor.
    pMessageCache
    
    %pNetworkTransmission Network layer transmissions
    pNetworkTransmission
    
    %pSequenceNumber Sequence number maintained by network layer
    pSequenceNumber = 0
end
   
% Private properties
properties (SetAccess = private)
    %MsgsTransmitted Number of messages transmitted from this node
    MsgsTransmitted = 0
    
    %MsgsReceived Number of messages received by this node
    MsgsReceived = 0
    
    %MsgsForAppRx Number of application messages received by this node
    MsgsForAppRx = 0
    
    %MsgsRelayed Number of messages relayed from this node
    MsgsRelayed = 0
    
    %MsgsDropped Number of messages dropped by this node
    MsgsDropped = 0
end

% Private properties
properties (SetAccess = private, Hidden)
    %pTransmissionActive Flag indicating status of transmissions
    pTransmissionActive = false
    
    %pMessageRelayedFromNode Indicates that the received message has to be
    %relayed
    pMessageRelayedFromNode = false
    
    %pMessageDestinedToNode Indicates that the message is destined for this
    %node
    pMessageDestinedToNode = false
    
    %pMessageIdentifier Unique identifier for a mesh message (SEQ and SRC)
    pMessageIdentifier = [0;0;0;0;0] % Five octets
    
    %pDecodedSRC Decoded source address value
    pDecodedSRC = '0000'
    
    %pDecodedDST Decoded destination address value
    pDecodedDST = '0000'
    
    %pDecodedCTL Decoded ctl field in the message
    pDecodedCTL = 0
    
    %pDecodedTTL Decoded ttl field in the message
    pDecodedTTL = 0
end

% Constant, Hidden properties
properties (Constant, Hidden)
    %USecPerMSec Microseconds for millisecond
    USecPerMSec = 1e3
end

% Hidden properties
properties (Hidden)
    %TypeOfTransmittingPDU PDU type given to advertising bearer interface
    TypeOfTransmittingPDU
    
    %PDUToTransmit PDU to be transmitted
    PDUToTransmit
    
    %DecodedLowerTransportPDU Decoded lower transport PDU
    DecodedLowerTransportPDU
end

% Public methods
methods
    % Constructor
    function obj = helperBLEMeshNetworkLayer(varargin)
        % Assign name-value pairs
        for idx = 1:2:nargin
            obj.(varargin{idx}) = varargin{idx+1};
        end
        % Max size of network layer queue 33 octets
        maxElementSize = 33;
        maxQueueSize = 100;
        maxCacheSize = 1000;
        obj.pNetworkTxQueue = helperBluetoothQueue(maxQueueSize, maxElementSize);
        obj.pRelayQueue = helperBluetoothQueue(maxQueueSize, maxElementSize);
        obj.pMessageCache = helperBluetoothQueue(maxCacheSize, maxElementSize);
        obj.pNetworkTransmission = helperBLEMeshRetransmissions('Count',1,...
            'Interval',10);
        % For codegen, assign default values in constructor
        obj.TypeOfTransmittingPDU = 'Not relay';
        obj.PDUToTransmit = zeros(1, 0);
        obj.DecodedLowerTransportPDU = zeros(1, 0);
    end
    
    % Set element address
    function set.ElementAddresses(obj, value)
        if iscell(value)
            for idx = 1:numel(value)
                ble.internal.validateHex(value{idx}, 4, 'ElementAddress');
                isUnicastAddress = validateAddresses(value{idx}, 'Unicast Address');
                if ~isUnicastAddress
                    fprintf('Element address must be a unicast address.\n');
                    return;
                end
            end
        else
            ble.internal.validateHex(value, 4, 'ElementAddress');
            isUnicastAddress = validateAddresses(value, 'Unicast Address');
            if ~isUnicastAddress
                fprintf('Element address must be a unicast address.\n');
                return;
            end
        end     
        obj.ElementAddresses = value;
    end

    % Set subscription address
    function set.SubscriptionAddresses(obj, value)
        if iscell(value)
            for idx = 1:numel(value)
                ble.internal.validateHex(value{idx}, 4, 'SubscriptionAddress');
                isGroupAddress = validateAddresses(value{idx}, 'Group Address');
                isVirtualAddress = validateAddresses(value{idx}, 'Virtual Address');
                if ~isGroupAddress && ~isVirtualAddress
                    fprintf('Subscription address must be a group address or a virtual address.\n');
                    return;
                end
            end
        else
            ble.internal.validateHex(value, 4, 'SubscriptionAddress');
            isGroupAddress = validateAddresses(value, 'Group Address');
            isVirtualAddress = validateAddresses(value, 'Virtual Address');
            if ~isGroupAddress && ~isVirtualAddress
                fprintf('Subscription address must be a group address or a virtual address.\n');
                return;
            end
        end
        obj.SubscriptionAddresses = value;
    end
    
    % Set Low Power node addresses
    function set.LowPowerNodeAddresses(obj, value)
        if iscell(value)
            for idx = 1:numel(value)
                ble.internal.validateHex(value{idx}, 4, 'LowPowerNodeAddress');
            end
        else
            ble.internal.validateHex(value, 4, 'LowPowerNodeAddress');
        end
        obj.LowPowerNodeAddresses = value;
    end

    % Set network transmit count
    function set.NetworkTransmitCount(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 0, '<=', 7}, mfilename, 'NetworkTransmitCount');
        obj.NetworkTransmitCount = value;
    end
    
    % Set network transmit interval
    function set.NetworkTransmitIntervalSteps(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 0, '<=', 31}, mfilename, ...
            'NetworkTransmitIntervalSteps');
        obj.NetworkTransmitIntervalSteps = value;
    end
    
    % Set relay retransmit count
    function set.RelayRetransmitCount(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 0, '<=', 7}, mfilename, 'RelayRetransmitCount');
        obj.RelayRetransmitCount = value;
    end
    
    % Set relay retransmit interval
    function set.RelayRetransmitIntervalSteps(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 0, '<=', 31}, mfilename, ...
            'RelayRetransmitIntervalSteps');
        obj.RelayRetransmitIntervalSteps = value;
    end 
    
    % Set type of transmitting PDU
    function set.TypeOfTransmittingPDU(obj, value)
        %  For codegen
        obj.TypeOfTransmittingPDU = blanks(0);
        obj.TypeOfTransmittingPDU = value;
    end
    
    % Set PDU to transmit
    function set.PDUToTransmit(obj, value)
        % For codegen
        maxNetworkPDUSize = 29;
        obj.PDUToTransmit = zeros(maxNetworkPDUSize, 1);
        obj.PDUToTransmit = value;
    end
    
    % Set decoded lower transport PDU
    function set.DecodedLowerTransportPDU(obj, value)
        % For codegen
        maxNetworkPDUSize = 29;
        obj.DecodedLowerTransportPDU = zeros(maxNetworkPDUSize, 1);
        obj.DecodedLowerTransportPDU = value;
    end
    
    % Run network layer
    function [nextInvokeTime, txPDU] = run(obj, elapsedTime, rxPDU)
        %run Runs mesh network layer
        %
        %   This function performs the following operations:
        %       * Generate network PDU from lower transport PDU
        %       * Decode network PDU
        %       * Transmit network PDU using advertising bearer network
        %         interface
        %       * Relays network PDU using advertising bearer network
        %         interface
        %       * Forward decoded information to lower transport layer
        %
        %   [NEXTINVOKETIME, TXPDU] = run(OBJ, ELAPSEDTIME,
        %   RXPDU) performs network layer actions.
        %
        %   NEXTINVOKETIME is the time (in microseconds) after which the
        %   run function should be invoked again.
        %
        %   TXPDU is the output network PDU to advertising bearer,
        %   specified as a column vector of decimal octets.
        %
        %   ELAPSEDTIME is the time elapsed in microseconds between the
        %   previous and current call of this function.
        %
        %   RXPDU is the input network PDU from advertising bearer,
        %   specified as a column vector of decimal octets.
        
        % Initialize
        nextInvokeTime = -1;
        txPDU = zeros(1, 0);
        obj.pMessageDestinedToNode = false;
        obj.pMessageRelayedFromNode = false;
        obj.pMessageIdentifier = [0;0;0;0;0];
        
        % Non-empty rxPDU
        if ~isempty(rxPDU)
            % Messages received by node
            obj.MsgsReceived = obj.MsgsReceived + 1;
            
            % Check for minimum PDU length, as specified in Bluetooth mesh
            % profile v1.0, section 3.4.4. Considering only ten octets, as
            % security is not considered and NetMIC is excluded in PDU.
            if numel(rxPDU) >= 10
                % Network layer rx
                relayedPDU = obj.networkLayerRx(rxPDU);
                
                % If message to be relayed
                if ~isempty(relayedPDU)
                    % Push into relay queue
                    obj.pRelayQueue.enqueue(relayedPDU);
                end
            else
                % Update number of messages dropped by the node
                obj.MsgsDropped = obj.MsgsDropped + 1;
            end
        end
        
        % Check for transmissions in progress from advertising bearer
        % network interface. If transmission is pending, cannot send new
        % packet from network layer. Refer Bluetooth mesh profile v1.0,
        % section 3.4.5.4
        if obj.pTransmissionActive
            [nextInvokeTime, txPDU] = obj.networkLayerAdvertisingBearerInterface(elapsedTime);
        
        % Transmit new messages from relay and input queues
        else
            % Non-empty relay queue
            if ~(obj.pRelayQueue.isEmpty)
                % Pop out message, handover to advertising bearer network
                % interface
                [isDataInQueue, data] = obj.pRelayQueue.dequeue();
                if isDataInQueue
                    obj.TypeOfTransmittingPDU = 'Relay';
                    obj.PDUToTransmit = data;
                    obj.pTransmissionActive = true;
                    % Use relay retransmit state, as specified in Bluetooth
                    % mesh profile v1.0, section 4.2.20
                    obj.pNetworkTransmission.Count = obj.RelayRetransmitCount + 1;
                    obj.pNetworkTransmission.Interval = ((obj.RelayRetransmitIntervalSteps + 1) * 10) * obj.USecPerMSec; % In microseconds
                    [nextInvokeTime, txPDU] = obj.networkLayerAdvertisingBearerInterface(elapsedTime);
 
                    % Messages relayed by node
                    obj.MsgsRelayed = obj.MsgsRelayed + 1;
                end
                
            % Non-empty network queue
            elseif ~(obj.pNetworkTxQueue.isEmpty)
                % Pop out message, handover to advertising bearer network
                % interface
                [isDataInQueue, data] = obj.pNetworkTxQueue.dequeue();
                if isDataInQueue
                    obj.TypeOfTransmittingPDU = 'Not relay';
                    obj.PDUToTransmit = data;
                    obj.pTransmissionActive = true;
                    % Use network transmit state, as specified in Bluetooth
                    % mesh profile v1.0, section 4.2.19
                    obj.pNetworkTransmission.Count = obj.NetworkTransmitCount + 1;
                    obj.pNetworkTransmission.Interval = ...
                        (((obj.NetworkTransmitIntervalSteps + 1) * 10) + randi([1 10])) * obj.USecPerMSec; % In microseconds

                    [nextInvokeTime, txPDU] = obj.networkLayerAdvertisingBearerInterface(elapsedTime);
                    
                    % Messages transmitted by node
                    obj.MsgsTransmitted = obj.MsgsTransmitted + 1;
                end
            end
        end
        
        % Interface output filter (applies filtering rules), pass txPDU to
        % bearer
    end
    
    % Append network header to lower transport PDU, push into network queue
    function isSuccess = pushUpperLayerPDU(...
            obj, src, dst, ttl, lowerTransportPDU, ctl)
        %pushUpperLayerPDU Push upper layer PDU into network layer queue
        %
        %   ISSUCCESS = pushUpperLayerPDU(OBJ, SRC, DST, TTL,
        %   LOWERTRANSPORTPDU, CTL)
        %
        %   ISSUCCESS indicates status of enqueue whether success or
        %   failure
        %
        %   SRC, DST are 4-element character vectors
        %
        %   TTL is an integer value
        %
        %   LOWERTRANSPORTPDU is a column vector of decimal octets
        %
        %   CTL is binary value
        
        % Initialize
        isSuccess = false;
        
        % Validate inputs, as specified in Bluetooth mesh profile v1.0,
        % section 3.4.4.4
        isValid = obj.networkLayerCheckAddressValidity(src, dst, ctl);
        if ~isValid
            return;
        end
        validateattributes(ttl, {'numeric'}, {'scalar', ...
            'integer', '>=', 0, '<=', 127}, mfilename, 'TTL');
        validateattributes(lowerTransportPDU, {'numeric'}, ...
            {'column', 'nonnegative', 'integer', '<=', 255}, ...
            mfilename, 'LowerTransportPDU');
        if ctl
            validateattributes(numel(lowerTransportPDU), {'numeric'}, ...
                {'integer', '<=', 12}, mfilename, 'LowerTransportPDU');
        else
            validateattributes(numel(lowerTransportPDU), {'numeric'}, ...
                {'integer', '<=', 16}, mfilename, 'LowerTransportPDU');
        end
        
        % Form network PDU
        networkPDU = helperBLEMeshNetworkPDU(...
            src, dst, obj.pSequenceNumber, ttl, lowerTransportPDU, ctl);
        
        % Update sequence number at network layer
        obj.pSequenceNumber = obj.pSequenceNumber + 1;
        
        % Push PDU to network tx queue
        isSuccess = obj.pNetworkTxQueue.enqueue(networkPDU);
    end
end

% Private methods
methods (Access = private)
    % Network layer Rx
    function relayedPDU = networkLayerRx(obj, networkPDU)
        % Initialize
        relayedPDU = zeros(1, 0);
        isMsgConsidered = false;
        
        % Network authentication and decryption
        
        % Interface input filter (applies filtering rules)
        
        % Message cache, as specified in Bluetooth mesh profile v1.0,
        % section 3.4.6.5
        isAlreadyCached = obj.networkLayerMessageCache(networkPDU);
        % Discard, if already in cache
        if isAlreadyCached
            obj.MsgsDropped = obj.MsgsDropped + 1;
            return;
        end
        
        % Decode network PDU
        [src, dst, seq, ttl, lowerTransportPDU, ctl] = ...
            helperBLEMeshNetworkPDUDecode(networkPDU);
        
        % Validate address, as specified in Bluetooth mesh profile v1.0,
        % section 3.4.3
        isValid = obj.networkLayerCheckAddressValidity(src, dst, ctl);
        if ~isValid
            obj.MsgsDropped = obj.MsgsDropped + 1;
            return;
        end
        
        % Destination address is a unicast address of an element on this
        % node or its Friend address
        if any(strcmp(dst, obj.ElementAddresses)) ...
                || any(strcmp(dst, obj.LowPowerNodeAddresses))
            % If message is to be considered for further processing, forward decoded
            % information (src, dst, seq, ttl, lowerTransPDU, ctl) to upper
            % layer
            isMsgConsidered = true;
            
        elseif any(strcmp(dst, obj.SubscriptionAddresses))
            % If message to be considered for further processing, forward decoded
            % information (src, dst, seq, ttl, lowerTransPDU, ctl) to upper
            % layer
            isMsgConsidered = true;
            
            % Relay
            if obj.Relay
                relayedPDU = obj.networkLayerRelay(...
                    src, dst, seq, ttl, lowerTransportPDU, ctl);
            end
            
        % Destination address is not a unicast address of this node
        else
            % Relay
            if obj.Relay
                relayedPDU = obj.networkLayerRelay(...
                    src, dst, seq, ttl, lowerTransportPDU, ctl);
            
            % Drop the message
            else
                % Messages dropped at node
                obj.MsgsDropped = obj.MsgsDropped + 1;
            end
        end
        
        % Message considered for further processing
        if isMsgConsidered
            % Update flag
            obj.pMessageDestinedToNode = true;
            
            % Update statistics
            obj.MsgsForAppRx = obj.MsgsForAppRx + 1;
            
            % Update decoded configuration
            obj.pDecodedSRC = src;
            obj.pDecodedDST = dst;
            obj.pDecodedCTL = ctl;
            obj.pDecodedTTL = ttl;
            obj.DecodedLowerTransportPDU = lowerTransportPDU;
        end
    end
    
    % Message cache
    function isAlreadyCached = networkLayerMessageCache(obj, networkPDU)
        % Select unique part of network PDU to cache, considering 5 octets
        % (SEQ and SRC)
        obj.pMessageIdentifier = networkPDU(3:7);
        isAlreadyCached = false;
        % If PDU is cached
        if ~obj.pMessageCache.isEmpty
            isAlreadyCached = obj.pMessageCache.hasValue(obj.pMessageIdentifier);
        end

        % If PDU is not already cached, push into message cache
        if ~isAlreadyCached
            % If queue is full, discard oldest entry
            if obj.pMessageCache.isFull
                [~, ~] = obj.pMessageCache.dequeue();
            end
            obj.pMessageCache.enqueue(obj.pMessageIdentifier);
        end
    end
    
    % Address validity
    function isValid = networkLayerCheckAddressValidity(~, src, dst, ctl)
        % Initialize
        isValid = true;
        
        % Validate
        ble.internal.validateHex(src, 4, 'SourceAddress');
        ble.internal.validateHex(dst, 4, 'DestinationAddress');
        validateattributes(ctl, {'numeric'}, {'scalar', 'binary'}, ...
            mfilename, 'CTL');
        
        % Source address should be unicast address
        isUnicastAddress = validateAddresses(src, 'Unicast Address');
        % Discard
        if ~isUnicastAddress
            isValid = false;
        end
        
        % For control message, destination address cannot be unassigned or
        % virtual address
        if ctl
            isUnassignedAddress = validateAddresses(dst, 'Unassigned Address');
            isVirualAddress = validateAddresses(dst, 'Virtual Address');
            % Discard
            if isUnassignedAddress || isVirualAddress
                isValid = false;
            end
            
        % For access message, destination address cannot be unassigned
        % address
        else
            isUnassignedAddress = validateAddresses(dst, 'Unassigned Address');
            % Discard
            if isUnassignedAddress
                isValid = false;
            end
        end
    end
    
    % Relay (message flooding)
    function relayedPDU = networkLayerRelay(...
            obj, src, dst, seq, ttl, lowerTransportPDU, ctl)
        % TTL should be more than 2, for being relayed
        if ttl < 2
            % Messages dropped at node
            obj.MsgsDropped = obj.MsgsDropped + 1;
            relayedPDU = zeros(1, 0);
            return;
        end
        
        % Update TTL
        ttl = ttl - 1;
        
        % Relay the message
        relayedPDU = helperBLEMeshNetworkPDU(...
            src, dst, seq, ttl, lowerTransportPDU, ctl);
        % Update flag to indicate that the message is relayed
        obj.pMessageRelayedFromNode = true;
    end
    
    % Advertising bearer network interface
    function [nextEventTime, pdu] = networkLayerAdvertisingBearerInterface(obj, elapsedTime)
        % Initialize
        pdu = zeros(1, 0);
        
        % Run retransmission timer
        [nextEventTime, transmit, stopTransmission] = obj.pNetworkTransmission.runRtx(elapsedTime);
        
        % Transmissions
        if transmit
            pdu = obj.PDUToTransmit;
        end
        
        % Stop timer, update flag
        if stopTransmission
            obj.pTransmissionActive = false;
            obj.PDUToTransmit = zeros(1, 0);
        end
    end
end
end

% Check whether given address matches with the specified type or not
function isAddressMatchWithType = validateAddresses(address, type)
% Initialize
isAddressMatchWithType = false;
% Convert address to binary
addressBinary = de2bi(hex2dec(address), 16, 'left-msb');

% Based on type of address
switch type
    case 'Unicast Address'
        if addressBinary(1) == 0 && sum(addressBinary) ~= 0
            isAddressMatchWithType = true;
        end
    case 'Virtual Address'
        if addressBinary(1) == 1 && addressBinary(2) == 0
            isAddressMatchWithType = true;
        end
    case 'Group Address'
        if addressBinary(1) == 1 && addressBinary(2) == 1
            isAddressMatchWithType = true;
        end
    case 'Unassigned Address'
        if sum(addressBinary) == 0
            isAddressMatchWithType = true;
        end
end
end
