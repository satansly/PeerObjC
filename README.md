# PeerObjectiveC

## About

<b>PeerObjC</b> is PeerJS port to iOS. It allows you to setup your client easily and communicate to [peerjs-server](https://github.com/peers/peerjs-server).

This library inspires from  [AppRTCDemo](https://code.google.com/p/webrtc/source/browse/trunk/talk/examples/ios/?r=4466#ios%2FAppRTCDemo) (that Google has been published) for [peerjs-server](https://github.com/peers/peerjs-server) signaling process and [PeerJS](http://peerjs.com/) 
and [PeerObjectiveC](https://github.com/hiroeorz/PeerObjectiveC.git).

## Getting Started

1. Install via cocoapods

    ```
    $ pod 'PeerObjC'
    ```
2. Get PeerJS API Key or setup your own server
Go to [PeerJS Server](http://peerjs.com/peerserver) and create an API key.

3. Initialize ```OGPeerOptions``` and set server details as needed:
	
	Custom server
	
    ```objectivec
	OGPeerOptions * options = [[OGPeerOptions alloc] init];
    options.key = @"peerjs";
    options.host = @"192.198.0.3";
    options.port = @(9000);
    options.path = @"";
    options.secure = NO;
    options.config = [OGPeerConfig defaultConfig];
    options.debugLevel = DDLogLevelDebug;
    ```
    
    PeerJS Cloud

    ```objectivec    
    OGPeerOptions * options = [[OGPeerOptions alloc] init];
    options.key = @"<your api key>";
    options.config = [OGPeerConfig defaultConfig];
    options.debugLevel = DDLogLevelDebug;
    ```    
        
3. Initialize ```OGPeer``` with options to create connection


    ```objectivec
    OGPeer * peer = [[OGPeer alloc] initWithId:@"<your peer id>" options:options];
    [peer addDelegate:self]; //Important for receiving updates from peer
    
    ```

4. Connect to a peer for data/messages exchange

	```objectivec
    	OGDataConnectionOptions * options = [[OGDataConnectionOptions alloc] init];
        options.label = @"MyLabel";
        options.serialization = OGSerializationBinary;
        OGDataConnection * conn = [_peer connect:@"<other peer id>" options:options];
	```
5. Call a peer with Audio/Video call

	```objectivec
            OGMediaConnectionOptions* moptions = [[OGMediaConnectionOptions alloc] init];
            moptions.type = OGStreamTypeBoth;
            moptions.direction = AVCaptureDevicePositionFront;
            OGMediaConnection * mconnection = [_peer call:@"<other peer id>" options:moptions];
	```
	
6. To receive data and media connections. Implement ```OGMediaConnectionDelegate``` and ```OGDataConnectionDelegate``` and remember to add the delegate class via ```addDelegate:``` method            


## License

MIT