import { merge } from 'lodash';
import {
  trackFreeTrialAccountSubmissions,
  trackNewRegistrations,
  trackSaasTrialSubmit,
  trackSaasTrialSkip,
  trackSaasTrialGroup,
  trackSaasTrialProject,
  trackSaasTrialProjectImport,
  trackSaasTrialGetStarted,
} from '~/google_tag_manager';
import { setHTMLFixture } from 'helpers/fixtures';
import { logError } from '~/lib/logger';

jest.mock('~/lib/logger');

describe('~/google_tag_manager/index', () => {
  let spy;

  beforeEach(() => {
    spy = jest.fn();

    window.dataLayer = {
      push: spy,
    };
    window.gon.features = {
      gitlabGtmDatalayer: true,
    };
  });

  const createHTML = ({ links = [], forms = [] } = {}) => {
    // .foo elements are used to test elements which shouldn't do anything
    const allLinks = links.concat({ cls: 'foo' });
    const allForms = forms.concat({ cls: 'foo' });

    const el = document.createElement('div');

    allLinks.forEach(({ cls = '', id = '', href = '#', text = 'Hello', attributes = {} }) => {
      const a = document.createElement('a');
      a.id = id;
      a.href = href || '#';
      a.className = cls;
      a.textContent = text;

      Object.entries(attributes).forEach(([key, value]) => {
        a.setAttribute(key, value);
      });

      el.append(a);
    });

    allForms.forEach(({ cls = '', id = '' }) => {
      const form = document.createElement('form');
      form.id = id;
      form.className = cls;

      el.append(form);
    });

    return el.innerHTML;
  };

  const triggerEvent = (selector, eventType) => {
    const el = document.querySelector(selector);

    el.dispatchEvent(new Event(eventType));
  };

  const getSelector = ({ id, cls }) => (id ? `#${id}` : `.${cls}`);

  const createTestCase = (subject, { forms = [], links = [] }) => {
    const expectedFormEvents = forms.map(({ expectation, ...form }) => ({
      selector: getSelector(form),
      trigger: 'submit',
      expectation,
    }));

    const expectedLinkEvents = links.map(({ expectation, ...link }) => ({
      selector: getSelector(link),
      trigger: 'click',
      expectation,
    }));

    return [
      subject,
      {
        forms,
        links,
        expectedEvents: [...expectedFormEvents, ...expectedLinkEvents],
      },
    ];
  };

  const createOmniAuthTestCase = (subject, accountType) =>
    createTestCase(subject, {
      forms: [
        {
          id: 'new_new_user',
          expectation: {
            event: 'accountSubmit',
            accountMethod: 'form',
            accountType,
          },
        },
      ],
      links: [
        {
          // id is needed so that the test selects the right element to trigger
          id: 'test-0',
          cls: 'js-oauth-login',
          attributes: {
            'data-provider': 'myspace',
          },
          expectation: {
            event: 'accountSubmit',
            accountMethod: 'myspace',
            accountType,
          },
        },
        {
          id: 'test-1',
          cls: 'js-oauth-login',
          attributes: {
            'data-provider': 'gitlab',
          },
          expectation: {
            event: 'accountSubmit',
            accountMethod: 'gitlab',
            accountType,
          },
        },
      ],
    });

  describe.each([
    createOmniAuthTestCase(trackFreeTrialAccountSubmissions, 'freeThirtyDayTrial'),
    createOmniAuthTestCase(trackNewRegistrations, 'standardSignUp'),
    createTestCase(trackSaasTrialSkip, {
      links: [{ cls: 'js-skip-trial', expectation: { event: 'saasTrialSkip' } }],
    }),
    createTestCase(trackSaasTrialGroup, {
      forms: [{ cls: 'js-saas-trial-group', expectation: { event: 'saasTrialGroup' } }],
    }),
    createTestCase(trackSaasTrialProject, {
      forms: [{ id: 'new_project', expectation: { event: 'saasTrialProject' } }],
    }),
    createTestCase(trackSaasTrialProjectImport, {
      links: [
        {
          id: 'js-test-btn-0',
          cls: 'js-import-project-btn',
          attributes: { 'data-platform': 'bitbucket' },
          expectation: { event: 'saasTrialProjectImport', saasProjectImport: 'bitbucket' },
        },
        {
          // id is neeeded so we trigger the right element in the test
          id: 'js-test-btn-1',
          cls: 'js-import-project-btn',
          attributes: { 'data-platform': 'github' },
          expectation: { event: 'saasTrialProjectImport', saasProjectImport: 'github' },
        },
      ],
    }),
    createTestCase(trackSaasTrialGetStarted, {
      links: [
        {
          cls: 'js-get-started-btn',
          expectation: { event: 'saasTrialGetStarted' },
        },
      ],
    }),
  ])('%p', (subject, { links = [], forms = [], expectedEvents }) => {
    beforeEach(() => {
      setHTMLFixture(createHTML({ links, forms }));

      subject();
    });

    it.each(expectedEvents)('when %p', ({ selector, trigger, expectation }) => {
      expect(spy).not.toHaveBeenCalled();

      triggerEvent(selector, trigger);

      expect(spy).toHaveBeenCalledTimes(1);
      expect(spy).toHaveBeenCalledWith(expectation);
      expect(logError).not.toHaveBeenCalled();
    });

    it('when random link is clicked, does nothing', () => {
      triggerEvent('a.foo', 'click');

      expect(spy).not.toHaveBeenCalled();
    });

    it('when random form is submitted, does nothing', () => {
      triggerEvent('form.foo', 'submit');

      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('No listener events', () => {
    it('when trackSaasTrialSubmit is invoked', () => {
      expect(spy).not.toHaveBeenCalled();

      trackSaasTrialSubmit();

      expect(spy).toHaveBeenCalledTimes(1);
      expect(spy).toHaveBeenCalledWith({ event: 'saasTrialSubmit' });
      expect(logError).not.toHaveBeenCalled();
    });
  });

  describe.each([
    { dataLayer: null },
    { gon: { features: null } },
    { gon: { features: { gitlabGtmDatalayer: false } } },
  ])('when window %o', (windowAttrs) => {
    beforeEach(() => {
      merge(window, windowAttrs);
    });

    it('no ops', () => {
      setHTMLFixture(createHTML({ forms: [{ id: 'new_project' }] }));

      trackSaasTrialProject();

      triggerEvent('#new_project', 'submit');

      expect(spy).not.toHaveBeenCalled();
      expect(logError).not.toHaveBeenCalled();
    });
  });

  describe('when window.dataLayer throws error', () => {
    const pushError = new Error('test');

    beforeEach(() => {
      window.dataLayer = {
        push() {
          throw pushError;
        },
      };
    });

    it('logs error', () => {
      setHTMLFixture(createHTML({ forms: [{ id: 'new_project' }] }));

      trackSaasTrialProject();

      triggerEvent('#new_project', 'submit');

      expect(logError).toHaveBeenCalledWith(
        'Unexpected error while pushing to dataLayer',
        pushError,
      );
    });
  });
});
