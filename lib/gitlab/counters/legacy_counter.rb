# frozen_string_literal: true

module Gitlab
  module Counters
    # This class is a wrapper over ActiveRecord counter
    # for attributes that have not adopted Redis-backed BufferedCounter.
    class LegacyCounter
      def initialize(counter_record, attribute)
        @counter_record = counter_record
        @attribute = attribute
        @current_value = counter_record.method(attribute).call
      end

      def increment(amount)
        updated = counter_record.class.update_counters(counter_record.id, { attribute => amount })

        if updated == 1
          counter_record.execute_after_commit_callbacks
          @current_value += amount
        end

        @current_value
      end

      def reset!
        counter_record.update!(attribute => 0)
      end

      private

      attr_reader :counter_record, :attribute
    end
  end
end
