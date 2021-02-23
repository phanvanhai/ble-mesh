classdef helperBLEChannel < handle
%helperBLEChannel Create an object for BLE channel model
%   BLECHANNEL = helperBLEChannel creates an object for BLE channel model.
%   This class performs the range propagation loss and free-space path loss
%   on the given waveform.
%
%   BLECHANNEL = helperBLEChannel(Name, Value) creates a BLE channel
%   model object with the specified property Name set to the specified
%   Value. You can specify additional name-value pair arguments in any
%   order as (Name1, Value1, ..., NameN, ValueN).
%
%   helperBLEChannel properties:
%
%   ChannelIndex            - BLE channel index for receiving the link
%                             layer (LL) PDU
%   RxRange                 - Receiving range of BLE node in meters
%   RangePropagationLoss    - Enable/disable range propagation loss
%   FSPLModel               - Enable/disable free-space path loss
%   NodePosition            - Coordinates (x, y, z) of the node

%   Copyright 2019 The MathWorks, Inc.

%#codegen

properties
    %ChannelIndex BLE channel index for receiving the LL PDU
    %   Specify channel index as a scalar integer in the range [0, 39]. It
    %   defines the transmitting channel for LL PDUs. To receive LL data
    %   PDUs, channels 0 to 36 are used. Whereas, channels 37, 38 and 39
    %   are used to receive LL advertising PDUs. The default value is 37
    %   (advertising channel).
    ChannelIndex = 37
    
    %RxRange Receiving range of BLE node in meters
    %   Specify Rx range as a scalar integer in the range [1, 400] meters.
    %   It defines the receiving range of the BLE node. The default value
    %   is 10 meters.
    RxRange = 10
    
    %RangePropagationLoss Enable/disable range propagation loss
    %   Specify range propagation loss as a scalar boolean value. It
    %   defines whether to enable/disable the range propagation loss.
    %   Signal strength is same within its receiving range. Signal strength
    %   becomes zero if the distance is outside the receiving range. By
    %   default, range propagation loss is true (enabled).
    RangePropagationLoss (1, 1) logical = true
    
    %FSPLModel Enable/disable free-space path loss
    %   Specify free-space path loss model as a scalar boolean value. It
    %   defines whether to enable/disable the free-space path loss. Signal
    %   strength reduces as the distance is increasing. By default,
    %   free-space path loss is true (enabled).
    FSPLModel (1, 1) logical = true
        
    %NodePosition Coordinates (x, y, z) of the node
    %   Specify the position of node as a row-vector of integer values
    %   representing the three-dimensional coordinate. The 'z' value is not
    %   considered. The default value is [0 0 0].
    NodePosition = [0 0 0]
end

properties (Constant, Hidden)
    % BLE channels center frequencies in MHz
    % Refer Bluetooth Core Specification version 5.1, volume 6, part B,
    % Table 1.2
    ChannelCenterFrequencies = [2404:2:2424 2428:2:2478 2402 2426 2480]
    
    % Rx gain in dB
    RxGain = 0
    
    % Path loss exponent (to model the free-space path loss)
    PLExponent = 2
end

