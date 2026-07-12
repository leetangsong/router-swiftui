Pod::Spec.new do |s|
  s.name = 'Router-SwiftUI'
  s.version = '1.0.2'
  s.summary = 'A lightweight type-safe routing library for SwiftUI.'
  s.description = <<-DESC
Router-SwiftUI is a lightweight SwiftUI routing library that supports
type-safe navigation, multiple tab navigation stacks, sheets,
full-screen covers, deep links, route interceptors, and navigation events.
  DESC
  s.homepage = 'https://github.com/leetangsong/router-swiftui'
  s.license = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author = { 'leetangsong' => 'leetangsong@icloud.com' }
  s.source = { :git => 'https://github.com/leetangsong/router-swiftui.git', :tag => s.version.to_s }

  s.ios.deployment_target = '17.0'
  s.swift_versions = ['6.0']
  s.module_name = 'Router'
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'SwiftUI'
end
