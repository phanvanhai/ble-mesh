function [messageType, modelPDU] = helperBLEMeshAccessPDUDecode(accessPDU)
%helperBLEMeshAccessPDUDecode Decode Bluetooth mesh access PDU
%   [MESSAGETYPE, MODELPDU] = helperBLEMeshAccessPDUDecode(ACCESSPDU)
%   decodes access PDU and returns the Bluetooth mesh model layer PDU and
%   the respective message type.
%
%   MESSAGETYPE is a character vector or a string scalar indicating the
%   type of message.
%
%   MODELPDU is a column vector of decimal octets.
%
%   ACCESSPDU is a column vector of decimal octets.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Validate access PDU
validateattributes(accessPDU, {'numeric'}, ...
    {'vector', 'nonnegative', '<=', 255}, mfilename, 'accessPDU');

% Initialize
modelPDU = zeros(1, 0);

% Get opcode from access PDU
opcodeOctets = accessPDU(1:2);
opcode = [dec2hex(opcodeOctets(1), 2) dec2hex(opcodeOctets(2), 2)];

% Get message type from opcode
messageType = getMessageType(opcode);

% Get model PDU
if ~isempty(messageType)
    modelPDU = accessPDU(3:end);
end
end

% Get the message type from opcode
function messageType = getMessageType(opcode)
% Initialize
messageType = blanks(0);

switch opcode   
    % Generic messages
    % Refer "Table 7.1" in Bluetooth Mesh Model specification v1.0
    case '8202'
        messageType = 'Generic onOff set';
    case '8203'
        messageType = 'Generic onOff set unacknowledged';
    case '8204'
        messageType = 'Generic onOff status';
    
    % Lighting messages
    % Refer "Table 7.1" in Bluetooth Mesh Model specification v1.0
    case '824C'
        messageType = 'Light lightness set';
    case '824D'
        messageType = 'Light lightness set unacknowledged';
    case '824E'
        messageType = 'Light lightness status';
        
    % Edit: them doan ben duoi
    % Config messages
    case '8080'
        messageType = 'Config set';
    
    otherwise
        fprintf("AccessPDUDecode: Given opcode is not supported.\n");
end
end
