classdef AppDES < matlab.DiscreteEventSystem
    % AppDES Add summary here
    %
    % This template includes the minimum set of functions required
    % to define a Discrete Event System object.
    
    % Public, tunable properties
    properties
        %NodeID Unique device identification number
        NodeID (1, 1) {mustBeInteger, mustBeGreaterThan(NodeID, 0)} = 1
        
        %DestinationNode Unique device identification number of destination node
        DestinationNode (1, 1) {mustBeInteger, mustBeGreaterThan(DestinationNode, 0)} = 1
        
        %ApplicationState 
        % 0- EndNode, 1- Send OnOff, 2- Send Relay config, 3- Send TTL
        % config
        ApplicationState = 0
        
        %SourceRate 
        SourceRate (1, 1) = 1       
        
        %TotalPackets 
        TotalPackets (1, 1) {mustBePositive, mustBeInteger} = 1       
    end
    
    
    % Constant, Hidden properties
    properties (Constant, Hidden)
        %DefaultPriority Default priority for an event
        DefaultPriority = 100

        %USecPerSec Microseconds per second
        USecPerSec = 1e6  
        
        %LowerTransportPDUOutQueueID
        LowerTransportPDUOutQueueID = 1

        %LowerTransportPDUInQueueID
        LowerTransportPDUInQueueID = 3

        %NetworkLayerTimerQueueID
        InternalQueueID = 4
        
        %NetworkLayerConfigQueueID
        NetworkLayerConfigQueueID = 2
    end
    
        % Constant, Hidden properties
    properties (Hidden)                
        PacketInterval = 0
        PacketCount = 0
        TTL = 127
        ConfigParam = 0
        ConfigValue = 0
    end

    % Discrete-event algorithms
    methods       
        function events = setupEvents(obj)
            % Set up entity generation events at start of simulation         
            events = obj.initEventArray();
            if obj.ApplicationState > 0 && obj.PacketCount <= obj.TotalPackets
                events = [events, obj.eventGenerate(obj.InternalQueueID, 'Start timer', 0, obj.DefaultPriority)];
            end
            
            if obj.ApplicationState == 1
                obj.TTL = 20;
            elseif obj.ApplicationState == 2
                obj.TTL = 1;
            elseif obj.ApplicationState == 3
                obj.TTL = 1;
            end
        end
        
        % Invoke network layer object
        function [entity, events] = internalGenerate(obj, ~, entity, ~)
            % Initialize events array
            events = obj.initEventArray();
            
            % Schedule timer event
            if obj.ApplicationState > 0 && obj.PacketCount <= obj.TotalPackets
                events = [events, obj.eventTimer('schedule generate pdu', obj.PacketInterval/obj.USecPerSec)];
            end  
        end

        % xu ly su kien timer
        function [entity,events] = internalTimer(obj,~,entity,~)
            % Specify event actions when entity timer completed            
            % Initialize events array
            events = obj.initEventArray();
            
            coder.extrinsic('fprintf');            
            obj.PacketCount = obj.PacketCount + 1;
            if obj.PacketCount <= obj.TotalPackets   
                if obj.ApplicationState == 1
                    fprintf('App layer:     Node:%f generate OnOff PDU\n', obj.NodeID);
                    events = [events, obj.eventGenerate(obj.LowerTransportPDUOutQueueID, 'Generate OnOff PDU', 0, obj.DefaultPriority)];                    
                elseif obj.ApplicationState == 2 %&& obj.PacketCount == 2
                    fprintf('App layer:     Node:%f generate Relay Config PDU\n', obj.NodeID);
                    events = [events, obj.eventGenerate(obj.LowerTransportPDUOutQueueID, 'Generate Relay PDU', 0, obj.DefaultPriority)];                    
                elseif obj.ApplicationState == 3 %&& obj.PacketCount == 2
                    fprintf('App layer:     Node:%f generate TTL Config PDU\n', obj.NodeID);
                    events = [events, obj.eventGenerate(obj.LowerTransportPDUOutQueueID, 'Generate TTL PDU', 0, obj.DefaultPriority)];                    
                end
                events = [events, obj.eventTimer('generate pdu', obj.PacketInterval/obj.USecPerSec)];
            end
        end
        
        % Invoke network layer object
        function [entity, events] = transportPDUOutGenerate(obj, ~, entity, tag)
            % Initialize events array
            events = obj.initEventArray();
            
            coder.extrinsic('fprintf');     
            coder.extrinsic('helperBLEMeshAppGenericPDU');
            coder.extrinsic('helperBLEMeshAccessPDU');
            coder.extrinsic('helperBLEMeshTransportDataMessage');
            coder.extrinsic('helperAppGeneric');            
            
            [msgType, appPDU] = helperAppGeneric(obj.ApplicationState);
            
            % Generate access PDU
            accessPDU = helperBLEMeshAccessPDU(msgType, appPDU);
            % Generate transport data PDU
            transportDataPDU = helperBLEMeshTransportDataMessage(accessPDU);
            
            % Lower transport data PDU length
            transportDataPDULen = numel(transportDataPDU);
            entity.data.Length = transportDataPDULen;                                          
            % Lower transport data PDU
            entity.data.PDU(1:entity.data.Length) = transportDataPDU';            
            % Type of lower transport data
            entity.data.CTL = 0;
            % Source address of the packet
            srcAddress = hex2dec(reshape(dec2hex(obj.NodeID, 4), 2, [])');
            entity.data.SourceAddress = [srcAddress(1); srcAddress(2)];
            % Destination address of the packet
            dstAddress = hex2dec(reshape(dec2hex(obj.DestinationNode, 4), 2, [])');
            entity.data.DestinationAddress = [dstAddress(1); dstAddress(2)];
            % TTL
            entity.data.TTL = obj.TTL;
            
            fprintf('App layer:     Node:%f send the message to Node:%f with TTL=%f\n',obj.NodeID, dstAddress(1)*256 + dstAddress(2),...
                                                                        entity.data.TTL);
            events = [events, obj.eventForward('output', obj.LowerTransportPDUOutQueueID, 0)]; 
        end
        
        % Lower transport PDU In entry action
        function [entity, events] = transportPDUInEntry(obj, ~, entity, ~)
            coder.extrinsic('fprintf');            
            % Initialize events array
            events = obj.initEventArray();
            % Get data from entity
            src =  reshape(dec2hex(entity.data.SourceAddress, 2)', 1, []);
            dst = reshape(dec2hex(entity.data.DestinationAddress, 2)', 1, []);
            ttl = entity.data.TTL;
            ctl = entity.data.CTL;
            length = entity.data.Length;            
            lowerTransportPDU = entity.data.PDU(1:entity.data.Length);
            fprintf('App layer:     Node:%f has received the message from Node:%f with TTL=%f\n',obj.NodeID, ...
                                                entity.data.SourceAddress(1)*256 + entity.data.SourceAddress(2), ttl);
            events = obj.lowerTransportPDURecieverHandle(src, dst, ttl, ctl, length, lowerTransportPDU, events);                        
            % Destroy entity
            events = [events, obj.eventDestroy()];
        end
        
        function [entity, events] = configGenerate(obj, ~, entity, ~)
            % Initialize events array
            events = obj.initEventArray();
            entity.data.ConfigParam = obj.ConfigParam;
            entity.data.ConfigValue = obj.ConfigValue;
            events = [events, obj.eventForward('output', obj.NetworkLayerConfigQueueID, 0)]; 
        end

        % Specify actions when receiver low transport PDU:
        function events = lowerTransportPDURecieverHandle(obj, src, dst, ttl, ctl, length, lowerTransportPDU, events)
            coder.extrinsic('fprintf');     
            coder.extrinsic('helperBLEMeshAppGenericPDUDecode');
            coder.extrinsic('helperBLEMeshAccessPDUDecode');
            coder.extrinsic('helperBLEMeshTransportDataMessageDecode');
            
            accessPDU = helperBLEMeshTransportDataMessageDecode(lowerTransportPDU);
            [messageType, modelPDU] = helperBLEMeshAccessPDUDecode(accessPDU);
            [messageType, data1, data2] = helperBLEMeshAppGenericPDUDecode(messageType, modelPDU);
            if strcmp(messageType, 'Config set')                    
                    obj.ConfigParam = double(data1);
                    obj.ConfigValue = double(data2);                    
                    if obj.ConfigParam == 1
                        fprintf('App layer:     Node:%f sets Relay feature = %f\n', obj.NodeID, obj.ConfigValue);
                        events = [events, obj.eventGenerate(obj.NetworkLayerConfigQueueID, 'Generate Config', 0, obj.DefaultPriority)];
                    end
                    
                    if obj.ConfigParam == 2
                        obj.TTL = obj.ConfigValue;
                        fprintf('App layer:     Node:%f sets TTL config = %f\n', obj.NodeID, obj.TTL);
                    end                    
            end
        end
        
        function obj = AppDES(~)             
        end
        
        % Set Node ID
        function set.NodeID(obj, value)            
            % Validate node ID 
            coder.extrinsic('helperBLEMeshValidateNodeID');
            helperBLEMeshValidateNodeID(value);
            obj.NodeID = value;           
        end
        
        % Set DestinationNode
        function set.DestinationNode(obj, value)            
            % Validate node ID 
            coder.extrinsic('helperBLEMeshValidateNodeID');
            helperBLEMeshValidateNodeID(value);
            obj.DestinationNode = value;           
        end
        
        % Set ApplicationState
        function set.ApplicationState(obj, value)                           
            obj.ApplicationState = value;                        
        end
        
        % Set SourceRate
        function set.SourceRate(obj, value)                           
            obj.SourceRate = value;                      
        end

        % Set TotalPackets
        function set.TotalPackets(obj, value)                           
            obj.TotalPackets = value;                      
        end
    end

    methods(Access = protected)
        function entityTypes = getEntityTypesImpl(obj)            
            % Return entity type structures with fields specifying
            % properties such as name, size, data type, and complexity
            entityTypes = [obj.entityType('transportPDUOut', 'LowerTransportPDU'), ...
                            obj.entityType('config', 'NetworkConfig'), ...
                            obj.entityType('transportPDUIn', 'LowerTransportPDU'), ...
                            obj.entityType('internal', 'double', [1, 1], false)];
        end

        function [inputTypes,outputTypes] = getEntityPortsImpl(obj)
            % Specify entity input and output ports. Return entity types at
            % a port as strings in a cell array. Use empty string to
            % indicate a data port.
            inputTypes = {'transportPDUIn'};
            outputTypes = {'transportPDUOut', 'config'};
        end

        function [storageSpec,I,O] = getEntityStorageImpl(obj)
            % Return entity storage specification and connectivity
            % information from input ports and output ports to storage
            queueSize = 2;
            storageSpec = [obj.queueFIFO('transportPDUOut', queueSize), ...
                obj.queueFIFO('config', queueSize), ...
                obj.queueFIFO('transportPDUIn', queueSize), ...
                obj.queueFIFO('internal', queueSize)];
            I = obj.LowerTransportPDUInQueueID;
            O = [obj.LowerTransportPDUOutQueueID, obj.NetworkLayerConfigQueueID];
        end

        function setupImpl(obj)            
            % Perform one-time calculations, such as computing constants
            obj.PacketInterval = round((1/obj.SourceRate)*1e6);
            
            % Set rng seed
            rng(obj.NodeID);
        end

        function resetImpl(obj)            
            % Initialize / reset discrete-state properties
        end

        function num = getNumInputsImpl(obj)
            % Define total number of inputs for system with optional inputs
            num = 1;           
        end

        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system with optional
            % outputs
            num = 2;            
        end
        
         % Define names for input ports used in this Discrete Event System
        function name = getInputNamesImpl(~)
            % Specify names for input ports
            name = 'transportPDUIn';            
        end

        function [out1, out2] = getOutputNamesImpl(obj)
            % Return output port names for System block
            out1 = 'transportPDUOut';
            out2 = 'networkConfig';
        end
    end
end
