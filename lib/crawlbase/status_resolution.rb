# frozen_string_literal: true

module Crawlbase
  # Resolves Crawlbase status from response headers or JSON bodies.
  # Prefers +cb_status+, falling back to deprecated +pc_status+.
  module StatusResolution
    PC_STATUS_DEPRECATION =
      '[Crawlbase] `pc_status` is deprecated and will be removed in a future major release. Use `cb_status` instead.'

    module_function

    def resolve_cb_status(source)
      raw = source['cb_status']
      raw = source['pc_status'] if raw.nil? || raw.to_s.empty?
      raw.to_i
    end

    def warn_pc_status_deprecated
      return if Crawlbase.instance_variable_get(:@pc_status_deprecation_warned)

      Crawlbase.instance_variable_set(:@pc_status_deprecation_warned, true)
      warn PC_STATUS_DEPRECATION, uplevel: 1
    end
  end
end
