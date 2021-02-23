function [src, dst, seq, ttl, lowerTransportPDU, ctl] = helperBLEMeshNetworkPDUDecode(networkPDU)
%helperBLEMeshNetworkPDUDecode Bluetooth mesh network PDU decoder
%   [SRC, DST, SEQ, TTL, LOWERTRANSPORTPDU, CTL] =
%   helperBLEMeshNetworkPDUDecode(NETWORKPDU) returns the decoded network
%   PDU parameters such as source address (SRC), destination address (DST),
%   sequence number (SEQ), time to live (TTL), lower transport PDU and its
%   type (LOWERTRANSPORTPDU and CTL respectively).
%
%   SRC, DST are 4-element character vector or string scalar denoting a
%   2-octet hexadecimal value.
%
%   SEQ, TTL and CTL are integer values.
%
%   LOWERTRANSPORTPDU is a column vector of decimal octets.
%
%   NETWORKPDU should be specified as a column vector of decimal octets.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Initialize counter
cnt = 1;

% IVI||NID (fixed)
% iviNID = networkPDU(cnt, :);
cnt = cnt+1;

% CTL||TTL
ctlTTL = networkPDU(cnt, :);
ctlTTLBinary = de2bi(ctlTTL, 8, 'left-msb');

% CTL
ctl = ctlTTLBinary(1);

% TTL
ttl = bi2de(ctlTTLBinary(2:8), 'left-msb');
cnt = cnt+1;

% SEQ
seqOctets = networkPDU(cnt:cnt+2);
seq = bi2de(reshape(de2bi(seqOctets, 8, 'left-msb')', 1, 24), 'left-msb');
cnt = cnt+3;

% SRC
src = reshape(dec2hex(networkPDU(cnt:cnt+1), 2)', 1, 4);
cnt = cnt+2;

% DST
dst = reshape(dec2hex(networkPDU(cnt:cnt+1), 2)', 1, 4);
cnt = cnt+2;

% TransportPDU
lowerTransportPDU = networkPDU(cnt:end);
end
