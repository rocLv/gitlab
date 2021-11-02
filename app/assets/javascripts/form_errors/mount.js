import Vue from 'vue';
import FormErrors from '~/form_errors/components/form_errors.vue';

const mountFormErrors = ({ el }) => {
  const { errors, truncate, type } = el.dataset;

  return new Vue({
    el,
    name: 'FormErrorsApp',
    render(h) {
      return h(FormErrors, {
        props: {
          errors: JSON.parse(errors),
          truncate: JSON.parse(truncate),
          type,
        },
      });
    },
  });
};

export default mountFormErrors;
