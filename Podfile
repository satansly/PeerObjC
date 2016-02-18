platform :ios, "7.0"






def import_pods
    pod "SocketRocket"
    pod "libjingle_peerconnection"
    pod "EventEmitter"
    pod "CocoaLumberjack"
end

def test_pods
     pod "OCMock"
end

target 'OGPeerObjC' do
    import_pods
    podspec
end

target 'OGPeerObjCTests' do
    test_pods
    podspec
end
