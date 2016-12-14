Pod::Spec.new do |s|
  s.name         = "Telepat"
  s.version      = "0.4.0"
  s.summary      = "Real Time, Open Source Data Sync"

  s.description  = <<-DESC
                   Telepat is an open-source backend stack, designed to deliver information and information updates in real-time to clients, while allowing for flexible deployment and simple scaling.
                   DESC

  s.homepage     = "http://telepat.io"
  s.license      = "Apache"
  s.author       = { "Appscend" => "ovidiu@appscend.com" }
  s.platform     = :ios
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/telepat-io/telepat-ios-sdk.git", :tag => s.version.to_s }
  s.source_files = "Telepat", "Telepat/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "Objective-LevelDB", "~>2.1"
  s.dependency "JSONModel", "~>1.7.0"
  s.dependency "AFNetworking", "~>2.5.0"
  s.dependency "SIOSocket", "~>0.2.0"
  s.dependency "CocoaLumberjack", "~>2.3"

end
