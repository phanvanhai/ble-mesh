classdef helperBLEMeshLLGAPBearer < handle
%helperBLEMeshLLGAPBearer Create an object for BLE LL advertising bearer
%   MESHLLGAP = helperBLEMeshLLGAPBearer creates a BLE Link Layer object
%   supporting communication over mesh advertising bearer using Generic
%   Access Profile (GAP).
%
%   MESHLLGAP = helperBLEMeshLLGAPBearer(Name, Value) creates a BLE Link
%   Layer object with the specified property Name set to the specified
%   Value. You can specify additional name-value pair arguments in any
%   order as (Name1, Value1, ..., NameN, ValueN).
%
%   helperBLEMeshLLGAPBearer properties:
%
%   AdvertisingInterval - Advertising interval for GAP broadcaster role
%   ScanInterval        - Scan interval for GAP observer role
%   RandomAdvertising   - Random advertising packet transmissions

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Public properties
properties
    %AdvertisingInterval Advertising interval for GAP broadcaster role
    %   Specify advertising interval as a scalar integer in the range [4,
    %   2097152]. It is used in transmitting the advertising packets in an
    %   advertising event. Advertising interval is an integer multiple of 5
    %   milliseconds (which is a multiple of 0.625 milliseconds) in the
    %   range of 20 milliseconds to 10485.75 seconds. The default value is
    %   4 (20 milliseconds).
    AdvertisingInterval = 4
    
    %ScanInterval Scan interval for GAP observer role
    %   Specify scan interval as a scalar integer in the range [1, 8192].
    %   It is used in scanning the advertising packets in scanning state.
    %   Scan interval is an integer multiple of 5 milliseconds (which is a
    %   multiple of 0.625 milliseconds) in the range of 5 milliseconds to
    %   40.96 seconds. The default value is 1 (5 milliseconds).
    ScanInterval = 1
    
    %RandomAdvertising Random advertising packet transmissions
    %   Specify this property as a scalar logical. A true value indicates
    %   that the random selection of advertising channels is enabled and it
    %   also indicates that the advertising packets are transmitted in
    %   three different channel advertising channels randomly by
    %   considering the maximum gap between two advertising instances is 10
    %   milliseconds. The default value is false.
    RandomAdvertising (1, 1) logical = false
end

% Constant, Hidden properties
properties (Constant, Hidden)    
    %USecPerMSec Microseconds for millisecond
    USecPerMSec = 1e3
end

% Private properties
properties (SetAccess = private)
    %SleepTime Time spent in sleep state in microseconds
    SleepTime = 0
    
    %IdleTime Time spent in standby state in microseconds
    IdleTime = 0
    
    %ListenTime Time spent in listening state in microseconds
    ListenTime = 0
    
    %TransmittedMsgs Number of messages transmitted
    TransmittedMsgs = 0
    
    %BytesTransmitted Number of bytes transmitted
    BytesTransmitted = 0
    
    %ReceivedMsgs Number of messages received
    ReceivedMsgs = 0
    
    %BytesReceived Number of bytes received
    BytesReceived = 0
    
    %NListenToSleep Number of state transitions from listen to sleep
    NListenToSleep = 0
    
    %NSleepToListen Number of state transitions from sleep to listen
    NSleepToListen = 0
    
    %CRCFailedMsgs Number of mesh messages received with CRC failures
    CRCFailedMsgs = 0
end

% Private properties
properties (SetAccess = private, Hidden)
    %pChannelIndex Index of the channel for reception or transmission
    pChannelIndex = -1
    
    %pGAPDataRxFlag Set to true when received GAP data block while scanning
    pGAPDataRxFlag = false
    
    %pState State of the Link Layer state machine
    % 0 - Standby
    % 1 - Scanning
    % 2 - Advertising
    pState = 0 % Default value is 'Standby'
    
    %pAccessAddress Default access address for advertising channels
    pAccessAddress = de2bi(hex2dec('8e89bed6'), 32)'
    
    %pMessageIdentifier Unique identifier for each network PDU
    pMessageIdentifier = [0; 0; 0; 0; 0] % Five octets
end

