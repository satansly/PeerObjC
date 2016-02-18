Pod::Spec.new do |s|
  s.name         = "OGPeerObjC"
  s.version      = "0.0.1"
  s.summary      = "peerJS port in Objective-C. webRTC client to connect to peerjs-server."

  s.description  = <<-DESC
                   peerJS port in Objective-C. webRTC client to connect to peerjs-server.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/satansly/PeerObjC.git"

  s.license      = "MIT (example)"
  s.author             = { "Omar Hussain" => "satansly@gmail.com" }
   s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/satansly/PeerObjC.git", :tag => "0.0.1" }
	s.prefix_header_contents = "#import \"OGPrefix.h\""
  s.source_files  = "OGPeerObjC", "OGPeerObjC/**/*.{h,m}"
   s.public_header_files = "OGPeerObjC/*.h"
   s.requires_arc = true
    s.dependency "SocketRocket", "~>0.4.2"
    s.dependency "libjingle_peerconnection","~>11177.2.0"
    s.dependency "EventEmitter","~>0.1.3"
    s.dependency "CocoaLumberjack", "~>2.2.0"
end
