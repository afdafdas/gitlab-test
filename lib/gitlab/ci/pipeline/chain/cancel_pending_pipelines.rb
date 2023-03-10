# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CancelPendingPipelines < Chain::Base
          include Chain::Helpers

          BATCH_SIZE = 25

          # rubocop: disable CodeReuse/ActiveRecord
          def perform!
            return if pipeline.parent_pipeline? # skip if child pipeline
            return unless project.auto_cancel_pending_pipelines?

            Gitlab::OptimisticLocking.retry_lock(auto_cancelable_pipelines, name: 'cancel_pending_pipelines') do |cancelables|
              cancelables.select(:id).each_batch(of: BATCH_SIZE) do |cancelables_batch|
                auto_cancel_interruptible_pipelines(cancelables_batch.ids)
              end
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def break?
            false
          end

          private

          def auto_cancelable_pipelines
            project.all_pipelines
              .created_after(1.week.ago)
              .ci_and_parent_sources
              .for_ref(pipeline.ref)
              .where_not_sha(project.commit(pipeline.ref).try(:id))
              .alive_or_scheduled
              .id_not_in(pipeline.id)
          end

          def auto_cancel_interruptible_pipelines(pipeline_ids)
            ::Ci::Pipeline
              .id_in(pipeline_ids)
              .with_only_interruptible_builds
              .each do |cancelable_pipeline|
                Gitlab::AppLogger.info(
                  class: self.class.name,
                  message: "Pipeline #{pipeline.id} auto-canceling pipeline #{cancelable_pipeline.id}",
                  canceled_pipeline_id: cancelable_pipeline.id,
                  canceled_by_pipeline_id: pipeline.id,
                  canceled_by_pipeline_source: pipeline.source
                )

                # cascade_to_children not needed because we iterate through descendants here
                cancelable_pipeline.cancel_running(
                  auto_canceled_by_pipeline_id: pipeline.id,
                  cascade_to_children: false
                )
              end
          end
        end
      end
    end
  end
end
