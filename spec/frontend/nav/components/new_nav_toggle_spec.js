import { mount, createWrapper } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { getByText as getByTextHelper } from '@testing-library/dom';
import { GlToggle } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';

jest.mock('~/flash');

const TEST_ENDPONT = 'https://example.com/toggle';

describe('NewNavToggle', () => {
  let wrapper;

  const findToggle = () => wrapper.findComponent(GlToggle);

  const createComponent = (propsData = { enabled: false }) => {
    wrapper = mount(NewNavToggle, {
      propsData: {
        endpoint: TEST_ENDPONT,
        ...propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  it('renders its title', () => {
    createComponent();
    expect(getByText('Navigation redesign').exists()).toBe(true);
  });

  describe('when user preference is enabled', () => {
    beforeEach(() => {
      createComponent({ enabled: true });
    });

    it('renders the toggle as enabled', () => {
      expect(findToggle().props('value')).toBe(true);
    });
  });

  describe('when user preference is disabled', () => {
    beforeEach(() => {
      createComponent({ enabled: false });
    });

    it('renders the toggle as disabled', () => {
      expect(findToggle().props('value')).toBe(false);
    });
  });

  describe('changing the toggle', () => {
    useMockLocationHelper();
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      createComponent();
    });

    it('reloads the page on success', async () => {
      mock.onPut(TEST_ENDPONT).reply(200);
      findToggle().vm.$emit('change');
      await waitForPromises();

      expect(window.location.reload).toHaveBeenCalled();
    });

    it('shows an alert on error', async () => {
      mock.onPut(TEST_ENDPONT).reply(500);
      findToggle().vm.$emit('change');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: s__(
            'NorthstarNavigation|Could not update the new navigation preference. Please try again later.',
          ),
        }),
      );
      expect(window.location.reload).not.toHaveBeenCalled();
    });

    afterEach(() => {
      mock.restore();
    });
  });
});
