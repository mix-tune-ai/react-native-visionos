# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

require "json"

package = JSON.parse(File.read(File.join(__dir__, "..", "package.json")))
version = package['version']

source = { :git => 'https://github.com/facebook/react-native.git' }
if version == '1000.0.0'
  # This is an unpublished version, use the latest commit hash of the react-native repo, which we’re presumably in.
  source[:commit] = `git rev-parse HEAD`.strip if system("git rev-parse --git-dir > /dev/null 2>&1")
else
  source[:tag] = "v#{version}"
end

module_name = "FBReactNativeSpec"
header_dir = "FBReactNativeSpec"

folly_config = get_folly_config()
folly_compiler_flags = folly_config[:compiler_flags]
folly_version = folly_config[:version]
boost_config = get_boost_config()
boost_compiler_flags = boost_config[:compiler_flags]
new_arch_flags = ENV['RCT_NEW_ARCH_ENABLED'] == '1' ? ' -DRCT_NEW_ARCH_ENABLED=1' : ''

header_search_paths = [
  "\"$(PODS_ROOT)/RCT-Folly\"",
]

Pod::Spec.new do |s|
  s.name                   = "React-RCTFBReactNativeSpec"
  s.version                = version
  s.summary                = "FBReactNativeSpec for React Native."
  s.homepage               = "https://reactnative.dev/"
  s.license                = package["license"]
  s.author                 = "Meta Platforms, Inc. and its affiliates"
  s.platforms              = min_supported_versions
  s.source                 = source
  s.source_files           = "FBReactNativeSpec/**/*.{c,h,m,mm,S,cpp}"
  s.compiler_flags         = folly_compiler_flags + ' ' + boost_compiler_flags + new_arch_flags
  s.header_dir             = header_dir
  s.module_name            = module_name
  s.pod_target_xcconfig    = {
    "HEADER_SEARCH_PATHS" => header_search_paths,
    "OTHER_CFLAGS" => "$(inherited) " + folly_compiler_flags + new_arch_flags,
    "CLANG_CXX_LANGUAGE_STANDARD" => rct_cxx_language_standard()
  }

  s.dependency "React-jsi"
  s.dependency "React-jsiexecutor"
  s.dependency "RCT-Folly"
  s.dependency "RCTRequired"
  s.dependency "RCTTypeSafety"
  s.dependency "React-Core"
  s.dependency "React-NativeModulesApple"
  add_dependency(s, "ReactCommon", :subspec => "turbomodule/core", :additional_framework_paths => ["react/nativemodule/core"])
  add_dependency(s, "ReactCommon", :subspec => "turbomodule/bridging", :additional_framework_paths => ["react/nativemodule/bridging"])

  if ENV["USE_HERMES"] == nil || ENV["USE_HERMES"] == "1"
    s.dependency "hermes-engine"
  else
    s.dependency "React-jsc"
  end


  s.script_phases = [
    {
      :name => '[RN]Check FBReactNativeSpec',
      :execution_position => :before_compile,
      :script => <<-EOS
echo "Checking whether Codegen has run..."
fbReactNativeSpecPath="$REACT_NATIVE_PATH/React/FBReactNativeSpec"

if [[ ! -d "$fbReactNativeSpecPath" ]]; then
  echo 'error: Codegen did not run properly in your project. Please reinstall cocoapods with `bundle exec pod install`.'
  exit 1
fi
      EOS
    }
  ]
end
