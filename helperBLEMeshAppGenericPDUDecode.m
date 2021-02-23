function [msgType, varargout] = helperBLEMeshAppGenericPDUDecode(msgType, genericPDU)
%helperBLEMeshAppGenericPDUDecode Decode Bluetooth mesh generic PDU
%   [MSGTYPE, VARARGOUT] = helperBLEMeshAppGenericPDUDecode(MSGTYPE,
%   GENERICPDU) decodes generic PDU and returns the decoded generic PDU
%   parameters based on the message type, MSGTYPE.
%
%   MSGTYPE is a character vector or a string scalar indicating the type of
%   message.
%
%   GENERICPDU is a column vector of decimal octets.
%
%   Output parameters can be different for each message
%   1. Generic onOff set, Generic onOff set unacknowledged
%   If non-instantaneous state change, output parameters are MSGTYPE, 
%   ONOFF, TID, TRANSITIONTIMESTEPS, TRANSITIONTIMERESOLUTION, DELAY. If 
%   instantaneous state change, output parameters are MSGTYPE, ONOFF, TID.
% 
%   2. Generic onOff status
%   If state transition is in progress, output parameters are MSGTYPE, 
%   PRESENTONOFF, TARGETONOFF, REMAININGTIMESTEPS, REMAININGTIMERESOLUTION
%   otherwise, output parameters are MSGTYPE, ONOFF.
%   
%   ONOFF, PRESENTONOFF, TARGETONOFF, TID, TRANSITIONTIMESTEPS,
%   TRANSITIONTIMERESOLUTION, DELAY, REMAININGTIMESTEPS,
%   REMAININGTIMERESOLUTION are integer values.
% 
%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Validate generic PDU
validateattributes(genericPDU, {'numeric'}, ...
    {'vector', 'nonnegative', '<=', 255}, mfilename, 'genericPDU');

% Validate message type
validateattributes(msgType, {'string', 'char'}, {}, mfilename, 'msgType');

% Initialize
varargout{1} = 0;
varargout{2} = 0;
varargout{3} = 0;
varargout{4} = 0;
varargout{5} = 0;
cnt = 1;

switch msgType
    case {'Generic onOff set', 'Generic onOff set unacknowledged'}
        % Generic OnOff state(1 octet)
        varargout{1} = genericPDU(cnt);
        cnt = cnt + 1;
        
        % Transaction Identifier (1 octet)
        varargout{2} = genericPDU(cnt);
        cnt = cnt + 1;
        
        % State change is non-instantaneous
        if (length(genericPDU) > 2)            
            % Transition time (1 octet)
            transitionTime = de2bi(genericPDU(cnt), 8);
            varargout{3} = bi2de(transitionTime(1:6));
            varargout{4} = bi2de(transitionTime(7:8));
            cnt = cnt + 1;
            
            % Message execution delay (1 octet)
            varargout{5} = genericPDU(cnt);
        end
        
    case 'Generic onOff status'        
        % Generic OnOff state (1 octet)
        varargout{1} = genericPDU(cnt);
        cnt = cnt + 1;
        
        % State change is in progress
        if(length(genericPDU) > 1)
            % Target OnOff state (1 octet)
            varargout{2} = genericPDU(cnt);
            cnt = cnt + 1;
            
            % Remaining time to reach target state (1 octet)
            remainingTime = de2bi(genericPDU(cnt), 8);
            varargout{3} = bi2de(remainingTime(1:6));
            varargout{4} = bi2de(remainingTime(7:8));
        end
        
    % Edit: them doan ben duoi
    case 'Config set'
        % Config Type
        varargout{1} = genericPDU(cnt);
        cnt = cnt + 1;
        
        % Config Value
        varargout{2} = genericPDU(cnt);
        
    otherwise
        fprintf("APPGenericPDUDecode: Given message type is not supported.\n");
end
end