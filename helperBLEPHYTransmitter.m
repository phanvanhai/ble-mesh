classdef helperBLEPHYTransmitter < handle
%helperBLEPHYTransmitter Create an object for BLE PHY transmitter
%   BLEPHYTX = helperBLEPHYTransmitter creates a BLE PHY transmitter object
%   supporting all the four PHY transmission modes (LE1M, LE2M, LE500K and
%   LE125K).
%
%   BLEPHYTX = helperBLEPHYTransmitter(Name, Value) creates a BLE PHY
%   transmitter object with the specified property Name set to the
%   specified Value. You can specify additional name-value pair arguments
%   in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   helperBLEPHYTransmitter properties:
%
%   ChannelIndex        - BLE channel index for transmitting the link layer
%                         (LL) PDU
%   PHYMode             - Specifies the PHY transmission mode
%   TxPower             - Signal transmission power in dBm

%   Copyright 2019 The MathWorks, Inc.

properties
    %ChannelIndex BLE channel index for transmitting the LL PDU
    %   Specify channel index as a scalar integer in the range [0, 39]. It
    %   defines the transmitting channel for LL PDUs. To receive LL data
    %   PDUs, channels 0 to 36 are used. Whereas, channels 37, 38 and 39
    %   are used to receive LL advertising PDUs. The default value is 37
    %   (advertising channel).
    ChannelIndex = 37
        
    %PHYMode Specifies the PHY transmission mode
    %   Specify the PHY mode based on the data rate as 'LE1M' | 'LE2M' |
    %   'LE500K' or 'LE125K'. It specifies the PHY transmitting mode. Refer
    %   Bluetooth Core Specification version 5.0, volume 6, part B, section
    %   2.
    PHYMode = 'LE1M'
    
    %TxPower Signal transmission power in dBm
    % Specify the Tx power as a scalar integer be in the range [-20, 20].
    % It specifies the signal transmission power in dBm. The default value
    % is 20 dBm.
    TxPower = 20
end

properties (Constant, Hidden)
    % PHY mode values
    PHYModeValues = {'LE1M', 'LE2M', 'LE500K', 'LE125K'}
    
    % BLE channel bandwidth in MHz
    ChannelBandwidth = 2 % in MHz
    
    % BLE channels center frequencies in MHz
    % Refer Bluetooth Core Specification version 5.0, volume 6, part B,
    % Table 1.2
    ChannelCenterFrequencies = [2404:2:2424 2428:2:2478 2402 2426 2480]
    
    % Number of samples per symbol
    SamplesPerSymbol = 20
    
    % Tx gain in dB
    TxGain = 0
end

properties (Access = private)    
    %pTransmissionTimer Timer for LL PDU transmission (in microseconds)
    pTransmissionTimer = 0
    
    %pTransmission Flag to specify the LL PDU is transmitting
    pTransmission = false
    
    %pPacketLen Transmitting packet length in bits
    pPacketLen = 0
    
    %pImpairments Handle for the BLE impairments
    pImpairments
end

properties (SetAccess = private, Hidden)
    %pDuration Duration for transmitting the LL PDU (in microseconds)
    pDuration = 0
    
    %pStatus Status of the LL PDU transmission (either 0 | 1 | 2 )
    % 0 - Not started
    % 1 - TxStart
    % 2 - TxEnd
    pStatus = 0
end

properties (SetAccess = private)    
    %TransmittedSignals Number of signals transmitted
    TransmittedSignals = 0
    
    %TransmittedBits Number of bits transmitted
    TransmittedBits = 0
    
    %TransmissionTime Transmission time in microseconds
    TransmissionTime = 0
end

properties (Dependent, SetAccess = private)
    %SampleRate Sample rate of the transmitted waveform
    %   Sample rate of BLE waveform is depends on <a
    %   href="matlab:help('helperBLEPHYTransmitter.PHYMode')">PHYMode</a>
    %   and <a
    %   href="matlab:help('helperBLEPHYTransmitter.SamplesPerSymbol')">SamplesPerSymbol</a>.
    %   It is represented in samples per second.
    SampleRate
end

