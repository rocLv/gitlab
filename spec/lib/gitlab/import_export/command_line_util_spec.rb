# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::CommandLineUtil do
  include ExportFileHelper

  let(:path) { "#{Dir.tmpdir}/symlink_test" }
  let(:archive) { 'spec/fixtures/symlink_export.tar.gz' }
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }
  let(:tmpdir) { Dir.mktmpdir }

  subject do
    Class.new do
      include Gitlab::ImportExport::CommandLineUtil

      def initialize
        @shared = Gitlab::ImportExport::Shared.new(nil)
      end

      def download(url, upload_path)
        super(url, upload_path)
      end
    end.new
  end

  before do
    FileUtils.mkdir_p(path)
    subject.untar_zxf(archive: archive, dir: path)
  end

  after do
    FileUtils.rm_rf(path)
    FileUtils.remove_entry(tmpdir)
  end

  it 'has the right mask for project.json' do
    expect(file_permissions("#{path}/project.json")).to eq(0755) # originally 777
  end

  it 'has the right mask for uploads' do
    expect(file_permissions("#{path}/uploads")).to eq(0755) # originally 555
  end

  describe '#gzip' do
    it 'compresses specified file' do
      tempfile = Tempfile.new('test', path)
      filename = File.basename(tempfile.path)

      subject.gzip(dir: path, filename: filename)

      expect(File.exist?("#{tempfile.path}.gz")).to eq(true)
    end

    context 'when exception occurs' do
      it 'raises an exception' do
        expect { subject.gzip(dir: path, filename: 'test') }.to raise_error(Gitlab::ImportExport::Error)
      end
    end
  end

  describe '#gunzip' do
    it 'decompresses specified file' do
      filename = 'labels.ndjson.gz'
      gz_filepath = "spec/fixtures/bulk_imports/gz/#{filename}"
      FileUtils.copy_file(gz_filepath, File.join(tmpdir, filename))

      subject.gunzip(dir: tmpdir, filename: filename)

      expect(File.exist?(File.join(tmpdir, 'labels.ndjson'))).to eq(true)
    end

    context 'when exception occurs' do
      it 'raises an exception' do
        expect { subject.gunzip(dir: path, filename: 'test') }.to raise_error(Gitlab::ImportExport::Error)
      end
    end
  end

  describe '#tar_cf' do
    let(:archive_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(archive_dir)
    end

    it 'archives a folder without compression' do
      archive_file = File.join(archive_dir, 'archive.tar')

      result = subject.tar_cf(archive: archive_file, dir: tmpdir)

      expect(result).to eq(true)
      expect(File.exist?(archive_file)).to eq(true)
    end

    context 'when something goes wrong' do
      it 'raises an error' do
        expect(Gitlab::Popen).to receive(:popen).and_return(['Error', 1])

        klass = Class.new do
          include Gitlab::ImportExport::CommandLineUtil
        end.new

        expect { klass.tar_cf(archive: 'test', dir: 'test') }.to raise_error(Gitlab::ImportExport::Error, 'System call failed')
      end
    end
  end

  describe '#download' do
    before do
      stub_request(:get, loc)
        .to_return(
          status: status,
          body: content
        )
    end

    context 'a non-localhost uri' do
      let(:loc) { 'https://gitlab.com' }
      let(:content) { File.open('spec/fixtures/rails_sample.tif') }

      context 'with ok status code' do
        let_it_be(:status) { HTTP::Status::OK }

        it 'gets the contents' do
          Tempfile.create('xyz') do |f|
            subject.download(loc, f.path)
            expect(f.read).to eq(File.open('spec/fixtures/rails_sample.tif').read)
          end
        end

        it 'streams the contents' do
          expect(Gitlab::HTTP).to receive(:get).with(loc, hash_including(stream_body: true))
          Tempfile.create('xyz') do |f|
            subject.download(loc, f.path)
          end
        end
      end

      %w[MOVED_PERMANENTLY FOUND TEMPORARY_REDIRECT].each do |s|
        context "with a redirect status code #{s}" do
          let_it_be(:status) { HTTP::Status.const_get(s, false) }

          it 'logs the redirect' do
            expect(Gitlab::Import::Logger).to receive(:warn)
            Tempfile.create('xyz') do |f|
              subject.download(loc, f.path)
            end
          end
        end
      end

      %w[CREATED ACCEPTED NON_AUTHORITATIVE_INFORMATION RESET_CONTENT PARTIAL_CONTENT SEE_OTHER UNAUTHORIZED PROXY_AUTHENTICATE_REQUIRED BAD_REQUEST INTERNAL].each do |s|
        context "with an invalid status code #{s}" do
          let_it_be(:status) { HTTP::Status.const_get(s, false) }

          it 'throws an error' do
            Tempfile.create('xyz') do |f|
              expect { subject.download(loc, f.path) }.to raise_error(Gitlab::ImportExport::Error)
            end
          end
        end
      end
    end

    context 'a localhost uri' do
      let(:loc) { 'https://localhost:8081/foo/bar' }
      let(:content) { 'some sort of content' }

      let_it_be(:status) { HTTP::Status::OK }

      it 'throws a blocked url error' do
        Tempfile.create('xyz') do |f|
          expect { subject.download(loc, f.path) }.to raise_error(Gitlab::HTTP::BlockedUrlError)
        end
      end
    end
  end
end
