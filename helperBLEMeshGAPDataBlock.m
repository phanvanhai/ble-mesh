function advertisingData = helperBLEMeshGAPDataBlock(networkPDU)
%helperBLEMeshGAPDataBlock Generate advertising data with Bluetooth mesh
%network PDU
%   [ADVERTISINGDATA] = helperBLEMeshGAPDataBlock(NETWORKPDU) generates BLE
%   advertising data (AD) of type "Mesh message" having Bluetooth mesh
%   network PDU.
%
%   ADVERTISINGDATA represents the output BLE GAP advertising data,
%   returned as a column vector of decimal octets.
%
%   NETWORKPDU is a column vector of decimal octets.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Mesh message AD type
meshMessageADType = 42;

% Validate the networkPDU
validateattributes(networkPDU, {'numeric'}, ...
    {'column', 'nonempty', 'nonnegative', '<=', 255}, mfilename, 'networkPDU');

% Network PDU length
networkPDULength = numel(networkPDU);

% Validate network PDU (network PDU length must be less then 30 bytes)
validateattributes(networkPDULength, {'numeric'}, ...
    {'scalar', 'integer', '<', 30}, mfilename, 'networkPDULength');

% Form advertising data with AD type "Mesh message"
% Length | MessageType | NetworkPDU
advertisingData = [networkPDULength+1; meshMessageADType; networkPDU];
end
