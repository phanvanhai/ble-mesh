classdef helperBLEMeshRetransmissions < handle
% helperBLEMeshRetransmissions Retransmissions in Bluetooth mesh
%   MESHRTX = helperBLEMeshNetworkLayer creates a Bluetooth mesh
%   retransmission object with properties and methods related to
%   retransmissions. This object retransmits the PDU with specified count
%   and interval.
%
%   MESHRTX = helperBLEMeshNetworkLayer(Name, Value) creates a Bluetooth
%   mesh retransmission object with the specified property Name set to the
%   specified Value. You can specify additional name-value pair arguments
%   in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   helperBLEMeshRetransmissions properties:
%
%   Count        - Count of retransmissions
%   Interval     - Interval between retransmissions
%   AckReceived  - Acknowledgment received
%
%   helperBLEMeshRetransmissions methods:
%
%   runRtx  - Runs timer logic
%   reset   - Reset configuration

%   Copyright 2019 The MathWorks, Inc.

%#codegen

% Public properties
properties
    %Count Count of retransmissions
    %   Specify the count as an integer. This value indicates the count of
    %   retransmissions. The default value is 1.
    Count = 1
    
    %Interval Interval between retransmissions
    %   Specify the interval as an integer. This value indicates the
    %   interval between each transmission. Each unit is taken as one
    %   millisecond. The default value is 10.
    Interval = 10
    
    %AckReceived Flag indicating acknowledgment
    %   Specify this property as a scalar logical. A true value indicates
    %   that the acknowledgment is received. The default value is false.
    AckReceived (1, 1) logical = false
end
    
% Private properties
properties (Access = private)
    %Initial timer maintained by this module
    pInitialTimer = 0
    
    %Initial count as specified
    pCount = 0
end
    
% Public methods
methods
    % Constructor
    function obj = helperBLEMeshRetransmissions(varargin)
        % Assign constructor name-value pairs
        for idx = 1:2:nargin
            obj.(varargin{idx}) = varargin{idx+1};
        end
    end
    
    % Set count
    function set.Count(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>', 0}, mfilename, 'Count');
        obj.Count = value;
    end
    
    % Set interval
    function set.Interval(obj, value)
        validateattributes(value, {'numeric'}, {'scalar', ...
            'integer', '>', 0}, mfilename, 'Interval');
        obj.Interval = value;
    end
    
    % Run retransmission object
    function [nextInvokeTime, retransmit, stopRetransmission] = runRtx(obj, elapsedTime)
        %runRtx Run retransmission object
        %
        %   This function performs the following operations:
        %       * Indicates the caller function when timer met the interval
        %       * Indicates the caller function when specified count of
        %         timer events are completed
        %
        %   [NEXTINVOKETIME, RETRANSMIT, STOPRETRANSMISSION] = run(OBJ,
        %   ELAPSEDTIME) performs retransmission.
        %
        %   NEXTINVOKETIME is the time units after which this handle object
        %   should be invoked again.
        %
        %   RETRANSMIT retransmit the PDU.
        %
        %   STOPRETRANSMISSION stop retransmission.
        %
        %   ELAPSEDTIME is the time units elapsed between the previous and
        %   current call of this handle object.
        
        % By default, set the flags to false
        retransmit = false;
        stopRetransmission = false;
        
        % Increment timer
        obj.pInitialTimer = obj.pInitialTimer + elapsedTime;
        % Update next event time
        nextInvokeTime = obj.Interval - obj.pInitialTimer;
            
        % Stop timer when the acknowledgment received
        if  obj.AckReceived
            stopRetransmission = true;
            reset(obj);
            nextInvokeTime = 0;
            return;
        end
        
        % Start retransmission when timer meets specified interval
        if (obj.pInitialTimer == obj.Interval)
            % Set retransmission flag
            retransmit = true;
            % Reset timer
            obj.pInitialTimer = 0;
            % Increment count
            obj.pCount = obj.pCount + 1;
            % Update next event time
            nextInvokeTime = obj.Interval;
            
            % Stop timer when specified retransmissions completed
            if obj.pCount == obj.Count
                stopRetransmission = true;
                reset(obj);
                nextInvokeTime = 0;
                return;
            end
        end
    end
    
    % Reset retransmission object
    function reset(obj)
        %reset Reset retransmission object
        obj.pInitialTimer = 0;
        obj.pCount = 0;
    end
end
end
