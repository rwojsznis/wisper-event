# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wisper_event/version'

Gem::Specification.new do |spec|
  spec.name = "wisper-event"
  spec.version = WisperEvent::VERSION
  spec.authors = ["Rafal Wojsznis"]
  spec.email = ["rafal.wojsznis@gmail.com"]
  spec.description = %q{Structured events for Wisper}
  spec.summary = %q{Backward-compatible support for structured events in Wisper}
  spec.homepage = "https://github.com/rwojsznis/wisper-event"
  spec.license = "MIT"

  spec.files = Dir.glob("{lib}/**/*") + %w(README.md)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.7'
  spec.add_dependency "wisper", "3.0.0"
end