% Private properties
properties (Access = private)
    %pQueue Queue for storing messages from higher layers
    pQueue
    
    %pScanInterval Scan interval in microseconds
    pScanInterval = 0
    
    %pAdvertisingInterval Advertising interval in microseconds
    pAdvertisingInterval = 0
    
    %pAdvertisingDelay Delay between two consecutive advertising packet
    %transmissions in microseconds
    pAdvertisingDelay = 0
    
    %pEventTimer Timer for scan intervals or advertising events in
    %microseconds
    pEventTimer = 0

    %pRandomAdvertisingChannelList Statistical list of all possible
    %advertising channel sequences
    pRandomAdvertisingChannelList = [39 38 37; 39 37 38; 38 39 37; ...
        38 37 39; 37 39 38; 37 38 39]
    
    %pAdvertisingChannelList List of advertising channels
    pAdvertisingChannelList = [37; 38; 39]
    
    %pChannelSelectionCounter Index of advertising channel list
    pChannelSelectionCounter = 1
    
    %pAdvertisingInstances Advertising checkpoints
    % Divide the advertising interval into 3 checkpoint timestamps for
    % transmitting advertising packets in 3 advertising channels. The time
    % between two consecutive advertising packet transmissions must be less
    % than 10 milliseconds. Since 20 milliseconds is the minimum supported
    % advertising interval, three timestamps are considered between 1
    % millisecond and 20 milliseconds.
    pAdvertisingInstances = linspace(1, (3/4)*(20), 3)
    
    %pAdvertisingInstancesInUs Advertising instances in microseconds
    pAdvertisingInstancesInUs = zeros(1, 3)

    %pAdvertisingTimeTriggers Time triggers for events in advertising state
    pAdvertisingTimeTriggers
    
    %pAdvertisingTimeTriggerIdx Index for advertising time triggers
    pAdvertisingTimeTriggerIdx = 0
    
    %pActiveTimer Most recent time trigger for an event to occur
    pActiveTimer = 0    
end

% Hidden properties
properties (Hidden)
    %pAdvertising Link Layer is transmitting mesh messages
    pAdvertising = false

    %pGAPDataRx Received GAP data block while scanning
    pGAPDataRx
    
    %pGAPDataTx GAP data block to be transmitted while advertising
    pGAPDataTx
end

