Pod::Spec.new do |s|
  s.name         = "RBEFireworks"
  s.version      = "1.0.0"
  s.summary      = "A feature rich and flexible network library"
  s.description  = <<-DESC
                    A feature rich and flexible network library.
                   DESC
  s.author       = "Robbie"
  s.license      = "MIT"
  s.homepage     = "https://github.com/robbie23/RBEFireworks" 
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/robbie23/RBEFireworks.git", 
                     :tag => s.version }

  s.source_files  = "RBEFireworks/**/*.{h,m}"
  s.dependency 'AFNetworking', '~> 3.0'
  s.public_header_files = ['RBEFireworks/Fireworks/RBEUploadFirework.h', 'RBEFireworks/Fireworks/RBEDownloadFirework.h', 'RBEFireworks/Fireworks/RBEFirework.h', 'RBEFireworks/Fireworks/RBEChainFirework.h', 'RBEFireworks/Fireworks/RBEBatchFirework.h', 'RBEFireworks/Manager/RBEFireworkAdapter.h', 'RBEFireworks/Util/NSString+RBEAdditions.h', 'RBEFireworks/Fireworks/RBERequest.h', 'RBEFireworks/RBEFireworks.h']
  s.libraries = 'sqlite3'

end