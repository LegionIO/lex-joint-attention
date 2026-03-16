# frozen_string_literal: true

require_relative 'lib/legion/extensions/joint_attention/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-joint-attention'
  spec.version       = Legion::Extensions::JointAttention::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Joint Attention'
  spec.description   = "Tomasello's joint attention framework for LegionIO — shared focus between agents, " \
                       'mutual awareness tracking, referential communication, and collaborative attention ' \
                       'management with focus decay and working-memory constraints.'
  spec.homepage      = 'https://github.com/LegionIO/lex-joint-attention'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-joint-attention'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-joint-attention'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-joint-attention'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-joint-attention/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-joint-attention.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
