import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import FilterBody from 'ee/security_dashboard/components/shared/filters/filter_body.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import ProjectFilterOld from 'ee/security_dashboard/components/shared/filters/project_filter_old.vue';
import { getProjectFilter } from 'ee/security_dashboard/helpers';

const generateProjects = (length) => {
  const projects = [];

  for (let i = 1; i <= length; i += 1) {
    projects.push({ id: i, name: `Option ${i}` });
  }

  return projects;
};

describe('Project Filter Old component', () => {
  let wrapper;

  const createWrapper = ({ projects }) => {
    wrapper = shallowMount(ProjectFilterOld, {
      propsData: { filter: getProjectFilter(projects) },
    });
  };

  const dropdownItems = () => wrapper.findAllComponents(FilterItem);
  const filterBody = () => wrapper.findComponent(FilterBody);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('search box', () => {
    it.each`
      phrase     | count | shouldShow
      ${'shows'} | ${20} | ${true}
      ${'hides'} | ${15} | ${false}
    `('$phrase search box if there are $count options', ({ count, shouldShow }) => {
      createWrapper({ projects: generateProjects(count) });

      expect(filterBody().props('showSearchBox')).toBe(shouldShow);
    });

    it('filters options when something is typed in the search box', async () => {
      const projects = generateProjects(11);
      const expectedProjectNames = projects.filter((x) => x.name.includes('1')).map((x) => x.name);
      createWrapper({ projects });
      filterBody().vm.$emit('input', '1');
      await nextTick();

      expect(dropdownItems()).toHaveLength(3);
      expect(dropdownItems().wrappers.map((x) => x.props('text'))).toEqual(expectedProjectNames);
    });
  });
});
