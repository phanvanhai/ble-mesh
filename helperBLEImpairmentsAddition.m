function txImpairedWfm = helperBLEImpairmentsAddition(txWaveform,init)
%helperBLEImpairmentsAddition Adds RF impairments to the BLE
%waveform
%
%   TXIMPAIREDWFM = helperBLEImpairmentsAddition(TXWAVEFORM,INIT) adds
%   RF impairments to the transmitted waveform, TXWAVEFORM,
%   based on INIT and outputs the impaired waveform, TXIMPAIREDWFM. INIT is
%   a structure which contains the parameters corresponding to DC, frequency,
%   phase offsets and timing drift.
%   The following RF impairments are added to the TXWAVEFORM.
%   * DC offset
%   * Carrier frequency offset
%   * Carrier phase offset
%   * Timing drift
%
%   See also bleWaveformGenerator, bleIdealReceiver.

%   Copyright 2018-2019 The MathWorks, Inc.

% Add frequency and phase offset
txWfmFreqPhaseOffset = init.pfo(txWaveform);

% Add timing drift
txWfmTimeOffset = init.varDelay(txWfmFreqPhaseOffset,init.vdelay);

% Add DC offset
dcValue = (init.dc/100)*max(txWfmTimeOffset);
txImpairedWfm = txWfmTimeOffset + dcValue;

% Release the System objects
release(init.pfo);

end