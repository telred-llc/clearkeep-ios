# Uncomment this line to define a global platform for your project
platform :ios, '11.0'

# Use frameforks to allow usage of pod written in Swift (like PiwikTracker)
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'


# Different flavours of pods to MatrixKit
# The current MatrixKit pod version
$matrixKitVersion = 'local'

# The develop branch version
#$matrixKitVersion = 'develop'

# The one used for developing both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#$matrixKitVersion = 'local'


# Method to import the right MatrixKit flavour
def import_MatrixKit
    pod 'IQKeyboardManagerSwift','~> 6.2.0'
    pod 'Parchment', '~> 1.5.0'
    pod 'XLActionController', '5.0.2'
    pod 'Alamofire', '4.8.1'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'XLActionController/Youtube'
    pod 'PromiseKit'
    pod 'Firebase/Analytics'
    pod 'SwiftImagePicker', :git => 'https://github.com/sinbadflyce/image-picker.git', :inhibit_warnings => true
    pod 'FloatingPanel'
    pod 'RxTheme', '~> 3.0'
    pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
    
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => './Libraries/matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/SwiftSupport', :path => './Libraries/matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/JingleCallStack', :path => './Libraries/matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit', :path => './Libraries/matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/JingleCallStack', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
        else
            #pod 'MatrixKit', $matrixKitVersion
            pod 'MatrixKit/AppExtension', :git => 'https://github.com/sinbadflyce/matrix-ios-kit.git', :branch => 'o365', :inhibit_warnings => true
            pod 'MatrixSDK/SwiftSupport', :inhibit_warnings => true
            pod 'MatrixSDK/JingleCallStack', :inhibit_warnings => true
        end
    end
end

# Method to import the right MatrixKit/AppExtension flavour
def import_MatrixKitAppExtension
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => './Libraries/matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/SwiftSupport', :path => './Libraries/matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/JingleCallStack', :path => './Libraries/matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit', :path => './Libraries/matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/JingleCallStack', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
        else
            #pod 'MatrixKit/AppExtension', $matrixKitVersion
            pod 'MatrixKit/AppExtension', :git => 'https://github.com/sinbadflyce/matrix-ios-kit.git', :branch => 'o365', :inhibit_warnings => true
            pod 'MatrixSDK/SwiftSupport', :inhibit_warnings => true
            pod 'MatrixSDK/JingleCallStack', :inhibit_warnings => true
        end
    end
end


abstract_target 'RiotPods' do

    pod 'GBDeviceInfo', '~> 5.2.0'
    pod 'Reusable', '~> 4.0'
    pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'

    # Piwik for analytics
    # While https://github.com/matomo-org/matomo-sdk-ios/pull/223 is not released, use the PR branch
    pod 'PiwikTracker', :git => 'https://github.com/manuroe/matomo-sdk-ios.git', :branch => 'feature/CustomVariables'
    #pod 'PiwikTracker', '~> 4.4.2'

    # Remove warnings from "bad" pods
    pod 'OLMKit', :inhibit_warnings => true
    pod 'cmark', :inhibit_warnings => true
    pod 'DTCoreText', :inhibit_warnings => true
    
    pod 'zxcvbn-ios'

    # Tools
    pod 'SwiftGen', '~> 6.1'
    pod 'SwiftLint', '~> 0.33.0'

    # Cache
    pod 'Cache'

    target "Riot" do
        import_MatrixKit
    end

    target "Riot-Prod" do
      import_MatrixKit
    end

    target "RiotShareExtension" do
        import_MatrixKitAppExtension
    end

    target "RiotShareExtension-Prod" do
        import_MatrixKitAppExtension
    end

    #target "SiriIntents" do
    #    import_MatrixKitAppExtension
    #end
    
end


post_install do |installer|
    installer.pods_project.targets.each do |target|

        # Disable bitcode for each pod framework
        # Because the WebRTC pod (included by the JingleCallStack pod) does not support it.
        # Plus the app does not enable it
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'

            if target.name == 'RxTheme'
              config.build_settings['SWIFT_VERSION'] = '4.2'
            else
                if target.name == 'SwiftImagePicker' || target.name == 'PiwikTracker'
                    config.build_settings['SWIFT_VERSION'] = '4.0'
                else
                    if target.name == 'Cache'
                        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
                        config.build_settings['SWIFT_VERSION'] = '5.1'
                    else
                        config.build_settings['SWIFT_VERSION'] = '5.1'
                    end
                end
            end
        end
    end
end

