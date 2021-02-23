function [messageType, genericPDU] = helperAppGeneric(ApplicationState)
    switch ApplicationState
                case 0
                    return;
                case 1   % Mode: send OnOff packet
                    % Model PDU ('Generic onOff set unacknowledged') from mesh generic model
                    [messageType, genericPDU] = helperBLEMeshAppGenericPDU('Generic onOff set unacknowledged', 1, 1, 10, 2, 5);                    
                case 2   % Mode: send Relay config packet: Relay = Off
                    [messageType, genericPDU] = helperBLEMeshAppGenericPDU('Config set', 1, 0);
                case 3   % Mode: send Relay config packet: TTL = 15
                    [messageType, genericPDU] = helperBLEMeshAppGenericPDU('Config set', 2, 15);
                otherwise
                    fprintf('Application type not supported.\n');
    end
end