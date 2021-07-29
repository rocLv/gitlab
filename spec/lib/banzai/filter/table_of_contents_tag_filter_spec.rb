# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TableOfContentsTagFilter do
  include FilterSpecHelper

  context 'table of contents' do
    where(:toc_tag) do
      ['[[<em>TOC</em>]]', '[TOC]', '[toc]']
    end

    with_them do
      let(:html) { "<p>#{toc_tag}</p>" }

      it 'replaces tag with ToC result' do
        doc = filter(html, {}, { toc: 'FOO' })

        expect(doc.to_html).to eq('FOO')
      end

      it 'handles an empty ToC result' do
        doc = filter(html)

        expect(doc.to_html).to eq ''
      end

      it 'tag must be only thing in paragraph' do
        html = "<p>#{toc_tag} something</p>"
        doc = filter(html, {}, { toc: 'FOO' })

        expect(doc.to_html).to eq html
      end

      it 'can contain leading or trailing spaces' do
        html = "<p>      #{toc_tag}    </p>"
        doc = filter(html, {}, { toc: 'FOO' })

        expect(doc.to_html).to eq('FOO')
      end
    end
  end
end
