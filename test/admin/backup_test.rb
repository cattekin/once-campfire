require "test_helper"
require "tmpdir"
require "open3"
require "rbconfig"

class BackupTest < ActiveSupport::TestCase
  setup do
    @root = Dir.mktmpdir("campfire-backup")
    FileUtils.mkdir_p("#{@root}/script/admin")
    FileUtils.mkdir_p("#{@root}/config")
    FileUtils.mkdir_p("#{@root}/storage/db")
    FileUtils.cp(Rails.root.join("script/admin/prepare-backup"), "#{@root}/script/admin")
    FileUtils.cp(Rails.root.join("script/admin/restore-backup"), "#{@root}/script/admin")
    FileUtils.cp(Rails.root.join("config/database.yml"), "#{@root}/config")
    File.write("#{@root}/config/environment.rb", <<~RUBY)
      require "erb"
      require "fileutils"
      require "pathname"
      require "sqlite3"
      require "yaml"
      module Rails
        def self.root = Pathname.new(File.expand_path("..", __dir__))
        def self.env = "production"
        def self.application = self
        def self.config = self
        def self.database_configuration
          YAML.load(ERB.new(root.join("config/database.yml").read).result, aliases: true)
        end
      end
    RUBY
    @connections = database_names.map do |name|
      SQLite3::Database.new("#{@root}/storage/db/#{name}").tap do |database|
        database.execute("PRAGMA journal_mode=WAL")
        database.execute("CREATE TABLE entries (value TEXT)")
        database.execute("INSERT INTO entries VALUES ('before backup')")
      end
    end
  end

  teardown do
    @connections.each { |database| database.close unless database.closed? }
    FileUtils.remove_entry(@root)
  end

  test "snapshots WAL contents of every database and restores snapshots over live files" do
    run_script("prepare-backup")
    @connections.each { |database| database.execute("INSERT INTO entries VALUES ('after backup')") }
    @connections.each(&:close)
    database_names.each do |name|
      %w[ -wal -shm -journal ].each { |suffix| File.write("#{@root}/storage/db/#{name}#{suffix}", "stale") }
    end

    run_script("restore-backup")

    database_names.each do |name|
      %w[ -wal -shm -journal ].each { |suffix| assert_not File.exist?("#{@root}/storage/db/#{name}#{suffix}") }
    end
    (database_names - [ queue_database_name ]).each do |name|
      SQLite3::Database.new("#{@root}/storage/db/#{name}") do |database|
        assert_equal "ok", database.get_first_value("PRAGMA integrity_check")
        assert_equal [ [ "before backup" ] ], database.execute("SELECT value FROM entries")
      end
    end
  end

  test "the queue is neither snapshotted nor restored, so pending jobs are not replayed" do
    run_script("prepare-backup")
    @connections.each(&:close)

    run_script("restore-backup")

    assert_not File.exist?("#{@root}/storage/backups/#{queue_database_name}")
    assert_not File.exist?("#{@root}/storage/db/#{queue_database_name}")
  end

  test "restoring a legacy backup removes auxiliary databases" do
    run_script("prepare-backup")
    @connections.each(&:close)
    database_names.drop(1).each { |name| FileUtils.rm_f("#{@root}/storage/backups/#{name}") }

    run_script("restore-backup")

    assert File.file?("#{@root}/storage/db/production.sqlite3")
    database_names.drop(1).each { |name| assert_not File.exist?("#{@root}/storage/db/#{name}") }
  end

  test "restore without a primary snapshot leaves live databases untouched" do
    @connections.each(&:close)
    run_script("restore-backup")
    database_names.each { |name| assert File.file?("#{@root}/storage/db/#{name}") }
  end

  private
    def database_names
      %w[ production.sqlite3 production_cache.sqlite3 production_queue.sqlite3 production_cable.sqlite3 ]
    end

    def queue_database_name
      "production_queue.sqlite3"
    end

    def run_script(name)
      output, status = Open3.capture2e({ "RAILS_ENV" => "production" }, RbConfig.ruby, "#{@root}/script/admin/#{name}")
      assert status.success?, output
    end
end
