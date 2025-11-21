# frozen_string_literal: true

require_relative "lib/xseed/version"

Gem::Specification.new do |spec|
  spec.name          = "xseed"
  spec.version       = Xseed::VERSION
  spec.authors       = ["Ribose"]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Ruby XSD documentation generator with unified SVG and HTML output"
  spec.description   = "Generate comprehensive XSD documentation with SVG diagrams (via xsdvi gem) and HTML reference (XS3P port)"
  spec.homepage      = "https://github.com/metanorma/xseed"
  spec.license       = "BSD-2-Clause"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.adoc"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "lutaml-model", "~> 0.7"
  spec.add_dependency "lutaml-xsd", "~> 1.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "xsdvi", "~> 1.0"
end
