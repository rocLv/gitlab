<script>
import { UP_KEY_CODE, DOWN_KEY_CODE } from '~/lib/utils/keycodes';

export default {
  model: {
    prop: 'index',
    event: 'change',
  },
  props: {
    index: {
      type: Number,
      required: true,
    },
    max: {
      type: Number,
      required: true,
    },
  },
  watch: {
    max() {
      this.$emit('change', 0);
    },
  },
  created() {
    this.$emit('change', 0);
    document.addEventListener('keydown', this.handleKeydown);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleKeydown);
  },
  methods: {
    handleKeydown(event) {
      if (event.keyCode === DOWN_KEY_CODE) {
        // Prevents moving cursor on focused input
        event.preventDefault();
        event.stopPropagation();
        this.increment(1);
      } else if (event.keyCode === UP_KEY_CODE) {
        // Prevents moving cursor on focused input
        event.preventDefault();
        event.stopPropagation();
        this.increment(-1);
      }
    },
    increment(val) {
      if (this.max === 0) {
        return;
      }

      const nextIndex = Math.max(0, Math.min(this.index + val, this.max));

      if (nextIndex === this.index) {
        return;
      }

      this.$emit('change', nextIndex);
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
