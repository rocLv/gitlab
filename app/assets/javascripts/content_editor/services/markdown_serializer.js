import { uniq } from 'lodash';
import {
  MarkdownSerializerState,
  defaultMarkdownSerializer,
} from 'prosemirror-markdown/src/to_markdown';
import { DOMParser as ProseMirrorDOMParser } from 'prosemirror-model';
import Blockquote from '../extensions/blockquote';
import Bold from '../extensions/bold';
import BulletList from '../extensions/bullet_list';
import Code from '../extensions/code';
import CodeBlockHighlight from '../extensions/code_block_highlight';
import Emoji from '../extensions/emoji';
import HardBreak from '../extensions/hard_break';
import Heading from '../extensions/heading';
import HorizontalRule from '../extensions/horizontal_rule';
import Image from '../extensions/image';
import Italic from '../extensions/italic';
import Link from '../extensions/link';
import ListItem from '../extensions/list_item';
import OrderedList from '../extensions/ordered_list';
import Paragraph from '../extensions/paragraph';
import Strike from '../extensions/strike';
import Subscript from '../extensions/subscript';
import Superscript from '../extensions/superscript';
import Table from '../extensions/table';
import TableCell from '../extensions/table_cell';
import TableHeader from '../extensions/table_header';
import TableRow from '../extensions/table_row';
import TaskItem from '../extensions/task_item';
import TaskList from '../extensions/task_list';
import Text from '../extensions/text';

const defaultSerializerConfig = {
  marks: {
    [Bold.name]: defaultMarkdownSerializer.marks.strong,
    [Code.name]: defaultMarkdownSerializer.marks.code,
    [Italic.name]: { open: '_', close: '_', mixable: true, expelEnclosingWhitespace: true },
    [Subscript.name]: { open: '<sub>', close: '</sub>', mixable: true },
    [Superscript.name]: { open: '<sup>', close: '</sup>', mixable: true },
    [Link.name]: {
      open() {
        return '[';
      },
      close(state, mark) {
        const href = mark.attrs.canonicalSrc || mark.attrs.href;
        return `](${state.esc(href)}${
          mark.attrs.title ? ` ${state.quote(mark.attrs.title)}` : ''
        })`;
      },
    },
    [Strike.name]: {
      open: '~~',
      close: '~~',
      mixable: true,
      expelEnclosingWhitespace: true,
    },
  },

  nodes: {
    [Blockquote.name]: defaultMarkdownSerializer.nodes.blockquote,
    [BulletList.name]: defaultMarkdownSerializer.nodes.bullet_list,
    [CodeBlockHighlight.name]: (state, node) => {
      state.write(`\`\`\`${node.attrs.language || ''}\n`);
      state.text(node.textContent, false);
      state.ensureNewLine();
      state.write('```');
      state.closeBlock(node);
    },
    [Emoji.name]: (state, node) => {
      const { name } = node.attrs;

      state.write(`:${name}:`);
    },
    [HardBreak.name]: (state, node, parent, index) => {
      state.renderHardBreak(node, parent, index);
    },
    [Heading.name]: defaultMarkdownSerializer.nodes.heading,
    [HorizontalRule.name]: defaultMarkdownSerializer.nodes.horizontal_rule,
    [Image.name]: (state, node) => {
      const { alt, canonicalSrc, src, title } = node.attrs;
      const quotedTitle = title ? ` ${state.quote(title)}` : '';

      state.write(`![${state.esc(alt || '')}](${state.esc(canonicalSrc || src)}${quotedTitle})`);
    },
    [ListItem.name]: defaultMarkdownSerializer.nodes.list_item,
    [OrderedList.name]: defaultMarkdownSerializer.nodes.ordered_list,
    [Paragraph.name]: defaultMarkdownSerializer.nodes.paragraph,
    [Table.name]: (state, node) => {
      state.renderTable(node);
    },
    [TableCell.name]: (state, node) => {
      state.renderTableCell(node);
    },
    [TableHeader.name]: (state, node) => {
      state.renderTableCell(node);
    },
    [TableRow.name]: (state, node) => {
      state.renderTableRow(node);
    },
    [TaskItem.name]: (state, node) => {
      state.write(`[${node.attrs.checked ? 'x' : ' '}] `);
      state.renderContent(node);
    },
    [TaskList.name]: (state, node) => {
      if (node.attrs.type === 'ul') defaultMarkdownSerializer.nodes.bullet_list(state, node);
      else defaultMarkdownSerializer.nodes.ordered_list(state, node);
    },
    [Text.name]: defaultMarkdownSerializer.nodes.text,
  },
};

