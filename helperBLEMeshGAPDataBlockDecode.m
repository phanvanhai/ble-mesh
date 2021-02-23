function networkPDU = helperBLEMeshGAPDataBlockDecode(advertisingData)
%helperBLEMeshGAPDataBlockDecode Decode advertising data having Bluetooth
%mesh network PDU
%   [NETWORKPDU] = helperBLEMeshGAPDataBlockDecode(ADVERTISINGDATA) decodes
%   BLE advertising data of type 'Mesh message' having Bluetooth mesh
%   network PDU and returns the decoded network PDU.
%
%   NETWORKPDU represents the output Bluetooth mesh network PDU, returned
%   as a column vector of decimal octets.
%
%   ADVERTISINGDATA is a column vector of decimal octets.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% Initialize
networkPDU = zeros(1, 0);

% Mesh message AD type
meshMessageADType = 42;

% Validate advertising data
validateattributes(advertisingData, {'numeric'}, ...
    {'column', 'nonempty', 'nonnegative', '<=', 255}, mfilename, 'advertisingData');

% Decoding index
idx = 1;

% Validate length field
if (advertisingData(idx) ~= (numel(advertisingData)-1))
    fprintf('Unable to decode. Size of length field and data field must be same.\n');
    return;
end
idx = idx + 1;

% Validate AD type field
if (advertisingData(idx) ~= meshMessageADType)
    fprintf('Invalid AD type. Supported AD type is "Mesh message" (42).\n');
    return;
end
idx = idx + 1;

% Network PDU
networkPDU = advertisingData(idx:end);
end
