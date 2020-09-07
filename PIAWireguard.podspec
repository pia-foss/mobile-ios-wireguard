Pod::Spec.new do |s|
    s.name              = "PIAWireguard"
    s.version           = "1.0.1"
    s.summary           = "PIA Wireguard implementation in Swift."

    s.homepage          = "https://www.privateinternetaccess.com/"
    s.license           = { :type => "MIT", :file => "LICENSE" }
    s.author            = { "Jose Blaya" => "joseblaya@londontrustmedia.com" }
    s.source            = { :git => "https://github.com/pia-foss/piawireguard.git", :tag => "v#{s.version}" }

    s.osx.deployment_target = "10.11"

    s.prepare_command = <<-CMD
./wireguard-go-bridge/build.sh
./create-libwg-go-framework.sh
    CMD

    s.ios.deployment_target         = "11.0"
    s.ios.vendored_frameworks       = "frameworks/iPhone/libwg-go.framework"

    s.subspec "Core" do |p|
        p.source_files          = "PIAWireguard/Core/**/*.{h,m,c,swift}"
        p.private_header_files  = "PIAWireguard/Core/**/*.h"
        p.preserve_paths        = "PIAWireguard/Core/*.modulemap"
        p.pod_target_xcconfig   = { "SWIFT_INCLUDE_PATHS" => "${PODS_TARGET_SRCROOT}/PIAWireguard/Core",
                                    "APPLICATION_EXTENSION_API_ONLY" => "YES" }
        p.dependency "Alamofire"
        p.dependency "TweetNacl"

    end

    s.subspec "AppExtension" do |p|
        p.source_files          = "PIAWireguard/AppExtension/**/*.swift"
        p.resources             = "PIAWireguard/AppExtension/Certificates/**/*"

        p.frameworks            = "NetworkExtension"
        p.pod_target_xcconfig   = { "APPLICATION_EXTENSION_API_ONLY" => "YES" }

        p.dependency "PIAWireguard/Core"
    end
end
