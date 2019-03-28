require 'yaml'

class ParanoidVersioning
  include Comparable

  attr_accessor :major, :minor, :patch, :milestone, :build, :branch, :commiter, :build_date, :format

  [:major, :minor, :patch, :milestone, :build, :branch, :commiter, :build_date, :format].each do |attr|
    define_method "#{attr}=".to_sym do |value|
      instance_variable_set("@#{attr}".to_sym, value.blank? ? nil : value.to_s)
    end
  end

  # Creates a new instance of the version class using information in the passed
  # Hash to construct the version number
  #
  # ParanoidVersioning.new(:major => 1, :minor => 0) #=> "1.0"
  def initialize(args = nil)
    if args && args.is_a?(Hash) 
      args.keys.reject { |key| key.is_a?(Symbol) }.each{ |key| args[key.to_sym] = args.delete(key) }

      [:major, :minor].each do |param|
        raise ArgumentError.new("The #{param.to_s} parameter is required") if args[param].nil?
      end
    end

    @major     = args[:major].to_s
    @minor     = args[:minor].to_s
    @patch     = args[:patch].to_s unless args[:patch].nil?
    @milestone = args[:milestone].to_s unless args[:milestone].nil?
    @branch    = args[:branch].to_s unless args[:branch].nil?
    @commiter  = args[:commiter].to_s unless args[:commiter].nil?
    @format    = args[:format].to_s unless args[:format].nil?

    unless args[:build_date].nil?
      get_date = case args[:build_date]
                        when 'git-revdate', ''
                          get_revdate_from_git
                        else 
                          args[:build_date].to_s
                        end
      @build_date = Date.parse(get_date)
    end

    unless args[:branch].nil?
      @branch = get_branch_name_from_git
    end

    @build = case args[:build]
              when 'git-revcount'
                get_revcount_from_git
              when 'git-hash'
                get_hash_from_git
              when nil, ''
                unless args[:build].nil?
                  args.delete(:build)
                end
              else 
                args[:build].to_s
              end
  end

  # Parses a version string to create an instance of the Version class
  def self.parse(version)
    m = version.match(/(\d+)\.(\d+)(?:\.(\d+))?(?:\sM(\d+))?(?:\sof\s(\w+))?(?:\sby\s(\w+))?(?:\son\s(\S+))?/)

    raise ArgumentError.new("The version '#{version}' is unparsable") if m.nil?

    version = ParanoidVersioning.new :major     => m[1],
                             :minor     => m[2],
                             :patch     => m[3],
                             :milestone => m[4],
                             :build     => m[5],
                             :branch    => m[6],
                             :commiter  => m[7]

    if (m[8] && m[8] != '')
      date = Date.parse(m[8])
      version.build_date = date
    end

    return version

  end

  # Loads the version information from a YAML file
  def self.load(path)
    if File.exist?(path)
      ParanoidVersioning.new YAML::load(File.open(path))
    else 
      recipe = { "major" => 1, "minor" => 0 }
      template_yml = File.read(File.join(File.dirname(__FILE__), 'templates/version.yml'))
      File.open(path, "w+") { |f| f.write template_yml } #Store
      File.open(path, "a") { |f| f << recipe.to_yaml } #Store
      ParanoidVersioning.new YAML::load(File.open(path))
    end
  end

  def to_s
    if @format 
      str = eval(@format.to_s.inspect)
    else  
      str = "#{major}.#{minor}"
      str << ".#{patch}" unless patch.nil?
      str << ".#{milestone} " unless milestone.nil?
      str << "(#{build}) " unless build.nil?
      str << " of #{branch}" unless branch.nil?
      str << " by #{commiter} " unless commiter.nil?
      str << " on #{build_date.strftime('%d/%m/%Y')}" unless build_date.nil?
    end
    str
  end

  def get_revcount_from_git
    if File.exist?(".git")
      `git rev-list --count HEAD`.strip
    end
  end

  def get_revdate_from_git
    if File.exist?(".git")
      `git show --date=short --pretty=format:%cd`.split("\n")[0].strip
    end
  end

  def get_hash_from_git
    if File.exist?(".git")
      `git show --pretty=format:%H`.split("\n")[0].strip[0..5]
    end
  end

  def get_branch_name_from_git
    if File.exist?(".git")
      `git rev-parse --abbrev-ref HEAD`
    end
  end

  if defined?(Rails.root.to_s) && File.exist?("#{(Rails.root.to_s)}/config/version.yml")
    APP_VERSION = ParanoidVersioning.load "#{(Rails.root.to_s)}/config/version.yml"
  end

  def self.get_version
    ParanoidVersioning.load "#{(Rails.root.to_s)}/config/version.yml"
  end

end