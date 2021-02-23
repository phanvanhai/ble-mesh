function [txImpairedWfm] =  helperBLEImpairments(initImpairments, txWaveform, sps)
%helperBLEImpairments Adds impairments to the BLE waveform
%   [TXIMPAIREDWFM] = helperBLEImpairments(INITIMPAIRMENTS, TXWAVEFORM,
%   SPS) adds impairments to the BLE waveform.

%   Copyright 2019 The MathWorks, Inc.

% Define the RF impairment parameters
initImpairments.pfo.FrequencyOffset = randsrc(1,1,-50e3:10:50e3); % In Hz, Max range is +/- 150 KHz
initImpairments.pfo.PhaseOffset = randsrc(1,1,-10:5:10);;        % In degrees
initoff = 0.15*sps; % Static timing offset
stepsize = 20*1e-6; % Timing drift in ppm, Max range is +/- 50 ppm
txWaveform = [txWaveform; zeros(ceil(initoff/sps)*sps,1)];
initImpairments.vdelay = (initoff:stepsize:initoff+stepsize*(length(txWaveform)-1))'; % Variable timing offset
initImpairments.dc = 20;     % Percentage w.r.t maximum amplitude value

% Pass the generated waveform through RF impairments
txImpairedWfm = helperBLEImpairmentsAddition(txWaveform, initImpairments);

end
