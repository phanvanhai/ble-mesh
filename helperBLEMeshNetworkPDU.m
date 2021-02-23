function networkPDU = helperBLEMeshNetworkPDU(src, dst, seq, ttl, lowerTransportPDU, ctl)
%helperBLEMeshNetworkPDU Bluetooth mesh network PDU generation
%   NETWORKPDU = helperBLEMeshNetworkPDU(SRC, DST, SEQ, TTL,
%   LOWERTRANSPORTPDU, CTL) returns Bluetooth mesh network PDU, NETWORKPDU
%   (column vector of decimal octets), based on the specified inputs,
%   source address (SRC), destination address (DST), sequence number (SEQ),
%   time to live (TTL), lower transport PDU and its type (LOWERTRANSPORTPDU
%   and CTL respectively).
%
%   NETWORKPDU is column vector of decimal octets.
%
%   SRC, DST can be specified as a 4-element character vector or string
%   scalar denoting a 2-octet hexadecimal value.
%
%   SEQ, TTL and CTL are integer values.
%
%   LOWERTRANSPORTPDU can be specified as a column vector of decimal
%   octets.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

% IVI||NID (fixed)
iviNID = 104;

% TTL
ttl = de2bi(ttl, 7, 'left-msb');

% CTL||TTL
ctlTTL = bi2de([ctl ttl], 'left-msb');

% SEQ
seqBinary = de2bi(seq, 24, 'left-msb');
seq = [bi2de(seqBinary(1:8),'left-msb'); ...
    bi2de(seqBinary(9:16), 'left-msb'); ...
    bi2de(seqBinary(17:24), 'left-msb')];

% SRC
src = hex2dec(reshape(src, 2, [])');

% DST
dst = hex2dec(reshape(dst, 2, [])');

% Transport PDU
if ctl
    if numel(lowerTransportPDU) > 12
        error('Lower transport control PDU size must be less than or equal to 12');
    end
else 
    if numel(lowerTransportPDU) > 16
        error('Lower transport access PDU size must be less than or equal to 16');
    end
end
transportPDU = lowerTransportPDU;

% Form network PDU
networkPDU = [iviNID;ctlTTL;seq;src;dst;transportPDU];
end