methods
    % Constructor
    function obj = helperBLEPHYTransmitter(varargin)
        % Set name-value pairs
        for idx = 1:2:nargin
            obj.(varargin{idx}) = varargin{idx+1};
        end
    end
    
    % Auto-completion for fixed set of option strings
    function v = set(obj, prop)
        v = obj.([prop, 'Values']);
    end
    
    % Set channel index
    function set.ChannelIndex(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', 0, '<=', 39}, mfilename, 'ChannelIndex');
        obj.ChannelIndex = value;
    end
    
    % Set PHY mode
    function set.PHYMode(obj, value)
        obj.PHYMode = validatestring(value, obj.PHYModeValues, ...
            mfilename, 'PHYMode');
    end
    
    % Set Tx power in dBm
    function set.TxPower(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>=', -20, '<=', 20}, mfilename, 'TxPower');
        obj.TxPower = value;
    end
    
    % Get sample rate
    function value = get.SampleRate(obj)
        % PHY mode
        value = 0;
        switch obj.PHYMode
            case {'LE1M', 'LE500K', 'LE125K'}
                % 1msps (one mega symbols per second)
                value = 1e6;
            case 'LE2M'
                % 2msps (two mega symbols per second)
                value = 2e6;
        end
        % Multiply with sps (samples per symbol)
        value = value * obj.SamplesPerSymbol;
    end
    
    function [nextInvokeTime, bleWaveform] = run(obj, elapsedTime, llPDU, accessAddress)
    %run Process the received LL PDU and access address and returns the
    %generated waveform along with the next invoke time
    %
    %   [NEXTINVOKETIME, BLEWAVEFORM] = run(OBJ, LLPDU, ELAPSEDTIME,
    %   ACCESSADDRESS) generates and returns BLE waveform along with the
    %   next invoke time in microseconds.
    %
    %   NEXTINVOKETIME returns the time after which the run function must
    %   be invoked again.
    %
    %   BLEWAVEFORM returns the IQ samples of the generated waveform.
    %
    %   OBJ is instance of an object of type helperBLEPHYTransmitter.
    %
    %   ELAPSEDTIME is the time elapsed in microseconds between the
    %   previous and current call of this function.
    %
    %   LLPDU is the generated LL protocol data unit (PDU) appended with
    %   cyclic redundancy check (CRC) in binary format.
    %
    %   AccessAddress is the 32-bit access address to be used for this
    %   packet.
    
        % Initialize
        nextInvokeTime = -1;
        bleWaveform = zeros(1, 0);
        
        % PDU is transmitting
        if obj.pTransmission
            % Update the transmission timer
            obj.pTransmissionTimer = obj.pTransmissionTimer - elapsedTime;
            % LL PDU duration is completed
            if obj.pTransmissionTimer <= 0
                % Update the status
                obj.pStatus = 2;
                % Reset the transmission flag
                obj.pTransmission = false;
                % Reset the transmission timer
                obj.pTransmissionTimer = 0;
                
                % Update the transmission statistics
                obj.TransmittedSignals = obj.TransmittedSignals + 1;
                obj.TransmittedBits = obj.TransmittedBits + obj.pPacketLen;
                obj.TransmissionTime = obj.TransmissionTime + obj.pDuration;
                
                % Reset the duration time
                obj.pDuration = 0;
            else
                obj.pStatus = 0;
            end
            % Update next event timer
            nextInvokeTime = obj.pTransmissionTimer;
        % No active transmission of LL PDU
        else
            if ~isempty(llPDU) && ~isempty(accessAddress)
                % Generate waveform for the given LL PDU with the given
                % access address
                bleWaveform = bleWaveformGenerator(llPDU,'Mode',obj.PHYMode,...
                    'ChannelIndex',obj.ChannelIndex,'SamplesPerSymbol',obj.SamplesPerSymbol,...
                    'AccessAddress',accessAddress);
                
                % Add impairments to the generated waveform
                bleWaveform = helperBLEImpairments(obj.pImpairments, ...
                    bleWaveform, obj.SamplesPerSymbol);

                % Apply Tx power and Tx gain
                bleWaveform = applyTxPowerAndGain(obj, bleWaveform);
                
                % Update the status
                obj.pStatus = 1;
                % Set the transmission flag
                obj.pTransmission = true;
                % Calculate the duration to transmit the LL PDU
                obj.pDuration = calculateWaveformDuration(obj, llPDU);
                % Set the reception timer to waveform duration time
                obj.pTransmissionTimer = obj.pDuration;
                % Update next event timer
                nextInvokeTime = obj.pTransmissionTimer;
            else
                obj.pStatus = 0;
            end
        end
    end
    
    function init(obj)
    %init Initialize the PHY transmitter object
    %
    %   init(OBJ) initializes the PHY impairments object with the
    %   configured PHY mode and samples per symbol values.
    %
    %   OBJ is instance of object of type helperBLEPHYTransmitter.
    
        % Create and configure the System objects for BLE PHY impairments
        obj.pImpairments = helperBLEImpairmentsInit(obj.PHYMode, obj.SamplesPerSymbol);
    end
    
    function waveformDuration = calculateWaveformDuration(obj, llPDU)
    %calculateWaveformDuration Calculate waveform duration to transmit the
    %given LL PDU
    %
    %   WAVEFORMDURATION = calculateWaveformDuration(OBJ, LLPDU) returns
    %   the waveform duration to transmit the received LL PDU in
    %   microseconds.
    %
    %   WAVEFORMDURATION returns the duration of the waveform in
    %   microseconds.
    %
    %   OBJ is instance of object of type helperBLEPHYTransmitter.
    %
    %   LLPDU is the generated LL Protocol Data Unit (PDU) appended with
    %   Cyclic Redundancy Check (CRC) in binary format.
    
        % LL PDU length in bits
        packetLen = numel(llPDU);
        % Access address length in bits (4 octets)
        accessAddressLen = 32;
        % Access address coding used for LE coded PHY (LE125K and LE500K)
        aaCoding = 8;
        
        % PHY mode
        switch obj.PHYMode
            % LE1M
            case 'LE1M'
                % 1 Mb/s (one megabits per second)
                bitDuration = 1; % in microseconds
                preambleLen = 8; % in bits
                % Calculate waveform duration (in microseconds)
                obj.pPacketLen = packetLen + accessAddressLen + preambleLen;
                waveformDuration = obj.pPacketLen * bitDuration;
                
            % LE2M
            case 'LE2M'
                % 2 Mb/s (two megabits per second)
                bitDuration = 0.5; % in microseconds
                preambleLen = 16; % in bits
                % Calculate waveform duration (in microseconds)
                obj.pPacketLen = packetLen + accessAddressLen + preambleLen;
                waveformDuration = obj.pPacketLen * bitDuration;
                
            % LE500K
            case 'LE500K'
                % 500 kb/s (500 kilobits per second)
                preambleLen = 80; % in bits
                bitDuration = 1; % in microseconds
                % PDU coding used for LE coded PHY LE500K
                pduCoding = 2;
                % Coding indicator (CI) length used for LE coded PHY
                % (LE125K and LE500K)
                codingIndicatorLen = 2 * aaCoding; % in bits
                % Length of TERM1 and TERM2 used for LE coded PHY (LE125K
                % and LE500K)
                termLen1 = 3 * aaCoding; % in bits
                termLen2 = 3 * pduCoding; % in bits
                
                % Calculate packet length in bits
                obj.pPacketLen = packetLen + accessAddressLen + preambleLen + ...
                    codingIndicatorLen + termLen1 + termLen2;
                
                accessAddressLen = accessAddressLen * aaCoding; % in bits
                
                % Update packet length based on the coding scheme used
                packetLen = packetLen * pduCoding;
                % Calculate waveform duration (in microseconds)
                waveformDuration = (packetLen + accessAddressLen + preambleLen + ...
                    termLen1 + termLen2 + codingIndicatorLen) * bitDuration;
                
            % LE125K
            case 'LE125K'
                % 125 kb/s (125 kilobits per second)
                preambleLen = 80; % in bits
                bitDuration = 1; % in microseconds
                % Coding indicator (CI) length used for LE coded PHY
                % (LE125K and LE500K)
                codingIndicatorLen = 2 * aaCoding; % in bits
                % PDU coding used for LE coded PHY LE125K
                pduCoding = 8;
                % Length of TERM1 and TERM2 used for LE coded PHY (LE125K
                % and LE500K)
                termLen1 = 3 * aaCoding; % in bits
                termLen2 = 3 * pduCoding; % in bits
                
                % Calculate packet length in bits
                obj.pPacketLen = packetLen + accessAddressLen + preambleLen + ...
                    codingIndicatorLen + termLen1 + termLen2;
                
                accessAddressLen = accessAddressLen * aaCoding; % in bits
                % Update packet length based on the coding scheme used
                packetLen = packetLen * pduCoding;
                % Calculate waveform duration (in microseconds)
                waveformDuration = (packetLen + accessAddressLen + preambleLen + ...
                    termLen1 + termLen2 + codingIndicatorLen) * bitDuration;
        end
    end
    
    function centerFrequency = bleFrequency(obj)
    %bleFrequency Return the center frequency in MHz corresponding to the
    %configured BLE channel number
    %
    %   CENTERFREQUENCY = bleFrequency(OBJ) returns the center frequency in
    %   MHz corresponding to the configured BLE channel number.
    %
    %   CENTERFREQUENCY returns an integer representing the center
    %   frequency in MHz.
    
        % Fetch the center frequency from the array of frequencies
        centerFrequency = obj.ChannelCenterFrequencies(obj.ChannelIndex + 1);
    end
end

methods (Access = private)
    function bleWaveform = applyTxPowerAndGain(obj, bleWaveform)
    % Apply Tx power and gain on the given waveform
        scale = 10.^((-30 + obj.TxPower + obj.TxGain)/20);
        bleWaveform = bleWaveform * scale;
    end
end
end
