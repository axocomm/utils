#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

PROFILE_DIR = "#{Dir.home}/.gp"

LIST_LINE_RE = /^([a-z_]+) = (.*)$/

def profiles(profile_dir)
  Dir.glob("#{profile_dir}/*.yaml")
    .map { |f| File.basename f, '.yaml' }
    .reject { |f| f == 'example' }
end

def list_profiles(profile_dir)
  puts 'Available Profiles'
  puts '------------------'
  profiles(profile_dir).each { |f| puts "- #{f}" }
end

def current_config
  out = `gcloud config list 2>/dev/null`
  raise 'Could not get configuration' unless out
  out.split(/\n/).drop(1).inject({}) do |acc, line|
    if m = LIST_LINE_RE.match(line)
      acc[m[1]] = m[2]
    end

    acc
  end
end

def switch_config(profile_dir, profile_name)
  filename = "#{profile_dir}/#{profile_name}.yaml"
  profile = YAML.load_file filename
  cmd = profile.map { |(k, v)| "gcloud config set #{k} #{v}" }.join(' && ')
  system(cmd)
end

def parse_args
  options = {}
  optparse = OptionParser.new do |opts|
    options[:list] = false
    opts.on('-l', '--list', 'List profiles') do
      options[:list] = true
    end

    options[:profile_dir] = PROFILE_DIR
    opts.on('-d', '--profile-dir DIR', 'Profile directory') do |dir|
      options[:profile_dir] = dir
    end
  end

  optparse.parse!
  options
end

if $PROGRAM_NAME == $0
  opts = parse_args
  profile_dir = opts[:profile_dir]

  if opts[:list]
    list_profiles profile_dir
  elsif profile = ARGV.shift
    unless profiles(profile_dir).include?(profile)
      raise "Invalid profile #{profile}"
    end

    switch_config opts[:profile_dir], profile
  else
    puts YAML.dump(current_config)
  end
end
