%% Estimate Packet Delivery Ratio in Bluetooth Mesh Network
%
% This example models a multi-node Bluetooth mesh network discrete event
% simulation (DES) by using the Communications Toolbox(TM) Library for the
% Bluetooth(R) Protocol. DES is the process of simulating the behavior of a
% system as an ordered and discrete sequence of well-defined events
% occurring in the time domain. DES allows you to model events in a system
% that occur in microsecond granularity. Moreover, DES also results in low
% simulation time thus making it viable to support large-scale system-level
% simulations. The multi-node mesh network simulated in this example models
% the complete Bluetooth mesh stack over the advertising bearer. The
% example aims to accurately model the asynchronous transmissions by using
% DES. The simulation results include packet delivery ratio (PDR),
% node-related statistics, and a plot displaying the visual representation
% of the mesh network.

% Copyright 2019-2020 The MathWorks, Inc.

%% Bluetooth Mesh Stack
%
% The Bluetooth Core Specification [ <#8 1> ] includes a low energy version
% for low-rate wireless personal area networks, referred as Bluetooth low
% energy (BLE) or Bluetooth Smart. The BLE stack consists of the: generic
% attribute profile (GATT), attribute protocol (ATT), security manager
% protocol (SMP), logical link control and adaptation protocol (L2CAP),
% link layer (LL) and physical layer (PHY). BLE was added to the standard
% for low energy devices generating small amounts of data, such as the
% notification alerts used in applications like home automation,
% healthcare, fitness, and the Internet of Things (IoT).
%
% The Bluetooth Mesh Profile [ <#8 2> ] defines the fundamental
% requirements to implement mesh networking solutions for BLE. The mesh
% stack is located on top of the Bluetooth Core Specification and consists
% of the: model layer, foundation model layer, access layer, upper
% transport layer, lower transport layer, network layer and bearer layer.
% Bluetooth mesh networking enables end-to-end communication in large-scale
% networks to support applications like smart lighting, industrial
% automation, sensor networking, asset tracking, and many other IoT
% solutions.
%
% *Mesh Stack*
%
% This figure shows the Bluetooth mesh stack over the advertising bearer.
%
% <<../BluetoothMeshStackOverAdvBearer.png>>
%
% * Model layer: This layer defines the models, messages, and states
% required to create user scenarios. For example, to change the state of a
% light to On or Off, use the 'Generic onOff set' message from the 'Generic
% onOff' model.
%
% * Foundation model layer: This layer defines the models, messages, and
% states required to configure and manage the mesh network. This layer
% configures the element, the publish and the subscription addresses of the
% node.
%
% * Access layer: This layer defines the interface to the upper transport
% layer and the format of the application data. This layer also controls
% the encryption and decryption of the application data in the upper
% transport layer.
%
% * Upper transport layer: The functionality of the upper transport layer
% includes encryption, decryption and authentication of the application
% data and provides confidentiality of the access messages. This layer also
% generates the transport control messages (Friendship and Heartbeat) and
% transmits them to the peer upper transport layer.
%
% * Lower transport layer: The functionality of lower transport layer
% includes segmentation and reassembly of upper transport layer messages
% into multiple lower transport layer messages. This layer helps to deliver
% large upper transport layer messages to other nodes in the network. It
% also defines the Friend queue used by the Friend node to store the lower
% transport layer messages for a Low Power node.
%
% * Network layer: This layer defines encryption, decryption, and
% authentication of the lower transport layer messages. It transmits the
% lower transport layer messages over the bearer layer and relays the mesh
% messages when the 'Relay' feature is enabled. It also defines the message
% cache containing all the recently seen network messages. If the received
% message is in the cache, then it is discarded. The message cache is used
% by the relay nodes (nodes in which the 'Relay' feature is enabled).
%
% * Bearer layer: This layer is an interface between the Bluetooth mesh
% stack and the BLE core stack. This layer is also responsible for creating
% a mesh network by provisioning the devices. Here, provisioning implies
% authenticating and providing basic information to a device. A device must
% be provisioned to become a node. This example assumes all the nodes are
% already provisioned into a mesh network. The two types of bearers
% supported by the Bluetooth mesh are advertising bearer and GATT bearer.
% This example uses only the advertising bearer.
%
% *BLE Core Stack*
%
% This example models these layers of the BLE core stack:
%
% * Generic access profile: This profile defines advertising data (AD)
% types for carrying mesh messages over the advertising bearer. This
% example supports 'Mesh message' AD type, which is used for exchanging
% network layer messages between mesh nodes.
%
% * Link layer: This layer defines Broadcaster and Observer roles for
% message exchange between the nodes within the Bluetooth mesh network. In
% a Broadcaster role, a node always advertises. Whereas in an Observer
% role, the node always scans for the advertisers. Each node in the mesh
% network switches between these two roles to serve as a Bluetooth mesh
% node.
%
% * Physical layer: This layer transmits and receives the waveforms for
% exchanging messages between the nodes within the Bluetooth mesh network.
% This layer models channel impairments such as free-space path loss, range
% propagation loss, and interference.

%% Discrete Event Simulation
%
% DES is a type of simulation that models the functioning of a system as a
% discrete sequence of events in the time domain. Each event occurs at a
% specific time epoch and subsequently marks a change of state in the
% system. As a result, the simulation can directly jump from event to event
% in the time domain. The fundamental advantages of using DES in this
% example are:
%
% * Its flexibility in time handling to suppress or expand, allowing the
% simulation to speed-up or slow-down the phenomena under investigation.
% This property of DES is used to model asynchronous transmissions in a
% multi-node Bluetooth network, resulting in accurate modeling of
% collisions.
%
% * DES improves the simulation time performance and thus makes it feasible
% to support large-scale system-level simulations. For accurate modeling in
% a MATLAB implementation, simulations might need to run in microsecond
% steps. This will not only increase the simulation time but will also
% impact the network scalability. An increase in the step time might not
% allow you to capture or schedule events that occur in the microsecond
% granularity. DES enables you to address this issue by modeling events in
% discrete points in time.

%% Check for Support Package Installation

% Check if the 'Communications Toolbox Library for the Bluetooth Protocol'
% support package is installed or not.
commSupportPackageCheck('BLUETOOTH');

%% Multi-Node Bluetooth Mesh Network Model
%
% This example models a Bluetooth mesh network with 21 nodes. The model
% outputs PDR of the network along with different statistics such as the
% number of transmitted, received, and dropped packets at physical, link,
% and network layers, and also a plot visualizing the network scenario. The
% modeling includes:
%
% * Multiple nodes, where each node contains a Bluetooth mesh packet
% generator and receiver (mesh packet includes model, access, and transport
% layer encoding and decoding), network layer, link layer, and physical
% layer
% * A shared channel, which is simulated with these channel impairment
% options: range propagation loss, free-space path loss, and interference
% * Packets transmitted over the shared channel
% * A node position allocator (NPA) that configures the position of nodes
% in the network. NPA supports linear, grid, and list allocation strategies
% * A visualizer that visualizes the mesh network scenario
%
% <<../BluetoothMeshDESModel.png>>
%
% To configure a specific scenario, do one of these:
%
% * Update the default configuration parameters for each node in the
% preceding model
%
% * Specify the configuration as an input to
% <matlab:edit('helperBLEMeshCreateNetworkModel')
% helperBLEMeshCreateNetworkModel> for creating a mesh network model
%
% *Bluetooth node*
%
% Each node is modeled as a subsystem with a network stack, which includes
% the Bluetooth mesh packet generator and receiver, network layer, LL, and
% PHY.
%
% <<../BluetoothMeshDESNode.png>>
%
% * The application layer generates packets by using the
% <docid:simevents_ref#bu3zmqp-1 Entity Generator> block
% * The <docid:simevents_ref#bu4khrj-1 MATLAB Discrete-Event System> block 
% is used to model the network layer, LL, and PHY
% * In each node, the shared channel is modeled in the receive path
%
% *Application layer*
%
% The application layer is implemented to generate and receive application
% traffic. It is divided into two sub-blocks:
%
% <<../BluetoothMeshDESAppLayer.png>>
%
% * *Bluetooth mesh packet generator* This block uses the SimEvents Entity
% Generator block to generate lower transport data protocol data unit
% (PDU). The generated PDU contains the model layer message of type
% 'Generic onOff set unacknowledged' appended with higher layer headers.
% This PDU is passed to the network layer. You can configure the
% application state (On/Off), name of the destination node, source rate (in
% packets/second), and maximum number of packets that can be transmitted
% from source to destination by using this block. The block stops
% generating the packets once it has generated the maximum number of
% packets configured.
%
% * *Bluetooth mesh packet receiver* This block uses the SimEvents Entity
% Terminator block to receive the output from the network layer
%
% *Network layer*
%
% The network layer is modeled as a DES block. This block is responsible
% for transmitting the lower transport layer messages over the advertising
% bearer and relaying the mesh messages when the 'Relay' feature is
% enabled. When a network PDU is received, this block decodes the received
% PDU. If the PDU is decoded successfully, then the decoded information is
% passed to the lower transport layer.
%
% <<../BluetoothMeshDESNetLayer.png>>
%
% You can configure the relay feature, network transmit interval, network
% transmit count, relay retransmit interval, and relay retransmit count by
% using mask parameters of the Network layer block.
%
% *Link layer*
%
% The link layer is modeled as a DES block. This block maintains a state
% machine for LL Broadcaster and Observer roles. This block is responsible
% for transmitting and receiving the mesh advertising packets by using
% <docid:comm_ref#mw_fccd1d53-97fd-42f0-bc75-3dcc8a93ca5e
% bleLLAdvertisingChannelPDU> and
% <docid:comm_ref#mw_0309e66e-dc52-4189-872e-2523a76669de
% bleLLAdvertisingChannelPDUDecode> functions.
%
% <<../BluetoothMeshDESLinkLayer.png>>
%
% You can configure scan and advertising intervals by using mask parameters
% of the Link layer block.
%
% *Physical layer*
%
% The PHY functionality includes:
%
% * *Transmit chain*
%
% LL initiates packet transmission by sending an LL packet and Tx
% indication to the PHY Tx block. This block generates a waveform for the
% received LL packet by using the <docid:comm_ref#fcn_bleWaveformGenerator
% bleWaveformGenerator> function. It also scales the samples of the BLE
% waveform with the configured Tx power (assuming Tx gain is 0). The
% generated BLE waveform is transmitted through the shared channel. The
% shared channel is modeled by using the SimEvents Multicast Queue.
%
% <<../BluetoothMeshDESPHYTx.png>>
%
% You can configure the Tx power (dBm) by using mask parameters of the PHY
% Tx block.
%
% * *Channel impairments modeling*
%
% The free-space path loss model is added to the transmitted BLE waveform
% as channel impairments. You can choose to enable or disable this
% impairment. In addition to this impairment model, the signal reception
% range can also be limited by using an optional range propagation loss
% model. To model any of these channel impairment options, the channel
% model must contain the position of both the sender and the receiver. The
% channel is modeled inside each receiving node, before passing the BLE
% waveform to the PHY Rx block.
%
% <<../BluetoothMeshDESChannel.png>>
%
% You can configure channel impairments by using mask parameters of the BLE
% channel block.
%
% * *Receive chain* 
%
% This block applies thermal noise and interference to the received BLE
% waveform (assuming Rx gain is 0). Thermal noise is modeled by using the
% <docid:comm_ref#bsnfiz3_6 comm.ThermalNoise> function with the configured
% value of the noise figure. Interference is modeled by adding the IQ
% samples of both the interfered and the actual signals. After applying
% thermal noise and interference, PHY Rx block decodes the resultant
% waveform. If the LL packet is decoded successfully, then it is passed to
% the LL.
%
% <<../BluetoothMeshDESPHYRx.png>>
%
% You can configure the noise figure (in dB) using mask parameters of the
% PHY Rx block.
%
% *Node position allocator (NPA)* Assigns the location of nodes in the mesh
% network. This block supports linear, grid, and list position allocation
% strategies.
% 
% * *Linear position allocation* Places nodes uniformly in a straight line
% on a 2D grid
% 
% * *Grid position allocation* Places nodes in a grid format specified by
% the grid properties
%
% * *List position allocation* Assigns node positions from a list [[x1,
% y1, z1] [x2, y2, z2] ... [xn, yn, zn]] such that (xk, yk, zk) is the
% position of the kth node for all k in (1, 2, ..., n)
%
% *Visualizer* This block is used to visualize the mesh network scenario
% in the simulation. You can configure this block to visualize the
% specified configuration. You can enable or disable visualization by using
% the mask parameters of this block.

%% Simulation Results
%
% The results obtained in this simulation are:
%
% * *Packet delivery ratio (PDR)*
%
% The PDR is the ratio of number of received packets at the destination to
% the number of packets transmitted by the source and is given by:
%
% <<../BluetoothMeshDESPDREquation.png>>
%
% This model outputs PDR for this multi-node mesh network and is saved to a
% base workspace variable named |PDR|.
%
% * *Statistics at each node*
%
% This model outputs statistics of each node in the workspace variable
% |statisticsAtEachNode|. The statistics captured at each node are:
%
% * Number of transmitted and received messages at the PHY
% * Number of transmitted and received messages at the LL
% * Number of messages received with CRC failures
% * Number of transmitted, received, and dropped messages at the network layer
% * Number of messages relayed at the network layer
% * Number of received application messages at the network layer
%
% * *Network visualization*
%
% A plot with visual representation of the mesh network scenario is shown
% in the simulation. You can see the statistics of each node by placing
% your cursor over it.
%
%
% <<../BluetoothMeshDESPlot.png>>
%
% This example shows how to configure and simulate a multi-node Bluetooth
% mesh network by using DES. The mesh network model in this example outputs
% PDR as a workspace variable with a visual representation of the mesh
% network.

%% Further Exploration
%
% To observe the variation in the network PDR, you can vary the
% configuration parameters at the mesh packet generator, the network layer,
% LL and PHY. In these simulation results, you can see the impact of
% network layer repetitions (NLR) on the network PDR.
%
% <<../BluetoothMeshDESPDR.png>>
%
% The NLR includes the repetitions of both the network messages and the
% relayed messages. The working principle of flood-based networks ensures
% that the message reaches the destination node. Therefore, it is important
% to retransmit the network and the relay messages. The number of NLR is
% dependent on the network configuration of the given network topology.
% Increasing the number of NLR ensures that the likelihood of the messages
% reaching the desired destination node is high. However, specifying a high
% value of the NLR can have adverse effects on the network performance
% parameters such as the overhead, energy consumption, and the duty cycle.
% As a result, it is essential to tune the value of NLR for a given network
% topology and achieve an efficient tradeoff between the PDR and network
% performance.
%
% In the preceding figure you can see that the PDR increases with the NLR
% and decreases with the number of source nodes in the network. For a
% specific value of the NLR, the PDR value reaches 1 and thereafter it
% stabilizes. This specific value of the NLR might vary based on the
% network configuration parameters such as the total number of nodes,
% location of the nodes, number of source nodes, number of relay nodes, and
% so on. You can run <matlab:edit('helperBLEMeshDESPDRCalculation')
% helperBLEMeshDESPDRCalculation> to reproduce these results by using three
% source nodes. Set the number of source nodes to two and five to get the
% corresponding results. You can run the simulations for any custom network
% scenario and get the optimal value of the NLR.
%
% Apart from the NLR, the PDR varies with respect to multiple configuration
% parameters stated in <matlab:edit('helperBLEMeshDESPDRCalculation')
% helperBLEMeshDESPDRCalculation>. You can further explore the mesh network
% model by varying any of these parameters.

%% Appendix
%
% The example uses these features:
%
% * <docid:comm_ref#obj_bleLLAdvertisingChannelPDUConfig
% bleLLAdvertisingChannelPDUConfig>: Create a configuration object for the
% BLE Link Layer advertising channel PDU
% * <docid:comm_ref#mw_fccd1d53-97fd-42f0-bc75-3dcc8a93ca5e
% bleLLAdvertisingChannelPDU>: Generate BLE Link Layer advertising channel
% PDU
% * <docid:comm_ref#mw_0309e66e-dc52-4189-872e-2523a76669de
% bleLLAdvertisingChannelPDUDecode>: Decode BLE Link Layer advertising
% channel PDU
% * <docid:comm_ref#fcn_bleWaveformGenerator bleWaveformGenerator>:
% Generate BLE waveform
%
% The example uses these helpers:
%
% * <matlab:edit('helperBLEMeshAppGenericPDU') helperBLEMeshAppGenericPDU>:
% Generate Bluetooth mesh generic PDU
% * <matlab:edit('helperBLEMeshAccessPDU') helperBLEMeshAccessPDU>:
% Generate Bluetooth mesh access PDU
% * <matlab:edit('helperBLEMeshTransportDataMessage')
% helperBLEMeshTransportDataMessage>: Generate Bluetooth mesh transport
% data message
% * <matlab:edit('helperBLEMeshNetworkLayer') helperBLEMeshNetworkLayer>:
% Create an object for Bluetooth mesh network layer functionality
% * <matlab:edit('helperBLEMeshNetworkLayerDES')
% helperBLEMeshNetworkLayerDES>: Model Bluetooth mesh network layer
% * <matlab:edit('helperBLEMeshNetworkPDU') helperBLEMeshNetworkPDU>:
% Generate Bluetooth mesh network PDU
% * <matlab:edit('helperBLEMeshNetworkPDUDecode')
% helperBLEMeshNetworkPDUDecode>: Decode Bluetooth mesh network PDU
% * <matlab:edit('helperBLEMeshLLGAPBearer') helperBLEMeshLLGAPBearer>:
% Create an object for BLE LL advertising bearer functionality
% * <matlab:edit('helperBLEMeshLinkLayerDES') helperBLEMeshLinkLayerDES>:
% Model Bluetooth mesh link layer
% * <matlab:edit('helperBLEMeshGAPDataBlock') helperBLEMeshGAPDataBlock>:
% Generate advertising data with Bluetooth mesh network PDU
% * <matlab:edit('helperBLEMeshGAPDataBlockDecode')
% helperBLEMeshGAPDataBlockDecode>: Decode advertising data with Bluetooth
% mesh network PDU
% * <matlab:edit('helperBLEPHYTransmitter') helperBLEPHYTransmitter>:
% Create an object for BLE PHY transmitter
% * <matlab:edit('helperBLEPHYTxDES') helperBLEPHYTxDES>: Generate and
% transmit the BLE waveform
% * <matlab:edit('helperBLEChannel') helperBLEChannel>:
% Create an object for BLE channel model
% * <matlab:edit('helperBLEChannelDES') helperBLEChannelDES>: Apply channel
% model on the received BLE waveform
% * <matlab:edit('helperBLEPHYReceiver') helperBLEPHYReceiver>:
% Create an object for BLE PHY receiver
% * <matlab:edit('helperBLEPHYRxDES') helperBLEPHYRxDES>: Receive and
% decode the BLE waveform
% * <matlab:edit('helperBLEPracticalReceiver') helperBLEPracticalReceiver>:
% Demodulate and decode the received signal
% * <matlab:edit('helperBluetoothQueue') helperBluetoothQueue>: Create an
% object for Bluetooth queue functionality
% * <matlab:edit('helperBLEMeshRetransmissions')
% helperBLEMeshRetransmissions>: Create an object for retransmissions in
% Bluetooth mesh
% * <matlab:edit('helperBLEMeshVicinityNodes') helperBLEMeshVicinityNodes>:
% Obtain the vicinity nodes of a given node
% * <matlab:edit('helperBLEMeshGraphCursorCallback')
% helperBLEMeshGraphCursorCallback>: Display the node statistics on mouse
% hover action
% * <matlab:edit('helperBLEMeshVisualizeNetwork')
% helperBLEMeshVisualizeNetwork>: Create an object for Bluetooth mesh
% network visualization
% * <matlab:edit('helperBLEMeshAssignNodeIDs') helperBLEMeshAssignNodeIDs>:
% Assigns node IDs to all the nodes in the model
% * <matlab:edit('helperBLEMeshGetNodeNamesList') helperBLEMeshGetNodeNamesList>:
% Get the list of nodes in the model
% * <matlab:edit('helperBLEMeshCreateNetworkModel')
% helperBLEMeshCreateNetworkModel>: Create a Bluetooth mesh network with
% given configuration
% * <matlab:edit('helperBLEMeshUpdateStatistics')
% helperBLEMeshUpdateStatistics>: Create and update statistics in a
% Bluetooth mesh network simulation

%% References
%
% # Bluetooth Special Interest Group (SIG). "Bluetooth Core Specification".
% Version 5.0. https://www.bluetooth.com/.
% # Bluetooth Special Interest Group (SIG). "Bluetooth Mesh Profile".
% Version 1.0. https://www.bluetooth.com/.