class ContentEditorMarkdownSerializerState extends MarkdownSerializerState {
  tableMap = new Map();

  defaultAttrs = {
    td: { colspan: 1, rowspan: 1, colwidth: null },
    th: { colspan: 1, rowspan: 1, colwidth: null },
  };

  constructor(nodes, marks, options) {
    super(
      { ...defaultSerializerConfig.nodes, ...nodes },
      { ...defaultSerializerConfig.marks, ...marks },
      options,
    );
  }

  // eslint-disable-next-line class-methods-use-this
  shouldRenderCellInline(cell) {
    return cell.childCount === 1 && cell.child(0).type.name === 'paragraph';
  }

  // eslint-disable-next-line class-methods-use-this
  getRowsAndCells(table) {
    const cells = [];
    const rows = [];
    table.descendants((n) => {
      if (n.type.name === 'tableCell' || n.type.name === 'tableHeader') {
        cells.push(n);
        return false;
      }

      if (n.type.name === 'tableRow') {
        rows.push(n);
      }

      return true;
    });
    return { rows, cells };
  }

  tableHasBlockContent(table) {
    const { cells } = this.getRowsAndCells(table);

    const childCount = Math.max(...cells.map((cell) => cell.childCount));
    const maxColspan = Math.max(...cells.map((cell) => cell.attrs.colspan));
    const maxRowspan = Math.max(...cells.map((cell) => cell.attrs.rowspan));

    if (childCount === 1 && maxColspan === 1 && maxRowspan === 1) {
      const children = uniq(cells.map((cell) => cell.child(0).type.name));
      if (children.length === 1 && children[0] === 'paragraph') {
        return false;
      }
    }

    return true;
  }

  renderTagOpen(tag, attrs = {}) {
    this.write(`<${tag}`);

    Object.entries(attrs).forEach(([key, value]) => {
      if (this.defaultAttrs[tag]?.[key] === value) return;

      this.write(` ${key}=${this.quote(value?.toString() || '')}`);
    });

    this.write('>');
  }

  renderTagClose(tag) {
    this.write(`</${tag}>`);
  }

  renderTableCell(node) {
    if (!this.isInBlockTable(node) || this.shouldRenderCellInline(node)) {
      this.renderInline(node.child(0));
    } else {
      this.renderContent(node);
    }
  }

  renderTableRowAsMarkdown(node, isHeaderRow = false) {
    const cellWidths = [];

    this.flushClose(1);

    this.write('| ');
    node.forEach((cell, _, i) => {
      if (i) this.write(' | ');

      const { length } = this.out;
      this.render(cell, node, i);
      cellWidths.push(this.out.length - length);
    });
    this.write(' |');

    this.closeBlock(node);

    if (isHeaderRow) this.renderTableHeaderRowAsMarkdown(node, cellWidths);
  }

  renderTableHeaderRowAsMarkdown(node, cellWidths) {
    this.flushClose(1);

    this.write('|');
    node.forEach((cell, _, i) => {
      if (i) this.write('|');

      this.write(cell.attrs.align === 'center' ? ':' : '-');
      this.write(this.repeat('-', cellWidths[i]));
      this.write(cell.attrs.align === 'center' || cell.attrs.align === 'right' ? ':' : '-');
    });
    this.write('|');

    this.closeBlock(node);
  }

  renderTableRowAsHTML(node, isHeaderRow = false) {
    const tag = isHeaderRow ? 'th' : 'td';

    this.renderTagOpen('tr');
    node.forEach((cell, _, i) => {
      this.renderTagOpen(tag, cell.attrs);
      if (!this.shouldRenderCellInline(cell)) {
        this.write('\n\n');
      }

      this.render(cell, node, i);
      this.flushClose(1);
      this.renderTagClose(tag);
    });
    this.renderTagClose('tr');
  }

