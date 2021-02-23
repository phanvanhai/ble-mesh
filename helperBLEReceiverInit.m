function initRx = helperBLEReceiverInit(phyMode,sps,accessAddress)
%helperBLEReceiverInit Initialize BLE receiver parameters
%
%   INITRX = helperBLEReceiverInit(PHYMODE,SPS) outputs a structure,
%   INITRX, which contains the BLE receiver parameters for the given
%   PHYMODE and SPS. PHYMODE is a character vector or string specifying the
%   PHY on which decoding is performed. It must be one of the following:
%   'LE1M','LE2M','LE500K','LE125K'. SPS denotes the number of samples per
%   symbol and must be a positive integer. ACCESSADDRESS is a column vector
%   of length 32 bits containing the access address information.
%
%   See also bleWaveformGenerator, bleIdealReceiver.

%   Copyright 2018-2019 The MathWorks, Inc.

% Initialize parameters
initRx.sps = sps;
initRx.phyMode = phyMode;
% Define symbol rate based on PHY mode
initRx.symbolRate = 1e6;
if strcmp(phyMode,'LE2M')
    initRx.symbolRate = 2e6;
end

% Generate reference signals used for packet detection
initRx.accAddress = accessAddress; 
initRx.preamble = ble.internal.preambleGenerator(phyMode,initRx.accAddress);  
if any(strcmp(phyMode,{'LE1M','LE2M'})) % For LE1M or LE2M
    initRx.refSequence = [initRx.preamble; initRx.accAddress];
    initRx.skipAALen = 32;              % Access address length in bits
else                                    % For LE500K or LE125K
    trellis = poly2trellis(4,[17 13]);
    fecAA = convenc(initRx.accAddress,trellis);
    pattern = [1 1 0 0].';
    patternLen = length(pattern);
    repBlock = reshape(repmat(fecAA.',patternLen,1),1,[]);
    repPattern = reshape(repmat(pattern,1,length(fecAA)),1,[]);
    codedAA = ~xor(repBlock,repPattern).';
    initRx.refSequence = [initRx.preamble; codedAA];
    initRx.skipAALen = 32*8;            % Coded access address length in bits
end
initRx.refSym = ble.internal.gmskmod(initRx.refSequence,1);

% Matched filter coefficients
BT = 0.5;
span = 2;
initRx.h = gaussdesign(BT,span,floor(1.5*sps));

% Initialize automatic gain control System object
initRx.agc = comm.AGC;

% Initialize timing synchronizer System object
initRx.gmsktSync = comm.MSKTimingSynchronizer('SamplesPerSymbol',initRx.sps);

% Initialize frequency compensator System object
initRx.coarsesync = comm.CoarseFrequencyCompensator('Modulation','OQPSK',...
                                                    'SampleRate',initRx.symbolRate*initRx.sps,...
                                                    'SamplesPerSymbol',2*initRx.sps,...
                                                    'FrequencyResolution',10);

% Initialize preamble detector System object
initRx.prbdet = comm.PreambleDetector('Input','Symbol','Detections','First');

end
