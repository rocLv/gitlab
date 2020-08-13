import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import { GlAlert, GlLink } from '@gitlab/ui';
import SecurityConfigurationApp from 'ee/security_configuration/components/app.vue';
import ManageFeature from 'ee/security_configuration/components/manage_feature.vue';
import stubChildren from 'helpers/stub_children';
import { generateFeatures } from './helpers';

const propsData = {
  features: [],
  autoDevopsEnabled: false,
  latestPipelinePath: 'http://latestPipelinePath',
  autoDevopsHelpPagePath: 'http://autoDevopsHelpPagePath',
  autoDevopsPath: 'http://autoDevopsPath',
  helpPagePath: 'http://helpPagePath',
  gitlabCiPresent: false,
  autoFixSettingsProps: {},
  createSastMergeRequestPath: 'http://createSastMergeRequestPath',
};

describe('Security Configuration App', () => {
  let wrapper;
  const createComponent = (options = {}) => {
    wrapper = mount(
      SecurityConfigurationApp,
      merge(
        {},
        {
          stubs: {
            ...stubChildren(SecurityConfigurationApp),
            GlTable: false,
            GlSprintf: false,
          },
          propsData,
        },
        options,
      ),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const getPipelinesLink = () => wrapper.find({ ref: 'pipelinesLink' });
  const getFeaturesTable = () => wrapper.find({ ref: 'securityControlTable' });
  const getFeaturesRows = () => getFeaturesTable().findAll('tbody tr');
  const getAlert = () => wrapper.find(GlAlert);
  const getRowCells = row => {
    const [feature, status, manage] = row.findAll('td').wrappers;
    return { feature, status, manage };
  };

  describe('header', () => {
    it.each`
      autoDevopsEnabled | expectedUrl
      ${true}           | ${propsData.autoDevopsHelpPagePath}
      ${false}          | ${propsData.latestPipelinePath}
    `(
      'displays a link to "$expectedUrl" when autoDevops is "$autoDevopsEnabled"',
      ({ autoDevopsEnabled, expectedUrl }) => {
        createComponent({ propsData: { autoDevopsEnabled } });

        expect(getPipelinesLink().attributes('href')).toBe(expectedUrl);
        expect(getPipelinesLink().attributes('target')).toBe('_blank');
      },
    );
  });

  describe('Auto DevOps alert', () => {
    describe.each`
      gitlabCiPresent | autoDevopsEnabled | canEnableAutoDevops | shouldShowAlert
      ${false}        | ${false}          | ${true}             | ${true}
      ${true}         | ${false}          | ${true}             | ${false}
      ${false}        | ${true}           | ${true}             | ${false}
      ${false}        | ${false}          | ${false}            | ${false}
    `(
      'given gitlabCiPresent is $gitlabCiPresent, autoDevopsEnabled is $autoDevopsEnabled, canEnableAutoDevops is $canEnableAutoDevops',
      ({ gitlabCiPresent, autoDevopsEnabled, canEnableAutoDevops, shouldShowAlert }) => {
        beforeEach(() => {
          createComponent({
            propsData: {
              gitlabCiPresent,
              autoDevopsEnabled,
              canEnableAutoDevops,
            },
          });
        });

        it(`is${shouldShowAlert ? '' : ' not'} rendered`, () => {
          expect(getAlert().exists()).toBe(shouldShowAlert);
        });

        if (shouldShowAlert) {
          it('has the expected text', () => {
            expect(getAlert().text()).toMatchInterpolatedText(
              SecurityConfigurationApp.autoDevopsAlertMessage,
            );
          });

          it('has a link to the Auto DevOps docs', () => {
            const link = getAlert().find(GlLink);
            expect(link.attributes().href).toBe(propsData.autoDevopsHelpPagePath);
          });

          it('has the correct primary button', () => {
            expect(getAlert().props()).toMatchObject({
              title: 'Auto DevOps',
              primaryButtonText: 'Enable Auto DevOps',
              primaryButtonLink: propsData.autoDevopsPath,
              dismissible: false,
            });
          });
        }
      },
    );
  });

  describe('features table', () => {
    it('passes the expected data to the GlTable', () => {
      const features = generateFeatures(5);

      createComponent({ propsData: { features } });

      expect(getFeaturesTable().classes('b-table-stacked-md')).toBeTruthy();
      const rows = getFeaturesRows();
      expect(rows).toHaveLength(5);

      for (let i = 0; i < features.length; i += 1) {
        const { feature, status, manage } = getRowCells(rows.at(i));
        expect(feature.text()).toMatch(features[i].name);
        expect(feature.text()).toMatch(features[i].description);
        expect(status.text()).toMatch(features[i].configured ? 'Enabled' : 'Not enabled');
        expect(manage.find(ManageFeature).props()).toMatchObject({
          feature: features[i],
          autoDevopsEnabled: propsData.autoDevopsEnabled,
          gitlabCiPresent: propsData.gitlabCiPresent,
          createSastMergeRequestPath: propsData.createSastMergeRequestPath,
        });
      }
    });

    describe('given a feature enabled by Auto DevOps', () => {
      it('displays the expected status text', () => {
        const features = generateFeatures(1, { configured: true });

        createComponent({ propsData: { features, autoDevopsEnabled: true } });

        const { status } = getRowCells(getFeaturesRows().at(0));
        expect(status.text()).toMatch('Enabled with Auto DevOps');
      });
    });
  });
});