% Public methods
methods
    % Constructor
    function obj = helperBLEMeshLLGAPBearer(varargin)
        % Name value pairs
        for idx = 1:2:nargin
            obj.(varargin{idx}) = varargin{idx+1};
        end
        % Max size of network layer payload 33 octets
        maxElementSize = 33;
        maxQueueSize = 100;
        obj.pQueue = helperBluetoothQueue(maxQueueSize, maxElementSize);
        % For codegen
        obj.pGAPDataTx = zeros(1, 0);
        obj.pGAPDataRx = zeros(1, 0);
        obj.pAdvertisingTimeTriggers = zeros(1, 0);
    end
    
    % Set advertising interval
    function set.AdvertisingInterval(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 4, '<=', 2097152}, mfilename, ...
            'AdvertisingInterval');
        obj.AdvertisingInterval = value;
    end
    
    % Set scan interval
    function set.ScanInterval(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 1, '<=', 8192}, mfilename, 'ScanInterval');
        obj.ScanInterval = value;
    end
    
    % Set GAP data to be transmitted
    function set.pGAPDataTx(obj, value)
        % For codegen
        maxGAPDataSize = 31;
        obj.pGAPDataTx = zeros(maxGAPDataSize, 1);
        obj.pGAPDataTx = value;
    end
    
    % Set received GAP data
    function set.pGAPDataRx(obj, value)
        % For codegen
        maxGAPDataSize = 31;
        obj.pGAPDataRx = zeros(maxGAPDataSize, 1);
        obj.pGAPDataRx = value;
    end
    
    % Push GAP data block
    function flag = pushGAPData(obj, gapData)
        %pushGAPData Push GAP data block into link layer queue
        %
        %   FLAG = pushGAPData(OBJ, GAPDATA)
        %
        %   FLAG indicates status of enqueue whether success or failure.
        %
        %   GAPDATA is a column vector of decimal octets.
        
        % Validate GAP data block
        validateattributes(gapData, {'numeric'}, {'column', 'integer', ...
            'nonnegative', '<=', 255}, mfilename, 'gapData');
        
        % Push GAP data block into queue
        flag = obj.pQueue.enqueue(gapData);
        if ~flag
            fprintf('Queue is full at Link Layer advertising bearer.\n');
        end
    end
    
    % Initialize configuration
    function init(obj)
        %init Initialize link layer intervals
        
        % Scan interval in microseconds
        obj.pScanInterval = obj.ScanInterval * 5 * obj.USecPerMSec;
        % Advertising interval in microseconds
        obj.pAdvertisingInterval = obj.AdvertisingInterval * 5 * obj.USecPerMSec;
        % Random advertising channel index selection, refer Section
        % 4.4.2.2, PART B, Vol 6, Bluetooth core specification v5.1
        if obj.RandomAdvertising
            obj.pAdvertisingChannelList = obj.pRandomAdvertisingChannelList(randi([1 6]), :)';
        end
    end
    
    % Run link layer
    function [nextInvokeTime, output, channelIndex, rxFlag] = run(obj, elapsedTime, input, friendState)
        %run Runs link layer state machine
        %
        %   This function performs the following operations:
        %   1. Maintain link layer state machine supporting Broadcaster and
        %      Observer roles
        %   2. Transmit and decode advertising packets
        %
        %   [NEXTINVOKETIME, OUTPUT, CHANNELINDEX, RXFLAG] = run(OBJ,
        %   ELAPSEDTIME, INPUT) performs link layer actions.
        %
        %   NEXTINVOKETIME is the time (in microseconds) after which the
        %   run function should be invoked again.
        %
        %   OUTPUT is the link layer protocol data unit (PDU) appended with
        %   cyclic redundancy check (CRC) in binary format.
        %
        %   CHANNELINDEX is an integer indication channel on which the
        %   advertising packet is to be transmitted.
        %
        %   RXFLAG is an integer value:
        %   % -1 - No action
        %   %  0 - Stop reception
        %   %  1 - Start reception
        %
        %   ELAPSEDTIME is the time elapsed in microseconds between the
        %   previous and current call of this function.
        %
        %   INPUT is the link layer protocol data unit (PDU) appended with
        %   cyclic redundancy check (CRC) in binary format.
        %
        %   [NEXTINVOKETIME, OUTPUT, CHANNELINDEX, RXFLAG] = run(OBJ,
        %   ELAPSEDTIME, INPUT, FRIENDSTATE) performs link layer actions
        %   when Bluetooth mesh friend feature is enabled.
        %
        %   FRIENDSTATE is an integer value:
        %   % -1 - Friend feature disabled
        %   %  0 - Sleep state
        %   %  1 - Listen state
        %   %  2 - Transmission state
        %   %  3 - Friendship termination
        
        % Initialize
        nextInvokeTime = -1;
        output = zeros(1, 0);
        channelIndex = -1;
        rxFlag = -1;
        
        % Set decode success flag value false
        obj.pGAPDataRxFlag = false;
        
        % Validate number of input arguments
        narginchk(3, 4);
        if nargin < 4
            friendState = -1; % Friend feature is disabled
        end
        
        switch obj.pState
            % Standby
            case 0
                % Sleep flag for Low Power node
                sleepFlag = false;
                
                % Any messages received from upper-layers
                if isEmpty(obj.pQueue)
                    % Friend feature enabled
                    if (friendState ~= -1)
                        % Receive window at Low Power node. Listening for
                        % messages from Friend node
                        if (friendState == 1)
                            % Switch to 'Scanning' state
                            obj.pState = 1;
                            obj.NSleepToListen = obj.NSleepToListen + 1;
                            % Set event timer
                            obj.pEventTimer = obj.pScanInterval;
                            % Update next invoke time
                            nextInvokeTime = obj.pScanInterval;
                            % Update the channel index
                            nextAdvertisingChannel(obj);
                        else
                            % Update sleep flag
                            sleepFlag = true;
                            % Update sleep time
                            obj.SleepTime = obj.SleepTime + elapsedTime;
                        end
                    else
                        % Switch to 'Scanning' state
                        obj.pState = 1;
                        obj.NSleepToListen = obj.NSleepToListen + 1;
                        % Set event timer
                        obj.pEventTimer = obj.pScanInterval;
                        % Update the channel index
                        nextAdvertisingChannel(obj);
                        % Update next invoke time
                        nextInvokeTime = obj.pScanInterval;
                        % Start reception
                        rxFlag = 1;
                    end
                    
                    % Update idle time
                    if ~sleepFlag
                        obj.IdleTime = obj.IdleTime + elapsedTime;
                    end
                    
                else
                    % Switch to 'Advertising' state
                    obj.pState = 2;
                    % Random advertising channel index selection, refer Section
                    % 4.4.2.2, PART B, Vol 6, Bluetooth core specification v5.1
                    if obj.RandomAdvertising
                        obj.pAdvertisingChannelList = obj.pRandomAdvertisingChannelList(randi([1 6]), :)';
                    end
                    % Set channel selection counter
                    obj.pChannelSelectionCounter = 1;
                    % Choose advertising delay between 0 to 10 milliseconds
                    obj.pAdvertisingDelay = randi([0 10]) * obj.USecPerMSec;
                    % GAP data block for transmission
                    [~, obj.pGAPDataTx] = dequeue(obj.pQueue);
                    % Set event timer
                    obj.pEventTimer = obj.pAdvertisingInterval + obj.pAdvertisingDelay;
                    % Update advertising instances
                    obj.pAdvertisingInstancesInUs = obj.pEventTimer - (obj.pAdvertisingInstances * obj.USecPerMSec);
                    % Random advertising is enabled
                    if obj.RandomAdvertising
                        % Get random advertising instances
                        obj.pAdvertisingInstancesInUs = obj.pEventTimer - obj.getRandomAdvertisingInstances();
                    end
                    % Set advertising time triggers
                    obj.pAdvertisingTimeTriggers = sort([0 obj.pAdvertisingInstancesInUs]);
                    % Set advertising time trigger index
                    obj.pAdvertisingTimeTriggerIdx = numel(obj.pAdvertisingTimeTriggers);
                    % Set active timer
                    obj.pActiveTimer = obj.pAdvertisingTimeTriggers(obj.pAdvertisingTimeTriggerIdx);
                    % Update advertising time trigger index
                    obj.pAdvertisingTimeTriggerIdx = obj.pAdvertisingTimeTriggerIdx - 1;
                    % Update next invoke time
                    nextInvokeTime = obj.pEventTimer - obj.pActiveTimer;
                    % Stop reception
                    rxFlag = 0;
                end
                
            % Scanning
            case 1
                % Update listening time
                obj.ListenTime = obj.ListenTime + elapsedTime;
                % Update the event timer
                obj.pEventTimer = obj.pEventTimer - elapsedTime;
                
                % Perform passive scanning for the complete duration of
                % scan interval in one of the 3 advertising channels (37,
                % 38 and 39).
                % Refer Section 3.3.1, in the Bluetooth Specification of
                % the Mesh Profile v1.0.
                if obj.pEventTimer > 0
                    % Process the input message
                    if ~isempty(input)
                        % Decode Link Layer packet
                        [status, llCfg] = bleLLAdvertisingChannelPDUDecode(input);
                        % Received non-connectable non-scannable
                        % advertising indication
                        if status == blePacketDecodeStatus.Success && ...
                                strcmp(llCfg.PDUType, 'Advertising non connectable indication')
                            obj.pGAPDataRx = hex2dec(llCfg.AdvertisingData);
                            % Non-empty advertising data
                            if numel(obj.pGAPDataRx) > 2
                                % Update message identifier
                                obj.pMessageIdentifier = obj.pGAPDataRx(5:9, :);% For codegen
                            end
                            obj.pGAPDataRxFlag = true;
                        else
                            % Received mesh message with invalid CRC
                            if status == blePacketDecodeStatus.CRCFailed
                                obj.CRCFailedMsgs = obj.CRCFailedMsgs + 1;
                            end
                            obj.pGAPDataRx = zeros(1, 0);
                        end
                        % Update number of message receptions
                        obj.ReceivedMsgs = obj.ReceivedMsgs + 1;
                        obj.BytesReceived = obj.BytesReceived + numel(input)/8;
                    end
                    % Update next invoke time
                    nextInvokeTime = obj.pEventTimer;
                    
                else
                    % State transition to 'Standby'
                    obj.pState = 0;
                    obj.NListenToSleep = obj.NListenToSleep + 1;
                    % Reset event timer
                    obj.pEventTimer = 0;
                    % Update next invoke time
                    nextInvokeTime = 0;
                end
                
            % Advertising
            case 2
                % Set advertising flag
                obj.pAdvertising = true;
                % Update the event timer
                obj.pEventTimer = obj.pEventTimer - elapsedTime;
                
                % Transmit mesh messages in all the 3 advertising channels
                % (37, 38 and 39)
                if obj.pEventTimer > 0
                    if any(obj.pEventTimer == obj.pAdvertisingInstancesInUs)
                        % Update the channel index
                        nextAdvertisingChannel(obj);
                        % Return channel index
                        channelIndex = obj.pChannelIndex;
                        % Configure Link Layer non-connectable and
                        % non-scannable advertising indication
                        llCfg = bleLLAdvertisingChannelPDUConfig;
                        llCfg.PDUType = 'Advertising non connectable indication';
                        llCfg.AdvertisingData = obj.pGAPDataTx;
                        % Generate advertising channel PDU
                        output = bleLLAdvertisingChannelPDU(llCfg);
                        % Update number of message transmissions
                        obj.TransmittedMsgs = obj.TransmittedMsgs + 1;
                        obj.BytesTransmitted = obj.BytesTransmitted + numel(output)/8;
                    else
                        % Update idle time
                        obj.IdleTime = obj.IdleTime + elapsedTime;
                    end
                    
                    % Update active timer value
                    if obj.pAdvertisingTimeTriggerIdx > 0
                        if obj.pEventTimer == obj.pActiveTimer
                            obj.pActiveTimer = obj.pAdvertisingTimeTriggers(obj.pAdvertisingTimeTriggerIdx);
                            obj.pAdvertisingTimeTriggerIdx = obj.pAdvertisingTimeTriggerIdx - 1;
                        end
                    end
                    % Update next invoke time based active timer
                    nextInvokeTime = obj.pEventTimer - obj.pActiveTimer;
                    
                else
                    % State transition to 'Standby'
                    obj.pState = 0;
                    % Reset event timer
                    obj.pEventTimer = 0;
                    % Reset advertising flag
                    obj.pAdvertising = false;
                    % Update next invoke time
                    nextInvokeTime = 0;
                    % Reset advertising event index
                    obj.pAdvertisingTimeTriggerIdx = numel(obj.pAdvertisingTimeTriggers);
                end
        end
    end