  renderTableRow(node) {
    const isHeaderRow = node.child(0).type.name === 'tableHeader';

    if (this.isInBlockTable(node)) {
      this.renderTableRowAsHTML(node, isHeaderRow);
    } else {
      this.renderTableRowAsMarkdown(node, isHeaderRow);
    }
  }

  renderTable(node) {
    this.setIsInBlockTable(node, this.tableHasBlockContent(node));

    if (this.isInBlockTable(node)) this.renderTagOpen('table');

    this.renderContent(node);

    if (this.isInBlockTable(node)) this.renderTagClose('table');

    this.unsetIsInBlockTable(node);
  }

  renderHardBreak(node, parent, index) {
    let br = '\\\n';

    if (this.isInTable(parent) && !this.isInBlockTable(parent)) {
      br = '<br>';
    }

    for (let i = index + 1; i < parent.childCount; i += 1)
      if (parent.child(i).type !== node.type) {
        this.write(br);
        return;
      }
  }

  isInBlockTable(node) {
    return this.tableMap.get(node);
  }

  isInTable(node) {
    return this.tableMap.has(node);
  }

  setIsInBlockTable(table, value) {
    this.tableMap.set(table, value);

    const { rows, cells } = this.getRowsAndCells(table);
    rows.forEach((row) => this.tableMap.set(row, value));
    cells.forEach((cell) => {
      this.tableMap.set(cell, value);
      if (cell.childCount && cell.child(0).type.name === 'paragraph')
        this.tableMap.set(cell.child(0), value);
    });
  }

  unsetIsInBlockTable(table) {
    this.tableMap.delete(table);

    const { rows, cells } = this.getRowsAndCells(table);
    rows.forEach((row) => this.tableMap.delete(row));
    cells.forEach((cell) => {
      this.tableMap.delete(cell);
      if (cell.childCount) this.tableMap.delete(cell.child(0));
    });
  }
}

const wrapHtmlPayload = (payload) => `<div>${payload}</div>`;

/**
 * A markdown serializer converts arbitrary Markdown content
 * into a ProseMirror document and viceversa. To convert Markdown
 * into a ProseMirror document, the Markdown should be rendered.
 *
 * The client should provide a render function to allow flexibility
 * on the desired rendering approach.
 *
 * @param {Function} params.render Render function
 * that parses the Markdown and converts it into HTML.
 * @returns a markdown serializer
 */
export default ({ render = () => null, serializerConfig = {} } = {}) => ({
  /**
   * Converts a Markdown string into a ProseMirror JSONDocument based
   * on a ProseMirror schema.
   * @param {ProseMirror.Schema} params.schema A ProseMirror schema that defines
   * the types of content supported in the document
   * @param {String} params.content An arbitrary markdown string
   * @returns A ProseMirror JSONDocument
   */
  deserialize: async ({ schema, content }) => {
    const html = await render(content);

    if (!html) {
      return null;
    }

    const parser = new DOMParser();
    const {
      body: { firstElementChild },
    } = parser.parseFromString(wrapHtmlPayload(html), 'text/html');
    const state = ProseMirrorDOMParser.fromSchema(schema).parse(firstElementChild);

    return state.toJSON();
  },

  /**
   * Converts a ProseMirror JSONDocument based
   * on a ProseMirror schema into Markdown
   * @param {ProseMirror.Schema} params.schema A ProseMirror schema that defines
   * the types of content supported in the document
   * @param {String} params.content A ProseMirror JSONDocument
   * @returns A Markdown string
   */
  serialize: ({ schema, content }) => {
    const proseMirrorDocument = schema.nodeFromJSON(content);
    const state = new ContentEditorMarkdownSerializerState(
      serializerConfig.nodes,
      serializerConfig.marks,
      { tightLists: true },
    );
    state.renderContent(proseMirrorDocument);
    return state.out;
  },
});
