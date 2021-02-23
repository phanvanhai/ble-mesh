function [bits,accessAddress] = helperBLEPracticalReceiver(rxWaveform,init,chanIdx)
%helperBLEPracticalReceiver Demodulate and decodes the received signal
%
%   [BITS,ACCESSADDRESS] = helperBLEPracticalReceiver(RXWAVEFORM,INIT,
%   CHANIDX) decodes the received signal, RXWAVEFORM, based on CHANIDX and
%   the parameters specified in a structure, INIT. BITS is a column vector
%   containing the recovered information bits with maximum length of 2080
%   bits. ACCESSADDRESS is a column vector of length 32 bits containing the
%   access address information.
%
%   helperBLEPracticalReceiver performs the following operations:
%
%   * Automatic gain control (AGC)
%   * DC removal
%   * Carrier frequency offset correction
%   * Matched filtering
%   * Packet detection
%   * Timing error correction
%   * Demodulation and decoding
%   * De-whitening

%   Copyright 2018-2019 The MathWorks, Inc.

% Automatic Gain Control (AGC)
rxAGC = init.agc(rxWaveform);

% DC offset correction
rxDCFree = rxAGC - mean(rxAGC);
% Coarse frequency offset correction
rxWfmFreqComp = init.coarsesync(rxDCFree);

% Matched filtering
rxWaveformMF = conv(rxWfmFreqComp,init.h,'same');

% Timing recovery
% Append zeros to account for the delays due to MSK timing synchronizer
timrecDelay = 2;
rxWaveformMF = [rxWaveformMF ;zeros(timrecDelay*init.sps,1)];
rxWfmTimeComp = init.gmsktSync(rxWaveformMF);
rxWfmTimeComp = rxWfmTimeComp(timrecDelay+1:end); % Remove the delays

% Packet detection at symbol level
syncIdx = preambleDetection(rxWfmTimeComp,init);

preambleLen = length(init.preamble);
refSeqLen = init.skipAALen+preambleLen;

% Packet that always starts with a preamble
if syncIdx >= refSeqLen

    % GMSK demodulation
    demodData = ble.internal.gmskdemod(rxWfmTimeComp(1+syncIdx-refSeqLen:end),1);

    % Preamble synchronization
    demodSyncData = demodData(1+preambleLen:end);

    % Decode as per PHY mode
    if any(strcmp(init.phyMode,{'LE1M','LE2M'}))    % For LE1M or LE2M
        accessAddress = int8(demodSyncData(1:init.skipAALen)>0);
        decodeData = int8(demodSyncData(1+init.skipAALen:end)>0);
    else                                            % For LE500K or LE125K
        if strcmp(init.phyMode,'LE500K') && (rem(length(demodSyncData),2) ~= 0)
            padLen = 2 - rem(length(demodSyncData),2);
        elseif strcmp(init.phyMode,'LE125K') && (rem(length(demodSyncData),8) ~= 0)
            padLen = 8 - rem(length(demodSyncData),8);
        else
            padLen = 0;
        end
        demodSyncData = [demodSyncData; zeros(padLen,1)];
        [decodeData,accessAddress] = ble.internal.decode(demodSyncData,init.phyMode);
    end

    % Data De-whitening
    dewhitenStateLen = 6;
    chanIdxBin = comm.internal.utilities.de2biBase2LeftMSB(chanIdx,dewhitenStateLen);
    initState = [1 chanIdxBin]; % Initial conditions of shift register
    bits = ble.internal.whiten(decodeData,initState);
else
    bits = [];
    accessAddress = [];
end
% Release the System objects
release(init.coarsesync);
release(init.prbdet);
end

function syncIdx = preambleDetection(inData,init)
% Performs preamble detection based on known reference signal
frameLen = length(init.refSym)*2;
if (length(inData) <= frameLen)
    frameLen = length(inData);
end
init.prbdet.Preamble = init.refSym;
[~,detmet] = init.prbdet(inData(1:frameLen));
release(init.prbdet)
init.prbdet.Threshold = max(detmet);
[syncIdx,~] = init.prbdet(inData(1:frameLen));
if(syncIdx < init.skipAALen) % To make sure positive indexing
    syncIdx = init.skipAALen;
end

end