end

% Private methods
methods (Access = private)
    % Get the next advertising channel indexes (37, 38 and 39)
    function nextAdvertisingChannel(obj)
        % After three channel selections
        if obj.pChannelSelectionCounter > 3
            obj.pChannelSelectionCounter = 1;
        end
        % Select channel index sequentially
        obj.pChannelIndex = obj.pAdvertisingChannelList(obj.pChannelSelectionCounter);
        % Update channel selection counter
        obj.pChannelSelectionCounter = obj.pChannelSelectionCounter + 1;
    end
    
    % Get random advertising instances
    function advInstances = getRandomAdvertisingInstances(obj)
        % Initialize the advertising instances with zeros
        advInstances = zeros(1, 3);
        initialGap = 1000;
        % Maximum gap between two advertising packet transmissions in
        % microseconds considered
        advGapInUs = 7000;
        
        % First advertising instance
        advInstances(1) = randi([initialGap advGapInUs]);
        % Second advertising instance
        advInstances(2) = randi([advInstances(1)+obj.USecPerMSec ...
            advInstances(1)+obj.USecPerMSec+advGapInUs]);
        % Third advertising instance
        advInstances(3) = randi([advInstances(2)+obj.USecPerMSec ...
            min(advInstances(2)+obj.USecPerMSec+advGapInUs, obj.pAdvertisingInterval)]);
    end
end
end