methods
    % Constructor
    function obj = helperBLEChannel(varargin)
        % Set name-value pairs
        for idx = 1:2:nargin
            obj.(varargin{idx}) = varargin{idx+1};
        end
    end
    
    % Set receiving range
    function set.RxRange(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', 'positive', '<=', 400}, mfilename, 'RxRange');
        obj.RxRange = value;
    end
    
    % Set channel index
    function set.ChannelIndex(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 0, '<=', 39}, mfilename, 'ChannelIndex');
        obj.ChannelIndex = value;
    end
    
    % Set node position
    function set.NodePosition(obj, value)
        validateattributes(value, {'numeric'}, {'row', 'real', ...
            'numel', 3}, mfilename, 'NodePosition');
        obj.NodePosition = value;
    end
    
    function bleWaveformOut = run(obj, bleWaveformIn, rxChannel, destinationNodePosition)
    %run Process the received BLE signal and return the signal after
    %passing through the channel
    %
    %   BLEWAVEFORMOUT = run(OBJ, BLEWAVEFORMIN, RXCHANNEL,
    %   DESTINATIONNODEPOSITION) process the received BLE signal and
    %   returns the signal after passing through the channel.
    %
    %   BLEWAVEFORMOUT returns the IQ samples of the waveform after passing
    %   through the channel.
    %
    %   BLEWAVEFORMIN specifies the IQ samples of the received waveform.
    %
    %   RXCHANNEL is the center frequency of the receiving BLE channel.
    %
    %   DESTINATIONNODEPOSITION is the location of the destination node.
    
        % Initialize
        bleWaveformOut = zeros(1, 0);
        
        % Calculate distance between the source and destination nodes in
        % meters
        distance = norm(destinationNodePosition - obj.NodePosition);
        
        % Get BLE channel index from the given center frequency
        rxChannelIndex = getChannelIndex(obj, rxChannel);
        
        % Check if channels match
        if obj.ChannelIndex == rxChannelIndex
            % Enable range propagation model
            if obj.RangePropagationLoss
                % Check if the BLE nodes are within their limits of receive
                % range
                if (distance <= obj.RxRange)
                    % Return the waveform
                    bleWaveformOut = bleWaveformIn;
                end
            % Disable range propagation model
            else
                % Return the waveform
                bleWaveformOut = bleWaveformIn;
            end
            
            % Enable free-space path loss model
            if ~isempty(bleWaveformOut) && obj.FSPLModel
                % Source and destination nodes are at the same location
                if distance ~= 0
                    % Get the linear scaling factor (alpha) after applying the
                    % free-space path loss
                    [~, alpha] = applyPathloss(obj, distance, rxChannel*1e6, ...
                        obj.PLExponent);
                    % Apply free-space path loss
                    bleWaveformOut = alpha * bleWaveformOut;
                end
            end
        end
    end
    
    function channelIndex = getChannelIndex(obj, centerFrequency)
    %getChannelIndex Return the BLE channel index corresponding to given
    %BLE channel center frequency (in MHz)
    %   CHANNELINDEX = getChannelIndex(OBJ, CENTERFREQUENCY) returns the
    %   channel index corresponding to the given BLE center frequency in
    %   MHz.
    %
    %   CHANNELINDEX returns the index of the BLE channel.
    %
    %   CENTERFREQUENCY is an integer representing the center frequency in
    %   MHz.
    
        % Get channel index from the given center frequency
        channelIndex = (find(obj.ChannelCenterFrequencies == centerFrequency))-1;
    end
end

methods (Access = private)
    function [rxPowerdB, alpha] = applyPathloss(obj, distance, ...
            centerFrequency, plExponent)
        %applyPathloss Return the linear scaling factor after modeling the
        %BLE path loss
        %
        %   [RXPOWERDB, ALPHA] = applyPathloss(OBJ, DISTANCE,
        %   CENTERFREQUENCY, PLEXPONENT) returns the linear scaling factor
        %   after modeling the BLE path loss.
        %
        %   RXPOWERDB returns the resultant Rx power in dB.
        %
        %   ALPHA returns the linear scaling factor to be applied on the
        %   received waveform.
        %
        %   DISTANCE is the distance between transmitter and receiver in
        %   meters.
        %
        %   CENTERFREQUENCY is an integer represents the center frequency
        %   in Hz.
        %
        %   PLEXPONENT is the path loss exponent as follows:
        %------------------------------------------------------------------
        %         Environment                    |   Path loss exponent
        %------------------------------------------------------------------
        %         Free-space                     |    2
        %         Urban area cellular radio      |    2.7 to 3.5
        %         Shadowed urban cellular radio  |    3 to 5
        %         In building LOS                |    1.6 to 1.8
        %         Obstructed in building         |    4 to 6
        %         Obstructed in Factories        |    2 to 3
        %------------------------------------------------------------------
        
        lamda = 3e8/centerFrequency;
        pathLoss = (distance^plExponent)*(4*pi/lamda)^2;
        pathLossdB = 10*log10(pathLoss); % in dB
        
        % RxGain is considered as zero.
        rxPowerdBm = obj.RxGain - pathLossdB; % in dBm
        
        rxPowerdB = rxPowerdBm - 30;  % in dB
        alpha = 10^(rxPowerdB/20);
    end
end
end
