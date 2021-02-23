function transportDataMessage = helperBLEMeshTransportDataMessage(accessMessage)
%helperBLEMeshTransportDataMessage Generate Bluetooth mesh transport data
%message
%   TRANSPORTDATAMESSAGE = helperBLEMeshTransportDataMessage(ACCESSMESSAGE)
%   generates a Bluetooth mesh transport data message corresponding to the
%   input parameter ACCESSMESSAGE.
%
%   TRANSPORTDATAMESSAGE represents the output Bluetooth mesh
%   lower-transport data message, returned as a column vector of decimal
%   octets.
%
%   ACCESSMESSAGE is the upper-transport access message of type column
%   vector of decimal octets.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Validate the access message
validateattributes(accessMessage, {'numeric'}, {'column', 'integer', ...
    'nonnegative', '<=', 255, 'nonempty'}, mfilename, 'accessMessage')
accessMessageSize = length(accessMessage);

% Validate the size of the access message. The access message is not
% combined with the TransMIC as the upper transport layer does not support
% encryption. Refer Mesh Profile Bluetooth Specification v1.0.1 | Section
% 3.5
validateattributes(accessMessageSize, {'numeric'}, {'scalar', ...
    'integer', '>=', 1, '<=', 11}, mfilename, 'Access message size')

% segmented: '0b0' (no segmentation)
segmented = 0;

% Application key flag: '0b0' (Set by the upper transport layer according
% to the application key or device key used to encrypt the access payload)
akf = 0;

% Application key identifier: '0b000000' (Set by the upper transport layer
% according to the application key or device key used to encrypt the access
% payload)
aid = [0 0 0 0 0 0];

% Concatenate received input data with segmentation, akf and aid fields
transportDataMessage = [comm.internal.utilities.bi2deLeftMSB([segmented akf ...
    aid], 2); accessMessage];

end

