# Compatibility fix for Ruby 3.2 with older Rails versions
if RUBY_VERSION >= '3.2' && !Logger.const_defined?(:Severity)
  module Logger::Severity
    # Stub for compatibility
  end
end
