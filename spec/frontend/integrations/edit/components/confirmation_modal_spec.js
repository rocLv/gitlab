import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { createStore } from '~/integrations/edit/store';

import ConfirmationModal from '~/integrations/edit/components/confirmation_modal.vue';

describe('ConfirmationModal', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ConfirmationModal, {
      store: createStore(),
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findGlModal = () => wrapper.find(GlModal);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlModal with correct copy', () => {
      expect(findGlModal().exists()).toBe(true);
      expect(findGlModal().attributes('title')).toBe('Save settings?');
      expect(findGlModal().text()).toContain(
        'Saving will update the default settings for all projects that are not using custom settings.',
      );
      expect(findGlModal().text()).toContain(
        'Projects using custom settings will not be impacted unless the project owner chooses to use parent level defaults.',
      );
    });

    it('emits `submit` event when `primary` event is emitted on GlModal', async () => {
      expect(wrapper.emitted().submit).toBeUndefined();

      findGlModal().vm.$emit('primary');

      await wrapper.vm.$nextTick();

      expect(wrapper.emitted().submit).toHaveLength(1);
    });
  });
});
