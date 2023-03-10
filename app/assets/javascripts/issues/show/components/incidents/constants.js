import { __, n__, s__ } from '~/locale';

export const timelineTabI18n = Object.freeze({
  title: s__('Incident|Timeline'),
  emptyDescription: s__('Incident|No timeline items have been added yet.'),
  addEventButton: s__('Incident|Add new timeline event'),
});

export const timelineFormI18n = Object.freeze({
  createError: s__('Incident|Error creating incident timeline event: %{error}'),
  createErrorGeneric: s__(
    'Incident|Something went wrong while creating the incident timeline event.',
  ),
  areaPlaceholder: s__('Incident|Timeline text...'),
  save: __('Save'),
  cancel: __('Cancel'),
  delete: __('Delete'),
  description: __('Description'),
  hint: __('You can enter up to 280 characters'),
  textRemaining: (count) => n__('%d character remaining', '%d characters remaining', count),
  saveAndAdd: s__('Incident|Save and add another event'),
  areaLabel: s__('Incident|Timeline text'),
});

export const timelineListI18n = Object.freeze({
  deleteButton: s__('Incident|Delete event'),
  deleteError: s__('Incident|Error deleting incident timeline event: %{error}'),
  deleteErrorGeneric: s__(
    'Incident|Something went wrong while deleting the incident timeline event.',
  ),
  deleteModal: s__('Incident|Are you sure you want to delete this event?'),
  editError: s__('Incident|Error updating incident timeline event: %{error}'),
  editErrorGeneric: s__(
    'Incident|Something went wrong while updating the incident timeline event.',
  ),
});

export const timelineItemI18n = Object.freeze({
  delete: __('Delete'),
  edit: __('Edit'),
  moreActions: __('More actions'),
  timeUTC: __('%{time} UTC'),
});

export const MAX_TEXT_LENGTH = 280;
