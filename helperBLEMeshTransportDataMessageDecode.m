function accessMessage = helperBLEMeshTransportDataMessageDecode(transportDataMessage)
%helperBLEMeshTransportDataMessage Decode Bluetooth mesh transport data
%message
%   ACCESSMESSAGE =
%   helperBLEMeshTransportDataMessageDecode(TRANSPORTDATAMESSAGE) decodes
%   Bluetooth mesh transport data message corresponding to the input
%   parameter TRANSPORTDATAMESSAGE.
%
%   ACCESSMESSAGE represents the output Bluetooth mesh upper-transport
%   access message, returned as a column vector of decimal octets.
%
%   TRANSPORTDATAMESSAGE is the lower-transport access message of type
%   column vector of decimal octets.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Validate the transport data message
validateattributes(transportDataMessage, {'numeric'}, {'column', 'vector', ...
    'integer', 'nonnegative', '<=', 255}, mfilename, 'transportDataMessage')
transportDataMessageSize = length(transportDataMessage);

% Validate the size of the transport data message
validateattributes(transportDataMessageSize, {'numeric'}, {'scalar', ...
    'integer', '>=', 2, '<=', 12}, mfilename, 'transportDataMessageSize')

% Initialize accessMessage with its maximum size
accessMessage = zeros(15, 1);

% Segmented, application key flag and application key identifier fields
octet0 = ...
    comm.internal.utilities.de2biBase2LeftMSB(transportDataMessage(1), 8);

% segmented: '0b0' (no segmentation)
segmented = octet0(1, 1);

% Received unsegmented transport data message
if ~segmented
    % Decoded transport data message
    accessMessage = transportDataMessage(2:end);
else
    fprintf(['helperBLEMeshTransportDataMessageDecode function does not' ...
        ' support decoding of segmented transport data message']);
end
end