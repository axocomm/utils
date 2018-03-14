#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

# CONFIG_DIR = File.join(Dir.home, '.gp')
CONFIG_DIR = "#{Dir.pwd}/gp"

LIST_LINE_RE = /^([a-z_]+) = (.*)$/

def profiles(config_dir)
  Dir.glob("#{config_dir}/*.yaml").map { |f| File.basename f, '.yaml' }
end

def list_profiles(config_dir)
  puts 'Available Profiles'
  puts '------------------'
  profiles(config_dir).each { |f| puts "- #{f}" }
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

def switch_config(config_dir, profile_name)
  filename = "#{config_dir}/#{profile_name}.yaml"
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

    options[:config_dir] = CONFIG_DIR
    opts.on('-c', '--config-dir DIR', 'Configuration directory') do |dir|
      options[:config_dir] = dir
    end
  end

  optparse.parse!
  options
end

if $PROGRAM_NAME == $0
  opts = parse_args
  config_dir = opts[:config_dir]

  if opts[:list]
    list_profiles config_dir
  elsif profile = ARGV.shift
    unless profiles(config_dir).include?(profile)
      raise "Invalid profile #{profile}"
    end

    switch_config opts[:config_dir], profile
  else
    puts YAML.dump(current_config)
  end
end
