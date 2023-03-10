<script>
import { GlDatepicker, GlFormInput, GlFormGroup, GlButton } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { MAX_TEXT_LENGTH, timelineFormI18n } from './constants';
import { getUtcShiftedDate } from './utils';

export default {
  name: 'TimelineEventsForm',
  restrictedToolBarItems: [
    'quote',
    'strikethrough',
    'bullet-list',
    'numbered-list',
    'task-list',
    'collapsible-section',
    'table',
    'attach-file',
    'full-screen',
  ],
  components: {
    MarkdownField,
    GlDatepicker,
    GlFormInput,
    GlFormGroup,
    GlButton,
  },
  i18n: timelineFormI18n,
  MAX_TEXT_LENGTH,
  props: {
    showSaveAndAdd: {
      type: Boolean,
      required: false,
      default: false,
    },
    showDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEventProcessed: {
      type: Boolean,
      required: true,
    },
    previousOccurredAt: {
      type: String,
      required: false,
      default: null,
    },
    previousNote: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    // if occurredAt is null, returns "now" in UTC
    const placeholderDate = getUtcShiftedDate(this.previousOccurredAt);

    return {
      timelineText: this.previousNote,
      placeholderDate,
      hourPickerInput: placeholderDate.getHours(),
      minutePickerInput: placeholderDate.getMinutes(),
      datePickerInput: placeholderDate,
    };
  },
  computed: {
    isTimelineTextValid() {
      return this.timelineTextCount > 0 && this.timelineTextRemainingCount >= 0;
    },
    occurredAtString() {
      const year = this.datePickerInput.getFullYear();
      const month = this.datePickerInput.getMonth();
      const day = this.datePickerInput.getDate();

      const utcDate = new Date(
        Date.UTC(year, month, day, this.hourPickerInput, this.minutePickerInput),
      );

      return utcDate.toISOString();
    },
    timelineTextRemainingCount() {
      return MAX_TEXT_LENGTH - this.timelineTextCount;
    },
    timelineTextCount() {
      return this.timelineText.length;
    },
  },
  mounted() {
    this.focusDate();
  },
  methods: {
    clear() {
      const newPlaceholderDate = getUtcShiftedDate();
      this.datePickerInput = newPlaceholderDate;
      this.hourPickerInput = newPlaceholderDate.getHours();
      this.minutePickerInput = newPlaceholderDate.getMinutes();
      this.timelineText = '';
    },
    focusDate() {
      this.$refs.datepicker.$el.querySelector('input')?.focus();
    },
    handleSave(addAnotherEvent) {
      const event = {
        note: this.timelineText,
        occurredAt: this.occurredAtString,
      };
      this.$emit('save-event', event, addAnotherEvent);
    },
  },
};
</script>

<template>
  <form class="gl-flex-grow-1 gl-border-gray-50">
    <div class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row">
      <gl-form-group :label="__('Date')" class="gl-mt-5 gl-mr-5">
        <gl-datepicker id="incident-date" ref="datepicker" v-model="datePickerInput" />
      </gl-form-group>
      <div class="gl-display-flex gl-mt-5">
        <gl-form-group :label="__('Time')">
          <div class="gl-display-flex">
            <label label-for="timeline-input-hours" class="sr-only"></label>
            <gl-form-input
              id="timeline-input-hours"
              v-model="hourPickerInput"
              data-testid="input-hours"
              size="xs"
              type="number"
              min="00"
              max="23"
            />
            <label label-for="timeline-input-minutes" class="sr-only"></label>
            <gl-form-input
              id="timeline-input-minutes"
              v-model="minutePickerInput"
              class="gl-ml-3"
              data-testid="input-minutes"
              size="xs"
              type="number"
              min="00"
              max="59"
            />
          </div>
        </gl-form-group>
        <p class="gl-ml-3 gl-align-self-end gl-line-height-32">{{ __('UTC') }}</p>
      </div>
    </div>
    <div class="common-note-form">
      <gl-form-group class="gl-mb-3" :label="$options.i18n.areaLabel">
        <markdown-field
          :can-attach-file="false"
          :add-spacing-classes="false"
          :show-comment-tool-bar="false"
          :textarea-value="timelineText"
          :restricted-tool-bar-items="$options.restrictedToolBarItems"
          markdown-docs-path=""
          :enable-preview="false"
          class="bordered-box gl-mt-0"
        >
          <template #textarea>
            <textarea
              v-model="timelineText"
              class="note-textarea js-gfm-input js-autosize markdown-area"
              data-testid="input-note"
              dir="auto"
              data-supports-quick-actions="false"
              :aria-label="$options.i18n.description"
              aria-describedby="timeline-form-hint"
              :placeholder="$options.i18n.areaPlaceholder"
              :maxlength="$options.MAX_TEXT_LENGTH"
            >
            </textarea>
            <div id="timeline-form-hint" class="gl-sr-only">{{ $options.i18n.hint }}</div>
            <div
              aria-hidden="true"
              class="gl-absolute gl-text-gray-500 gl-font-sm gl-line-height-14 gl-right-4 gl-bottom-3"
            >
              {{ timelineTextRemainingCount }}
            </div>
            <div role="status" class="gl-sr-only">
              {{ $options.i18n.textRemaining(timelineTextRemainingCount) }}
            </div>
          </template>
        </markdown-field>
      </gl-form-group>
    </div>
    <gl-form-group class="gl-mb-0">
      <div class="gl-display-flex">
        <gl-button
          variant="confirm"
          category="primary"
          class="gl-mr-3"
          data-testid="save-button"
          :disabled="!isTimelineTextValid"
          :loading="isEventProcessed"
          @click="handleSave(false)"
        >
          {{ $options.i18n.save }}
        </gl-button>
        <gl-button
          v-if="showSaveAndAdd"
          variant="confirm"
          category="secondary"
          class="gl-mr-3 gl-ml-n2"
          data-testid="save-and-add-button"
          :disabled="!isTimelineTextValid"
          :loading="isEventProcessed"
          @click="handleSave(true)"
        >
          {{ $options.i18n.saveAndAdd }}
        </gl-button>
        <gl-button class="gl-ml-n2" :disabled="isEventProcessed" @click="$emit('cancel')">
          {{ $options.i18n.cancel }}
        </gl-button>
        <gl-button
          v-if="showDelete"
          class="gl-ml-auto btn-danger"
          :disabled="isEventProcessed"
          @click="$emit('delete')"
        >
          {{ $options.i18n.delete }}
        </gl-button>
      </div>
      <div class="timeline-event-bottom-border"></div>
    </gl-form-group>
  </form>
</template>
