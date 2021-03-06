#!/usr/bin/env ruby

require 'rubygems'

material       = ENV['JIRA_MATERIAL']
from_revision  = ENV["GO_FROM_REVISION#{material}"]
to_revision    = ENV["GO_TO_REVISION#{material}"]
org_repo       = ENV['ORG_REPO']
code_dir       = ARGV[0] || '.'
comment_prefix = ARGV[1] || ''

if from_revision.nil? || to_revision.nil?
  $stderr.puts "Not updating status to Jira, since there is no commit information."
  exit(0)
end

def jira_issue_from_commit_message(message)
  message.sub(/^[^#].*/, '').sub(/^#([^ ]+) .*/, '\1')
end

def issue_comment_body_from_commits(org_repo, commits, comment_prefix)
  comment = commits.collect do |commit|
    _, msg, commit_sha = commit.match(/^(.*) ([0-9a-z]+)$/).to_a
    "&nbsp;&nbsp;[#{msg}|https://github.com/#{org_repo}/commit/#{commit_sha}]"
  end.join("\n")

  url = "http://bcdemo.gocd.io:8153/go/tab/build/detail/#{ENV['GO_PIPELINE_NAME']}/#{ENV['GO_PIPELINE_COUNTER']}/#{ENV['GO_STAGE_NAME']}/#{ENV['GO_STAGE_COUNTER']}/#{ENV['GO_JOB_NAME']}"

  "#{comment_prefix}\nCommits:\n#{comment}\n\nGoCD job: [#{ENV['GO_PIPELINE_NAME']}/#{ENV['GO_STAGE_NAME']}/#{ENV['GO_JOB_NAME']}|#{url}]"
end

begin
  Dir.chdir(code_dir) do
    %x(git log #{from_revision}~1..#{to_revision} --pretty="format:%s %H").split("\n").group_by {|line| jira_issue_from_commit_message(line)}.each do |issue_key, commits|
      if issue_key.empty?
        puts "Not updating Jira with #{commits.size} commit(s) since there is no issue number"
        next
      end

      message = issue_comment_body_from_commits(org_repo, commits, comment_prefix)
      command = message =~ /CLOSE/ ? 'close' : 'comment'

      system(File.join(__dir__, 'jira.rb'), issue_key, command, message)
      puts "Failed to operate on issue #{issue_key} (command: #{command}): #{$?.inspect}" unless $?.success?
    end
  end
rescue => e
  $stderr.puts "Failed to update status to Jira. Something went wrong: #{e.message}"
end
