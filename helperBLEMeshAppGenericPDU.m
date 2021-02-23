function [msgType, genericPDU] = helperBLEMeshAppGenericPDU(msgType, varargin)
%helperBLEMeshAppGenericPDU Generate Bluetooth mesh generic PDU
%   [MSGTYPE, GENERICPDU] = helperBLEMeshAppGenericPDU(MSGTYPE, VARARGIN)
%   generates Bluetooth mesh generic PDU, GENERICPDU and type of message
%   MSGTYPE, based on the specified inputs.
%
%   MSGTYPE is a character vector or a string scalar indicating the type of
%   message.
%
%   GENERICPDU is a column vector of decimal octets.
%
%   Signatures of different generic messages are as follows:
%   1. Generic onOff set, Generic onOff set unacknowledged
%   If non-instantaneous state change, the signature is [MSGTYPE, 
%   GENERICPDU] = helperBLEMeshAppGenericPDU(MSGTYPE, ONOFF, TID, 
%   TRANSITIONTIMESTEPS, TRANSITIONTIMERESOLUTION, DELAY). If instantaneous
%   state change, the signature is [MSGTYPE, GENERICPDU] = 
%   helperBLEMeshAppGenericPDU(MSGTYPE, ONOFF, TID).
% 
%   2. Generic onOff status
%   If state transition is in progress the signature is [MSGTYPE, 
%   GENERICPDU] = helperBLEMeshAppGenericPDU(MSGTYPE, PRESENTONOFF, 
%   TARGETONOFF, REMAININGTIMESTEPS, REMAININGTIMERESOLUTION) otherwise the
%   signature is [MSGTYPE, GENERICPDU] = 
%   helperBLEMeshAppGenericPDU(MSGTYPE, ONOFF).
%   
%   ONOFF, PRESENTONOFF, TARGETONOFF, TID, TRANSITIONTIMESTEPS,
%   TRANSITIONTIMERESOLUTION, DELAY, REMAININGTIMESTEPS,
%   REMAININGTIMERESOLUTION are integer values.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Validate message type
validateattributes(msgType, {'string', 'char'}, {}, mfilename, 'msgType');

% Initialize
genericPDU = zeros(1, 0);

switch msgType
    case {'Generic onOff set', 'Generic onOff set unacknowledged'}
        % Number of input arguments check
        narginchk(3, 6);
        
        % Validate generic on off
        validateattributes(varargin{1}, {'numeric'}, ...
            {'scalar', 'integer', '>=', 0, '<=', 1}, mfilename, 'GenericOnOff');
        
        % Validate transaction identifier
        validateattributes(varargin{2}, {'numeric'}, {'scalar', 'integer', ...
            '>=', 0, '<=', 255, 'real'}, mfilename, 'TransactionId');
        
        % State change is non-instantaneous
        if (length(varargin) > 2)
            % Validate transition time steps
            validateattributes(varargin{3}, {'numeric'}, {'scalar', 'integer', ...
                '>=', 0, '<=', 63}, mfilename, 'TransitionTimeSteps');
            
            % Validate transition time resolution
            validateattributes(varargin{4}, {'numeric'}, {'scalar', 'integer', ...
                '>=', 0, '<=', 3}, mfilename, 'TransitionTimeResolution');
            
            % Validate delay
            validateattributes(varargin{5}, {'numeric'}, {'scalar', 'integer', ...
                '>=', 0, '<=', 255}, mfilename, 'Delay');
            
            % Transition time (1 octet)
            transitionTimeSteps = de2bi(varargin{3}, 6);
            transitionTimeResolution = de2bi(varargin{4}, 2);
            transitionTime = bi2de([transitionTimeSteps, ...
                transitionTimeResolution]);
            
            % Put it all together
            genericPDU = [varargin{1}; varargin{2}; ...
                transitionTime; varargin{5}];
        else
            % Put it all together
            genericPDU = [varargin{1}; varargin{2}];
        end
        
    case 'Generic onOff status'
        % Number of input arguments check
        narginchk(2, 5);
        
        % Validate present on off
        validateattributes(double(varargin{1}), {'numeric'}, ...
            {'scalar', 'integer', '>=', 0, '<=', 1}, mfilename, 'GenericOnOff');
        
        % State change is in progress
        if (length(varargin) > 2)
            % Validate target on off
            validateattributes(varargin{2}, {'numeric'}, ...
            {'scalar', 'integer', '>=', 0, '<=', 1}, mfilename, 'TargetOnOff');
            
            % Validate remaining time steps
            validateattributes(varargin{3}, {'numeric'}, {'scalar', 'integer', ...
                '>=', 0, '<=', 62}, mfilename, 'RemainingTimeSteps');
            
            % Validate remaining time resolution
            validateattributes(varargin{4}, {'numeric'}, {'scalar', 'integer', ...
                '>=', 0, '<=', 3}, mfilename, 'RemainingTimeResolution');
            
            % Remaining time to reach target state (1 octet)
            remainingTimeSteps = de2bi(varargin{3}, 6);
            remainingTimeResolution = de2bi(varargin{4}, 2);
            remainingTime = bi2de([remainingTimeSteps, ...
                remainingTimeResolution]);
            
            % Put it all together
            genericPDU = [varargin{1}; double(varargin{2}); ...
                remainingTime];
        else
            % Put it all together
            genericPDU = varargin{1};
        end
    
    % Edit: them doan ben duoi
    case 'Config set'
        
        % Validate generic on off
        validateattributes(varargin{1}, {'numeric'}, ...
            {'scalar', 'integer', '>=', 1, '<=', 2}, mfilename, 'Config Type');
        
        % Validate transaction identifier
        validateattributes(varargin{2}, {'numeric'}, {'scalar', 'integer', ...
            '>=', 0, '<=', 255, 'real'}, mfilename, 'Config Value');
        
        % Put it all together
        %         varargin{1}   varargin{2}    
        %             1           0/1         Set relay
        %             2           0-127       Set TTL
        genericPDU = [varargin{1}; varargin{2}];
    
    otherwise
        fprintf('Generic message type not supported.\n');
end
end
