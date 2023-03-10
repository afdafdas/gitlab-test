# frozen_string_literal: true

module Gitlab
  # Parser/renderer for markups without other special support code.
  module OtherMarkup
    RENDER_TIMEOUT = 10.seconds

    # Public: Converts the provided markup into HTML.
    #
    # input         - the source text in a markup format
    #
    def self.render(file_name, input, context)
      html = render_markup(file_name, input, context).force_encoding(input.encoding)

      context[:pipeline] ||= :markup

      html = Banzai.render(html, context)
      html.html_safe
    end

    def self.render_markup(file_name, input, context)
      if Feature.enabled?(:markup_rendering_timeout, context[:project])
        Gitlab::RenderTimeout.timeout(foreground: RENDER_TIMEOUT) { GitHub::Markup.render(file_name, input) }
      else
        GitHub::Markup.render(file_name, input)
      end

    rescue Timeout::Error => e
      class_name = name.demodulize
      timeout_counter.increment(source: class_name)
      Gitlab::ErrorTracking.track_exception(e, project_id: context[:project]&.id, class_name: class_name,
                                               file_name: file_name)

      ActionController::Base.helpers.simple_format(input)
    end

    def self.timeout_counter
      Gitlab::Metrics.counter(:banzai_filter_timeouts_total, 'Count of the Banzai filters that time out')
    end
  end
end
