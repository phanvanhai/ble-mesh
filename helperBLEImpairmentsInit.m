function init = helperBLEImpairmentsInit(phyMode,sps)
%helperBLEImpairmentsInit Initialize RF impairment parameters
%
%   INIT = helperBLEImpairmentsInit(PHYMODE,SPS) outputs a structure,
%   INIT, which contains the front-end impairment parameters for the given
%   PHYMODE and SPS. PHYMODE is a character vector or string specifying the
%   PHY on which decoding is performed. It must be one of the following:
%   'LE1M','LE2M','LE500K','LE125K'. SPS denotes the number of samples per
%   symbol and must be a positive integer.
%
%   See also bleWaveformGenerator, bleIdealReceiver.

%   Copyright 2018-2019 The MathWorks, Inc.

% Initialize parameters
% Define symbol rate based on the PHY mode
symbolRate = 1e6;
if strcmp(phyMode,'LE2M')
    symbolRate = 2e6;
end
sampleRate = symbolRate*sps;

% Initialize frequency and phase offset System object
init.pfo = comm.PhaseFrequencyOffset('SampleRate',sampleRate);

% Initialize variable timing offset System object
init.varDelay = dsp.VariableFractionalDelay;

end
