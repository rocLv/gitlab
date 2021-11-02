import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FormErrors from '~/form_errors/components/form_errors.vue';

describe('Form Errors', () => {
  let wrapper;

  const mockErrors = [
    {
      attribute: 'title',
      message: 'Title is not complete',
    },
    {
      attribute: 'key',
      message: 'Key is invalid',
    },
  ];

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findErrors = () => wrapper.findAll('[data-testid=form-error]');

  const createComponent = (props) => {
    wrapper = shallowMount(FormErrors, {
      propsData: {
        errors: mockErrors,
        type: 'form',
        truncate: ['title'],
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows errors', () => {
      expect(findGlAlert().exists()).toBe(true);
      expect(findErrors().length).toBe(2);
    });

    it('shows title', () => {
      expect(findGlAlert().props('title')).toBe('The form contains the following errors:');
    });

    it('truncates the appropriate message', () => {
      expect(findErrors().at(0).find('.gl-str-truncated').exists()).toBe(true);
      expect(findErrors().at(1).find('.gl-str-truncated').exists()).toBe(false);
    });
  });

  describe('when a different type is provided', () => {
    beforeEach(() => {
      createComponent({ type: 'key' });
    });

    it('shows title', () => {
      expect(findGlAlert().props('title')).toBe('The key contains the following errors:');
    });
  });
});
