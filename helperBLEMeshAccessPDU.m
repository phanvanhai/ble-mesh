function accessPDU = helperBLEMeshAccessPDU(msgType, modelPDU)
%helperBLEMeshAccessPDU Generate Bluetooth mesh access PDU
%   ACCESSPDU = helperBLEMeshAccessPDU(MSGTYPE, MODELPDU) generates BLE
%   mesh access layer PDU by adding opcode to the model layer PDU.
%
%   ACCESSPDU is a column vector of decimal octets.
%
%   MSGTYPE is a character vector or a string scalar indicating the type of
%   message.
%
%   MODELPDU is a column vector of decimal octets.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Validate message type
validateattributes(msgType, {'string', 'char'}, {}, mfilename, 'msgType');

% Validate model PDU
if ~isempty(modelPDU)
    validateattributes(modelPDU, {'numeric'}, ...
        {'vector', 'nonnegative', '<=', 255}, mfilename, 'modelPDU');
end

% Initialize
accessPDU = zeros(1, 0);

% Get opcode from message type
opcodeHex = getOpcode(msgType);
if ~isempty(opcodeHex)
    opcode = [hex2dec(opcodeHex(1:2)); ...
        hex2dec(opcodeHex(3:4))];
    
    % Put it all together
    accessPDU = [opcode; modelPDU];
end
end

% Get opcode for a given message type
function opcode = getOpcode(msgType)
% Initialize
opcode = blanks(0);

switch msgType
    % Generic messages
    % Refer "Table 7.1" in Bluetooth Mesh Model specification v1.0
    case 'Generic onOff set'
        opcode = '8202';
    case 'Generic onOff set unacknowledged'
        opcode = '8203';
    case 'Generic onOff status'
        opcode = '8204';
    
    % Lighting messages
    % Refer "Table 7.1" in Bluetooth Mesh Model specification v1.0
    case 'Light lightness set'
        opcode = '824C';
    case 'Light lightness set unacknowledged'
        opcode = '824D';
    case 'Light lightness status'
        opcode = '824E'; 
        
    % Edit: them doan ben duoi
    % Config messages
    case 'Config set'
        opcode = '8080';
        
    otherwise
        fprintf('Access message type not supported.\n');
end
end
