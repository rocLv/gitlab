import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from './constants';
import component from './components/form.vue';

export default [
  {
    name: INDEX_ROUTE_NAME,
    path: '/',
  },
  {
    name: NEW_ROUTE_NAME,
    path: '/new',
    component,
  },
  {
    name: EDIT_ROUTE_NAME,
    path: '/:id/edit',
    component,
    props: { isEditMode: true },
  },
];
